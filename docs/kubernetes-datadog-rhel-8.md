
# Docker and Kubernetes installation with the Datadog operator integration in a new RHEL 8.10

As root user set a hostname

```bash
hostnamectl set-hostname <new-server-hostname>
```

Harcode the current server in the next file

```bash
echo "<the-server-IP> <new-server-hostname>" >> /etc/hosts
```

Disable SELinux (both actually and permanently)

```bash
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

Add at OS level the `kube` user, put it a password and add it to the sudoers file

```bash
adduser kube --shell /bin/bash
echo "<the-new-secure-password>" | passwd --stdin kube
echo "kube  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
```

Create/edit the next kernel configuration files with the next content

```bash
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

```bash
cat <<EOF | tee -a /etc/sysctl.conf
net.ipv4.ip_forward = 1
EOF
```

Apply the changes

```bash
sysctl --system
sysctl -p
```

(Optional in EC2 instances) Disable the SWAP

```bash
swapoff -a
vi /etc/fstab
```

(If `wget` is not installed) Download the `wget` library

```bash
dnf -y install wget
```

Download the next docker repository file

```bash
wget https://download.docker.com/linux/centos/docker-ce.repo
```

Move the previous file to the respective path

```bash
mv docker-ce.repo /etc/yum.repos.d/
```

Install docker

```bash
dnf -y install containerd.io docker-ce-cli docker-ce
```

Enable the docker daemon that is currently running

```bash
systemctl enable --now docker
```

Add the kube user to the docker group to pull local images

```bash
usermod -aG docker kube
```

Create the next kubernetes repository file

```bash
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF
```

Install kubernetes

```bash
dnf install -y kubelet kubeadm kubectl kubernetes-cni --disableexcludes=kubernetes
```

Enable the kubernetes service actually running

```bash
systemctl enable --now kubelet
```

Remove the default `containerd` configuration and restart the `containerd` service

```bash
rm -f /etc/containerd/config.toml
systemctl restart containerd
```

Create the next cluster information changing the *ClusterName* and *controlPlaneEndpoint* values

```bash
cat <<EOF | tee cluster-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: "<your-new-cluster-name>"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/24"
  dnsDomain: "cluster.local"
kubernetesVersion: "v1.30.4"
controlPlaneEndpoint: "<the-server-ip>:6443"
certificatesDir: "/etc/kubernetes/pki"
imageRepository: "registry.k8s.io"
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0
scheduler:
  extraArgs:
    bind-address: 0.0.0.0
EOF
```

Create cluster using the previous file with the next parameters

```bash
kubeadm init --config cluster-config.yaml  --ignore-preflight-errors Swap --v=5
```

>![NOTE]
>The last command output says you to do the next and give you some tokens that you need to store safely

As **kube user** run the following commands

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Download the `kube-flannel.yml` file

```bash
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Apply the previous kube-flannel

```bash
kubectl apply -f kube-flannel.yml
```

(Looking for this)

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## Datadog integration

As kube user install `helm`

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
```

```bash
chmod 700 get_helm.sh
```

(this requires git)

```bash
./get_helm.sh
```

Verify installation

```bash
helm version
```

As `kube` user run the following commands

```bash
helm repo add datadog https://helm.datadoghq.com
```

```bash
helm repo update
```

Add the operator to the cluster (this create 1 deployment and 1 pod)

```bash
helm install datadog-operator datadog/datadog-operator
```

Add the Datadog API Key to the cluster

```bash
kubectl create secret generic datadog-secret --from-literal api-key=<your-datadog-console-api-key> --from-literal app-key=<your-datadog-console-api-key>
```

Create a new `datadog.yaml` file. Content:

```yaml
apiVersion: datadoghq.com/v2alpha1
kind: DatadogAgent
metadata:
  name: <your-hostname-visible-in-datadog-console>
spec:
  global:
    clusterName: <your-cluster-name-as-in-config>
    kubelet:
      tlsVerify: false
    credentials:
      apiSecret:
        secretName: datadog-secret
        keyName: api-key
      appSecret:
        secretName: datadog-secret
        keyName: app-key
    site: datadoghq.com
    tags:
      - env:
      - service:
      - app:
      - clkube:
  override:
    nodeAgent:
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/control-plane
          operator: Exists
  features:
    clusterChecks:
      enabled: true
    eventCollection:
      collectKubernetesEvents: true
    liveProcessCollection:
      enabled: true
    liveContainerCollection:
      enabled: true
    orchestratorExplorer:
      enabled: true
    admissionController:
      enabled: true
      agentCommunicationMode: service
      mutateUnlabelled: false
    apm:
      enabled: true
      instrumentation:
        enabled: true
        enabledNamespaces:
          - default
          - kube-flannel
          - kube-node-lease
          - kube-public
          - kube-system
    dogstatsd:
      hostPortConfig:
        enabled: true
    logCollection:
      enabled: true
      containerCollectAll: true
    asm:
      threats:
        enabled: true
      sca:
        enabled: true
      iast:
        enabled: true
    cws:
      enabled: true
    cspm:
      enabled: true
    sbom:
      enabled: true
      containerImage:
        enabled: true
      host:
        enabled: true
    usm:
      enabled: true
    npm:
      enabled: true
    processDiscovery:
      enabled: true
    oomKill:
      enabled: true
    tcpQueueLength:
      enabled: true
    ebpfCheck:
      enabled: true
    otlp:
      receiver:
        protocols:
          grpc:
            enabled: true
    remoteConfiguration:
      enabled: true
    kubeStateMetricsCore:
      enabled: true
    externalMetricsServer:
      enabled: true
    prometheusScrape:
      enabled: true

```

> [!NOTE]
> The global.tags will be propagated to the pods and their logs but not to the APM traces from the pods


> [!NOTE]
> This yaml uses the "admission controller" to inject the necessary environment variables to the application pods

Apply the Datadog integration (this agent creates 3 pods, 3  services, 1 daemonset, 2 deployment, 3 replicaset y varios jobs)

```bash
kubectl apply -f datadog.yml
```

Verify that the Cluster Agent is created successfully

```bash
kubectl get deployments
```

Check if the Node Agent DaemonSet is running (Not continue until the ds is completed)

```bash
kubectl get ds
```
Verify that the pods called "datadog-agent..." and "datadog-cluster-agent..." exists 

```bash
kubectl get pods -o wide
```

(Optional) Run the `datadog-agent status` command inside the Agents

```bash
kubectl exec -ti <agent-or-cluster-agent-pod-name> -- agent status
```

### Tagging the pods with extra tags

- The fields in the `spec.template.metadata.labels` will become extra tags to the pods created from this deployment
- The logs from the pods will only have the tags propagated by kubernetes or by the agent

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <a-deployment-name>
  ...
spec:
  ...
  selector:
    matchLabels:
      name: <a-deployment-name>
  template:
    metadata:
      labels:
        name: <a-deployment-name>
        admission.datadoghq.com/enabled: "true"
        my.custom.tag: "customvalue"
      ...
    spec:
        ...
```

### Collect APM traces from the application pods

- Keep in mind that the containers should have activity or requests to report traces
- Ensure that the datadog agent has the Admission Controller configured in the `datadog.yaml` file

```yaml
...
spec:
  ...
  features:
    admissionController:
      agentCommunicationMode: service
      mutateUnlabelled: false
    apm:
      enabled: true
      instrumentation:
        enabled: true
        enabledNamespaces:
          - default
          - kube-flannel
          - kube-node-lease
          - kube-public
          - kube-system
    dogstatsd:
      hostPortConfig:
        enabled: true
    logCollection:
      enabled: true
      containerCollectAll: true
    ...
```

- Ensure that the application `.yaml` files have the `admission.datadoghq.com/enabled: "true"` label 
- Ensure that the application `.yaml` files have the `admission.datadoghq.com/<lang>-lib.version: "latest"` annotation where the lang can be: python, java, js, ruby and more
- Ensure that every container have the 'DD_TRACE_ANALYTICS_ENABLED', 'DD_LOGS_INJECTION', 'DATADOG_SERVICE_NAME' environment variables
- Add extra tags to the pod in the labels in the format `myowntag: "mycustomvalue"`

```yaml
...
spec:
  ...
  template:
    metadata:
      labels:
        admission.datadoghq.com/enabled: "true"
      annotations:
        admission.datadoghq.com/<python,java,js,ruby>-lib.version: "latest"
        ...
    spec:
      containers:
          ...
          env:
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: 'true'
            - name: DD_LOGS_INJECTION
              value: 'true'
            - name: DATADOG_SERVICE_NAME
              value: '<service-name-visible-in-datadog-apm-console>'
              ...

```

> ![INFO]
> I cannot find how to stablish tags exclusively to the individual pod logs or pod traces

### Cleanup

- Having the operator working delete the agent by simply running `kubectl delete -f datadog.yaml`, ensure that is deleted the `deployment` and `ds`, then unninstal the operator with helm running `helm uninstall datadog-operator datadog/datadog-operator`
- If the operator is failing then delete the pods, ds and deployment of the agent (in that order) by running `kubectl delete <pod/ds/deployment> <name>` and then let the operator to run properly. Once the operator is recovered follow the above step

#### test application yaml from a datadog course

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-service
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: frontend-service
  template:
    metadata:
      labels:
        app: frontend-service
        admission.datadoghq.com/enabled: "true"
          #annotations:
          #admission.datadoghq.com/js-lib.version: "latest"
    spec:
      containers:
        - name: frontend-service
          image: burningion/k8s-distributed-tracing-frontend:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5005
              #name: frontendport
                #protocol: TCP
          env:
            - name: DD_LOGS_INJECTION
              value: 'true'
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: 'true'
            - name: DATADOG_SERVICE_NAME
              value: 'gke'
            - name: FLASK_APP
              value: 'api'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5005'
            - name: DATADOG_PATCH_MODULES
              value: 'requests:true'
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP
  selector:
    app: frontend-service
  ports:
    - name: http
      port: 80
      targetPort: 5005

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-external
  labels:
    app: frontend-service
spec:
  type: LoadBalancer
  selector:
    app: frontend-service
  ports:
  - name: http
    port: 80
    targetPort: 5005
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: node-api
  template:
    metadata:
      labels:
        app: node-api
        admission.datadoghq.com/enabled: "true"
          #annotations:
          #admission.datadoghq.com/js-lib.version: "latest"
    spec:
      containers:
        - name: node-api
          image: burningion/k8s-distributed-tracing-users:latest
          imagePullPolicy: Always
#          ports:
#            - containerPort: 5004
#              name: node-port
#              hostPort: 5004
          env:
          - name: DD_SERVICE_NAME
            value: 'gke'
          - name: DD_LOGS_INJECTION
            value: 'true'
          - name: DD_TRACE_ANALYTICS_ENABLED
            value: 'true'
---
apiVersion: v1
kind: Service
metadata:
  name: node-api
spec:
  selector:
    app: node-api
  ports:
    - name: http
      protocol: TCP
      port: 5004
  type: NodePort

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pumps-service
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: pumps-service
  template:
    metadata:
      labels:
        app: pumps-service
        admission.datadoghq.com/enabled: "true"
          #annotations:
          #admission.datadoghq.com/js-lib.version: "latest"
    spec:
      containers:
        - name: pumps-service
          image: burningion/k8s-distributed-tracing-pumps:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5001
          env:
            - name: DATADOG_SERVICE_NAME
              value: 'gke'
            - name: DD_LOGS_INJECTION
              value: 'true'
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: 'true'
            - name: FLASK_APP
              value: 'thing'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5001'
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-user
                  key: token
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-password
                  key: token
---
apiVersion: v1
kind: Service
metadata:
  name: pumps-service
spec:
  selector:
    app: pumps-service
  ports:
    - name: http
      protocol: TCP
      port: 5001
  type: NodePort

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sensors-api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: sensors-api
  template:
    metadata:
      labels:
        app: sensors-api
        admission.datadoghq.com/enabled: "true"
          # annotations:
          # admission.datadoghq.com/js-lib.version: "latest"
    spec:
      containers:
        - name: sensors-api
          image: burningion/k8s-distributed-tracing-sensors:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5002
          env:
            - name: DATADOG_SERVICE_NAME
              value: 'sensors-api'
            - name: DD_LOGS_INJECTION
              value: 'true'
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: 'true'
            - name: FLASK_APP
              value: 'sensors'
            - name: FLASK_DEBUG
              value: '1'
            - name: FLASK_RUN_PORT
              value: '5002'
            - name: POSTGRES_USER
              value: "postgres"
            - name: POSTGRES_PASSWORD
              value: "postgres"
---
apiVersion: v1
kind: Service
metadata:
  name: sensors-api
spec:
  selector:
    app: sensors-api
  ports:
    - name: http
      protocol: TCP
      port: 5002
  type: NodePort
```

## amazon linux 2023

hostnamectl set-hostname 
dnf update -y
dnf install -y docker
systemctl enable --now docker
systemctl start docker
setenforce -1
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k7s.io/core:/stable:/v1.29/rpm/
enabled=0
gpgcheck=0
gpgkey=https://pkgs.k7s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
kubeadm init --apiserver-advertise-address= --pod-network-cidr=10.244.0.0/24

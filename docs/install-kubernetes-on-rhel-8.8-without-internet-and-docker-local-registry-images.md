
# Install Kubernetes without internet and use a local docker registry

## Prerequisites

-  OS: RHEL 8.8

Set properly the hostname and IP server on `/etc/hosts` file

```bash
echo "your-private-ip-address  your-hostname   your-web-server-endpoint" >> /etc/hosts
```

Set SELinux in `permissive` mode

```bash
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

Crear usuario

```bash
adduser kube --shell /bin/bash
echo "mysupersecurepassword" | passwd --stdin kube
```

Add "sudo" permissions to the `kube` user

```bash
echo "kube  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
```

Add Firewall permissions for Kubernetes and Docker

```bash
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --reload
```

Set the next Linux Kernel parameters

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

Update the parameters

```bash
sysctl --system
sysctl -p
```

Disable the system swap

```bash
swapoff -a
vi /etc/fstab
```


```bash
#https://download.docker.com/linux/centos/8/x86_64/stable/Packages/
```

Download the next previous RPM packages

```bash
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/iproute-tc-5.18.0-1.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libnetfilter_queue-1.0.4-3.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libnetfilter_cttimeout-1.0.0-11.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libnetfilter_cthelper-1.0.0-15.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/conntrack-tools-1.4.4-11.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/socat-1.7.4.1-1.el8.x86_64.rpm
```

Install them with RPM

```bash
rpm -ivh iproute-tc-5.18.0-1.el8.x86_64.rpm \
    libnetfilter_queue-1.0.4-3.el8.x86_64.rpm \
    libnetfilter_cttimeout-1.0.0-11.el8.x86_64.rpm \
    libnetfilter_cthelper-1.0.0-15.el8.x86_64.rpm \
    conntrack-tools-1.4.4-11.el8.x86_64.rpm \
    socat-1.7.4.1-1.el8.x86_64.rpm
```

## Download and install Docker-CE 26.0.0

Download the next RPM packages

```bash
wget https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/container-selinux-2.229.0-2.module_el8+847+7863d4e6.noarch.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.28-3.2.el8.x86_64.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-cli-26.0.0-1.el8.x86_64.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libcgroup-0.41-19.el8.x86_64.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-26.0.0-1.el8.x86_64.rpm
```

Install them with RPM

```bash
rpm -ivh container-selinux-2.229.0-2.module_el8+847+7863d4e6.noarch.rpm \
    containerd.io-1.6.28-3.2.el8.x86_64.rpm \
    docker-ce-cli-26.0.0-1.el8.x86_64.rpm \
    libcgroup-0.41-19.el8.x86_64.rpm \
    docker-ce-26.0.0-1.el8.x86_64.rpm
```

Start the Docker service

```bash
systemctl enable docker
systemctl enable --now docker
systemctl status docker
```

## Download and install Kubernetes

Download the next RPM packages

```bash
wget https://pkgs.k8s.io/core:/stable:/v1.29/rpm/x86_64/cri-tools-1.29.0-150500.1.1.x86_64.rpm
wget https://pkgs.k8s.io/core:/stable:/v1.29/rpm/x86_64/kubectl-1.29.3-150500.1.1.x86_64.rpm
wget https://pkgs.k8s.io/core:/stable:/v1.29/rpm/x86_64/kubernetes-cni-1.3.0-150500.1.1.x86_64.rpm
wget https://pkgs.k8s.io/core:/stable:/v1.29/rpm/x86_64/kubelet-1.29.3-150500.1.1.x86_64.rpm
wget https://pkgs.k8s.io/core:/stable:/v1.29/rpm/x86_64/kubeadm-1.29.3-150500.1.1.x86_64.rpm
```

Install them with RPM

```bash
rpm -ivh cri-tools-1.29.0-150500.1.1.x86_64.rpm \
    kubectl-1.29.3-150500.1.1.x86_64.rpm \
    kubernetes-cni-1.3.0-150500.1.1.x86_64.rpm \
    kubelet-1.29.3-150500.1.1.x86_64.rpm \
    kubeadm-1.29.3-150500.1.1.x86_64.rpm
```

Obtener la lista de imagenes que necesita Kubernetes:

```bash
kubeadm config images list --kubernetes-version=v1.29.3
```

Descargar image para Networking

```bash
#wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
#grep image kube-flannel.yml
```

======================== DESCARGAR Y EMPAQUETAR IMAGENES ========================
Descargar las imagenes Docker en otra PC con Internet y llevarlas al server

```bash
mkdir /docker-images
cd /docker-images
```

pull the images

```bash
docker pull registry

docker pull registry.k8s.io/kube-apiserver:v1.29.3
docker pull registry.k8s.io/kube-controller-manager:v1.29.3
docker pull registry.k8s.io/kube-scheduler:v1.29.3
docker pull registry.k8s.io/kube-proxy:v1.29.3
docker pull registry.k8s.io/pause:3.9
docker pull registry.k8s.io/etcd:3.5.12-0
docker pull registry.k8s.io/coredns/coredns:v1.11.1

docker pull docker.io/flannel/flannel:v0.24.4
docker pull docker.io/flannel/flannel-cni-plugin:v1.4.0-flannel1
```

save images as TAR archives
docker save registry > registry.tar

```bash
docker save registry.k8s.io/kube-apiserver:v1.29.3 > kube-apiserver_v1.29.3.tar
docker save registry.k8s.io/kube-controller-manager:v1.29.3 > kube-controller-manager_v1.29.3.tar
docker save registry.k8s.io/kube-scheduler:v1.29.3 > kube-scheduler_v1.29.3.tar
docker save registry.k8s.io/kube-proxy:v1.29.3 > kube-proxy_v1.29.3.tar
docker save registry.k8s.io/pause:3.9 > pause_3.9.tar
docker save registry.k8s.io/etcd:3.5.12-0 > etcd_3.5.12-0.tar
docker save registry.k8s.io/coredns/coredns:v1.11.1 > coredns_v1.11.1.tar

docker save docker.io/flannel/flannel:v0.24.4 > flannel_v0.24.4.tar
docker save docker.io/flannel/flannel-cni-plugin:v1.4.0-flannel1 > flannel-cni-plugin_v1.4.0-flannel1.tar
```

Package all TAR files

```bash
tar cvfz k8s-images.tar.gz *
```


Extaer las imagenes

```bash
mkdir -p /images-extract
tar -xzvf k8s-images.tar.gz -C /images-extract
cd /images-extract
for x in *.tar; do docker load < $x && echo "loaded from file $x"; done;
```

Modificar la imagen de Containerd

```bash
containerd config default | tee /etc/containerd/config.toml
sed -i "s/sandbox_image\ =\ \"registry.k8s.io\/pause:3.6\"/sandbox_image\ =\ \"localhost:5000\/pause:3.9\"/g" /etc/containerd/config.toml
systemctl restart containerd
systemctl status containerd
```

Reinciciar

```bash
shutdown -Fr now
```

Iniciar contenedor de Registry

```bash
docker run -d -p 5000:5000 --name registry registry
```

Realizar el registro y tag de imagenes descargadas.

```bash
docker tag registry.k8s.io/kube-apiserver:v1.29.3 localhost:5000/kube-apiserver:v1.29.3
docker tag registry.k8s.io/kube-controller-manager:v1.29.3 localhost:5000/kube-controller-manager:v1.29.3
docker tag registry.k8s.io/kube-scheduler:v1.29.3 localhost:5000/kube-scheduler:v1.29.3
docker tag registry.k8s.io/kube-proxy:v1.29.3 localhost:5000/kube-proxy:v1.29.3
docker tag registry.k8s.io/pause:3.9 localhost:5000/pause:3.9
docker tag registry.k8s.io/etcd:3.5.12-0 localhost:5000/etcd:3.5.12-0
docker tag registry.k8s.io/coredns/coredns:v1.11.1 localhost:5000/coredns:v1.11.1
docker tag docker.io/flannel/flannel:v0.24.4 localhost:5000/flannel:v0.24.4
docker tag docker.io/flannel/flannel-cni-plugin:v1.4.0-flannel1 localhost:5000/flannel-cni-plugin:v1.4.0-flannel1
```

```bash
docker push localhost:5000/kube-apiserver:v1.29.3
docker push localhost:5000/kube-controller-manager:v1.29.3
docker push localhost:5000/kube-scheduler:v1.29.3
docker push localhost:5000/kube-proxy:v1.29.3
docker push localhost:5000/pause:3.9
docker push localhost:5000/etcd:3.5.12-0
docker push localhost:5000/coredns:v1.11.1
docker push localhost:5000/flannel:v0.24.4
docker push localhost:5000/flannel-cni-plugin:v1.4.0-flannel1
```

Start the kubelet service

```bash
systemctl enable kubelet
systemctl enable --now kubelet
systemctl status kubelet
```

Initialize Kubernetes

```bash
kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --apiserver-advertise-address=192.168.200.100  \
    --kubernetes-version=v1.29.3 \
    --ignore-preflight-errors Swap  \
    --image-repository localhost:5000 \
    --v=5
```

Become `kube` user

```bash
su - kube
```

Copy the generated configuration

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Change the image URL in the YML to the local images

```bash
sudo cp /root/rhel-8.8-packages-install-k8s-v1.29.3/kube-flannel.yml /images-extract
cd /images-extract
```

> [!WARNING]
> Remember to replace the local image to Flannel

Validate what is the image in the `kube-flannel.yml` file

```bash
grep image kube-flannel.yml
```

Apply network configurations

```bash
kubectl apply -f kube-flannel.yml
kubectl get pods -A
kubectl get nodes
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

> **Example:** Importing an NGINX image and registering it locally

```bash
docker load < nginx.tar
docker tag nginx localhost:5000/nginx
docker push localhost:5000/nginx
```

Once the image is registered, create the YAML deployment file

```bash
su - kube
vi nginx-deployment.yaml
```

Contenido

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: localhost:5000/nginx
        ports:
        - containerPort: 8080
```

Run application

```bash
kubectl apply -f nginx-deployment.yaml
```



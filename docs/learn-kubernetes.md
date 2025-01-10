
# Learning kubernetes

## About installation

- Is required to previously disable the system swap
- Is required to previously install a container runtime as docker, containerd or CRI-O
- Install the necessary to run the kubeadm, kubelet, kubectl and kubernetes-cni repositories in all of the machines
- It is possible to deploy a cluster in multiple VMs after running `kubeadm init` command in the master node VM and then join the node VMs using the `kubeadm join` command
- Once created de cluster remember to copy the ~/.kube files to your current user home
  - Once created de cluster should not be necessary to run commands in the node VMs, only in the master VM

This are the resources in kubernetes:

- Deployment: is the most common way to create multiple pods via replicas
- ConfigMap: instead of create resources this is useful to set enviroments variables or mount volumes in future deployments, curiously is used with `kubectl apply` and `delete`
- DaemonSet: deploys 1 specific pod per node, this is more used for monitoring tools like the Datadog Agent
- Statefullset: ideal to statefull applications (go down to the storage section)
- PVC: is the storage volume related to StatefullSet component
- Service: is equal to a set of pods
  - There are different types of services (go down to the Networking section)
  - kube-proxy and ... are under the hood all sets of pods
- Secret: this can be applied with an `apply`
  - really this is cyphered wiht base64 in etcd, this is no enough encryption
- Ingress: Is like an nginx (go down to the Networking section)
- Kustization: automate the utilization of the yamls
  - the API is kustomize.config.k8s.io/v1beta1 and use a different command `kustomize`

This are kubernetes important components:

- Container runtime: commonly docker or containerd
- kubelet: is a process existent in each node and enables comunication between the container and the node
- kube-proxy: is a process that route the network traffic between the node pods
- API Server: is the "worker nodes gatekeeper", validate and authenticate requests from nodes and then perform actions. Is the entrypoint to the cluster
- Scheduler: Just decide where to put each new pod and how much resources provide to them. Once decided is kubelet who perform that order
- etcd: database (like the terraform state) that describe each Kubernetes cluster
- Controller Manager: Detects cluster state changes and then request changes to the scheduler
- CCM: The Cloud Controller Manager that enables the comunications between the kubernetes clusters and the Cloud service (AKS, EKS)

In a new cluster, by default these pods are created: kube-apiserver, kube-controller-manager, kube-scheduler, etcd, kube-proxy and the CNI plugins like flannel maybe

Considerations:

- The nodes are not specified because kubernetes is desired-state and specifying nodes can add more human error. Each worker node has their kubelet, kube-proxy and container runtime
- A kubernetes cluster can have multiple master nodes (commonly two), each one with their API Server, Scheduler, Controler Manager and etcd
- Stablishing `requests` and `limits` fields in the deployments yaml, is the Linux Kernel (and not kubernetes) who kill or do throttling the specified pod
- An quick and easy way to expose a webpage is to create a deployment together to their Service separated by `---` matching the selectors
- To expose correctly a webpage, the way is the LoadBalancer service type because the other uses variable IPs and the LoadBalancer type assign an IP to the Service that is not variable, and using Cloud Providers this type can provision an load balancer in the Cloud Provider, all with only 1 yaml and some commands
- In on-premise environments you can have worker/master nodes in different machines

Tools: 
- stern: watch logs more efficiently

## Networking

- Each pod has their own IP, that IP is accessible for all other IPs and changes on restartings
- Each node changes on restartings their own IP
- Each container inside a pod uses the pod's IP to comunicate with containers in other pods
- Each pod uses the CNI as calico/flannel for example (similar to kubelet) that enable each node to use the network
  - The CNI as calico/flannel creates IP routes that links the IPs properly
  - Calico might not be pre-installed, in that case apply it from the .yaml file

Services types:

- ClusterIP: An fixed IP inside the cluster, shared for all pods inside it, this is the default
- NodePort: This creates a port in each node that will receive the trafic and redirects the traffic to the proper pod. Then you can assign the container port, the pod port and the node port to expose
- LoadBalancer: Is more near to the Cloud Provider, literally can creates Load Balancers in the Cloud Provider

Ingress: Uses a different API because is more recent (networking.k8s.io/v1) and is a little more complex
  - By default is not built-in in kubernetes or in the Cloud services (AKS, EKS) and maybe manual installation would be required (can be installed with helm)
  - Under the hood is an nginx because this enables paths
  - The only disadvantage is that all the deployments are created separately



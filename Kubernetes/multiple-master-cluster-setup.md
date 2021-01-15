Setup K8s Multiple Master Nodes Cluster ON Centos Server
---------

## K8s Cluster Nodes

+ master Node   10.124.44.105
+ master Node   10.124.44.106
+ master Node   10.124.44.107 
    
## Configure Host Name for all servers

- Edit /etc/hosts, append below lines:
``` bash
10.124.44.105   k8s-master
10.124.44.106   k8s-node1
10.124.44.107   k8s-node2
```

## Haproxy deployment on all k8s nodes
- create haproxy configuration file
``` bash
mkdir /etc/haproxy
```

``` bash
touch /etc/haproxy/haproxy.cfg
```

``` bash
cat >> /etc/haproxy/haproxy.cfg << EOF
# haproxy.cfg settings
global
    log         127.0.0.1 local2
    maxconn     4000

\# common defaults that all the 'listen' and 'backend' sections will
\# use if not designated in their block

defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    option http-server-close
    \# option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000


\# main frontend which proxys to the backends

frontend  kubernetes-apiserver
    mode tcp
    bind *:9443
    # bind *:443 ssl # To be completed ....

    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    default_backend             kubernetes-apiserver


\# round robin balancing between the various backends

backend kubernetes-apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
         \# k8s-apiservers backend
         server master-10.124.44.105 10.124.44.105:6443 check
         server master-10.124.44.106 10.124.44.106:6443 check
         server master-10.124.44.107 10.124.44.107:6443 check
EOF
```

- run docker image

```bash
docker run -d --name=diamond-haproxy --net=host  -v /etc/haproxy:/usr/local/etc/haproxy/:ro haproxy
```
## Keepalived Deployment

- Create configuration file

```bash
mkdir /etc/keepalived/ && cd /etc/keepalived/
touch keepalived.conf
```
```bash
global_defs {
   script_user root
   enable_script_security

}

vrrp_script chk_haproxy {
    script "/bin/bash -c 'if [[ $(netstat -nlp | grep 9443) ]]; then exit 0; else exit 1; fi'"  # haproxy check
    interval 2
    weight 11
}

vrrp_instance VI_1 {
  interface ens32

  state MASTER # node role by default, this is master node
  virtual_router_id 51 # same id means same virtual group
  priority 100 # weight
  nopreempt # role can change to be master

  unicast_peer {

  }

  virtual_ipaddress {
    10.124.44.125  # vip
  }

  authentication {
    auth_type PASS
    auth_pass password
  }

  track_script {
      chk_haproxy
  }

  # notify "/container/service/keepalived/assets/notify.sh"
}
```

- run keepalived container

```bash
docker run --cap-add=NET_ADMIN --cap-add=NET_BROADCAST --cap-add=NET_RAW --net=host --volume /etc/keepalived/keepalived.conf:/usr/local/etc/keepalived/keepalived.conf -d osixia/keepalived:2.0.20 --copy-service
```

## Deploy Kubernetes with Kubeadm

- Set yum repo

```bash
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# clean yum cache & recache
yum clean all
yum makecache
```
- Stop firewalld & Disable selinux

``` bash
systemctl stop firewalld
systemctl disable firewalld

setenforce 0
vim /etc/selinux/config
set SELINUX=disabled
```

- Create K8s.conf

``` bash
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

- Enable IPv4 forward

```bash
vi /etc/sysctl.conf
net.ipv4.ip_forward = 1
sysctl -p
```

- Turn Off Swap

```bash
swapoff -a
```
comment out the line.
```bash
vi /etc/fstab
#/dev/mapper/cl-swap     swap                    swap    defaults        0 0
```
- Add K8s yum Repo

```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

- Install Kubernetes Components

```bash
yum -y install kubectl kubelet kubeadm
systemctl enable kubelet && systemctl start  kubelet
```

- kubernetes cluster init

```bash
kubeadm init --control-plane-endpoint "10.124.44.125:6443" --upload-certs --pod-network-cidr=10.244.0.0/16
```

+ kubeadm init --control-plane-endpoint "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT" --upload-certs --pod-network-cidr=10.244.0.0/16

+ Here, LOAD_BALANCER_DNS is the IP address or the dns name of the loadbalancer. I will use the dns name of the server, i.e. loadbalancer as the LOAD_BALANCER_DNS. In case your DNS name is not resolvable across your network, you can use the IP address for the same.

+ The LOAD_BALANCER_PORT is the front end configuration port defined in HAPROXY configuration. For this demo, we have kept the port as 6443.


+ After execution the command, below 3 commands output:
* 1# command
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
* 2# command

The command execute on master node: '**kubeadm init phase upload-certs --experimental-upload-certs**' update the --certificate-key if expired.
```bash
kubeadm join 10.124.44.125:6443 --token lfku8c.bbbewtcyh0j9v31z     --discovery-token-ca-cert-hash sha256:4273c55072f4ea08e3535ba33397c779f4576c81f198a4809655cf80c406d703     --control-plane --certificate-key 3c21216e68441116ca3a68ee93a8a31343746c8a56d5f11729fb1885ef9717f3
```
* 3# command

The command execute on master node: '**kubeadm token create --print-join-command**' generate the join token command.
```bash
kubeadm join 10.124.44.125:6443 --token u7djab.gih4reqcnbeplo53     --discovery-token-ca-cert-hash sha256:4273c55072f4ea08e3535ba33397c779f4576c81f198a4809655cf80c406d703 
```
    
#1 command: execute this command on the master node to enable kubectl api.

#2 command: the command is to add master node to the cluster.

#3 command: the command is to add worker node to the cluster.

- How to resolve: k8s inner pod cannot visit clusterIP and service ip

https://www.cnblogs.com/52py/p/14141385.html

- How to resolve: Can not access service by curl <ClusterIP>:<Port>
   
https://github.com/kubernetes/kubernetes/issues/37199

## Manage certs

- Check certs expiration date

``` bash
[root@k8s-master ~]# kubeadm alpha certs check-expiration
Command "check-expiration" is deprecated, please use the same command under "kubeadm certs"
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jan 15, 2022 00:51 UTC   364d                                    no      
apiserver                  Jan 15, 2022 00:51 UTC   364d            ca                      no      
apiserver-etcd-client      Jan 15, 2022 00:51 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Jan 15, 2022 00:51 UTC   364d            ca                      no      
controller-manager.conf    Jan 15, 2022 00:51 UTC   364d                                    no      
etcd-healthcheck-client    Jan 15, 2022 00:51 UTC   364d            etcd-ca                 no      
etcd-peer                  Jan 15, 2022 00:51 UTC   364d            etcd-ca                 no      
etcd-server                Jan 15, 2022 00:51 UTC   364d            etcd-ca                 no      
front-proxy-client         Jan 15, 2022 00:51 UTC   364d            front-proxy-ca          no      
scheduler.conf             Jan 15, 2022 00:51 UTC   364d                                    no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jan 12, 2031 07:26 UTC   9y              no      
etcd-ca                 Jan 12, 2031 07:26 UTC   9y              no      
front-proxy-ca          Jan 12, 2031 07:26 UTC   9y              no 
```

- renew certs if expired

+ execute the command **kubectl get cm -o yaml -n kube-system kubeadm-config**.
+ Get the **ClusterConfiguration** section from the output and save as **kubeadm.yaml**.
``` bash
[root@k8s-master ~]# kubectl get cm -o yaml -n kube-system kubeadm-config

apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
      timeoutForControlPlane: 4m0s
    apiVersion: kubeadm.k8s.io/v1beta2
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controlPlaneEndpoint: 10.124.44.125:6443
    controllerManager: {}
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: k8s.gcr.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.20.2
    networking:
      dnsDomain: cluster.local
      podSubnet: 10.244.0.0/16
      serviceSubnet: 10.96.0.0/12
    scheduler: {}
  ClusterStatus: |
    apiEndpoints:
      k8s-master:
        advertiseAddress: 10.124.44.105
        bindPort: 6443
      k8s-node1:
        advertiseAddress: 10.124.44.106
        bindPort: 6443
      k8s-node2:
        advertiseAddress: 10.124.44.107
        bindPort: 6443
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterStatus
kind: ConfigMap
metadata:
  creationTimestamp: "2021-01-14T07:27:47Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:ClusterConfiguration: {}
        f:ClusterStatus: {}
    manager: kubeadm
    operation: Update
    time: "2021-01-14T07:27:47Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "2411"
  uid: 37764103-a41e-455e-b688-9c1e5df5ae1c
```

- backup the certs and configurations and etcd data

``` bash
$ mkdir /etc/kubernetes.bak
$ cp -r /etc/kubernetes/pki/ /etc/kubernetes.bak
$ cp /etc/kubernetes/*.conf /etc/kubernetes.bak
```

``` bash
$ cp -r /var/lib/etcd /var/lib/etcd.bak
```

- run command to renew the certs

```
[root@k8s-master kubernetes]# kubeadm alpha certs renew all --config=kubeadm.yaml
Command "all" is deprecated, please use the same command under "kubeadm certs"
certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate the apiserver uses to access etcd renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for liveness probes to healthcheck etcd renewed
certificate for etcd nodes to communicate with each other renewed
certificate for serving etcd renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler manager to use renewed

Done renewing certificates. You must restart the kube-apiserver, kube-controller-manager, kube-scheduler and etcd, so that they can use the new certificates.

```

- run command to generate the new configurations and replace the old one

``` bash
[root@k8s-master kubernetes]# kubeadm init phase kubeconfig all --config kubeadm.yaml
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/admin.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/scheduler.conf"
```

- restart kube-apiserver, kube-controller-manager, kube-scheduler and etcd,

+ show all pods with labels

```
[root@k8s-master kubernetes]# kubectl get pods --all-namespaces --show-labels
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE   LABELS
default       nginx-deployment-66b6c48dd5-7bvjd          1/1     Running   0          17h   app=nginx,pod-template-hash=66b6c48dd5
default       nginx-deployment-66b6c48dd5-bmgm9          1/1     Running   0          17h   app=nginx,pod-template-hash=66b6c48dd5
default       nginx-deployment-66b6c48dd5-npwzb          1/1     Running   0          17h   app=nginx,pod-template-hash=66b6c48dd5
kube-system   calico-kube-controllers-7c7b4546b9-fkw69   1/1     Running   0          52m   k8s-app=calico-kube-controllers,pod-template-hash=7c7b4546b9
kube-system   calico-node-6bd2c                          1/1     Running   0          17h   controller-revision-hash=685c6c67b7,k8s-app=calico-node,pod-template-generation=1
kube-system   calico-node-7g946                          1/1     Running   0          17h   controller-revision-hash=685c6c67b7,k8s-app=calico-node,pod-template-generation=1
kube-system   calico-node-wkxw6                          1/1     Running   0          17h   controller-revision-hash=685c6c67b7,k8s-app=calico-node,pod-template-generation=1
kube-system   coredns-599459c87f-drdwb                   1/1     Running   0          53m   k8s-app=kube-dns,pod-template-hash=599459c87f
kube-system   coredns-599459c87f-rm8f4                   1/1     Running   0          53m   k8s-app=kube-dns,pod-template-hash=599459c87f
kube-system   etcd-k8s-master                            1/1     Running   0          46m   component=etcd,tier=control-plane
kube-system   etcd-k8s-node1                             1/1     Running   0          46m   component=etcd,tier=control-plane
kube-system   etcd-k8s-node2                             1/1     Running   0          46m   component=etcd,tier=control-plane
kube-system   kube-apiserver-k8s-master                  1/1     Running   0          47m   component=kube-apiserver,tier=control-plane
kube-system   kube-apiserver-k8s-node1                   1/1     Running   0          47m   component=kube-apiserver,tier=control-plane
kube-system   kube-apiserver-k8s-node2                   1/1     Running   0          47m   component=kube-apiserver,tier=control-plane
kube-system   kube-controller-manager-k8s-master         1/1     Running   1          45m   component=kube-controller-manager,tier=control-plane
kube-system   kube-controller-manager-k8s-node1          1/1     Running   1          45m   component=kube-controller-manager,tier=control-plane
kube-system   kube-controller-manager-k8s-node2          1/1     Running   0          45m   component=kube-controller-manager,tier=control-plane
kube-system   kube-proxy-76lkw                           1/1     Running   0          17h   controller-revision-hash=b89db7f56,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-proxy-7pzxd                           1/1     Running   0          17h   controller-revision-hash=b89db7f56,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-proxy-gl89x                           1/1     Running   0          17h   controller-revision-hash=b89db7f56,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-scheduler-k8s-master                  1/1     Running   1          45m   component=kube-scheduler,tier=control-plane
kube-system   kube-scheduler-k8s-node1                   1/1     Running   1          45m   component=kube-scheduler,tier=control-plane
kube-system   kube-scheduler-k8s-node2                   1/1     Running   0          45m   component=kube-scheduler,tier=control-plane
```

+ delete kube-apiserver, kube-controller-manager, kube-scheduler with specified label

``` bash
kubectl -n kube-system delete pod -l 'component=kube-apiserver'
kubectl -n kube-system delete pod -l 'component=kube-controller-manager'
kubectl -n kube-system delete pod -l 'component=kube-scheduler'
```

+ check new certs and the next experiation date

``` bash
[root@k8s-master kubernetes]# kubeadm alpha certs check-expiration
Command "check-expiration" is deprecated, please use the same command under "kubeadm certs"
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jan 15, 2022 01:38 UTC   364d                                    no      
apiserver                  Jan 15, 2022 01:38 UTC   364d            ca                      no      
apiserver-etcd-client      Jan 15, 2022 01:38 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Jan 15, 2022 01:38 UTC   364d            ca                      no      
controller-manager.conf    Jan 15, 2022 01:38 UTC   364d                                    no      
etcd-healthcheck-client    Jan 15, 2022 01:38 UTC   364d            etcd-ca                 no      
etcd-peer                  Jan 15, 2022 01:38 UTC   364d            etcd-ca                 no      
etcd-server                Jan 15, 2022 01:38 UTC   364d            etcd-ca                 no      
front-proxy-client         Jan 15, 2022 01:38 UTC   364d            front-proxy-ca          no      
scheduler.conf             Jan 15, 2022 01:38 UTC   364d                                    no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jan 12, 2031 07:26 UTC   9y              no      
etcd-ca                 Jan 12, 2031 07:26 UTC   9y              no      
front-proxy-ca          Jan 12, 2031 07:26 UTC   9y              no      
```

```
$echo | openssl s_client -showcerts -connect 127.0.0.1:6443 -servername api 2>/dev/null | openssl x509 -noout -enddate
notAfter=Jan 15 01:38:48 2022 GMT
```


## K8s Installation Video
```
https://www.youtube.com/watch?v=ZxC6FwEc9WQ
https://www.youtube.com/watch?v=zj6r_EEhv6s
```
## Other online installation guide

https://www.youtube.com/watch?v=E3h8_MJmkVU
https://github.com/tunetolinux/Kubernetes-Installation/wiki
https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos
https://blog.csdn.net/weixin_40768973/article/details/109323941
https://github.com/hub-kubernetes/kubeadm-multi-master-setup
https://www.cnblogs.com/xiao987334176/p/11899321.html
https://www.qikqiak.com/post/update-k8s-10y-expire-certs/


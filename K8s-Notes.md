Setup K8s Multiple Master Nodes Cluster ON Centos Server
---------
#### K8s Nodes
|Node Name | IP |
|--- | --- |
| Master Node   | 10.124.44.105 |
| Worker Node   | 10.124.44.106 |
| Worker Node   | 10.124.44.107 |

#### Haproxy deployment on all k8s nodes
- create haproxy configuration file
```
mkdir /etc/haproxy
```

```
touch /etc/haproxy/haproxy.cfg
```

```
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

```
docker run -d --name=diamond-haproxy --net=host  -v /etc/haproxy:/usr/local/etc/haproxy/:ro haproxy
```
#### Keepalived Deployment

- Create configuration file

```
mkdir /etc/keepalived/
touch keepalived.conf
```
```
global_defs {
   script_user root 
   enable_script_security

}

vrrp_script chk_haproxy {
    script "/bin/bash -c 'if [[ $(netstat -nlp | grep 9443) ]]; then exit 0; else exit 1; fi'"  \# haproxy check
    interval 2  
    weight 11 
}

vrrp_instance VI_1 {
  interface eth0

  state MASTER \# node role by default, this is master node
  virtual_router_id 51\# same id means same virtual group
  priority 100 \# weight
  nopreempt # role can change to be master

  unicast_peer {

  }

  virtual_ipaddress {
    10.124.44.125  \# vip
  }

  authentication {
    auth_type PASS
    auth_pass password
  }

  track_script {
      chk_haproxy
  }

  notify "/container/service/keepalived/assets/notify.sh"
}
```

- run keepalived container

```
docker run --cap-add=NET_ADMIN --cap-add=NET_BROADCAST --cap-add=NET_RAW --net=host --volume /etc/keepalived/keepalived.conf:/container/service/keepalived/assets/keepalived.conf -d osixia/keepalived:2.0.20 --copy-service
```

#### Kubeadm 部署

#### etcd 部署

#### rancher 部署

#### kubeoperator 部署

### Persistent Volumes
```
https://www.youtube.com/watch?v=ZxC6FwEc9WQ
https://www.youtube.com/watch?v=zj6r_EEhv6s
```

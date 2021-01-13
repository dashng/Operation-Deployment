Setup K8s Multiple Master Nodes Cluster ON Centos Server
---------

#### haproxy deployment
- create docker mounted folder and haproxy config file
<code>
mkdir /etc/haproxy
touch /etc/haproxy/haproxy.cfg
cat >> /etc/haproxy/haproxy.cfg << EOF
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   https://www.haproxy.org/download/2.1/doc/configuration.txt
#   https://cbonte.github.io/haproxy-dconv/2.1/configuration.html
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    maxconn     4000


#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    option http-server-close
    # option forwardfor       except 127.0.0.0/8
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

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend  kubernetes-apiserver
    mode tcp
    bind *:9443
    # bind *:443 ssl # To be completed ....

    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    default_backend             kubernetes-apiserver

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend kubernetes-apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
         # k8s-apiservers backend
         server master-10.124.44.105 10.124.44.105:6443 check
         server master-10.124.44.106 10.124.44.106:6443 check
         server master-10.124.44.107 10.124.44.107:6443 check
EOF
</code>

#### Kubeadm 部署

#### etcd 部署

#### rancher 部署

#### kubeoperator 部署

### Persistent Volumes
```
https://www.youtube.com/watch?v=ZxC6FwEc9WQ
https://www.youtube.com/watch?v=zj6r_EEhv6s
```

Redis Sentinel Cluster With docker, haproxy
--------------

## Cluster Nodes

+ 10.124.44.105: master
+ 10.124.44.106: Replicator
+ 10.124.44.107: Replicator

## Create Redis.conf On Master Node

``` bash
cat <<EOF > /usr/local/etc/redis/redis.conf
bind 0.0.0.0
requirepass "123456"
EOF
```

## Create Redis.conf On Replicator Node

``` bash
cat <<EOF > /usr/local/etc/redis/redis.conf
bind 0.0.0.0
requirepass "123456"
replicaof 10.124.44.105 6379
masterauth "123456"
EOF
```

## Create Sentinel.conf On All Nodes

``` bash
cat <<EOF > /usr/local/etc/redis/sentinel.conf
port 26379
daemonize yes
# sentinel deny-scripts-reconfig yes
sentinel monitor mymaster 10.124.44.105 6379 2
sentinel down-after-milliseconds mymaster 26379
sentinel auth-pass mymaster 123456
```

## Run Redis Server Docker Container On All Nodes

``` bash
docker run  -tid --name redis --network host -p 6379:6379 -v /usr/local/etc/redis:/usr/local/etc/redis redis redis-server /usr/local/etc/redis/redis.conf
```

## Run Redis Sentinel Docker Container On All Nodes

``` bash
docker run  --rm -tid --name sentinel --network host -p 26379:26379 -v /usr/local/etc/redis:/usr/local/etc/redis redis sh -c "redis-sentinel /usr/local/etc/redis/sentinel.conf --sentinel & tail -f /dev/null" 
```


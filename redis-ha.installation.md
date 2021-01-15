# HA config

> master redis: redis.conf

append:
```
bind 0.0.0.0
requirepass "123456"
```

> master redis: sentinel.conf

```
port 5000
daemonize yes
# sentinel deny-scripts-reconfig yes
sentinel monitor mymaster 10.124.51.35 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel auth-pass mymaster 123456
```

> slave redis: redis.conf

```
bind 0.0.0.0
requirepass "123456"
replicaof 10.124.51.35 6379
masterauth "123456"
```

> slave redis: sentinel.conf

```
port 5000
daemonize yes
# sentinel deny-scripts-reconfig yes
sentinel monitor mymaster 10.124.51.35 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel auth-pass mymaster 123456
```

# service enable
> Create new service file
```
vi /etc/init.d/redis_master
```
> service file content
```
#!/bin/sh
# chkconfig: 2345 10 90
# description: Start and Stop redis
#
# Simple Redis init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

#Redis Port
REDISPORT=6379
#Redis server path
EXEC=/opt/redis-5.0.5/src/redis-server
#Redis terminal path
CLIEXEC=/opt/redis-5.0.5/src/redis-cli
#Redis process path
PIDFILE=/run/redis_${REDISPORT}.pid
#Redis config path
CONF="/opt/redis-5.0.5/redis.conf"
#sentinel config path
SlCONF="/opt/redis-5.0.5/sentinel.conf --sentinel"

case "$1" in
    start)
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo "Starting Redis server..."
                $EXEC $CONF;
                $EXEC $SlCONF
                # $EXEC $CONF
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $CLIEXEC -a '123456' -p $REDISPORT shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
```

# service restart / stop / start/ enable command

```
service redis_master start
service redis_master stop
chkconfig redis_master on
```



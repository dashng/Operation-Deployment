## postgre common commands

- connect postgre db on linux
```
psql postgresql://user:password@serverhost:port/database
psql -h myhost -p 5432 -d mydb -U myuser 
```
- CFG FILE

```
postgresql.conf

pg_hba.conf
```
- Common Command

```
# get postgres uptime
SELECT date_trunc('second', 
 current_timestamp - pg_postmaster_start_time()) as uptime; 
```
```
# show all databases
psql -l
/l

# select database

/c database_name

# cal current database size

SELECT pg_database_size(current_database());

# cal all database size

SELECT sum(pg_database_size(datname)) from pg_database;
```

# grant table all previleges on user

```
grant all privileges on database matrix_bgp_test to matrix_bgp;
```

# issue: django.db.utils.ProgrammingError: must be owner of table lsp_config
```
grant postgres to matrix_bgp;
```

# create database

```
create database xxx;
```

# database backup

```
pg_dump -U user -d database -f dump.sql

psql -U user -d database -f dump.sql
```

# add user from terminal 

```
su - postgres

createuser --interactive --pwprompt
```

# alter user password 

```
ALTER USER postgres PASSWORD '*****';
```

# Pacemaker + Corosync maintenance commands

1. clean up postgres data folder
```
rm -rf /var/lib/pgsql/10/data/*
```
2. grant data folder permission to 'postgres' user
```
chmod -R 0700 postgres /var/lib/pgsql/10/data/
chown -R postgres:postgres /var/lib/pgsql/10/data/
```
3. backup the database from master node
```
/usr/pgsql-10/bin/pg_basebackup -h {{ master_ip }} -U postgres -D /var/lib/pgsql/10/data/ -X stream -P
```
4. clean up HA nodes
```
pcs resource cleanup pgsql-cluster
```
5. show Status
```
crm_mon -Afr -1
```

6. open firewal

```
systemctl start firewalld
firewall-cmd --permanent --add-service=postgresql
firewall-cmd --permanent --zone=public --add-port=6432/tcp
```


# Postgresql Table Space

> 
```
CREATE TABLESPACE fastspace LOCATION '/mnt/sda1/postgresql/data';

```

> 
```
db =# select spcname from pg_tablespace;  
  spcname   
------------
 pg_default
 pg_global
 timeseries
(3 rows)
```

>
```
db=# select pg_size_pretty(pg_tablespace_size('timeseries')); 
 pg_size_pretty 
----------------
 11 GB
(1 row)
```

>
```
db=# select spcname
db-#       ,pg_tablespace_location(oid) 
db-# from   pg_tablespace;
  spcname   | pg_tablespace_location 
------------+------------------------
 pg_default | 
 pg_global  | 
 timeseries | /data/ts
(3 rows)
db=# select spcname
db-#       ,pg_tablespace_location(oid) 
db-# from   pg_tablespace;
  spcname   | pg_tablespace_location 
------------+------------------------
 pg_default | 
 pg_global  | 
 timeseries | /data/ts
(3 rows)

```

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
```


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

create database xxx;

# database backup

pg_dump -U user -d database -f dump.sql

psql -U user -d database -f dump.sql

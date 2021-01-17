#!/bin/bash
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)
# Edit docker image
docker run --name web-container -it centos:latest bash
# Commit image
docker commit -m "Added LAMP Server" -a "NAME" test-lamp-server USER/test-lamp-server:latest
# push to remote docker hub
docker push USER/test-lamp-server
# Docker edit & copy to another image
http://www.techrepublic.com/article/how-to-commit-changes-to-a-docker-image/
# build image
docker build -t igraph/ubuntu:v1 . 
# run image
docker run  --name='python-igraph'  -tid  igraph/ubuntu:v1 
# log into container
docker exec -it python-igraph /bin/bash
# load saved image
docker load --input fedora.tar
# export saved image
docker save -o apache.dev.tar apache:dev
# cp file from host to docker
docker cp foo.txt mycontainer:/foo.txt
docker cp mycontainer:/foo.txt foo.txt

docker cp src/. mycontainer:/target
docker cp mycontainer:/src/. target

docker ps --format=$FORMAT # FORMAT added as env variable

docker tag test:latest test:1

docker run --rm  -v /etc/kong:/etc/kong -p 0.0.0.0:8000:8000 -p 0.0.0.0:8801:8001 --name kong-local kong kong start -c /etc/kong/kong.conf --vv

> Persist Docke Volume

* docker volume create postgres

* docker rum -d --rm -v postgres:/var/lib/postgresql/data -e POSTGES_DB=postgress...

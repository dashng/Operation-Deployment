du -hsx * | sort -rh | head -10 # check top large folder
curl \
  -F "file=@/opt/software/SDN-Optimizer/net/host_list.csv" \
  http://localhost:8989/v1/devices_import/
  
# rm python process
  
ps aux | grep python | awk '{print $2}' | xargs kill -9
  
# rm django migrations
find . -path "*/migrations/*.pyc"  -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete

# export mongodb

mongoexport --db flow_meta --collection devices --out devices.json

# import mongodb

mongoimport --db test --collection contacts --file devices.json

du -hsx * | sort -rh | head -10 # check top large folder
curl \
  -F "file=@/opt/software/SDN-Optimizer/net/host_list.csv" \
  http://localhost:8989/v1/devices_import/
  
  ps aux | grep python | awk '{print $2}' | xargs kill -9
find . -path "*/migrations/*.pyc"  -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete

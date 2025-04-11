#!/bin/bash 
#
# Check if OPER parameter is provided to build custom container
OPER=${1:-0}
#
if [ "$OPER" = "1" ]; then
    echo "build custom container"
    docker build -t my-jupyter:latest . -f jupyter.Dockerfile
fi
#
echo "start Container Jypter p8888  - mlflow ui p5000 "
#
docker stop my_jupyter
docker rm my_jupyter
docker container run -it --name my_jupyter --mount type=bind,src=$(pwd),dst=/home/jovyan/work --rm -p 8888 my-jupyter:latest  #jupyter/base-notebook
#

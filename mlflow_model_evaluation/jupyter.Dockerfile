FROM jupyter/base-notebook

WORKDIR /home/jovyan

EXPOSE 5000:5000/tcp
EXPOSE 8888:8888/tcp

RUN pip install mlflow==2.21.3
RUN pip install pandas==2.2.3
RUN pip install openai==1.72.0
RUN pip install tiktoken==0.9.0


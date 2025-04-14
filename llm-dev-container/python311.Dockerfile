# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc \
    && echo "conda activate base" >> ~/.bashrc

# Add conda to PATH
ENV PATH=/opt/conda/bin:$PATH

# Create and activate conda environment with name llm_env
RUN conda create -n llm_env python=3.11 -y \
    && echo "conda activate llm_env" >> ~/.bashrc

# Activate conda environment and install packages
SHELL ["/bin/bash", "--login", "-c"]
RUN conda activate llm_env && \
    pip install --no-cache-dir \
    jupyter \
    flask \
    openai \
    anthropic \
    langchain \
    torch \
    transformers \
    sentence-transformers \
    datasets \
    evaluate \
    accelerate \
    bitsandbytes \
    peft \
    trl \
    huggingface_hub \
    pandas \
    pyarrow \
    numpy \
    scikit-learn \
    matplotlib \
    seaborn \
    tensorboard \
    wandb

# Set working directory
WORKDIR /app

# Expose ports for Jupyter and Flask
EXPOSE 8888:8888/tcp
EXPOSE 5000:5000/tcp

# Create a startup script
RUN echo '#!/bin/bash' > /app/start.sh \
    && echo 'source /opt/conda/etc/profile.d/conda.sh' >> /app/start.sh \
    && echo 'conda activate llm_env' >> /app/start.sh \
    && echo 'jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root' >> /app/start.sh \
    && chmod +x /app/start.sh

# Command to run the startup script
CMD ["/app/start.sh"]

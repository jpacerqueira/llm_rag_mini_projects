# Use Python 3.12 slim as base image
FROM python:3.12-slim

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
    vim \
    net-tools \
    procps \
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
    langchain==0.3.10 \
    langchain[anthropic]==0.3.10 \
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
    duckdb \
    fastparquet \
    openai \
    openai-agents \
    rich \
    numpy \
    scikit-learn \
    matplotlib \
    seaborn \
    tensorboard \
    wandb \
    dotenv \
    streamlit \
    fastapi \
    uvicorn \
    mangum \
    tiktoken \
    boto3 \
    awscli
     

# Set working directory
WORKDIR /app

# Expose ports for various applications
# 8888: Jupyter Notebook (default)
# 5000-5009: Flask/other web apps
# 8000-8009: FastAPI/other web apps
# 8501-8509: Streamlit apps
# 9999: TensorBoard
EXPOSE 8888
EXPOSE 5000-5009
EXPOSE 8000-8009
EXPOSE 8501-8509
EXPOSE 9999

# Create a startup script
RUN echo '#!/bin/bash' > /app/start.sh \
    && echo 'source /opt/conda/etc/profile.d/conda.sh' >> /app/start.sh \
    && echo 'conda activate llm_env' >> /app/start.sh \
    && echo 'jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root' >> /app/start.sh \
    && chmod +x /app/start.sh

# Command to run the startup script
CMD ["/app/start.sh"]

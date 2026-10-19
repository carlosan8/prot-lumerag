FROM python:3.11-slim

# Define o diretório de trabalho interno
WORKDIR /app

# Instala dependências básicas de sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    antiword \
    && rm -rf /var/lib/apt/lists/*

# Copia os requerimentos e instala as bibliotecas de IA, OpenSearch e Gradio
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r ./requirements.txt

# Copia o código da aplicação sem incluir arquivos locais, como o .env
COPY src/ ./src

# Comando para iniciar a aplicação unificada com a interface web
CMD ["python", "src/main.py"]

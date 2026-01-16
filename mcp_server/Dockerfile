FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt

# Copy application code
COPY soccer_mcp_server.py .

# Copy key files for authentication (if using key pair auth)
# COPY rsa_key.p8 .
# COPY rsa_key.pub .

# Copy static graph data (required - for graph analytics)
COPY graph_data/ /app/graph_data/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV MCP_TRANSPORT=http

# Run the MCP server
CMD ["python", "soccer_mcp_server.py"]

# Use Python 3.10 slim image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml ./

# Install pip dependencies
RUN pip install --no-cache-dir -e .

# Copy application code
COPY ./app ./app
COPY ./data ./data

# Expose port (Azure will provide $PORT)
EXPOSE 8000

# Healthcheck
RUN pip install requests
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import os, requests; requests.get(f'http://localhost:{os.environ.get(\"PORT\",8000)}/health')"

# Run uvicorn with dynamic port
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]

FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY dashboard/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app and analytics modules
COPY dashboard/ ./dashboard
COPY analytics/ ./analytics

WORKDIR /app/dashboard

EXPOSE 8501

CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]


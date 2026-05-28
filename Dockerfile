FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    pcscd \
    libpcsclite1 \
    libpcsclite-dev \
    mpv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV CONFIG_PATH=/app/config.yaml

EXPOSE 8080

CMD ["python", "-m", "src.web.app"]

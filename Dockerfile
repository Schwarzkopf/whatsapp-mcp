# ---- Stage 1: Build the Go WhatsApp bridge ----
FROM golang:1.24-bookworm AS bridge-builder

WORKDIR /build/whatsapp-bridge

COPY whatsapp-bridge/go.mod whatsapp-bridge/go.sum ./
RUN go mod download

COPY whatsapp-bridge/ ./
RUN CGO_ENABLED=1 GOOS=linux go build -o /build/whatsapp-bridge-bin main.go

# ---- Stage 2: Final runtime image ----
FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

WORKDIR /app

COPY --from=bridge-builder /build/whatsapp-bridge-bin /app/whatsapp-bridge/whatsapp-bridge

COPY whatsapp-mcp-server/pyproject.toml whatsapp-mcp-server/uv.lock /app/whatsapp-mcp-server/
WORKDIR /app/whatsapp-mcp-server
RUN uv sync --frozen --no-dev

COPY whatsapp-mcp-server/ /app/whatsapp-mcp-server/

WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV MCP_TRANSPORT=sse
ENV PORT=8000
ENV MESSAGES_DB_PATH=/app/whatsapp-bridge/store/messages.db
ENV WHATSAPP_API_BASE_URL=http://localhost:8080/api

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]

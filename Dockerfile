# Builder Stage
FROM rust:1.73 AS builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    libclang-dev \
    clang \
    make \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Clone RustDesk server repository
RUN git clone https://github.com/rustdesk/rustdesk-server /rustdesk-server
WORKDIR /rustdesk-server

# Build RustDesk server
RUN cargo build --release

# Clone RustDesk Web Client repository
RUN git clone https://github.com/rustdesk/web /rustdesk-web
WORKDIR /rustdesk-web

# Build the Web Client
RUN npm install && npm run build

# Runtime Stage
FROM ubuntu:22.04

# Install NGINX
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -ms /bin/bash rustdesk && \
    mkdir -p /etc/rustdesk /var/log/rustdesk && \
    chown -R rustdesk:rustdesk /etc/rustdesk /var/log/rustdesk

# Switch to non-root user
USER rustdesk

# Copy RustDesk server binaries
COPY --from=builder /rustdesk-server/target/release/hbbs /usr/local/bin/hbbs
COPY --from=builder /rustdesk-server/target/release/hbbr /usr/local/bin/hbbr

# Copy RustDesk configuration
COPY ./rustdesk-config/id_ed25519 /etc/rustdesk/id_ed25519
COPY ./rustdesk-config/id_ed25519.pub /etc/rustdesk/id_ed25519.pub

# Copy built Web Client
COPY --from=builder /rustdesk-web/dist /var/www/rustdesk-web

# Copy NGINX configuration
COPY nginx-config/default /etc/nginx/sites-available/default

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose necessary ports
EXPOSE 21115 21116 80

# Define entrypoint
CMD ["/usr/local/bin/entrypoint.sh"]

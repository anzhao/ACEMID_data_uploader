# Use a lightweight base image with bash and curl
FROM ubuntu:22.04

# Set non-root user
ARG USER_ID=10001
ARG GROUP_ID=10001

# Create a non-root user and group
RUN groupadd -g $GROUP_ID appuser && \
    useradd -u $USER_ID -g $GROUP_ID -m -s /bin/bash appuser

# Install required packages
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    zip \
    unzip \
    ca-certificates \
    poppler-utils \
    enscript \
    ghostscript \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire repo into the container
COPY --chown=appuser:appuser . .

# Create config directory and copy template
RUN mkdir -p /app/config && \
    cp /app/config/.env.template /app/config/.env.example && \
    chown -R appuser:appuser /app/config && \
    chmod 700 /app/config

# Make sure all scripts are executable
RUN chmod +x /app/*.sh /app/utils/*.sh

# Create log directory with proper permissions
RUN mkdir -p /var/log && \
    chown -R appuser:appuser /var/log && \
    chmod 755 /var/log

# Switch to non-root user
USER appuser

# Set environment variables (can be overridden at runtime)
ENV XNAT_URL=""
ENV XNAT_USERNAME=""
ENV XNAT_PASSWORD=""
ENV XNAT_PROJECT_ID=""
ENV STRICT_CERT_VALIDATION=1
ENV DEBUG_LOGGING=0
ENV CONNECTION_TIMEOUT=30
ENV LOG_FILE="/var/log/acemid_uploader.log"

# Default command to run the upload script
CMD ["./ACEMID_data_uploader.sh"]

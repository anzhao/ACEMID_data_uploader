# Use a lightweight base image with bash and curl
FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire repo into the container
COPY . .

# Check what is under the app dir
RUN ls -al /app


# Make sure the upload script is executable
RUN chmod +x /app/ACEMID_uploader.sh

# Set environment variables (can be overridden at runtime)
ENV XNAT_URL=""
ENV USERNAME=""
ENV PASSWORD=""
ENV PROJECT_ID=""

# Default command to run the upload script
CMD ["./ACEMID_uploader.sh"]

# Multi-stage build for loopwerk.io static site

# Stage 1: Build environment
# Using Ubuntu 24.04 (Noble) for libgd 2.3.2+ with AVIF support
FROM swift:6.0-noble AS builder

# Install system dependencies
RUN apt-get update && apt-get --no-install-recommends install -y \
    libgd-dev \
    libavif-dev \
    python3 \
    git \
    git-restore-mtime \
    curl \
    nodejs npm \
    just \
    && apt-get install -y libjavascriptcoregtk-4.1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pkg-config --libs javascriptcoregtk-4.1

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files for Node dependencies
COPY package.json pnpm-lock.yaml ./

# Install Node dependencies (including devDependencies needed for build)
RUN pnpm install --frozen-lockfile

# Copy Swift package files AND source code needed to build
COPY Package.swift ./
COPY Package.resolved ./
COPY Sources ./Sources
COPY Tests ./Tests
COPY justfile ./

# Pre-fetch and pre-build Swift dependencies
# This layer will be cached as long as Package files and Sources don't change
RUN echo "Prefetching and prebuilding dependencies..." && just compile

# Copy all source files
COPY . .

# Clone the repository to get .git directory for git-restore-mtime
# This is necessary because Coolify doesn't include .git in build context
RUN git clone https://github.com/loopwerk/loopwerk.io.git /tmp/repo \
    && cp -r /tmp/repo/.git . \
    && git restore-mtime --oldest-time \
    && rm -rf .git /tmp/repo

# Build the site: generate images, index, minify HTML, build & hash CSS
RUN echo "Starting website build..." && just build

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

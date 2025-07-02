# Multi-stage build for loopwerk.io static site

# Stage 1: Build environment
# Using Ubuntu 24.04 (Noble) for libgd 2.3.2+ with AVIF support
FROM swift:6.0-noble AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgd-dev \
    libavif-dev \
    python3 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 and pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files for Node dependencies
COPY package.json pnpm-lock.yaml ./

# Install Node dependencies (including devDependencies needed for build)
RUN pnpm install --frozen-lockfile

# Copy Swift package files
COPY Package.swift ./
COPY Package.resolved ./

# Pre-fetch Swift dependencies
RUN swift package resolve

# Copy all source files
COPY . .

# Clone the repository to get .git directory for git-restore-mtime
# This is necessary because Coolify doesn't include .git in build context
RUN git clone https://github.com/loopwerk/loopwerk.io.git /tmp/repo \
    && cp -r /tmp/repo/.git . \
    && ./git-restore-mtime \
    && rm -rf .git /tmp/repo

# Build the site with verbose output for debugging
RUN echo "Starting Swift build..." \
    && swift run Loopwerk createArticleImages \
    && pnpm index \
    && pnpm html-minifier --collapse-whitespace --input-dir deploy --file-ext html --output-dir deploy

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
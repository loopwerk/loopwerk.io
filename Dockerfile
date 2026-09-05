# Multi-stage build for loopwerk.io static site

# Stage 1: Build environment
# Using Ubuntu 24.04 (Noble) for libgd 2.3.2+ with AVIF support
FROM swift:6.1-noble AS builder

# Install system dependencies
RUN apt-get update && apt-get --no-install-recommends install -y \
    libgd-dev \
    libavif-dev \
    python3 \
    git \
    git-restore-mtime \
    curl \
    nodejs npm \
    && apt-get install -y libjavascriptcoregtk-4.1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pkg-config --libs javascriptcoregtk-4.1

# Install pnpm
RUN npm install -g pnpm@10

# Set working directory
WORKDIR /app

# Copy package files for Node dependencies
COPY package.json pnpm-lock.yaml ./

# Install Node dependencies (including devDependencies needed for build)
RUN pnpm install --frozen-lockfile

# Pre-fetch Swift dependencies (cached unless the Package files change)
COPY Package.swift Package.resolved ./
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    swift package resolve

# Pre-build the site generator (cached unless the sources change).
# .build is a cache mount so SwiftPM's incremental state survives between
# deploys: only the changed module recompiles. Because a cache mount isn't
# part of the image layer, the binary has to be copied out of it here, and
# is run from /usr/local/bin below. The resource bundles (Bundle.module)
# are looked up next to the executable, so they're copied along with it.
COPY Sources ./Sources
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    swift build --product Loopwerk \
    && cp .build/debug/Loopwerk /usr/local/bin/loopwerk \
    && cp -r .build/debug/*.bundle /usr/local/bin/

# Copy all source files
COPY . .

# Clone the repository to get .git directory for git-restore-mtime
# This is necessary because Coolify doesn't include .git in build context
RUN git clone https://github.com/loopwerk/loopwerk.io.git /tmp/repo \
    && cp -r /tmp/repo/.git . \
    && git restore-mtime --oldest-time \
    && rm -rf .git /tmp/repo

# Build the site: generate images, index, minify HTML, build & hash CSS
RUN --mount=type=cache,target=/root/.swifttailwind \
    loopwerk

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html

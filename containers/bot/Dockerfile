# ============================================================================
# Victoria SaaS - Bot Container Dockerfile
# ============================================================================
# This Dockerfile creates the bot container that processes WhatsApp messages
# ============================================================================

FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    postgresql-client \
    curl \
    bash

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose bot port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node healthcheck.js || exit 1

# Start application
CMD ["node", "index.js"]

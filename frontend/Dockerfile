# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Install build tools (npm versiyasını dəyişmə)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps --no-audit --no-fund

# Copy source code (bütün struktur)
COPY . .

# Public/index.html yaradın əgər yoxdursa
RUN mkdir -p public && \
    [ ! -f public/index.html ] && echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><title>Quiz System</title></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>' > public/index.html || true

# Verify React app structure
RUN echo "Checking React app structure:" && \
    ls -la src/ && \
    ls -la public/ && \
    echo "App.js content:" && \
    head -10 src/App.js || echo "App.js not found" && \
    echo "package.json scripts:" && \
    grep -A 10 '"scripts"' package.json

# Build the application
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=build /app/build /usr/share/nginx/html

# Set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]
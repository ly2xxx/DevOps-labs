# Use Node.js as the base image
FROM node:20-alpine

# Install pnpm and git
RUN npm install -g pnpm && apk add --no-cache git

# Set the working directory
WORKDIR /app

# The command to clone the repo (if missing), install dependencies, and start the Vite dev server
CMD sh -c "if [ ! -f /app/package.json ]; then \
             git clone https://github.com/coder/parameters-playground.git /tmp/playground && \
             cp -r /tmp/playground/. /app/ && \
             rm -rf /tmp/playground; \
           fi && \
           pnpm install && \
           pnpm run dev --host 0.0.0.0"

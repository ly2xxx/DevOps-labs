FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY server.js ./

# Run as non-root user
USER node

EXPOSE 8080

CMD ["npm", "start"]

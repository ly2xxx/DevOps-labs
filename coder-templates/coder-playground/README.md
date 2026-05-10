# Local Coder Parameters Playground

This directory contains the necessary files to host the [Coder Parameters Playground](https://github.com/coder/parameters-playground) locally using Docker Desktop.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

## Setup Instructions

1. **Start the Container**: Open your terminal in this directory and run:

   ```bash
   docker-compose up -d
   ```

2. **What happens in the background**:
   - Docker builds an Alpine Node.js image with `pnpm` and `git` installed.
   - It checks if the `./app` directory is empty. If it is, it clones the official `coder/parameters-playground` GitHub repository into it.
   - It installs the node dependencies and starts the Vite development server.

3. **Access the Playground**:
   Once the container is running and has finished downloading dependencies, open your browser and go to:
   
   👉 **http://localhost:5173**

## Customizing the Playground

Because the code is mounted from the container into the `./app` directory on your host machine, you can open `./app` in VS Code or any other editor and modify the playground's React source code. The Vite server will automatically hot-reload your changes in the browser.

## Stopping the Playground

To stop the container, run:

```bash
docker-compose down
```

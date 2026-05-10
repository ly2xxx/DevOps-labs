# Use the official HashiCorp Terraform image
FROM hashicorp/terraform:latest

# Create a temporary directory for setup
WORKDIR /setup

# Copy all local terraform files so Terraform can analyze all provider dependencies
COPY . .

# Create a directory to store the mirrored provider plugins
RUN mkdir -p /usr/local/share/terraform/plugins

# Install modules first so terraform providers mirror can parse them
RUN terraform get

# Mirror the providers based on the configuration. 
# This downloads them into the image so they are cached.
RUN terraform providers mirror /usr/local/share/terraform/plugins

# Configure Terraform to ALWAYS use the mirrored plugins directory during 'init'
# This prevents it from reaching out to the internet to download them again.
ENV TF_CLI_ARGS_init="-plugin-dir=/usr/local/share/terraform/plugins"

# Set the working directory where we will mount the Windows volume
WORKDIR /workspace

# Override the default entrypoint which is "terraform"
ENTRYPOINT []

# When the container starts, initialize Terraform and run the tests
# Note: Since the Windows volume is mounted to /workspace, we run init 
# in the mounted directory so the .terraform directory is created properly.
CMD ["sh", "-c", "terraform init && terraform test"]

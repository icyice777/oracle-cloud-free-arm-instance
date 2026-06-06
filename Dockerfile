FROM ghcr.io/oracle/oci-cli:latest
LABEL Name=oraclecloudfreearminstance Version=0.0.1

# Copy the script to the container
WORKDIR /app
COPY ./oracle_cloud_instance_creator.sh .

# Make the script executable
RUN chmod +x /app/oracle_cloud_instance_creator.sh

# Set the entry point to run the script when the container starts
ENTRYPOINT ["/bin/bash", "/app/oracle_cloud_instance_creator.sh"]

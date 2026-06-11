# Use the official Oracle OCI CLI image as the base
FROM ghcr.io/oracle/oci-cli:latest
LABEL Name=oraclecloudfreearminstance Version=0.0.1

# Switch to root user to allow package installation
USER root

# Clean cache, install mailx (RPM mail utility), and purge cache to keep the image small
RUN dnf clean all && \
    dnf -y install mailx && \
    rm -rf /var/cache/dnf/*

# Switch back to the non-root application user used by the base image
USER oracle

# Copy the script to the container
WORKDIR /app
COPY --chmod=+x ./oracle_cloud_instance_creator.sh .

# Set the entry point to run the script when the container starts
ENTRYPOINT ["/bin/bash", "/app/oracle_cloud_instance_creator.sh"]

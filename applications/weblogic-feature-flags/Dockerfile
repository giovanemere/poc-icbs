# WebLogic Server with Feature Flags - Docker Hub Ready
# Base: Oracle WebLogic Server 12.2.1.3
FROM vulhub/weblogic:12.2.1.3-2018

# Metadata
LABEL maintainer="edissonz8809"
LABEL description="WebLogic Server 12.2.1.3 with Feature Flags System"
LABEL version="v1.1.0"
LABEL org.opencontainers.image.title="WebLogic Feature Flags"
LABEL org.opencontainers.image.description="Production-ready WebLogic Server with integrated Feature Flags system"
LABEL org.opencontainers.image.version="v1.1.0"
LABEL org.opencontainers.image.authors="edissonz8809"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/edissonz8809/weblogic-feature-flags"
LABEL org.opencontainers.image.source="https://github.com/edissonz8809/docker-weblogic-oracle"

# Switch to root for setup
USER root

# Environment variables
ENV WEBLOGIC_VERSION=12.2.1.3 \
    DOMAIN_NAME=base_domain \
    FEATURE_FLAGS_ENABLED=true \
    HEALTH_CHECK_ENABLED=true \
    AUTO_DEPLOY_ENABLED=true \
    LOG_LEVEL=INFO

# Install additional packages for feature flags
RUN yum update -y && \
    yum install -y curl wget jq nc && \
    yum clean all && \
    rm -rf /var/cache/yum

# Create application directories
RUN mkdir -p /app/{src,config,scripts,deploy,logs,backup,container-scripts} && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/autodeploy && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs

# Copy application files from war-projects
COPY war-projects/ /app/war-projects/
COPY config/ /app/config/
COPY scripts/ /app/scripts/

# Create feature flags configuration
RUN echo '#!/bin/bash' > /app/scripts/setup-feature-flags.sh && \
    echo 'echo "Setting up Feature Flags system..."' >> /app/scripts/setup-feature-flags.sh && \
    echo 'mkdir -p /app/config/feature-flags' >> /app/scripts/setup-feature-flags.sh && \
    echo 'echo "{\"version_a_enabled\": true, \"version_b_enabled\": false}" > /app/config/feature-flags/flags.json' >> /app/scripts/setup-feature-flags.sh && \
    echo 'echo "Feature Flags configured successfully"' >> /app/scripts/setup-feature-flags.sh

# Create health check script
RUN echo '#!/bin/bash' > /app/scripts/health-check.sh && \
    echo 'curl -f http://localhost:7001/console > /dev/null 2>&1' >> /app/scripts/health-check.sh && \
    echo 'if [ $? -eq 0 ]; then' >> /app/scripts/health-check.sh && \
    echo '  echo "WebLogic Server is healthy"' >> /app/scripts/health-check.sh && \
    echo '  exit 0' >> /app/scripts/health-check.sh && \
    echo 'else' >> /app/scripts/health-check.sh && \
    echo '  echo "WebLogic Server is not responding"' >> /app/scripts/health-check.sh && \
    echo '  exit 1' >> /app/scripts/health-check.sh && \
    echo 'fi'

# Create startup script with feature flags integration
RUN echo '#!/bin/bash' > /app/scripts/start-weblogic-with-flags.sh && \
    echo 'echo "Starting WebLogic Server with Feature Flags..."' >> /app/scripts/start-weblogic-with-flags.sh && \
    echo '/app/scripts/setup-feature-flags.sh' >> /app/scripts/start-weblogic-with-flags.sh && \
    echo 'echo "Starting WebLogic Server..."' >> /app/scripts/start-weblogic-with-flags.sh && \
    echo 'cd /u01/oracle/user_projects/domains/base_domain' >> /app/scripts/start-weblogic-with-flags.sh && \
    echo './startWebLogic.sh' >> /app/scripts/start-weblogic-with-flags.sh

# Create container initialization script
RUN echo '#!/bin/bash' > /app/container-scripts/init-weblogic.sh && \
    echo 'echo "Initializing WebLogic Server with Feature Flags..."' >> /app/container-scripts/init-weblogic.sh && \
    echo 'sleep 30' >> /app/container-scripts/init-weblogic.sh && \
    echo 'if curl -f http://localhost:7001/console > /dev/null 2>&1; then' >> /app/container-scripts/init-weblogic.sh && \
    echo '  echo "WebLogic Server is running"' >> /app/container-scripts/init-weblogic.sh && \
    echo '  /app/scripts/deploy-features.sh' >> /app/container-scripts/init-weblogic.sh && \
    echo '  echo "WebLogic initialization completed successfully"' >> /app/container-scripts/init-weblogic.sh && \
    echo 'else' >> /app/container-scripts/init-weblogic.sh && \
    echo '  echo "Warning: WebLogic Server may not be fully ready"' >> /app/container-scripts/init-weblogic.sh && \
    echo 'fi' >> /app/container-scripts/init-weblogic.sh

# Create version info
RUN echo "WebLogic Feature Flags v1.1.0" > /app/VERSION && \
    echo "Build Date: $(date)" >> /app/VERSION && \
    echo "WebLogic Version: 12.2.1.3" >> /app/VERSION && \
    echo "Feature Flags: Enabled" >> /app/VERSION && \
    echo "Health Checks: Enabled" >> /app/VERSION

# Set permissions and ownership
RUN chown -R oracle:oracle /app && \
    chmod -R 755 /app && \
    find /app/scripts -name "*.sh" -exec chmod +x {} \; && \
    find /app/container-scripts -name "*.sh" -exec chmod +x {} \;

# Switch back to oracle user
USER oracle

# Expose ports
EXPOSE 7001 7002 9002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/scripts/health-check.sh

# Working directory
WORKDIR /u01/oracle/user_projects/domains/base_domain

# Default command
CMD ["/app/scripts/start-weblogic-with-flags.sh"]

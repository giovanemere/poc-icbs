# Use a publicly available WebLogic image
FROM vulhub/weblogic:12.2.1.3-2018

# Build arguments para diferentes ambientes
ARG BUILD_ENV=version-a
ARG DOMAIN_NAME=base_domain
ARG VERSION=A
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_COMMIT

# Environment variables usando los argumentos de build
ENV BUILD_ENV=${BUILD_ENV} \
    DOMAIN_NAME=${DOMAIN_NAME} \
    ADMIN_PORT="7001" \
    ADMIN_NAME="AdminServer" \
    ADMIN_HOST="localhost" \
    ADMIN_USERNAME="weblogic" \
    VERSION=${VERSION} \
    APP_VERSION=${APP_VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    BUILD_VERSION=${BUILD_VERSION} \
    BUILD_COMMIT=${BUILD_COMMIT} \
    PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/${DOMAIN_NAME}/bin \
    JAVA_OPTIONS="-Djava.awt.headless=true"

# Labels para identificar la imagen
LABEL maintainer="WebLogic Team" \
      version="${BUILD_VERSION}" \
      build-date="${BUILD_DATE}" \
      build-env="${BUILD_ENV}" \
      description="Oracle WebLogic Server for ${BUILD_ENV} environment"

# Copy SQLcl and database script
COPY oracle/scripts/setup/demo_oracle.ddl /u01/oracle/
COPY oracle/installers/sqlcl-25.2.2.199.0918.zip /u01/oracle/

# Copy container scripts
COPY container-scripts/ /u01/oracle/container-scripts/

USER root
RUN yum -y install unzip && \
    cd /u01/oracle/ && \
    if [ -f "sqlcl-25.2.2.199.0918.zip" ]; then \
        echo "Extracting SQLcl..."; \
        unzip -q sqlcl-25.2.2.199.0918.zip || echo "Warning: Failed to extract SQLcl, continuing without it"; \
        rm -f sqlcl-25.2.2.199.0918.zip; \
        if [ -d "sqlcl" ]; then chown -R oracle:oracle /u01/oracle/sqlcl; fi; \
    else \
        echo "SQLcl not found, skipping extraction"; \
    fi && \
    chmod +x /u01/oracle/container-scripts/*.sh && \
    mkdir -p /u01/oracle/deploy && \
    chown -R oracle:oracle /u01/oracle/deploy

# Copy WAR files if they exist (using a more Docker-friendly approach)
COPY deploy/ /tmp/deploy/
RUN mkdir -p /u01/oracle/deploy && \
    if [ -f "/tmp/deploy/${BUILD_ENV}.war" ]; then cp /tmp/deploy/${BUILD_ENV}.war /u01/oracle/deploy/; fi && \
    if [ -f "/tmp/deploy/${BUILD_ENV}-*.war" ]; then cp /tmp/deploy/${BUILD_ENV}-*.war /u01/oracle/deploy/; fi && \
    if [ -f "/tmp/deploy/feature-flags.war" ]; then cp /tmp/deploy/feature-flags.war /u01/oracle/deploy/; fi && \
    if [ -f "/tmp/deploy/ff4j-simple.war" ]; then cp /tmp/deploy/ff4j-simple.war /u01/oracle/deploy/; fi && \
    rm -rf /tmp/deploy && \
    chown -R oracle:oracle /u01/oracle/deploy

USER oracle

# Create WebLogic domain with environment-specific configuration
RUN mkdir -p /u01/oracle/user_projects/domains/base_domain && \
    echo "# WLST Script to create a WebLogic domain" > /u01/oracle/create_domain.py && \
    echo "readTemplate('/u01/oracle/wlserver/common/templates/wls/wls.jar')" >> /u01/oracle/create_domain.py && \
    echo "cd('Servers/AdminServer')" >> /u01/oracle/create_domain.py && \
    echo "set('ListenAddress','')" >> /u01/oracle/create_domain.py && \
    echo "set('ListenPort', 7001)" >> /u01/oracle/create_domain.py && \
    echo "cd('/')" >> /u01/oracle/create_domain.py && \
    echo "cd('Security/base_domain/User/weblogic')" >> /u01/oracle/create_domain.py && \
    echo "set('Name', 'weblogic')" >> /u01/oracle/create_domain.py && \
    echo "set('Password', 'welcome123')" >> /u01/oracle/create_domain.py && \
    echo "setOption('ServerStartMode', 'dev')" >> /u01/oracle/create_domain.py && \
    echo "writeDomain('/u01/oracle/user_projects/domains/base_domain')" >> /u01/oracle/create_domain.py && \
    echo "closeTemplate()" >> /u01/oracle/create_domain.py && \
    echo "exit()" >> /u01/oracle/create_domain.py

# Execute WLST script and setup directories
RUN cd /u01/oracle && \
    . /u01/oracle/wlserver/server/bin/setWLSEnv.sh && \
    java weblogic.WLST create_domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs && \
    chown -R oracle:oracle /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs

# Create autodeploy directory and logs
RUN mkdir -p /u01/oracle/user_projects/domains/base_domain/autodeploy && \
    mkdir -p /u01/oracle/logs/weblogic-monitoring && \
    chown -R oracle:oracle /u01/oracle/logs

WORKDIR /u01/oracle

# Expose ports
EXPOSE 7001 7002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD curl -f http://localhost:7001/console || exit 1

# Start WebLogic using the container script
CMD ["/u01/oracle/container-scripts/start-weblogic.sh"]

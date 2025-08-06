# Use a publicly available WebLogic image
FROM vulhub/weblogic:12.2.1.3-2018

# Environment variables
ENV DOMAIN_NAME="base_domain" \
    ADMIN_PORT="7001" \
    ADMIN_NAME="AdminServer" \
    ADMIN_HOST="localhost" \
    ADMIN_USERNAME="weblogic" \
    ADMIN_PASSWORD="welcome1" \
    VERSION="A" \
    PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin \
    JAVA_OPTIONS="-Djava.awt.headless=true"

# Copy SQLcl and database script
COPY install/sqlcl-25.2.2.199.0918.zip /u01/oracle/
COPY config/demo_oracle.ddl /u01/oracle/

# Copy container scripts
COPY container-scripts/ /u01/oracle/container-scripts/

USER root
RUN yum -y install unzip && \
    cd /u01/oracle/ && \
    unzip -q sqlcl-25.2.2.199.0918.zip && \
    rm -f sqlcl-25.2.2.199.0918.zip && \
    chown -R oracle:oracle /u01/oracle/sqlcl && \
    chmod +x /u01/oracle/container-scripts/*.sh

USER oracle

# Create WebLogic domain
RUN mkdir -p /u01/oracle/user_projects/domains/base_domain && \
    echo "# WLST Script to create a WebLogic domain" > /u01/oracle/create_domain.py && \
    echo "readTemplate('/u01/oracle/wlserver/common/templates/wls/wls.jar')" >> /u01/oracle/create_domain.py && \
    echo "cd('Servers/AdminServer')" >> /u01/oracle/create_domain.py && \
    echo "set('ListenAddress','')" >> /u01/oracle/create_domain.py && \
    echo "set('ListenPort', 7001)" >> /u01/oracle/create_domain.py && \
    echo "cd('/')" >> /u01/oracle/create_domain.py && \
    echo "cd('Security/base_domain/User/weblogic')" >> /u01/oracle/create_domain.py && \
    echo "set('Name', 'weblogic')" >> /u01/oracle/create_domain.py && \
    echo "set('Password', 'welcome1')" >> /u01/oracle/create_domain.py && \
    echo "setOption('ServerStartMode', 'dev')" >> /u01/oracle/create_domain.py && \
    echo "writeDomain('/u01/oracle/user_projects/domains/base_domain')" >> /u01/oracle/create_domain.py && \
    echo "closeTemplate()" >> /u01/oracle/create_domain.py && \
    echo "exit()" >> /u01/oracle/create_domain.py && \
    cd /u01/oracle && \
    . /u01/oracle/wlserver/server/bin/setWLSEnv.sh && \
    java weblogic.WLST create_domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs && \
    chown -R oracle:oracle /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs

# Create autodeploy directory
# Create directories for logs
RUN mkdir -p /u01/oracle/user_projects/domains/base_domain/autodeploy && \
    mkdir -p /u01/oracle/logs/weblogic-monitoring && \
    chown -R oracle:oracle /u01/oracle/logs

# Create a startup script
RUN echo '#!/bin/bash' > /u01/oracle/startWebLogic.sh && \
    echo 'echo "Starting WebLogic Server Version $VERSION..."' >> /u01/oracle/startWebLogic.sh && \
    echo 'cd /u01/oracle/user_projects/domains/base_domain' >> /u01/oracle/startWebLogic.sh && \
    echo 'mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs' >> /u01/oracle/startWebLogic.sh && \
    echo 'chown -R oracle:oracle /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs' >> /u01/oracle/startWebLogic.sh && \
    echo 'chmod -R 775 /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs' >> /u01/oracle/startWebLogic.sh && \
    echo 'nohup ./bin/startWebLogic.sh > /dev/null 2>&1 &' >> /u01/oracle/startWebLogic.sh && \
    echo 'echo "WebLogic Server started in background. Setting up monitoring..."' >> /u01/oracle/startWebLogic.sh && \
    echo '/u01/oracle/container-scripts/setup-monitoring.sh &' >> /u01/oracle/startWebLogic.sh && \
    echo '/u01/oracle/container-scripts/health-check.sh &' >> /u01/oracle/startWebLogic.sh && \
    echo 'echo "WebLogic Server is ready. Keeping container running..."' >> /u01/oracle/startWebLogic.sh && \
    echo 'tail -f /dev/null' >> /u01/oracle/startWebLogic.sh && \
    chmod +x /u01/oracle/startWebLogic.sh

# Create deploy directory and copy WAR files
RUN mkdir -p /u01/oracle/deploy

# Copy WAR files if they exist
COPY deploy/*.war /u01/oracle/deploy/

WORKDIR /u01/oracle

# Expose ports
EXPOSE 7001 7002

# Start WebLogic
CMD ["/u01/oracle/startWebLogic.sh"]

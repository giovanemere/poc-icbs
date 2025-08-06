# Oracle Database Express 21c - Docker Hub Ready
# Optimized for development and testing environments
FROM container-registry.oracle.com/database/express:21.3.0-xe

# Metadata
LABEL maintainer="edissonz8809"
LABEL description="Oracle Database Express 21c optimized for development"
LABEL version="v1.1.0"
LABEL org.opencontainers.image.title="Oracle Express DB"
LABEL org.opencontainers.image.description="Production-ready Oracle Database Express 21c with development optimizations"
LABEL org.opencontainers.image.version="v1.1.0"
LABEL org.opencontainers.image.authors="edissonz8809"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/edissonz8809/oracle-express-db"
LABEL org.opencontainers.image.source="https://github.com/edissonz8809/docker-weblogic-oracle"

# Switch to root for setup
USER root

# Environment variables for Oracle
ENV ORACLE_PWD=Oracle123 \
    ORACLE_CHARACTERSET=AL32UTF8 \
    ORACLE_EDITION=express \
    ORACLE_PDB=XEPDB1 \
    ORACLE_SID=XE \
    ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE \
    PATH=$ORACLE_HOME/bin:$PATH \
    INIT_SGA_SIZE=1024 \
    INIT_PGA_SIZE=512 \
    ORACLE_DOCKER_INSTALL=true

# Install additional packages for development (using yum instead of microdnf)
RUN yum update -y && \
    yum install -y \
        curl \
        wget \
        nc \
        procps \
        vim-minimal \
        less && \
    yum clean all

# Create application directories
RUN mkdir -p /app/{scripts,config,sql,backup,logs,monitoring} && \
    mkdir -p /opt/oracle/scripts/setup && \
    mkdir -p /opt/oracle/scripts/startup && \
    mkdir -p /u01/app/oracle/admin/XE/dpdump

# Copy application files
COPY scripts/ /app/scripts/
COPY config/ /app/config/
COPY sql/ /app/sql/

# Create initialization SQL scripts
RUN echo "-- Oracle Express DB Initialization" > /app/sql/01-init-database.sql && \
    echo "ALTER SESSION SET CONTAINER = XEPDB1;" >> /app/sql/01-init-database.sql && \
    echo "" >> /app/sql/01-init-database.sql && \
    echo "-- Create development user" >> /app/sql/01-init-database.sql && \
    echo "CREATE USER weblogic_dev IDENTIFIED BY WebLogic123;" >> /app/sql/01-init-database.sql && \
    echo "GRANT CONNECT, RESOURCE, DBA TO weblogic_dev;" >> /app/sql/01-init-database.sql && \
    echo "GRANT UNLIMITED TABLESPACE TO weblogic_dev;" >> /app/sql/01-init-database.sql && \
    echo "" >> /app/sql/01-init-database.sql && \
    echo "-- Create sample tables for WebLogic integration" >> /app/sql/01-init-database.sql && \
    echo "CREATE TABLE weblogic_dev.feature_flags (" >> /app/sql/01-init-database.sql && \
    echo "    id NUMBER PRIMARY KEY," >> /app/sql/01-init-database.sql && \
    echo "    flag_name VARCHAR2(100) NOT NULL," >> /app/sql/01-init-database.sql && \
    echo "    enabled NUMBER(1) DEFAULT 0," >> /app/sql/01-init-database.sql && \
    echo "    created_date DATE DEFAULT SYSDATE" >> /app/sql/01-init-database.sql && \
    echo ");" >> /app/sql/01-init-database.sql && \
    echo "" >> /app/sql/01-init-database.sql && \
    echo "-- Insert sample data" >> /app/sql/01-init-database.sql && \
    echo "INSERT INTO weblogic_dev.feature_flags VALUES (1, 'version_a_enabled', 1, SYSDATE);" >> /app/sql/01-init-database.sql && \
    echo "INSERT INTO weblogic_dev.feature_flags VALUES (2, 'version_b_enabled', 0, SYSDATE);" >> /app/sql/01-init-database.sql && \
    echo "INSERT INTO weblogic_dev.feature_flags VALUES (3, 'canary_deployment', 1, SYSDATE);" >> /app/sql/01-init-database.sql && \
    echo "COMMIT;" >> /app/sql/01-init-database.sql

# Create health check script
RUN echo '#!/bin/bash' > /app/scripts/health-check.sh && \
    echo 'export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE' >> /app/scripts/health-check.sh && \
    echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /app/scripts/health-check.sh && \
    echo '' >> /app/scripts/health-check.sh && \
    echo '# Check if Oracle is running' >> /app/scripts/health-check.sh && \
    echo 'if pgrep -f "ora_pmon_XE" > /dev/null; then' >> /app/scripts/health-check.sh && \
    echo '    # Check if database is accepting connections' >> /app/scripts/health-check.sh && \
    echo '    if echo "SELECT 1 FROM DUAL;" | sqlplus -s system/Oracle123@localhost:1521/XE > /dev/null 2>&1; then' >> /app/scripts/health-check.sh && \
    echo '        echo "Oracle Database is healthy"' >> /app/scripts/health-check.sh && \
    echo '        exit 0' >> /app/scripts/health-check.sh && \
    echo '    else' >> /app/scripts/health-check.sh && \
    echo '        echo "Oracle Database is not accepting connections"' >> /app/scripts/health-check.sh && \
    echo '        exit 1' >> /app/scripts/health-check.sh && \
    echo '    fi' >> /app/scripts/health-check.sh && \
    echo 'else' >> /app/scripts/health-check.sh && \
    echo '    echo "Oracle processes not running"' >> /app/scripts/health-check.sh && \
    echo '    exit 1' >> /app/scripts/health-check.sh && \
    echo 'fi' >> /app/scripts/health-check.sh

# Create database monitoring script
RUN echo '#!/bin/bash' > /app/scripts/monitor-db.sh && \
    echo 'export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE' >> /app/scripts/monitor-db.sh && \
    echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /app/scripts/monitor-db.sh && \
    echo '' >> /app/scripts/monitor-db.sh && \
    echo 'echo "=== Oracle Database Status ==="' >> /app/scripts/monitor-db.sh && \
    echo 'echo "Date: $(date)"' >> /app/scripts/monitor-db.sh && \
    echo 'echo ""' >> /app/scripts/monitor-db.sh && \
    echo '' >> /app/scripts/monitor-db.sh && \
    echo '# Database status' >> /app/scripts/monitor-db.sh && \
    echo 'echo "Database Status:"' >> /app/scripts/monitor-db.sh && \
    echo 'echo "SELECT name, open_mode FROM v\$database;" | sqlplus -s system/Oracle123@localhost:1521/XE 2>/dev/null || echo "Database not accessible"' >> /app/scripts/monitor-db.sh && \
    echo 'echo ""' >> /app/scripts/monitor-db.sh && \
    echo '' >> /app/scripts/monitor-db.sh && \
    echo '# Memory usage' >> /app/scripts/monitor-db.sh && \
    echo 'echo "Memory Usage:"' >> /app/scripts/monitor-db.sh && \
    echo 'echo "SELECT name, value FROM v\$parameter WHERE name IN ('"'"'sga_target'"'"', '"'"'pga_aggregate_target'"'"');" | sqlplus -s system/Oracle123@localhost:1521/XE 2>/dev/null || echo "Memory info not accessible"' >> /app/scripts/monitor-db.sh && \
    echo 'echo ""' >> /app/scripts/monitor-db.sh && \
    echo '' >> /app/scripts/monitor-db.sh && \
    echo '# Active sessions' >> /app/scripts/monitor-db.sh && \
    echo 'echo "Active Sessions:"' >> /app/scripts/monitor-db.sh && \
    echo 'echo "SELECT COUNT(*) as active_sessions FROM v\$session WHERE status = '"'"'ACTIVE'"'"';" | sqlplus -s system/Oracle123@localhost:1521/XE 2>/dev/null || echo "Session info not accessible"' >> /app/scripts/monitor-db.sh

# Create startup script with custom initialization
RUN echo '#!/bin/bash' > /app/scripts/start-oracle-with-init.sh && \
    echo 'echo "Starting Oracle Database Express with custom initialization..."' >> /app/scripts/start-oracle-with-init.sh && \
    echo '' >> /app/scripts/start-oracle-with-init.sh && \
    echo '# Start Oracle database' >> /app/scripts/start-oracle-with-init.sh && \
    echo '/opt/oracle/runOracle.sh &' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'ORACLE_PID=$!' >> /app/scripts/start-oracle-with-init.sh && \
    echo '' >> /app/scripts/start-oracle-with-init.sh && \
    echo '# Wait for Oracle to be ready' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'echo "Waiting for Oracle Database to be ready..."' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'for i in {1..60}; do' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    if /app/scripts/health-check.sh > /dev/null 2>&1; then' >> /app/scripts/start-oracle-with-init.sh && \
    echo '        echo "Oracle Database is ready!"' >> /app/scripts/start-oracle-with-init.sh && \
    echo '        break' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    fi' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    echo "Waiting... ($i/60)"' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    sleep 10' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'done' >> /app/scripts/start-oracle-with-init.sh && \
    echo '' >> /app/scripts/start-oracle-with-init.sh && \
    echo '# Run initialization SQL if database is ready' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'if /app/scripts/health-check.sh > /dev/null 2>&1; then' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    echo "Running custom initialization..."' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    if [ -f /app/sql/01-init-database.sql ]; then' >> /app/scripts/start-oracle-with-init.sh && \
    echo '        sqlplus system/Oracle123@localhost:1521/XE @/app/sql/01-init-database.sql' >> /app/scripts/start-oracle-with-init.sh && \
    echo '        echo "Custom initialization completed"' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    fi' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'else' >> /app/scripts/start-oracle-with-init.sh && \
    echo '    echo "Warning: Oracle Database not ready for initialization"' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'fi' >> /app/scripts/start-oracle-with-init.sh && \
    echo '' >> /app/scripts/start-oracle-with-init.sh && \
    echo '# Keep container running' >> /app/scripts/start-oracle-with-init.sh && \
    echo 'wait $ORACLE_PID' >> /app/scripts/start-oracle-with-init.sh

# Create version info
RUN echo "Oracle Express DB v1.1.0" > /app/VERSION && \
    echo "Build Date: $(date)" >> /app/VERSION && \
    echo "Oracle Version: 21.3.0-xe" >> /app/VERSION && \
    echo "WebLogic Integration: Enabled" >> /app/VERSION && \
    echo "Development Optimized: Yes" >> /app/VERSION && \
    echo "Health Checks: Enabled" >> /app/VERSION

# Set permissions
RUN chown -R oracle:dba /app && \
    chmod -R 755 /app && \
    find /app/scripts -name "*.sh" -exec chmod +x {} \; && \
    chown -R oracle:dba /opt/oracle/scripts

# Switch back to oracle user
USER oracle

# Expose Oracle ports
EXPOSE 1521 5500

# Health check
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD /app/scripts/health-check.sh

# Working directory
WORKDIR /opt/oracle

# Default command - use custom startup script
CMD ["/app/scripts/start-oracle-with-init.sh"]

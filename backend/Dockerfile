# ─────────────────────────────────────────────────────────────────────────────
# SQL Server image with auto-initialization
# Base: mcr.microsoft.com/mssql/server:2022-latest  (linux/amd64)
# ─────────────────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/mssql/server:2022-latest

# Accept the EULA and set default env vars (can be overridden in compose)
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer \
    SA_PASSWORD=YourStrong!Passw0rd

# Copy the init script and the custom entrypoint
COPY sql/init.sql   /init/init.sql
COPY entrypoint.sh  /init/entrypoint.sh

# Make the entrypoint executable (run as root briefly, then SQL Server drops privs)
USER root
RUN chmod +x /init/entrypoint.sh

# Expose the default SQL Server port
EXPOSE 1433

ENTRYPOINT ["/bin/bash", "/init/entrypoint.sh"]

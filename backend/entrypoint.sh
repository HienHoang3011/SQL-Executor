#!/bin/bash
# entrypoint.sh
# Starts SQL Server, waits for it to be ready, then runs the init script.

SA_PASSWORD="${SA_PASSWORD}"
INIT_SQL="/init/init.sql"

echo ">>> Starting SQL Server..."
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo ">>> Waiting for SQL Server to be ready..."
for i in $(seq 1 60); do
    /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "${SA_PASSWORD}" \
        -Q "SELECT 1" \
        -C \
        -b \
        > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ">>> SQL Server is ready after ${i}s."
        break
    fi
    echo "    Attempt ${i}/60 - not ready yet, waiting 1s..."
    sleep 1
done

echo ">>> Running initialization script..."
/opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "${SA_PASSWORD}" \
    -i "${INIT_SQL}" \
    -C \
    -b

if [ $? -eq 0 ]; then
    echo ">>> Database initialized successfully."
else
    echo "!!! Initialization script failed." >&2
fi

# Keep the container alive by waiting on SQL Server
wait $SQL_PID

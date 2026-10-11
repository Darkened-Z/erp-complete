#!/bin/bash
set -e

# Wait for DB to be ready
while ! mysql -h db -u root -padmin -e "SELECT 1" >/dev/null 2>&1; do
    echo "Waiting for database..."
    sleep 3
done

cd /home/frappe

if [ ! -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Initializing Frappe Bench with ParaLogic fork..."
    bench init --frappe-branch version-14 --frappe-path https://github.com/ParaLogicTech/frappe frappe-bench --skip-redis-config-generation
    cd frappe-bench

    bench set-mariadb-host db
    bench set-redis-cache-host redis:6379
    bench set-redis-queue-host redis:6379
    bench set-redis-socketio-host redis:6379

    echo "Fetching ERPNext and Textile apps..."
    bench get-app erpnext https://github.com/ParaLogicTech/erpnext --branch version-14
    bench get-app textile https://github.com/ParaLogicTech/textile --branch version-14

    echo "Creating new site..."
    bench new-site textile.localhost --db-root-password admin --admin-password admin --force
    bench --site textile.localhost install-app erpnext
    bench --site textile.localhost install-app textile
    bench use textile.localhost
    bench --site textile.localhost set-config dns_multitenant false
    echo "textile.localhost" > sites/currentsite.txt

    if [ -f "Procfile" ]; then
        sed -i 's/bench serve --port 8000/bench serve --port 8000 --host 0.0.0.0/g' Procfile
    fi
else
    echo "Bench already initialized."
    cd frappe-bench
    echo "textile.localhost" > sites/currentsite.txt
    if [ -f "Procfile" ]; then
        sed -i 's/bench serve --port 8000/bench serve --port 8000 --host 0.0.0.0/g' Procfile
    fi
fi

echo "Starting bench..."
exec bench start

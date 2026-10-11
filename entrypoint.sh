#!/bin/bash
set -e

# Wait for DB to be ready
while ! mysql -h db -u root -padmin -e "SELECT 1" >/dev/null 2>&1; do
    echo "Waiting for database..."
    sleep 3
done

if [ ! -d "frappe-bench/apps/frappe" ]; then
    echo "Initializing Frappe Bench with ParaLogic fork..."
    bench init --frappe-branch version-14 --frappe-path https://github.com/ParaLogicTech/frappe frappe-bench --skip-redis-config-generation
    cd frappe-bench
    bench set-config -g db_host db
    bench set-config -g redis_cache redis://redis:6379
    bench set-config -g redis_queue redis://redis:6379
    bench set-config -g redis_socketio redis://redis:6379

    bench new-site textile.localhost --db-root-password admin --admin-password admin --force

    bench get-app erpnext https://github.com/ParaLogicTech/erpnext --branch version-14
    bench get-app textile https://github.com/ParaLogicTech/textile --branch version-14

    bench --site textile.localhost install-app erpnext
    bench --site textile.localhost install-app textile
else
    echo "Bench already initialized."
    cd frappe-bench
fi

echo "Starting bench..."
exec bench start

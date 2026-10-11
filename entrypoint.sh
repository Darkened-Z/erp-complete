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
fi

cd /home/frappe/frappe-bench

python3 -c '
import json
p = "sites/common_site_config.json"
try:
    with open(p, "r") as f:
        d = json.load(f)
except Exception:
    d = {}
d["db_host"] = "db"
d["redis_cache"] = "redis://redis:6379"
d["redis_queue"] = "redis://redis:6379"
d["redis_socketio"] = "redis://redis:6379"
d["serve_default_site"] = True
d["developer_mode"] = 1
with open(p, "w") as f:
    json.dump(d, f, indent=1)
'

if [ ! -d "apps/crm" ]; then
    echo "Fetching CRM app..."
    bench get-app crm https://github.com/ParaLogicTech/crm --branch version-14
fi

if [ ! -d "apps/erpnext" ]; then
    echo "Fetching ERPNext app..."
    bench get-app erpnext https://github.com/ParaLogicTech/erpnext --branch version-14
else
    bench build --app erpnext || true
fi

if [ ! -d "apps/textile" ]; then
    echo "Fetching Textile app..."
    bench get-app textile https://github.com/ParaLogicTech/textile --branch version-14
fi

if [ ! -d "sites/textile.localhost" ]; then
    echo "Creating new site textile.localhost..."
    bench new-site textile.localhost --db-root-password admin --admin-password admin --force
    bench --site textile.localhost install-app crm
    bench --site textile.localhost install-app erpnext
    bench --site textile.localhost install-app textile
    bench use textile.localhost
    bench --site textile.localhost set-config dns_multitenant false
else
    bench --site textile.localhost install-app crm || true
    bench --site textile.localhost install-app erpnext || true
    bench --site textile.localhost install-app textile || true
    bench use textile.localhost
    bench --site textile.localhost set-config dns_multitenant false
fi

echo "textile.localhost" > sites/currentsite.txt

if [ -f "Procfile" ]; then
    sed -i 's/bench serve --port 8000/bench serve --port 8000 --host 0.0.0.0/g' Procfile
fi

echo "Starting bench..."
exec bench start

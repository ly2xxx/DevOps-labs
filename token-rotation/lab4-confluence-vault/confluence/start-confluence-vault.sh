#!/bin/bash
# start-confluence-vault.sh
# Uses curl to call the Vault HTTP API (vault CLI not available in this image)

set -e

echo "🔐 Requesting database credentials from Vault..."

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

if [ -z "$VAULT_TOKEN" ]; then
    echo "❌ VAULT_TOKEN not set"
    exit 1
fi

# Try to get dynamic credentials from Vault database engine
echo "  Calling Vault API at $VAULT_ADDR ..."
CREDS_JSON=$(curl -s \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/database/creds/confluence-app")

# Check if the database engine is configured (errors field will be present on failure)
ERROR=$(echo "$CREDS_JSON" | grep -o '"errors"' || true)
if [ -n "$ERROR" ]; then
    echo "⚠️  Vault database engine not configured yet. Using static credentials from env."
    DB_USER="${ATL_JDBC_USER:-confluence}"
    DB_PASS="${ATL_JDBC_PASSWORD:-confluence_password}"
else
    DB_USER=$(echo "$CREDS_JSON" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    DB_PASS=$(echo "$CREDS_JSON" | grep -o '"password":"[^"]*"' | cut -d'"' -f4)
    LEASE_ID=$(echo "$CREDS_JSON" | grep -o '"lease_id":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Received dynamic credentials: $DB_USER (lease: $LEASE_ID)"

    # Optionally write to Confluence config if it already exists
    CFG_FILE="/var/atlassian/application-data/confluence/confluence.cfg.xml"
    if [ -f "$CFG_FILE" ]; then
        sed -i "s|<property name=\"hibernate.connection.username\">.*</property>|<property name=\"hibernate.connection.username\">$DB_USER</property>|" "$CFG_FILE"
        sed -i "s|<property name=\"hibernate.connection.password\">.*</property>|<property name=\"hibernate.connection.password\">$DB_PASS</property>|" "$CFG_FILE"
    fi
fi

export ATL_JDBC_USER="$DB_USER"
export ATL_JDBC_PASSWORD="$DB_PASS"

# Remove stale PID file left by previous container runs (prevents "Start aborted")
rm -f /opt/atlassian/confluence/work/catalina.pid

echo "🚀 Starting Confluence..."
exec /opt/atlassian/confluence/bin/start-confluence.sh

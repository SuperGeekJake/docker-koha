#!/bin/bash
set -e

# Wait for DB to be ready
until mariadb-admin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent; do
  echo "Waiting for database connection..."
  sleep 5
done

# Create a Koha instance named 'library' if it doesn't exist
KOHA_INSTANCE="library"
if [ ! -d "/etc/koha/sites/$KOHA_INSTANCE" ]; then
    echo "Creating Koha instance: $KOHA_INSTANCE"
    # Use --request-db to skip local DB creation as we use a separate container
    # However, koha-create --request-db still wants to create a DB user sometimes.
    # We will try to mock some things or use a more direct approach.
    
    # We can try using koha-create --request-db if we have credentials
    # but koha-create is designed for local DB.
    
    # Alternatively, we can just copy templates.
    # For a docker setup, it's often better to just have the config files.
    # But let's try koha-create first.
    
    koha-create --request-db "$KOHA_INSTANCE" || true
    
    # Configure koha-conf.xml for the DB connection
    CONF_FILE="/etc/koha/sites/$KOHA_INSTANCE/koha-conf.xml"
    if [ -f "$CONF_FILE" ]; then
        sed -i "s/<db_scheme>.*/<db_scheme>mysql<\/db_scheme>/" "$CONF_FILE"
        sed -i "s/<database>.*/<database>$DB_NAME<\/database>/" "$CONF_FILE"
        sed -i "s/<hostname>.*/<hostname>$DB_HOST<\/hostname>/" "$CONF_FILE"
        sed -i "s/<user>.*/<user>$DB_USER<\/user>/" "$CONF_FILE"
        sed -i "s/<pass>.*/<pass>$DB_PASS<\/pass>/" "$CONF_FILE"
        
        # Configure Memcached
        sed -i "s/<memcached_servers>.*/<memcached_servers>$MEMCACHED_SERVER<\/memcached_servers>/" "$CONF_FILE"
        sed -i "s/<search_engine>.*/<search_engine>elasticsearch<\/search_engine>/" "$CONF_FILE"
        sed -i "s/<elasticsearch_uri>.*/<elasticsearch_uri>http:\/\/$OPENSEARCH_HOST:$OPENSEARCH_PORT<\/elasticsearch_uri>/" "$CONF_FILE"
    fi
    
    # Enable Apache site
    a2ensite "$KOHA_INSTANCE"
fi

# Link Koha logs to stdout/stderr
ln -sf /dev/stdout /var/log/koha/$KOHA_INSTANCE/opac-error.log
ln -sf /dev/stdout /var/log/koha/$KOHA_INSTANCE/intranet-error.log
ln -sf /dev/stdout /var/log/koha/$KOHA_INSTANCE/opac-access.log
ln -sf /dev/stdout /var/log/koha/$KOHA_INSTANCE/intranet-access.log

exec "$@"

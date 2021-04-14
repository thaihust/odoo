################################# Install
rm -rf addons config odoo-db-data odoo-web-data
mkdir -p addons config odoo-db-data odoo-web-data
chown -R 101:101 odoo-web-data
docker-compose -f odoo-compose.yml up -d

################################# Post install

su - postgres
psql -U odoo postgres

postgres-# \l
postgres-# \c odoo-db
odoo-db-# \dt

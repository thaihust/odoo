#!/bin/bash
################################################################################
# Script for installing Odoo V9 on Ubuntu 14.04 LTS (could be used for other version too)
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 14.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# nano odoo-install.sh
# Place this content in it and then make the file executable:
# chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################
 
#odoo
OE_USER=odoo-admin
OE_ADMINPASSWD=odoo-admin

##
###  WKHTMLTOPDF download links
WKHTMLTOX=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
apt-get update && apt-get upgrade -y

#--------------------------------------------------
# Install tool, python packages
#--------------------------------------------------	
apt-get install git python3-pip build-essential wget curl python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libpq-dev libsasl2-dev python3-setuptools node-less python3-pypdf2 libjpeg-dev -y
#Thieu libpq-dev va libjpeg-dev
#--------------------------------------------------
# Install and Configuring Nginx 
#--------------------------------------------------

apt-get install curl gnupg2 ca-certificates lsb-release -y
echo "deb [arch=amd64] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
apt-key fingerprint ABF5BD827BD9BF62
apt-get update
apt-get install nginx python3-certbot-nginx -y

mkdir -p /etc/nginx/ssl

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/nginx/ssl/odoo.fago-labs.com.key -out /etc/nginx/ssl/odoo.fago-labs.com.crt -subj "/CN=odoo.fago-labs.com"

cp ./odoo.conf /etc/nginx/conf.d/

systemctl restart nginx.service

#--------------------------------------------------
# Creating a System User
#--------------------------------------------------	
useradd -m -d /opt/$OE_USER -U -r -s /bin/bash $OE_USER


#--------------------------------------------------
# Installing and Configuring PostgreSQL
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
su - postgres -c "createuser -s $OE_USER" 

#--------------------------------------------------
# Install Wkhtmltopdf
#--------------------------------------------------
wget $WKHTMLTOX
apt-get install -y ./`basename $WKHTMLTOX`

#-------------------------------
#--------------------------------------------------
# Installing and Configuring Odoo 13 
#--------------------------------------------------
apt-get install -y locales && locale-gen en_US.UTF-8
export LANG='en_US.UTF-8'
export LANGUAGE='en_US:en'
export LC_ALL='en_US.UTF-8'

chown root:root /opt/$OE_USER
git clone https://www.github.com/odoo/odoo --depth 1 --branch 14.0 /opt/$OE_USER/odoo
cd /opt/$OE_USER
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip3 install wheel
#pip3 install psycopg2-binary
pip3 install -r odoo/requirements.txt
deactivate
mkdir /opt/$OE_USER/odoo-custom-addons
chown $OE_USER:$OE_USER /opt/$OE_USER
#-------------------------------

cat <<EOF > /etc/odoo.conf
[options]
; This is the password that allows database operations:
admin_passwd = $OE_ADMINPASSWD
db_host = False
db_port = 5432
db_user = $OE_USER
db_password = False
addons_path = /opt/$OE_USER/odoo/addons,/opt/$OE_USER/odoo-custom-addons
EOF

#--------------------------------------------------
# Creating a Systemd Unit File 
#--------------------------------------------------

cat <<EOF > /etc/systemd/system/odoo13.service
[Unit]
Description=Odoo13
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo13
PermissionsStartOnly=true
User=$OE_USER
Group=$OE_USER
ExecStart=/opt/$OE_USER/odoo-venv/bin/python3 /opt/$OE_USER/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now odoo13

## To see the messages logged by the Odoo service, use the command below:
### journalctl -u odoo13

systemctl restart nginx.service
systemctl restart odoo13.service


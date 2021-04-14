#!/bin/bash

source /etc/default/odoo
/usr/sbin/nginx
/opt/$OE_USER/odoo-venv/bin/python3 /opt/$OE_USER/odoo/odoo-bin -c /etc/odoo.conf

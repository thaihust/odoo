FROM ubuntu:18.04

#odoo env
ENV OE_VERSION=14.0
ENV OE_USER=odoo-admin
ENV OE_ADMINPASSWD=odoo-admin
ENV OS_DB_PASSWORD=odoo-admin
ENV OE_DB_HOST=odoo-db
ENV OE_DOMAIN=odoo.fago-labs.com
ENV WKHTMLTOX=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'
ENV TZ=Asia/Ho_Chi_Minh

#--------------------------------------------------
# Update Server
#--------------------------------------------------
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && sed -i "s|archive.ubuntu.com|sg.archive.ubuntu.com|g" /etc/apt/sources.list \ 
    && apt-get update && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install git python3-pip build-essential wget curl python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libpq-dev libsasl2-dev python3-setuptools node-less python3-pypdf2 libjpeg-dev curl gnupg2 ca-certificates lsb-release \
    && echo "deb [arch=amd64] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && apt-key fingerprint ABF5BD827BD9BF62 \
    && apt-get update \
    && apt-get install nginx python3-certbot-nginx -y \
    && mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/nginx/ssl/$OE_DOMAIN.key -out /etc/nginx/ssl/$OE_DOMAIN.crt -subj "/CN=$OE_DOMAIN"

COPY nginx/odoo.conf /etc/nginx/conf.d/
COPY odoo.conf /etc/
COPY start-odoo.sh /usr/local/bin/
COPY default/odoo /etc/default

#--------------------------------------------------
# Creating a System User
#--------------------------------------------------	
RUN sed -i "s|OE_DOMAIN|$OE_DOMAIN|g" /etc/nginx/conf.d/odoo.conf \
    && useradd -m -d /opt/$OE_USER -U -r -s /bin/bash $OE_USER \
    && wget $WKHTMLTOX \
    && apt-get install -y ./`basename $WKHTMLTOX` \
    && apt-get install -y locales && locale-gen en_US.UTF-8 \
    && chown root:root /opt/$OE_USER \
    && git clone https://www.github.com/odoo/odoo --depth 1 --branch $OE_VERSION /opt/$OE_USER/odoo \
    && cd /opt/$OE_USER \
    && python3 -m venv odoo-venv \
    && . odoo-venv/bin/activate \
    && pip3 install wheel \
    && pip3 install -r odoo/requirements.txt \
    && deactivate \
    && mkdir /opt/$OE_USER/odoo-custom-addons \
    && chown $OE_USER:$OE_USER /opt/$OE_USER \
    && sed -i "s|OE_ADMINPASSWD|$OE_ADMINPASSWD|g" /etc/odoo.conf && sed -i "s|OE_DB_HOST|$OE_DB_HOST|g" /etc/odoo.conf && sed -i "s|OE_USER|$OE_USER|g" /etc/odoo.conf && sed -i "s|OS_DB_PASSWORD|$OS_DB_PASSWORD|g" /etc/odoo.conf \
    && chmod +x /usr/local/bin/start-odoo.sh

CMD ["/usr/local/bin/start-odoo.sh"]

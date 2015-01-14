#!/usr/bin/env bash

# Before running script, change all CHANGE_xxxx variables.

echo "update and upgrade"
sudo apt-get update >/dev/null 2>&1
sudo apt-get upgrade >/dev/null 2>&1

# Install python-pip.
echo "Install python-pip"
sudo apt-get install -y python-pip >/dev/null 2>&1

# Install postgres
echo "Install django"
sudo pip install django >/dev/null 2>&1

# Install postgres
echo "Install postgres and dependencies"
sudo apt-get install -y libpq-dev python-dev >/dev/null 2>&1
sudo apt-get install -y postgresql postgresql-contrib >/dev/null 2>&1
sudo pip install psycopg2 >/dev/null 2>&1

# Install nginx
echo "Install nginx"
sudo apt-get install -y nginx >/dev/null 2>&1

# Install gunicorn
echo "Install gunicorn"
sudo pip install gunicorn >/dev/null 2>&1

# Install supervisor
echo "Install supervisor"
sudo apt-get install -y supervisor >/dev/null 2>&1

# Create user cyber-rt35. This is the user the site will run as (eventually).
#echo "create user cyber-rt35"
#echo -e "cyber-rt35\ncyber-rt35" | (sudo adduser cyber-rt35 2>&1)
#sudo adduser cyber-rt35 sudo

# Set up postgres DB
echo "Setup postgres"
sudo -u postgres psql <<< "
CREATE DATABASE websitedb;
CREATE USER website1 WITH PASSWORD 'university023';
GRANT ALL PRIVILEGES ON DATABASE websitedb TO website1;
"


# Change ownership of 'www' folder from 'root' to 'vagrant'.  Create required directories
echo "Create directories"
sudo mkdir -p www
sudo mkdir -p www/static
sudo mkdir -p www/media
sudo mkdir -p www/gunicorn

# Create nginx configuration file
echo "Configure nginx"
cat << EOF > /etc/nginx/sites-available/website
server {

    listen 8080;    

    server_name 127.0.0.1;

    #auth_basic "closed site";
    #auth_basic_user_file /etc/nginx/htpasswd;

    access_log off;

    location /static/ {
        alias /home/vagrant/www/static/;
    }

    location /media/ {
        alias /home/vagrant/www/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_set_header x-Real-IP \$remote_addr;
        add_header P3P 'CP="ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV"';
    }
}
EOF

#change nginx configuration file to new file
sudo ln -s /etc/nginx/sites-available/website /etc/nginx/sites-enabled/website
sudo rm /etc/nginx/sites-enabled/default

# create gunicorn configuration file
echo "Configure gunicorn"
cat << EOF > /home/vagrant/www/gunicorn/conf.py
command = 'gunicorn'
pythonpath = '/home/vagrant/www/website/'
bind = '127.0.0.1:8001'
workers = 3
EOF

# Create supervisor config file for gunicorn process
echo "Configure supervisor"
cat << EOF > /etc/supervisor/conf.d/gunicorn.conf
[program:gunicorn]
command=gunicorn -c /home/vagrant/www/gunicorn/conf.py CHANGE_sitename.wsgi
directory=/home/vagrant/www/website
user=vagrant
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/gunicorn/err.log
stdout_logfile=/var/log/supervisor/gunicorn/out.log
EOF

mkdir /var/log/supervisor/gunicorn

#change ownership of files to vagrant 
echo "Change ownership of 'www' to vagrant"
sudo chown -R vagrant:vagrant www

#restart nginx
echo "Restart nginx"
sudo service nginx restart

echo "Start gunicorn with supervisor"
sudo supervisorctl reread
sudo supervisorctl update

# Install django website dependencies
echo "Install Django website dependencies"
sudo pip install pillow >/dev/null 2>&1
sudo pip install django-bootstrap-form >/dev/null 2>&1
sudo pip install django-floppyforms >/dev/null 2>&1

# Install geodjango website dependencies
echo "Install geodjango website dependencies"
sudo apt-get install -y binutils libproj-dev gdal-bin >/dev/null 2>&1
sudo apt-get install -y postgis >/dev/null 2>&1
sudo apt-get install -y postgresql-9.3-postgis-scripts >/dev/null 2>&1
sudo apt-get install -y npm >/dev/null 2>&1
sudo apt-get install -y git >/dev/null 2>&1

# Configure postgres for geodjango
echo "Configure postgres to for geodjango"
sudo -u postgres psql -d websitedb <<< "
CREATE EXTENSION POSTGIS;
"

# Setup django
echo "Setup django"
rm www/website/settings.py
cp /vagrant/settings.py www/website/settings.py
python manage.py makemigrations customusers >/dev/null 2>&1
python manage.py migrate >/dev/null 2>&1
python manage.py collectstatic >/dev/null 2>&1

# Install optional preferences
echo "Install preferences"
sudo apt-get install -y vim >/dev/null 2>&1

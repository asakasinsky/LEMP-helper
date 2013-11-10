#!/bin/bash



# Modify the following to match your system
NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php5/fpm/pool.d'
NGINX_INIT='/etc/init.d/nginx'
PHP_FPM_INIT='/etc/init.d/php5-fpm'
SED=`which sed`
CURRENT_DIR=`dirname $0`

# MySQL root password
ROOTPASS='password'
TIMEZONE='Europe/Moscow'

MYSQLPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
SFTPPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
##############

echo "Enter username for site and database:"
read USERNAME

echo "Enter domain"
read DOMAIN

##############

echo "Creating user and home directory..."
useradd $USERNAME -m -G sftp -s "/bin/false" -d "/home/$USERNAME"
if [ "$?" -ne 0 ]; then
	echo "Can't add user"
	exit 1
fi
echo $SFTPPASS > ./tmp
echo $SFTPPASS >> ./tmp
cat ./tmp | passwd $USERNAME
rm ./tmp


WEB_DIR="/home/$USERNAME/workspace"

# UNIX-сокет
# возможно использование TCP-сокетов типа 127.0.0.1:9000
# Номера портов и путей к unix-сокетам во всех пулах должны быть разными!
SOCKET=$WEB_DIR"/"$DOMAIN"/tmp/"$USERNAME"_fpm.sock#g"

SITE_CHROOT="$WEB_DIR/$DOMAIN"


##############
# set file perms and create required dirs!
mkdir $WEB_DIR
mkdir $WEB_DIR/$DOMAIN
mkdir $WEB_DIR/$DOMAIN/htdocs
mkdir $WEB_DIR/$DOMAIN/logs
mkdir $WEB_DIR/$DOMAIN/sessions
mkdir $WEB_DIR/$DOMAIN/tmp

chmod 775 $WEB_DIR/$DOMAIN -R
chmod 775 $WEB_DIR/$DOMAIN/sessions
chmod 775 $WEB_DIR/$DOMAIN/logs
chmod 775 $WEB_DIR/$DOMAIN/htdocs
chmod 777 $WEB_DIR/$DOMAIN/tmp
chown $USERNAME:$USERNAME $WEB_DIR/ -R
chown root:root "/home/$USERNAME"

##############
# Now we need to copy the virtual host template
echo "Creating vhost file"
CONFIG=$NGINX_CONFIG/$DOMAIN.conf
cp $CURRENT_DIR/nginx.vhost.conf.template $CONFIG
$SED -i "s|@@HOSTNAME@@|$DOMAIN|g" $CONFIG
$SED -i "s|@@PATH@@|$WEB_DIR/$DOMAIN/htdocs|g" $CONFIG
$SED -i "s|@@LOG_PATH@@|$WEB_DIR/$DOMAIN/logs|g" $CONFIG
$SED -i "s#@@SOCKET@@#"$SOCKET $CONFIG

# echo "How many FPM servers would you like by default:"
# read FPM_SERVERS
# echo "Min number of FPM servers would you like:"
# read MIN_SERVERS
# echo "Max number of FPM servers would you like:"
# read MAX_SERVERS
# Now we need to create a new php fpm pool config

FPM_SERVERS=2
MIN_SERVERS=2
MAX_SERVERS=4

FPMCONF="$PHP_INI_DIR/$DOMAIN.pool.conf"

cp $CURRENT_DIR/pool.conf.template $FPMCONF

$SED -i "s/@@USER@@/$USERNAME/g" $FPMCONF
$SED -i "s/@@HOME_DIR@@/\/home\/$USERNAME/g" $FPMCONF
$SED -i "s/@@START_SERVERS@@/$FPM_SERVERS/g" $FPMCONF
$SED -i "s/@@MIN_SERVERS@@/$MIN_SERVERS/g" $FPMCONF
$SED -i "s/@@MAX_SERVERS@@/$MAX_SERVERS/g" $FPMCONF
MAX_CHILDS=$((MAX_SERVERS+START_SERVERS))
$SED -i "s/@@MAX_CHILDS@@/$MAX_CHILDS/g" $FPMCONF
$SED -i "s#@@SOCKET@@#"$SOCKET $FPMCONF

$SED -i "s|@@SITE_CHROOT@@|$SITE_CHROOT|g" $FPMCONF
$SED -i "s|@@TMP_DIR@@|$WEB_DIR/$DOMAIN/tmp|g" $FPMCONF

chmod 600 $CONFIG

ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN.conf

#############
echo "Reloading nginx"
$NGINX_INIT reload
echo "Restarting php5-fpm"
$PHP_FPM_INIT restart

##############

echo "Creating database"

Q1="CREATE DATABASE IF NOT EXISTS $USERNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $USERNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$MYSQLPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

mysql -uroot --password=$ROOTPASS -e "$SQL"

##############

echo "#!/bin/bash

echo \"Set permissions for $WEB_DIR...\";
echo \"CHOWN files...\";
chown -R $USERNAME:$USERNAME \"$WEB_DIR\";
echo \"CHMOD directories...\";
find \"$WEB_DIR\" -type d -exec chmod 775 '{}' \;
echo \"CHMOD files...\";
find \"$WEB_DIR\" -type f -exec chmod 0664 '{}' \;
" > /home/$USERNAME/chmod
chmod +x /home/$USERNAME/chmod

echo "<?php
phpinfo();
" > $WEB_DIR/$DOMAIN/htdocs/index.php
chmod 0666 $WEB_DIR/$DOMAIN/htdocs/index.php
chmod +x $WEB_DIR/$DOMAIN/htdocs/index.php



echo "Done.
User: $USERNAME
Password: $PASSWORD
SFTP password: $SFTPPASS
Mysql password: $MYSQLPASS" > /home/$USERNAME/pass.txt

cat /home/$USERNAME/pass.txt

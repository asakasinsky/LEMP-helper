#!/bin/bash

echo "Enter MySQL root password:";
read ROOTPASS;

echo "Enter username to delete:";
read USERNAME;

for directory in `find /home/$USERNAME/workspace -type d`
do
    rm -f "/etc/nginx/sites-enabled/$directory.conf";
    rm -f "/etc/nginx/sites-available/$directory.conf";
    rm -f "/etc/php5/fpm/pool.d/$directory.conf";
    rm -f "/etc/php5/fpm/pool.d/$directory.conf";
    # find /var/log/nginx/ -type f -name "$USERNAME*" -exec rm '{}';
    # find /var/log/nginx/ -type f -name "$directory*" -exec rm '{}';
done
mysql -uroot --password=$ROOTPASS -e "DROP USER $USERNAME@localhost";
mysql -uroot --password=$ROOTPASS -e "DROP DATABASE $USERNAME";
service nginx reload;
service php5-fpm reload;
userdel -rf $USERNAME;

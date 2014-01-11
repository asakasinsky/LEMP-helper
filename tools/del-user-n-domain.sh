#!/bin/bash

echo "Enter MySQL root password:";
read ROOTPASS;

echo "Enter username to delete:";
read USERNAME;


/etc/init.d/nginx stop;
/etc/init.d/php5-fpm stop;

cd "/home/$USERNAME/workspace"

for directory in *
do
    if [ -d "$directory" ];then
        rm -f "/etc/nginx/sites-enabled/$directory.conf";
        rm -f "/etc/nginx/sites-available/$directory.conf";
        rm -f "/etc/php5/fpm/pool.d/$directory.conf";
        # find /var/log/nginx/ -type f -name "$USERNAME*" -exec rm '{}';
        # find /var/log/nginx/ -type f -name "$directory*" -exec rm '{}';
      fi
done

cd

mysql -uroot --password=$ROOTPASS -e "DROP USER '$USERNAME'@'localhost'";
mysql -uroot --password=$ROOTPASS -e "DROP DATABASE \`$USERNAME\`";

/etc/init.d/nginx start;
/etc/init.d/php5-fpm start;

userdel -rf $USERNAME;

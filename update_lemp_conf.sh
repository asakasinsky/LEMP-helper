#!/bin/bash

cp -R ./configs/nginx/nginx-bp /etc/nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
cp -R ./configs/nginx/nginx.conf /etc/nginx/nginx.conf

mv /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.old
cp ./configs/php/php.ini /etc/php5/fpm/php.ini

mv /etc/php5/cli/php.ini /etc/php5/cli/php.ini.old
cp ./configs/php/php.ini /etc/php5/cli/php.ini

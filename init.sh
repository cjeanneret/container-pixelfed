#!/bin/sh
cp -r storage.skel/* storage/
cp -r public/* public.ext/
chown -R www-data:www-data storage/
php artisan storage:link
php artisan migrate --force
php artisan update
exec php-fpm

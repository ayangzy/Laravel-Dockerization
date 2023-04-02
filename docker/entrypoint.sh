#!/bin/bash

if [ ! -f "vendor/autoload.php" ]; then
    composer install --no-progress --no-interaction
fi

if [ ! -f ".env" ]; then
    echo "Creating env file for env $APP_ENV"
    cp .env.example .env
    php artisan key:generate
else
    echo "env file exists."
fi

role=${CONTAINER_ROLE:-app}

if [ "$role" = "app" ]; then
    php artisan config:clear
    php artisan migrate --force --seed
    php artisan clear-compiled
    php artisan auth:clear-resets
    php artisan optimize:clear
    php artisan config:cache
    php artisan view:cache
    php artisan route:cache
    composer dump-autoload
    php artisan serve --port=$PORT --host=0.0.0.0 --env=.env
    exec docker-php-entrypoint "$@"
elif [ "$role" = "queue" ]; then
    echo "Running the queue ... "
    php /var/www/artisan queue:work --verbose --tries=3 --timeout=180

fi
FROM php:8.1-apache-slim

# Install mysqli extension
RUN docker-php-ext-install mysqli

# Copy app source to Apache root
COPY index.php /var/www/html/

# Set ownership (optional best practice)
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 for Apache
EXPOSE 80

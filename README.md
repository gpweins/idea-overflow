# Project Setup

This project uses Docker to manage its services and provides scripts to generate SSL certificates for local HTTPS development. Follow these steps after cloning the repository.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) must be installed on your machine.
- [Docker Compose](https://docs.docker.com/compose/install/) (usually comes with Docker Desktop).

## 1. Set Up Docker Environment

Make sure Docker is running on your system. The project uses Docker Compose to build and run the following services:

- **PHP-FPM**: Custom PHP-FPM container (built from `.docker/php/Dockerfile`).
- **Nginx**: Using the `nginx:alpine` image.
- **Mailpit**: For capturing outgoing emails.
- **Redis**: For caching, session and queue management.
- **Postgres**: For the database.

### Starting the Environment

From the root directory of your project:

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Start the Docker services:

   ```bash
   docker-compose up -d
   ```

This command will build the custom PHP image and start all the services in the background.

## 2. Setting Up Dependencies and Running Migrations

Follow these steps to prepare your application:

1. Open a shell into the PHP container (php-fpm as specified in docker-compose.yml):

   ```bash
   docker-compose exec php-fpm sh
   ```

2. Install PHP dependencies via Composer:

   ```bash
   composer install
   ```

3. Generate the application key:

   ```bash
   php artisan key:generate
   ```

4. Run the Laravel migrations:

   ```bash
   php artisan migrate
   ```

5. Install Node dependencies and compile assets:

   ```bash
   npm install
   npm run dev
   ```

## 3. SSL Certificate Generation

The project includes a script to generate SSL certificates for local HTTPS development. To generate the certificates, follow these steps:

1. Navigate to the project root directory.

2. Run the certificate generation script located in `.docker/scripts` by executing:

   ```bash
   ./docker/scripts/generate_certificate.sh ideaoverflow.local
   ```

3. The script will generate two folders under `.docker/nginx/certificates`:
   - `ca`: Contains the Certificate Authority files.
   - `client`: Contains the files that should be included in the NGINX configuration.

4. Add the CA `.pem` file from the `ca` folder to your system's Certificate Manager.

## 4. Additional Notes

- Update your .env file as necessary to match your local setup (especially the database and caching configurations).
- Logs for Nginx are stored in ./storage/logs/nginx, and you can view them to debug any issues with SSL or routing.
- Ensure you generate the SSL certificates and add the CA certificate from the `ca` folder to your system's Certificate Manager.
- Add "127.0.0.1 ideaoverflow.local" to your hosts file.

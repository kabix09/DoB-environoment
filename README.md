# Dance Of Blades Environoment

A fully equipped environment for [DanceOfBlades](https://github.com/kabix09/DanceOfBlades) page which supports each project feature

## Table of Contents
* [Genera Info](#general-info)
* [Technologies Used](#technologies)
* [Launch](#launch)
* [Features](#features)

## General info

The purpose of writing this project was to get fully functional environoment which will allow to freely test the functionality of the website using each implemented element and familiarize myself with the used components.


## Technologies

The services used in the project:
* [Nginx](https://hub.docker.com/_/nginx)
* [PHP fpm](https://hub.docker.com/_/php)
* [Rabbit MQ](https://hub.docker.com/_/rabbitmq)
* [Mercure](https://hub.docker.com/r/dunglas/mercure)
* [Redis](https://hub.docker.com/_/redis)
* [Memcached](https://hub.docker.com/_/memcached)
* [MsSQL server](https://www.microsoft.com/pl-pl/sql-server/sql-server-2019)
* [Mailhog](https://hub.docker.com/r/mailhog/mailhog)
* [Samba](https://hub.docker.com/r/dperson/samba)

## Launch

### Prerequisites
----

I assume you have installed Docker and it is running.

See the [Docker website](http://www.docker.io/gettingstarted/#h_installation) for installation instructions.


### Build
----

Steps to build a Docker image:

1. Clone this repo

        git clone https://github.com/kabix09/docker-app

2. Go to `src` directory and clone webpage repo

        git clone https://github.com/kabix09/DanceOfBlades.git

3. Check website project branch to '`docker-env`'

        git checkout docker-env

4. Next move '`dob.env.local`' to '`src\DanceOfBlades\`' folder and rename file to '`env.local`'

5. Back to project root folder and build the image

        docker build -t="my-app" docker-app

    This will take a few minutes.

6. Run the image's default command, which should start everything up.

        docker run my-app

7. Once everything has started up, you should be able to access the webpage via [http://localhost:8080/](http://localhost:8080/) on your host machine.

        open http://localhost:8000/

### Usage
----

If you want to see *mail list* go to:

    open http://localhost:8001/

If you want to see *rabbit tasks list* go to:

    open http://localhost:15672/

You can also have a look into database content using:

    docker exec -it mssql2019-container bash
    $ /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "saPassword12" -d DanceOfBlades

## Features
* web page hosting
* e-mail service
* database service
* real-time communications service
* asynchronous message broker
* in-memory data store service
* external file storage service

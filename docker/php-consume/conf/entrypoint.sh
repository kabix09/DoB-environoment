#!/bin/bash
cd ./DanceOfBlades/
php bin/console messenger:setup-transports
php bin/console messenger:consume async_email_register_transport -vv
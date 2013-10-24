#!/bin/bash

install_composer(){
	curl -sS https://getcomposer.org/installer | php
	sudo mv composer.phar /usr/local/bin/composer
}

# Install Composer (PHP dependency manager)
install_composer

# Launch composer in current dir (search for composer.json) and install required
# libraries
composer install

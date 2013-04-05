name "vagrant_magento"
version "0.2.0"
description "A Chef cookbook for deployment of Magento with Vagrant."

supports "ubuntu"

depends "apt"
depends "build-essential"
depends "git"
depends "mysql"
depends "database"
depends "php"
depends "apache2"

recipe "vagrant_magento", "Main configuration for Magento"
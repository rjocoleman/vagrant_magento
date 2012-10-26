version "0.1.0"
description "A Chef cookbook for deployment of Magento with Vagrant."

supports "ubuntu"

depends "apache2"
depends "mysql"
depends "database"
depends "git"
depends "php"
depends "apt"
#default attributes. Not all of these are being used currently.

default['vagrant_magento']['phpinfo_enabled'] = false #add an alias for a /phpinfo.php file
default['vagrant_magento']['mage_check_enabled'] = false #add an alias for a /magento-check.php file

default['vagrant_magento']['sample_data']['install'] = false #install Magento sample data
default['vagrant_magento']['sample_data']['install_dir'] = "/vagrant/"
default['vagrant_magento']['sample_data']['source'] = "http://www.magentocommerce.com/downloads/assets/1.6.1.0/magento-sample-data-1.6.1.0.tar.gz"
default['vagrant_magento']['sample_data']['checksum'] = "201e38eef66edbd9528eee7134934adbf08e81cffa081f9063630a48f812d723"

default['vagrant_magento']['config']['generate'] = true #generate a standard local.xml
default['vagrant_magento']['config']['database'] = "vagrant_magento"
default['vagrant_magento']['config']['db1_user'] = "root"
default['vagrant_magento']['config']['db1_pass'] = "root"
default['vagrant_magento']['config']['db1_host'] = "localhost"
default['vagrant_magento']['config']['db_prefix'] = ""
default['vagrant_magento']['config']['mage_key'] = "1"

default['vagrant_magento']['admin']['create'] = false #create an admin user
default['vagrant_magento']['admin']['username'] = "mage-admin"
default['vagrant_magento']['admin']['password'] = "123123"
default['vagrant_magento']['admin']['salt'] = "GF"
default['vagrant_magento']['admin']['email'] = "test@example.com"
default['vagrant_magento']['admin']['firstname'] = "Admin"
default['vagrant_magento']['admin']['lastname'] = "User"

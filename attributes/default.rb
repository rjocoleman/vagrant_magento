#default attributes. Not all of these are being used currently.

default['vagrant_magento']['phpinfo_enabled'] = true #add an alias for a /phpinfo.php file
default['vagrant_magento']['mage_check_enabled'] = true #add an alias for a /magento-check.php file

default['vagrant_magento']['sample_data']['install'] = true #install Magento sample data
default['vagrant_magento']['sample_data']['install_dir'] = "/vagrant/"
default['vagrant_magento']['sample_data']['source'] = "http://www.magentocommerce.com/downloads/assets/1.6.1.0/magento-sample-data-1.6.1.0.tar.gz"
default['vagrant_magento']['sample_data']['checksum'] = "201e38eef66edbd9528eee7134934adbf08e81cffa081f9063630a48f812d723"
default['vagrant_magento']['sample_data']['database'] = "vagrant_magento"

default['vagrant_magento']['config']['generate'] = true #generate a standard local.xml
default['vagrant_magento']['config']['database'] = "vagrant_magento"
default['vagrant_magento']['config']['db1_user'] = "root"
#default['vagrant_magento']['config']['db1_pass'] = node['mysql']['server_root_password']
default['vagrant_magento']['config']['db1_host'] = "localhost"
default['vagrant_magento']['config']['db_prefix'] = ""
default['vagrant_magento']['config']['mage_key'] = "1"
default['vagrant_magento']['config']['base_url'] = "http://localhost/"

default['vagrant_magento']['wiz']['enable'] = true #enable Wiz by default
default['vagrant_magento']['wiz']['create_admin'] = true #create an admin user
default['vagrant_magento']['wiz']['admin_user'] = "mage-admin"
default['vagrant_magento']['wiz']['admin_pass'] = "123123"
default['vagrant_magento']['wiz']['admin_email'] = "test@example.com"
default['vagrant_magento']['wiz']['admin_firstname'] = "Admin"
default['vagrant_magento']['wiz']['admin_lastname'] = "User"

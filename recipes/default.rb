#what recipes do we need?
include_recipe "apt"
include_recipe "git"
include_recipe "mysql::server"
include_recipe "mysql::ruby"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "php::module_gd"
include_recipe "php::module_curl"
include_recipe "apache2"
include_recipe "apache2::mod_php5"

#add mod_rewrite
apache_module "rewrite" do
  enable true
end

#add php extension mcrypt
package "php5-mcrypt" do
  action :install
end


#disable default virtualhost.
apache_site "default" do
  enable false
  notifies :restart, "service[apache2]"
end

#create a virtualhost that's mapped to our shared folder and hostname.
web_app "vagrant_magento" do
  server_name node['hostname']
  server_aliases node['fqdn'], node['host_name']
  docroot "/vagrant"
  notifies :restart, "service[apache2]"
end

#create a phpinfo file for use in our Apache vhost
template "/var/www/phpinfo.php" do
  mode "0644"
  source "phpinfo.erb"
  not_if { node['vagrant_magento']['phpinfo_enabled'] == false }
  notifies :restart, "service[apache2]"
end

#we need unzip for magento-check (at least)
package "unzip" do
  action :install
end

#get magento check system requirements script
remote_file "#{Chef::Config[:file_cache_path]}/magento-check.zip" do
  source "http://www.magentocommerce.com/_media/magento-check.zip"
  backup false
  mode "0644"
  checksum "bb61351788759da0c852ec50d703634f49c0076978ddf0b2d3dc2bc3f012666a"
  not_if { node['vagrant_magento']['mage_check_enabled'] == false }
end

#extract magento check
execute "extract magento check" do
  cwd Chef::Config[:file_cache_path]
  command "unzip #{Chef::Config[:file_cache_path]}/magento-check.zip -d /var/www"
  not_if { node['vagrant_magento']['mage_check_enabled'] == false }
  action :run
end

#create a mysql database
mysql_database node['vagrant_magento']['sample_data']['database'] do
  connection ({:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']})
  action :create
end

#get the sample data
remote_file "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz" do
  source node['vagrant_magento']['sample_data']['source']
  backup false
  mode "0644"
  checksum node['vagrant_magento']['sample_data']['checksum']
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
end

#extract sample data
execute "extract sample data" do
  cwd Chef::Config[:file_cache_path]
  command "tar zxf #{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :run
end

#prefix sample data
=begin
execute "prefix sample data" do
  db_prefix = node['vagrant_magento']['config']['db1_prefix']
  command "sed -ie \"s/TABLES \`/TABLES \`#{db_prefix}/gI;s/TABLE \`/TABLE \`#{db_prefix}/gI;s/EXISTS \`/EXISTS \`#{db_prefix}/gI;s/INTO \`/INTO \`#{db_prefix}/gI;s/REFERENCES \`/REFERENCES \`#{db_prefix}/gI\" #{Chef::Config[:file_cache_path]}/magento-sample-data-1.6.1.0/magento_sample_data_for_1.6.1.0.sql"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :run 
end
=end

#import sample data
execute "import sample data" do
  command "mysql -u root -p#{node['mysql']['server_root_password']} #{node['vagrant_magento']['sample_data']['database']} < #{Chef::Config[:file_cache_path]}/magento-sample-data-1.6.1.0/magento_sample_data_for_1.6.1.0.sql"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :run
end

#copy sample data
execute "copy sample data" do
  command "cp -r #{Chef::Config[:file_cache_path]}/magento-sample-data-1.6.1.0/media #{node['vagrant_magento']['sample_data']['install_dir']}"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :run
end

#set environment variables
ENV['DB1_NAME'] = node['vagrant_magento']['config']['database']
ENV['DB1_USER'] = node['vagrant_magento']['config']['db1_user']
ENV['DB1_PASS'] = node['vagrant_magento']['config']['db1_pass']
ENV['DB1_HOST'] = node['vagrant_magento']['config']['db1_host']
ENV['DB_PREFIX'] = node['vagrant_magento']['config']['db_prefix']
ENV['MAGE_KEY'] = node['vagrant_magento']['config']['mage_key']
ENV['BASE_URL'] = node['vagrant_magento']['config']['base_url']

#generate local.xml
execute "generate local.xml" do
  command "php /vagrant/deploy_support/local_xml_generator.php"
  not_if { node['vagrant_magento']['config']['generate'] == false }
  action :run 
end

#get wiz
git "/usr/local/Wiz" do
  repository "https://github.com/nvahalik/Wiz.git"
  action :checkout
  revision "master"
  not_if { node['vagrant_magento']['wiz']['enable'] == false }
end

#install Wiz
execute "install wiz" do
  command "ln -s /usr/local/Wiz/wiz /usr/local/bin/wiz"
  not_if { node['vagrant_magento']['wiz']['enable'] == false }
  not_if { File.exists?("/usr/local/bin/wiz") }
  not_if { File.exists?("/etc/bash_completion.d/wiz.bash_completion.sh") }
  action :run
end

#create admin (viz Wiz)
execute "wiz: create admin" do
  cwd "/vagrant"
  #wiz admin-createadmin <username> <firstname> <lastname> <email> <password>
  command "wiz admin-createadmin #{node['vagrant_magento']['wiz']['admin_user']} #{node['vagrant_magento']['wiz']['admin_firstname']} #{node['vagrant_magento']['wiz']['admin_lastname']}  #{node['vagrant_magento']['wiz']['admin_email']} #{node['vagrant_magento']['wiz']['admin_pass']}"
  not_if { node['vagrant_magento']['wiz']['create_admin'] == false }
  action :run
end
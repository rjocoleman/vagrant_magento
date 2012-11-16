include_recipe "apt"
include_recipe "build-essential"
include_recipe "git"
include_recipe "mysql::server"
include_recipe "mysql::ruby"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "php::module_gd"
include_recipe "php::module_curl"
include_recipe "apache2"
include_recipe "apache2::mod_php5"

chef_gem "versionomy"

class Chef::Resource
  include MageHelper
end

#we need unzip for magento-check
package "unzip" do
  action :install
end

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
web_app "magento_dev" do
  server_name node['hostname']
  server_aliases node['fqdn'], node['host_name']
  docroot node['vagrant_magento']['mage']['dir']
  notifies :restart, "service[apache2]", :immediately
end

#create a phpinfo file for use in our Apache vhost
template "/var/www/phpinfo.php" do
  mode "0644"
  source "phpinfo.php.erb"
  not_if { node['vagrant_magento']['phpinfo_enabled'] == false }
  notifies :restart, "service[apache2]", :immediately
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
execute "magento-check-extract" do
  cwd Chef::Config[:file_cache_path]
  command "unzip -o #{Chef::Config[:file_cache_path]}/magento-check.zip -d /var/www"
  not_if { node['vagrant_magento']['mage_check_enabled'] == false }
  action :run
end

#create a mysql database
mysql_database node['vagrant_magento']['config']['db_name'] do
  connection ({:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']})
  action :create
end

#get the sample data
remote_file "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz" do
  #source get_sample_data_url
  source "http://www.magentocommerce.com/downloads/assets/#{get_sample_data_ver}/magento-sample-data-#{get_sample_data_ver}.tar.gz"  
  backup false
  mode "0644"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  only_if { `which php` != false }
  action :create

  notifies :run, "execute[sample-data-extract]", :immediately
  notifies :create, "ruby_block[sample-data-prefix]", :immediately
  notifies :run, "execute[sample-data-import]", :immediately
  notifies :run, "execute[sample-data-copy]", :immediately
end

#extract sample data
execute "sample-data-extract" do
  cwd Chef::Config[:file_cache_path]
  command "tar zxf #{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :nothing
end

#prefix sample data
ruby_block "sample-data-prefix" do
  block do
    db_prefix = node['vagrant_magento']['config']['db_prefix']
    sample_data = "#{Chef::Config[:file_cache_path]}/magento-sample-data-#{get_sample_data_ver}/magento_sample_data_for_#{get_sample_data_ver}.sql"

    if File.file?(sample_data) then
      read_data = File.open(sample_data, 'rb').read

      replacements = [ 
        ["/TABLES `/i", "TABLES `#{db_prefix}"], 
        ["/TABLE `/i", "TABLE `#{db_prefix}"], 
        ["/EXISTS `/i", "EXISTS `#{db_prefix}"],
        ["/INTO `/i", "INTO `#{db_prefix}"],
        ["/REFERENCES `/i", "REFERENCES `#{db_prefix}"] 
      ]
      replacements.each do |replacement| 
        read_data.gsub! replacement[0], replacement[1]
      end

      File.open(sample_data, 'w') { |f|
        f.puts read_data
      }
    end
  end
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :nothing 
end

#import sample data
execute "sample-data-import" do
  command "mysql -u root -p#{node['mysql']['server_root_password']} #{node['vagrant_magento']['config']['db_name']} < #{Chef::Config[:file_cache_path]}/magento-sample-data-#{get_sample_data_ver}/magento_sample_data_for_#{get_sample_data_ver}.sql"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :nothing
end

#copy sample data
execute "sample-data-copy" do
  command "cp -r #{Chef::Config[:file_cache_path]}/magento-sample-data-#{get_sample_data_ver}/media #{node['vagrant_magento']['mage']['dir']}"
  not_if { node['vagrant_magento']['sample_data']['install'] == false }
  action :nothing
end

#install magento
execute "magento-install" do
  args = [
    "--license_agreement_accepted yes",
    "--locale #{node['vagrant_magento']['config']['locale']}",
    "--timezone #{node['vagrant_magento']['config']['timezone']}",
    "--default_currency #{node['vagrant_magento']['config']['default_currency']}",
    "--db_host #{node['vagrant_magento']['config']['db_host']}",
    "--db_model #{node['vagrant_magento']['config']['db_model']}",
    "--db_name #{node['vagrant_magento']['config']['db_name']}",
    "--db_user #{node['vagrant_magento']['config']['db_user']}",
    "--db_pass #{node['vagrant_magento']['config']['db_pass']}",
    "--url #{node['vagrant_magento']['config']['url']}",
    "--admin_lastname #{node['vagrant_magento']['config']['admin_lastname']}",
    "--admin_firstname #{node['vagrant_magento']['config']['admin_firstname']}",
    "--admin_email #{node['vagrant_magento']['config']['admin_email']}",
    "--admin_username #{node['vagrant_magento']['config']['admin_username']}",
    "--admin_password #{node['vagrant_magento']['config']['admin_password']}",
  ]
  
  args << "--db_prefix #{node['vagrant_magento']['config']['db_prefix']}" unless node['vagrant_magento']['config']['db_prefix'].empty?
  args << "--session_save #{node['vagrant_magento']['config']['session_save']}" unless node['vagrant_magento']['config']['session_save'].empty?
  args << "--admin_frontname #{node['vagrant_magento']['config']['admin_frontname']}" unless node['vagrant_magento']['config']['admin_frontname'].empty?
  args << "--skip_url_validation #{node['vagrant_magento']['config']['skip_url_validation']}" unless node['vagrant_magento']['config']['skip_url_validation'].empty?
  args << "--use_rewrites #{node['vagrant_magento']['config']['use_rewrites']}" unless node['vagrant_magento']['config']['use_rewrites'].empty?
  args << "--use_secure #{node['vagrant_magento']['config']['use_secure']}" unless node['vagrant_magento']['config']['use_secure'].empty?
  args << "--secure_base_url #{node['vagrant_magento']['config']['secure_base_url']}" unless node['vagrant_magento']['config']['secure_base_url'].empty?
  args << "--use_secure_admin #{node['vagrant_magento']['config']['use_secure_admin']}" unless node['vagrant_magento']['config']['use_secure_admin'].empty?
  args << "--enable_charts #{node['vagrant_magento']['config']['enable_charts']}" unless node['vagrant_magento']['config']['enable_charts'].empty?
  args << "--encryption_key #{node['vagrant_magento']['config']['encryption_key']}" unless node['vagrant_magento']['config']['encryption_key'].empty?

  cwd node['vagrant_magento']['mage']['dir']
  command "php -f install.php -- #{args.join(' ')}"
  
  not_if { File.exists?("#{node['vagrant_magento']['mage']['dir']}/app/etc/local.xml") }
  not_if { node['vagrant_magento']['config']['install'] == false }
  action :run
end

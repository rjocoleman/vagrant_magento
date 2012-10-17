web_app "vagrant_apache2" do
  server_name node['hostname']
  server_aliases [node['fqdn'], "my-site.example.com"]
  docroot "/vagrant"
end

apache_site "default" do
  enable false
end
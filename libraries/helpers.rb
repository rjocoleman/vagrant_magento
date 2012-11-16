module MageHelper
  def get_mage_ver(dir=node['vagrant_magento']['mage']['dir'])
    result = mage_ver(dir)
    Chef::Log.fatal("Magento version could not be detected") unless !result.empty?
    result
  end

  def get_sample_data_ver(dir=node['vagrant_magento']['mage']['dir'])
#    installed_ver = mage_ver(dir)
#    if installed_ver >= '1.6.1.0' then
#      sample_data_version = Versionomy.create('1.6.1.0')
#    elsif installed_ver < '1.6.1.0' then
#      sample_data_version = Versionomy.create('1.2.0')
#    end
    sample_data_version = "1.6.1.0"
    Chef::Log.info("Using Sample Data v#{sample_data_version}") unless sample_data_version.empty?
    sample_data_version
  end

  def get_sample_data_url
    sample_data_ver = get_sample_data_ver
    puts "http://www.magentocommerce.com/downloads/assets/#{sample_data_ver}/magento-sample-data-#{sample_data_ver}.tar.gz"      
  end

  private
  def mage_ver(dir)
    #we want to capture a magneto version number in the format: 1.7.0.2-rc1
    #opt 1
    #mage_ver = `php -r "include '#{dir}app/Mage.php'; echo Mage::getVersion();"
    #
    #opt 2
    #  public static function getVersionInfo()
    #  {
    #      return array(
    #          'major'     => '1',
    #          'minor'     => '7',
    #          'revision'  => '0',
    #          'patch'     => '2',
    #          'stability' => '',
    #          'number'    => '',
    #      );
    #  }
    # return trim("{$i['major']}.{$i['minor']}.{$i['revision']}" . ($i['patch'] != '' ? ".{$i['patch']}" : "") . "-{$i['stability']}{$i['number']}", '.-');
    #
    #parse app/Mage.php and pull out then format our version

    mage_file = "#{dir}app/Mage.php"

    if File.file?(mage_file) then
      read_data = File.open(mage_file, 'rb').read
      h = Hash[read_data.scan /'(major|minor|revision|patch|stability|number)'.+=>.+'(\d{1}|[a-zA-Z]+|)',/]
      #puts "#{h['major']}.#{h['minor']}.#{h['revision']}.#{h['patch']}-#{h['stability']}#{h['number']}"
      puts Versionomy.create(:major => h['major'], :minor => h['minor'], :tiny => h['revision'], :tiny2 => h['patch'] )
    end
  end

end
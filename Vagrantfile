Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision :shell, path: "provision.sh"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.synced_folder "/home/drone-xb81/code/python/django/workout", "/home/vagrant/www/website"
end

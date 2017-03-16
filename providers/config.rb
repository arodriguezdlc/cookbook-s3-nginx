# Cookbook Name:: example
#
# Provider:: config
#

action :install do

  package "epel-release" do
    action :install
  end

  package "nginx" do
    action :install
  end

  bash 'setenforce' do
    action :nothing
    code "setenforce permissive"
  end

  template "/etc/selinux/config" do
    source    "selinux-config.erb"
    owner     "root"
    group     "root"
    cookbook  "s3nginx"
    mode      0644
    retries   2
    notifies :run, 'bash[setenforce]', :immediate
  end

end

action :configure do

  chef_data_bag 's3' do
    name "s3"
    action :create
  end

  directory "/etc/nginx/ssl" do
    owner   "nginx"
    group   "nginx"
    mode    "0755"
    action  :create
  end

  bash "generate-cert" do
    cwd "/etc/nginx/ssl"
    code <<-EOH
      openssl req -newkey rsa:2048 -nodes -keyout s3.key -x509 -days 365 -out s3.crt -batch
    EOH
    not_if { ::File.exist?("/etc/nginx/ssl/s3.key") }
  end

  template "/etc/nginx/conf.d/s3.conf" do
    source    "s3.conf.erb"
    owner     "root"
    group     "root"
    cookbook  "s3nginx"
    mode      0644
    retries   2
    variables( lazy {
      s3_nodes = search(:node, 'role:riak')
      { :servers => s3_nodes }
    } )
    notifies :reload, 'service[nginx]', :immediate
  end

  service "nginx" do
    supports :status => true, :start => true, :restart => true, :reload => true
    action [:enable, :start]
  end

end

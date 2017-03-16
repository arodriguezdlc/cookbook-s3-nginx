#
# Cookbook s3 nginx:: example
# Recipe:: default
#

s3nginx_config "config" do
  action [:install, :configure]
end

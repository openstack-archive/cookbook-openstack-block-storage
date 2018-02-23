source 'https://supermarket.chef.io'

%w(image identity common).each do |cookbook|
  if Dir.exist?("../cookbook-openstack-#{cookbook}")
    cookbook "openstack-#{cookbook}", path: "../cookbook-openstack-#{cookbook}"
  else
    cookbook "openstack-#{cookbook}", github: "openstack/cookbook-openstack-#{cookbook}",
                                      branch: 'stable/pike'
  end
end

cookbook 'openstackclient',
  github: 'cloudbau/cookbook-openstackclient',
  branch: 'stable/pike'

metadata

class profile_puppetca (
  $certname = 'puppet',
  $foreman  = $::fqdn,
  $puppetdb = $::fqdn,
) {
  class { '::puppet':
    dns_alt_names                => ['puppet',$::fqdn,$certname],
    server                       => true,
    server_external_nodes        => '',
    server_foreman_url           => "http://${foreman}",
    server_puppetdb_host         => $puppetdb,
    server_reports               => 'foreman',
    server_storeconfigs_backend  => 'puppetdb',
  } ->
  class { '::foreman_proxy':
    foreman_base_url => "http://${foreman}",
    trusted_hosts    => [$::fqdn, $foreman],
    bmc              => false,
    dhcp             => false,
    dns              => false,
    puppetca         => true,
    puppetrun        => true,
    tftp             => false,
  } ->
  cron { 'foreman-push-facts':
    command => "/usr/bin/ruby /etc/puppet/node.rb --push-facts &> /dev/null",
    user    => puppet,
    minute  => '*/2'
  }
  @@haproxy::balancermember { "puppetca-${::hostname}":
    listening_service => 'puppetca',
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress_eth1,
    ports             => '8140',
    options           => 'check',
  }
}
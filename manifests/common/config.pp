#
class mcollective::common::config {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  file { $mcollective::site_libdir:
    ensure       => directory,
    owner        => 'root',
    group        => '0',
    recurse      => true,
    purge        => true,
    force        => true,
    source       => [],
    sourceselect => 'all',
  }

  if $mcollective::server {
    # if we have a server install, reload when the plugins change
    File[$mcollective::site_libdir] ~> Class['mcollective::server::service']
  }

  datacat_collector { 'mcollective::site_libdir':
    before          => File[$mcollective::site_libdir],
    target_resource => File[$mcollective::site_libdir],
    target_field    => 'source',
    source_key      => 'source_path',
  }

  datacat_fragment { 'mcollective::site_libdir':
    target => 'mcollective::site_libdir',
    data   => {
      source_path => [ 'puppet:///modules/mcollective/site_libdir' ],
    }
  }

  mcollective::common::setting { 'libdir':
    value => "${mcollective::site_libdir}:${mcollective::core_libdir}",
  }

  mcollective::common::setting { 'connector':
    value => $mcollective::connector,
  }

  mcollective::common::setting { 'securityprovider':
    value => $mcollective::securityprovider,
  }

  mcollective::common::setting { 'collectives':
    value => join(flatten([$mcollective::collectives]), ','),
  }

  mcollective::common::setting { 'main_collective':
    value => $mcollective::main_collective,
  }

  if $mcollective::middleware_ssl or $mcollective::securityprovider == 'ssl' {
    file { "${mcollective::confdir}/ca.pem":
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      source => $mcollective::ssl_ca_cert,
    }

    file { "${mcollective::confdir}/server_public.pem":
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      source => $mcollective::ssl_server_public,
    }

    file { "${mcollective::confdir}/server_private.pem":
      owner  => 'root',
      group  => '0',
      mode   => '0400',
      source => $mcollective::ssl_server_private,
    }
  }

  $configkeys = keys($mcollective::pluginconf)
  mcollective::common::config::pluginconf::plugin_iteration{ $configkeys: }

  mcollective::soft_include { [
    "::mcollective::common::config::connector::${mcollective::connector}",
    "::mcollective::common::config::securityprovider::${mcollective::securityprovider}",
  ]:
    start => Anchor['mcollective::common::config::begin'],
    end   => Anchor['mcollective::common::config::end'],
  }

  anchor { 'mcollective::common::config::begin': }
  anchor { 'mcollective::common::config::end': }
}

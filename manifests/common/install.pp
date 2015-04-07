# private class
class mcollective::common::install {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $mcollective::manage_packages {
    package { $mcollective::common_package:
      ensure => $mcollective::version,
    }

    if $::osfamily == 'Debian' {
      # XXX the dependencies my test ubuntu 12.04 system seem to not correctly
      # state ruby-stomp as a dependency of mcollective, so hand specify
      package { $mcollective::ruby_stomp_package:
        ensure => $mcollective::ruby_stomp_ensure,
        before => Package[$mcollective::server_package],
      }
    }
  }
}

# Author::    Liam Bennett (mailto:liamjbennett@gmail.com)
# Copyright:: Copyright (c) 2014 Liam Bennett
# License::   Apache-2.0

# == Define: windows_power::schemes::scheme
#
# This definition configures a specific power scheme
#
# === Requirements/Dependencies
#
# Currently reequires the puppetlabs/stdlib module on the Puppet Forge in
# order to validate much of the the provided configuration.
#
# === Parameters
#
# [*scheme_name*]
# The name of the scheme to configure
#
# [*scheme_guid*]
# The windows guid used to uniquely identify the power scheme
#
# [*template_scheme*]
# The windows guid of an existing scheme to be used as a template for the current scheme
#
# [*activation*]
# Set the current scheme as the active scheme
#
# [*ensure*]
# Configure if the scheme is present or absent
#
# === Examples
#
#    windows_power::schemes::scheme { 'test scheme':
#       scheme_name     => 'test',
#       scheme_guid     => '381b4222-f694-41f0-9685-ff5bbxx65ddx',
#       template_scheme => '381b4222-f694-41f0-9685-ff5bb260df2e',
#       activation      => 'active',
#       ensure          => 'present',
#    }
#
define windows_power::schemes::scheme(
  $scheme_name,
  $scheme_guid,
  $template_scheme = '',
  $activation      = '',
  $ensure          = 'present',
) {

  include ::windows_power::params

  validate_string($scheme_name)
  validate_re($scheme_guid,'^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}$','The scheme guid provided is not formatted correctly')
  validate_re($ensure,'^(present|absent)$','The ensure argument is not set to present or absent')

  case $::operatingsystemversion {
    'Windows Vista','Windows 7','Windows 8','Windows Server 2008','Windows Server 2008 R2','Windows Server 2012': {
      if $ensure == 'present' {
        validate_string($template_scheme)
        validate_re($activation,'^(active|inactive)$','The activation argument is not set to active or inactive')
      }
    }
    default: {}
  }

  $template_guid = $windows_power::params::template_schemes[$template_scheme]
  $scheme_check = "${windows_power::params::nasty_ps} \$items.contains(\"${scheme_name}\")"

  if $ensure == 'present' {
#    case $::operatingsystem {
#      windows: {
        notice ("Made it into case statement with operatingsystem: ${operatingsystem}")
#        if $facts['operatingsystemrelease'] == 10 {
          notice ("Made it into if statement with facts::operatingsystemrelease: ${operatingsystemrelease}")
          exec { "create power scheme ${scheme_name}":
            command   => "& ${windows_power::params::powercfg} /DUPLICATESCHEME ${template_scheme} ${scheme_guid}",
            provider  => powershell,
            logoutput => true,
            unless    => "& ${windows_power::params::powercfg} /q ${scheme_guid}",
          }
          -> exec { "rename scheme to ${scheme_name}":
            command   => "& ${windows_power::params::powercfg} /CHANGENAME ${scheme_guid} ${scheme_name}",
            provider  => powershell,
            logoutput => true,
            onlyif    => $scheme_check,
          }
#        }
#        else {
#          notice ("Version ${operatingsystemrelease} of ${operatingsystemrelease} not supported")
#        }
#      }
#      default: {
#        notice ("${operatingsystem} Operating system not supported by this module")
#      }
#    }
  }
  elsif $ensure == 'absent' {
    exec { "delete power scheme ${scheme_name}":
      command   => "& ${windows_power::params::powercfg} /DELETE ${scheme_guid}",
      provider  => powershell,
      logoutput => true,
      onlyif    => $scheme_check,
    }
  }

  if $activation == 'active' {
    exec { "set ${scheme_name} scheme as active":
      command   => "& ${windows_power::params::powercfg} /SETACTIVE ${scheme_guid}",
      provider  => powershell,
      logoutput => true,
      onlyif    => $scheme_check,
    }
  }
}

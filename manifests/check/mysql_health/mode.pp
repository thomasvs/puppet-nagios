# Define:
#
# Only meant to be called from check::mysql_health, and looking up
# many variables directly there.
#
define nagios::check::mysql_health::mode () {

  # We need the mode name with underscores
  $mode_u = regsubst($title,'-','_','G')

  # Get the variables we need
  $check_title    = $::nagios::client::host_name
  $args           = $::nagios::check::mysql_health::args
  $modes_enabled  = $::nagios::check::mysql_health::modes_enabled
  $modes_disabled = $::nagios::check::mysql_health::modes_disabled
  $ensure         = $::nagios::check::mysql_health::ensure

  # Get the args passed to the main class for our mode
  $args_mode = getvar("nagios::check::mysql_health::args_${mode_u}")

  # allow hiera_array to work if _enabled/_disabled is specified in hieradata
  $modes_enabled_h = hiera_array('nagios::check::mysql_health::modes_enabled',
    undef)
  $modes_enabled_r = $modes_enabled_h ? {
    undef   => $modes_enabled,
    default => $modes_enabled_h,
  }

  $modes_disabled_h = hiera_array('nagios::check::mysql_health::modes_disabled',
    undef)
  $modes_disabled_r = $modes_disabled_h ? {
    undef   => $modes_disabled,
    default => $modes_disabled_h,
  }

  if ( ( $modes_enabled_r == [] and $modes_disabled_r == [] ) or
    ( $modes_enabled_r != [] and $mode_u in $modes_enabled_r ) or
    ( $modes_disabled_r != [] and ! ( $mode_u in $modes_disabled_r ) ) )
  {
    nagios::client::nrpe_file { "check_mysql_health_${mode_u}":
      ensure => $ensure,
      plugin => 'check_mysql_health',
      args   => "${args} --mode ${title} ${args_mode}",
    }
    nagios::service { "check_mysql_health_${mode_u}_${check_title}":
      ensure              => $ensure,
      check_command       => "check_nrpe_mysql_health_${mode_u}",
      service_description => "mysql_health_${mode_u}",
      servicegroups       => 'mysql_health',
    }
  } else {
    nagios::client::nrpe_file { "check_mysql_health_${mode_u}":
      ensure => 'absent',
    }
    nagios::service { "check_mysql_health_${mode_u}_${check_title}":
      ensure        => 'absent',
      check_command => 'foo',
    }
  }

}


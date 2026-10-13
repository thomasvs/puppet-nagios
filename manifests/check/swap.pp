class nagios::check::swap (
  $ensure                   = undef,
  $args                     = '',
  $check_title              = $::nagios::client::host_name,
  $servicegroups            = undef,
  $check_period             = $::nagios::client::service_check_period,
  $contact_groups           = $::nagios::client::service_contact_groups,
  $first_notification_delay = $::nagios::client::first_notification_delay,
  $max_check_attempts       = $::nagios::client::service_max_check_attempts,
  $notification_period      = $::nagios::client::service_notification_period,
  $use                      = $::nagios::client::service_use,
  $event_handler            = 'refresh-swap',
  $manage_event_handler     = true,
) inherits ::nagios::client {

  if $ensure != 'absent' {
    Package <| tag == 'nagios-plugins-swap' |>
  }

  # Include default arguments if no overrides in $args
  if $args !~ /-w/ { $arg_w = '-w 5% ' } else { $arg_w = '' }
  if $args !~ /-c/ { $arg_c = '-c 2% ' } else { $arg_c = '' }
  $fullargs = strip("${arg_w}${arg_c}${args}")

  nagios::client::nrpe_file { 'check_swap':
    ensure => $ensure,
    args   => $fullargs,
  }

  nagios::service { "check_swap_${check_title}":
    ensure                   => $ensure,
    check_command            => 'check_nrpe_swap',
    service_description      => 'swap',
    servicegroups            => $servicegroups,
    check_period             => $check_period,
    contact_groups           => $contact_groups,
    first_notification_delay => $first_notification_delay,
    notification_period      => $notification_period,
    max_check_attempts       => $max_check_attempts,
    use                      => $use,
    event_handler            => $event_handler,
  }

  if $manage_event_handler {
    file { '/usr/lib64/nagios/plugins/eventhandlers/refresh-swap':
      ensure => $ensure ? {
        'absent' => absent,
        default  => file,
      },
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/nagios/plugins/eventhandlers/refresh-swap',
    }

    file { '/etc/sudoers.d/nagios_refresh_swap':
      ensure  => $ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      content => template('nagios/plugins/eventhandlers/refresh_swap-sudoers.erb'),
    }
  }

}

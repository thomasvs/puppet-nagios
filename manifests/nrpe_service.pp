# = Define: nagios::nrpe_service
#
# This define defines a nagios service to check using nrpe,
# and deploys the necessary files to do so.
#
# This define should be used on the node that the actual plugin should run
# on through nrpe (called client-side below)
#
# == Parameters
#
# [* plugin *]
#   What nagios plugin to use.
#
# [* args *]
#   What arguments to use for the plugin
#
# [* sudo *]
#   Whether to use sudo for the client-side command
#
# [* sudo_user *]
#   If specified, what user to run sudo as
#
# == Examples
#
#  nagios::nrpe_service { "sentry_9100":
#    plugin => 'check_http',
#    args   => '-p 9100 localhost'
#  }
#
define nagios::nrpe_service (
  $plugin,
  $args = undef,
  $sudo = false,
  $sudo_user = undef,
  $ensure = present,
  $depends_on_nrpe = undef,
) {

  if (' ' in $name) {
    fail("name ${name} cannot contain spaces")
  }

  $host_name = $nagios::client::host_name

  # FIXME: without nagios::client, applying a manifest with only an
  #        nrpe_service fails because it doesn't find Service['nrpe']
  include nagios::client
  include nagios::params

  # client-side definition of nrpe command
  # goes in /etc/nagios/nrpe.d/nrpe-$name.cfg
  nagios::client::nrpe_file { "check_${name}":
    ensure    => $ensure,
    plugin    => $plugin,
    args      => $args,
    sudo      => $sudo,
    sudo_user => $sudo_user
  }

  # server-side definition of nagios command to invoke client-side nrpe command
  # goes in /etc/nagios/nagios_command.cfg
  nagios_command { "check_nrpe_${name}":
    ensure       => $ensure,
    # -u turns socket timeout into unknowns
    command_line => "${nagios::params::nrpe} -u -c check_${name}"
  }

  # server-side definition of nagios service to check
  # we use the nagios client host_name because the service name needs to
  # be unique over all clients on the server
  nagios::service { "${name}_nrpe_from_${host_name}":
    ensure        => $ensure,
    check_command => "check_nrpe_${name}",
    use           => 'nrpe-service',
    require       => Service['nrpe'],
  }

  if ($depends_on_nrpe) {
    nagios::servicedependency {
      "${name} dep on ${depends_on_nrpe} on ${host_name}":
      ensure                        => present,
      dependent_service_description => "${name}_nrpe_from_${host_name}",
      service_description           => "${depends_on_nrpe}_nrpe_from_${host_name}",
    }
  }

}

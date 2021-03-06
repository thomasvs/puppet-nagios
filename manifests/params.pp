# Class: nagios::params
#
# Parameters for and from the nagios module.
#
# Parameters :
#  none
#
# Sample Usage :
#  include nagios::params
#
class nagios::params (
  # Options for all nrpe-based checks
  $nrpe_options   = '-t 15',
) {
    $libdir = $::architecture ? {
        'x86_64' => 'lib64',
        'amd64'  => 'lib64',
        default  => 'lib',
    }
    # The easy bunch
    $nagios_service = 'nagios'
    $nagios_user    = 'nagios'
    # nrpe
    $nrpe_service   = 'nrpe'
    $nrpe_cfg_file  = '/etc/nagios/nrpe.cfg'

    # Full nrpe command to run, with default options
    $nrpe = "\$USER1\$/check_nrpe -H \$HOSTADDRESS\$ ${nrpe_options}"

    case $::operatingsystem {
        'Gentoo': {
            $nrpe_package       = [ 'net-analyzer/nrpe' ]
            $nrpe_package_alias = 'nrpe'
            $nrpe_user          = 'nagios'
            $nrpe_group         = 'nagios'
            $nrpe_pid_file      = '/run/nrpe.pid'
            $nrpe_cfg_dir       = '/etc/nagios/nrpe.d'
            $megaclibin         = '/opt/bin/MegaCli'
            $nagios_plugins_udp = 'nagios-plugins-udp'
        }
        'Fedora', 'RedHat', 'CentOS': {
            $nrpe_package       = [ 'nrpe', 'nagios-plugins' ]
            $nrpe_user          = 'nrpe'
            $nrpe_group         = 'nrpe'
            $nrpe_pid_file      = '/var/run/nrpe.pid'
            $nrpe_cfg_dir       = '/etc/nrpe.d'
            $megaclibin         = '/usr/sbin/MegaCli'
            if ( $::operatingsystem != 'Fedora' and versioncmp($::operatingsystemrelease, '7') >= 0 ) {
              # nagios flattens this inside the array we use it
              $nagios_plugins_udp = []
            } else {
              $nagios_plugins_udp = 'nagios-plugins-udp'
            }
        }
        default: {
            $nrpe_package       = [ 'nrpe', 'nagios-plugins' ]
            $nrpe_user          = 'nrpe'
            $nrpe_group         = 'nrpe'
            $nrpe_pid_file      = '/var/run/nrpe.pid'
            $nrpe_cfg_dir       = '/etc/nagios/nrpe.d'
            $megaclibin         = '/usr/sbin/MegaCli'
            $nagios_plugins_udp = 'nagios-plugins-udp'
        }
    }
    # Optional plugin packages, to be realized by tag where needed
    # Note: We use tag, because we can't use alias for 2 reasons :
    # * http://projects.puppetlabs.com/issues/4459
    # * The value of $alias can't be the same as $name
    $nagios_plugins_packages = [
        'nagios-plugins-disk',
        'nagios-plugins-file_age',
        'nagios-plugins-ide_smart',
        'nagios-plugins-ifstatus',
        'nagios-plugins-linux_raid',
        'nagios-plugins-load',
        'nagios-plugins-log',
        'nagios-plugins-mailq',
        'nagios-plugins-mysql',
        'nagios-plugins-ntp',
        'nagios-plugins-perl',
        'nagios-plugins-pgsql',
        'nagios-plugins-procs',
        'nagios-plugins-sensors',
        'nagios-plugins-swap',
        'nagios-plugins-users',
    ]
    case $operatingsystem {
        'Fedora', 'RedHat', 'CentOS': {
            $plugin_dir = "/usr/${libdir}/nagios/plugins"
            @package { $nagios_plugins_packages:
                ensure => installed,
                tag    => $name,
            }
        }
        'Gentoo': {
            $plugin_dir = "/usr/${libdir}/nagios/plugins"
            # No package splitting in Gentoo
            @package { 'net-analyzer/nagios-plugins':
                ensure => installed,
                tag    => $nagios_plugins_packages,
            }
        }
        default: {
            $plugin_dir = '/usr/libexec/nagios/plugins'
            @package { $nagios_plugins_packages:
                ensure => installed,
                tag    => $name,
            }
        }
    }

}


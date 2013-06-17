# Class: mcollective::server::middleware::rabbitmq
#
#	This class installs the RabbitMQ server package and all dependencies as well
#	as configures it for use with MCollective.
#
# Parameters:
#
#	[*version*]			- The version of the MCollective package(s) to be installed.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::server::middleware::rabbitmq (
	$package_name		= 'rabbitmq-server',
	$package_version	= '2.8.7-1',
	$delete_guest_user	= true,
	$mcollective_vhost	= '/mcollective',
	$mcollective_user	= 'mcollective',
	$mcollective_pass	= 'UNSET'
) {

	package { 'amqp' :
		ensure		=> installed,
		provider	=> 'gem'
	}

	class { 'rabbitmq::server' :
		version				=> $package_version,
		config_stomp		=> true,
		delete_guest_user	=> $delete_guest_user,
		require				=> Package['amqp']
	}

	rabbitmq_plugin {'rabbitmq_stomp':
		ensure		=> present,
		provider	=> 'rabbitmqplugins',
		require		=> Package[$package_name]
	}

	rabbitmq_vhost { $mcollective_vhost:
		ensure		=> present,
		provider	=> 'rabbitmqctl',
		require		=> Package[$package_name]
	}

	rabbitmq_user { $mcollective_user:
		admin		=> false,
		password	=> $mcollective_pass,
		provider	=> 'rabbitmqctl',
		require		=> Package[$package_name]
	}

	rabbitmq_user_permissions { "${mcollective_user}@${mcollective_vhost}":
		configure_permission	=> '.*',
		read_permission			=> '.*',
		write_permission		=> '.*',
		provider				=> 'rabbitmqctl',
		require					=> [ Rabbitmq_vhost[$mcollective_vhost], Rabbitmq_user[$mcollective_user] ]
	}

	rabbitmq_exchange { "moria_broadcast@${mcollective_vhost}" :
		exchange_type	=> topic,
		user			=> $mcollective_user,
		pass			=> $mcollective_pass,
		require			=> Rabbitmq_user_permissions["${mcollective_user}@${mcollective_vhost}"]
	}

	rabbitmq_exchange { "moria_directed@${mcollective_vhost}" :
		exchange_type	=> direct,
		user			=> $mcollective_user,
		pass			=> $mcollective_pass,
		require			=> Rabbitmq_user_permissions["${mcollective_user}@${mcollective_vhost}"]
	}

}
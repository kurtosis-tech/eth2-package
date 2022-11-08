load("github.com/kurtosis-tech/eth2-module/src/shared_utils/shared_utils.star", "new_port_spec", "path_join")
load("github.com/kurtosis-tech/eth2-module/src/module_io/parse_input.star", "get_client_log_level_or_default")
load("github.com/kurtosis-tech/eth2-module/src/el/el_client_context.star", "new_el_client_context")

module_io = import_types("github.com/kurtosis-tech/eth2-module/types.proto")


RPC_PORT_NUM       = 8545
WS_PORT_NUM        = 8546
DISCOVERY_PORT_NUM = 30303
ENGINE_RPC_PORT_NUM = 8551

# Port IDs
RPC_PORT_ID          = "rpc"
WS_PORT_ID           = "ws"
TCP_DISCOVERY_PORT_ID = "tcp-discovery"
UDP_DISCOVERY_PORT_ID = "udp-discovery"
ENGINE_RPC_PORT_ID    = "engine-rpc"
ENGINE_WS_PORT_ID     = "engineWs"

# TODO Scale this dynamically based on CPUs available and Geth nodes mining
NUM_MINING_THREADS = 1

GENESIS_DATA_MOUNT_DIRPATH = "/genesis"

PREFUNDED_KEYS_MOUNT_DIRPATH = "/prefunded-keys"

# The dirpath of the execution data directory on the client container
EXECUTION_DATA_DIRPATH_ON_CLIENT_CONTAINER = "/execution-data"
KEYSTORE_DIRPATH_ON_CLIENT_CONTAINER      = EXECUTION_DATA_DIRPATH_ON_CLIENT_CONTAINER + "/keystore"

# TODO remove this if facts & waits doesn't need it
EXPECTED_SECONDS_FOR_GETH_INIT                              = 10
EXPECTED_SECONDS_PER_KEY_IMPORT                             = 8
EXPECTED_SECONDS_AFTER_NODE_START_UNTIL_HTTP_SERVER_IS_AVAILABLE = 20
GET_NODE_INFO_TIME_BETWEEN_RETRIES                           = 1 * time.Second

GETH_ACCOUNT_PASSWORD      = "password"          #  Password that the Geth accounts will be locked with
GETH_ACCOUNT_PASSWORDS_FILE = "/tmp/password.txt" #  Importing an account to

PRIVATE_IP_ADDRESS_PLACEHOLDER = "KURTOSIS_IP_ADDR_PLACEHOLDER"

# TODO push this into shared_utils
TCP_PROTOCOL = "TCP"
UDP_PROTOCOL = "UDP"

USED_PORTS = {
	RPC_PORT_ID: new_port_spec(RPC_PORT_NUM, TCP_PROTOCOL),
	WS_PORT_ID: new_port_spec(WS_PORT_NUM, TCP_PROTOCOL),
	TCP_DISCOVERY_PORT_ID: new_port_spec(DISCOVERY_PORT_NUM, TCP_PROTOCOL),
	UDP_DISCOVERY_PORT_ID: new_port_spec(DISCOVERY_PORT_NUM, UDP_PROTOCOL),
	ENGINE_RPC_PORT_ID: new_port_spec(ENGINE_RPC_PORT_NUM, TCP_PROTOCOL)
}

ENTRYPOINT_ARGS = ["sh", "-c"]

VERBOSITY_LEVELS = {
	module_io.GlobalClientLogLevel.error: "1",
	module_io.GlobalClientLogLeve.warn:  "2",
	module_io.GlobalClientLogLeve.info:  "3",
	module_io.GlobalClientLogLevel.debug: "4",
	module_io.GlobalClientLogLevel.trace: "5",
}

def launch(
	launcher,
	service_id,
	image,
	participant_log_level,
	global_log_level,
	# If empty then the node will be launched as a bootnode
	existing_el_clients,
	extra_params):


	log_level = get_client_log_level_or_default(participant_log_level, global_log_level, ERIGON_LOG_LEVELS)

	service_config = get_service_config(launcher.network_id, launcher.el_genesis_data, launcher.prefunded_geth_keys_artifact_uuid,
                                    launcher.prefunded_account_info, image, existing_el_clients, log_level, extra_params)

	service = add_service(service_id, service_config)

	# TODO add facts & waits

	return new_el_client_context(
		"geth",
		"", # TODO fetch ENR from wait & fact
		"", # TODO add Enode from wait & fact,
		service.ip_address,
		RPC_PORT_NUM,
		WS_PORT_NUM,
		ENGINE_RPC_PORT_NUM
	)

def get_service_config(network_id, genesis_data, prefunded_geth_keys_artifact_uuid, prefunded_account_info, image, existing_el_clients, verbosity_level, extra_params):

	genesis_json_filepath_on_client = path_join(GENESIS_DATA_MOUNT_DIRPATH, genesis_data.geth_genesis_json_relative_filepath)
	jwt_secret_json_filepath_on_client = path_join(GENESIS_DATA_MOUNT_DIRPATH, genesis_data.jwt_secret_relative_filepath)

	account_addresses_to_unlock = []
	for prefunded_account in prefunded_account_info:
		account_addresses_to_unlock.append(prefunded_account.address)


	accounts_to_unlock_str = ",".join(account_addresses_to_unlock)

	init_datadir_cmd_str = "geth init --datadir={0} {1}".format(
		EXECUTION_DATA_DIRPATH_ON_CLIENT_CONTAINER,
		genesis_json_filepath_on_client,
	)

	# We need to put the keys into the right spot
	copy_keys_into_keystore_cmd_str = "cp -r {0}/* {1}/".format(
		PREFUNDED_KEYS_MOUNT_DIRPATH,
		KEYSTORE_DIRPATH_ON_CLIENT_CONTAINER,
	)

	create_passwords_file_cmd_str = "{ for i in $(seq 1 %v); do echo \"%v\" >> %v; done; }".format(
		len(prefunded_account_info),
		GETH_ACCOUNT_PASSWORD,
		GETH_ACCOUNT_PASSWORDS_FILE,
	)

	launch_node_cmd_args = [
		"geth",
		"--verbosity=" + verbosityLevel,
		"--unlock=" + accounts_to_unlock_str,
		"--password=" + GETH_ACCOUNT_PASSWORDS_FILE,
		"--datadir=" + EXECUTION_DATA_DIRPATH_ON_CLIENT_CONTAINER,
		"--networkid=" + network_id,
		"--http",
		"--http.addr=0.0.0.0",
		"--http.vhosts=*",
		"--http.corsdomain=*",
		# WARNING: The admin info endpoint is enabled so that we can easily get ENR/enode, which means
		#  that users should NOT store private information in these Kurtosis nodes!
		"--http.api=admin,engine,net,eth",
		"--ws",
		"--ws.addr=0.0.0.0",
		"--ws.port={0}".format(WS_PORT_NUM),
		"--ws.api=engine,net,eth",
		"--ws.origins=*",
		"--allow-insecure-unlock",
		"--nat=extip:" + PRIVATE_IP_ADDRESS_PLACEHOLDER,
		"--verbosity=" + verbosityLevel,
		"--authrpc.port={0}".format(ENGINE_RPC_PORT_NUM),
		"--authrpc.addr=0.0.0.0",
		"--authrpc.vhosts=*",
		"--authrpc.jwtsecret={0}".format(jwt_secret_json_filepath_on_client),
		"--syncmode=full",
	]

	bootnode_enode = ""
	if len(existing_el_clients) > 0 {
		bootnode_context = existing_el_clients[0]
		bootnode_enode = bootnode_context.enode
	}

	launch_node_cmd_args.append(
		launch_node_cmd_args,
		'--bootnodes="%s"'.format(bootnode_enode),
	)

	if len(extraParams) > 0 {
		launch_node_cmd_args.extend(extraParams)
	}

	launch_node_cmd_str = " ".join(launch_node_cmd_args)

	subcommand_strs = [
		init_datadir_cmd_str,
		copy_keys_into_keystore_cmd_str,
		create_passwords_file_cmd_str,
		launch_node_cmd_str,
	]
	command_str = " && ".join(subcommand_strs)



	return struct(
		container_image_name = image,
		used_ports = USED_PORTS,
		cmd_args = [command_str],
		files_artifact_mount_dirpaths = {
			genesis_data.files_artifact_uuid: GENESIS_DATA_MOUNT_DIRPATH,
			prefunded_geth_keys_artifact_uuid: PREFUNDED_KEYS_MOUNT_DIRPATH
		},
		entry_point_args = ENTRYPOINT_ARGS,
		# TODO add private IP address place holder when add servicde supports it
		# for now this will work as we use the service config default above
		# https://github.com/kurtosis-tech/kurtosis/pull/290
	)


def new_geth_launcher(network_id, el_genesis_data, prefunded_geth_keys_artifact_uuid, prefunded_account_info):
	return struct(
		network_id = network_id,
		el_genesis_data = el_genesis_data,
		prefunded_account_info = prefunded_account_info,
		prefunded_geth_keys_artifact_uuid = prefunded_geth_keys_artifact_uuid,
	)
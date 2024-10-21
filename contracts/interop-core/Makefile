profile ?= interop_core_gcp_dev
module ?= interop_core_gcp_dev

module_address = 0xece50a45c602a8f70cac6e5693d2c1641064888ea05f459e540e5cf5f15c37d9
utils = utils_gcp_dev
deployer_address ?= 0x5f64c71174eefa21370b1b5070640d7dcfc630eec99f98927d95f9dc76c5464b
base_token_contract ?= base_gcp_dev
named_addresses ?= interop_core=${module},utils=${utils},base_token_contract=${base_token_contract}

id ?= test
name ?= TestToken
symbol ?= tes

.PHONY: compile
compile:
	@aptos move compile --named-addresses  ${named_addresses}

.PHONY: test
test:
	@aptos move test --named-addresses  ${named_addresses}

.PHONY: custom_test
custom_test:
	@read -p "tests::" test_name; \
	aptos move test --named-addresses  ${named_addresses} --filter tests::$$test_name

.PHONY: publish
publish:
	@aptos move publish --named-addresses  ${named_addresses} --profile=${profile} --included-artifacts none

.PHONY: init
init:
	@aptos move run --function-id '${module}::core::init' --profile=${profile} \
		--args address:interop_multisig

.PHONY: add_admins
add_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::add_admins' \
		--args 'address:["0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca", \
						 "0xdd78ccac345cb269d04fccaa5c48d25b36c7314891bc0ab4e2894b8279098c2e"]'

.PHONY: remove_admins
remove_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::remove_admins' \
		--args 'address:["0x0a525782dac776c8c35d016fb18365c697ddcb0948b9570285e2d81732b3c8b3"]'

.PHONY: update_executer
update_executer:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::update_executer' \
		--args address:interop_multisig_gcp_dev

.PHONY: mint_token
mint_token:
	@aptos move run --profile=${profile} --function-id '${module}::core::mint_token' \
		--args u256:1 \
			string:${name} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
            u64:150

.PHONY: burn_token
burn_token:
	@aptos move run --profile=${profile} --function-id '${module}::core::burn_token' \
		--args u256:2 \
        	string:${name} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
            u64:50

.PHONY: send_instruction
send_instruction:
	@aptos move run --profile=${profile} --function-id '${module}::core::send_instruction' \
		--args string:Holesky \
			string:0x5aE630fEA4a056183F534504AD8Baaa2B8Bd3a1E \
			u256:2 \
			address:0x0B70373D5BA5b0Da8672fF62704bFD117211C2C2 \
			address:0xC29295f67F5d476105f19E8513da0E5027e73e39 \
        	u256:100 \
            u256:1

.PHONY: send_batch_instructions
send_batch_instructions:
	@aptos move run --profile=${profile} --function-id '${module}::core::send_batch_instructions' \
		--args 'string:["Holesky"]' \
            'string:["0x5aE630fEA4a056183F534504AD8Baaa2B8Bd3a1E"]' \
            'u256:["2"]' \
            'address:["0x0B70373D5BA5b0Da8672fF62704bFD117211C2C2"]' \
            'address:{"0xC29295f67F5d476105f19E8513da0E5027e73e39"}' \
            'u256:["100"]' \
            'u256:["1"]'

.PHONY: execute_instruction
execute_instruction:
	@aptos move run --profile=${profile} --function-id '${module}::core::execute_instruction' \
		--args string:Holesky \
			string:0x5aE630fEA4a056183F534504AD8Baaa2B8Bd3a1E \
			string:0x01e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa01000000000000000000000000000000000000000000000000000000000000000954657374546f6b656e

.PHONY: update_source_config
update_source_config:
	@aptos move run --profile=${profile} --function-id '${module}::resource::update_source_config' \
		--args string:Aptos

.PHONY: get_admins
get_admins:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_admins'

.PHONY: get_executer
get_executer:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_executer'

.PHONY: get_source_config
get_source_config:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_source_config'

.PHONY: create_payload
create_payload:
	@aptos move view --profile=${profile} --function-id '${module}::core::create_payload' \
		--args address:0x1d5f14250b767728db006993834e167c6ba740fa \
			u256:1 \
			string:${name} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
        	u64:100 \
            u8:1

.PHONY: get_payload
get_payload:
	@aptos move view --profile=${profile} --function-id '${module}::core::get_payload' \
		--args hex:"0x03e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b460454600000000000000000000000000000000000000af6c7bb298e4fb08c3a3f99e506fe33d69768cc5911300000000000000000000000000000000000000000000000000000000000006546573742d31"

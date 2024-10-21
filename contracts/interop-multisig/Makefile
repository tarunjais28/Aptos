profile ?= interop_multisig_gcp_dev
module ?= interop_multisig_gcp_dev

module_address = 0x8d0544be29754e46e52713c8f65a39ceef8be0bb923ff8264c07d5fc9e7230cd
utils = utils_gcp_dev
deployer_address ?= 0x5f64c71174eefa21370b1b5070640d7dcfc630eec99f98927d95f9dc76c5464b
base_token_contract ?= base_gcp_dev
interop_core ?= interop_core_gcp_dev
named_addresses ?= interop_multisig=${module},utils=${utils},base_token_contract=${base_token_contract},interop_core=${interop_core}

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
	@aptos move run --function-id '${module}::multisig::init' --profile=${profile} \
		--args u8:1

.PHONY: add_admins
add_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::add_admins' \
		--args 'address:["0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca", \
						 "0xdd78ccac345cb269d04fccaa5c48d25b36c7314891bc0ab4e2894b8279098c2e"]'

.PHONY: remove_admins
remove_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::remove_admins' \
		--args 'address:["0x0a525782dac776c8c35d016fb18365c697ddcb0948b9570285e2d81732b3c8b3"]'

.PHONY: add_validators
add_validators:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::add_validators' \
		--args 'address:["0xd047accc45c4896b85110c35b681aee6c8a64558a83ce4761aaf587ba626c981"]'

.PHONY: remove_validators
remove_validators:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::remove_validators' \
		--args 'address:["0x18c7e53fca7b0eca42f2563fdb324047f2ff39d7174779762ede88c7e8fbfefe"]'

.PHONY: cast_vote
cast_vote:
	@aptos move run --profile=${profile} --function-id '${module}::multisig::cast_vote' \
		--args string:0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca \
			bool:true

.PHONY: execute_transaction
execute_transaction:
	@aptos move run --profile=${profile} --function-id '${module}::multisig::execute_transaction' \
		--args string:Polygon \
			string:0xc56d216564831cfa682be379359905224b30adf6 \
			string:0xc29fe0b412c281a6200a025b82a61983fbd16b5f6f127634ec1c6acacf769c8b \
			hex:0x02e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa04000000000000000000000000000000000000000000000000000000000000000454657374

.PHONY: update_threshold
update_threshold:
	@aptos move run --profile=${profile} --function-id '${module}::resource::update_threshold' \
		--args u8:1

.PHONY: get_validators
get_validators:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_validators'

.PHONY: get_admins
get_admins:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_admins'

.PHONY: get_threshold
get_threshold:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_threshold'

.PHONY: get_vote
get_vote:
	@aptos move view --profile=${profile} --function-id '${module}::multisig::get_vote' \
		--args string:""0xaaf14b0d1711de1f5e445efed54814da88208ce23ab1ae6d1aa35e3ceece473c""

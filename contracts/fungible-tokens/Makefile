profile ?= token_gcp_dev
module ?= token_gcp_dev

module_address = 0xe719c1e4add0f0c16b667455ca3f5cdf027fde211be7e9f3cf86cd7444e3bcab
utils = utils_gcp_dev
deployer_address ?= 0x5f64c71174eefa21370b1b5070640d7dcfc630eec99f98927d95f9dc76c5464b
named_addresses ?= fungible_tokens=${module},utils=utils_gcp_dev

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
	@aptos move run --function-id '${module}::asset_coin::init' --profile=${profile}

.PHONY: add_sub_admins
add_sub_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::add_sub_admins' \
		--args 'address:["0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca", \
						 "0x655334349931ea34daee09819cec31b59f5b3b1a7ba793c74be0f6387642a529", \
						 "0x848734730150a556b0d0cab089b69c130b78fd86d313db930ff82c6c324df0a4"]'

.PHONY: remove_sub_admins
remove_sub_admins:
	@aptos move run --profile=${profile} --function-id '${module}::maintainers::remove_sub_admins' \
		--args 'address:["0x0a525782dac776c8c35d016fb18365c697ddcb0948b9570285e2d81732b3c8b3"]'

.PHONY: update_admin
update_admin:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::update_admin' \
		--args address:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9 \
			address:${deployer_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: grant_access_to_agent
grant_access_to_agent:
	@aptos move run --profile=${profile} --function-id '${module}::agents::grant_access_to_agent' \
		--args string:${id} \
			address:"0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045" \
			'u8:[0]'

.PHONY: ungrant_access_to_agent
ungrant_access_to_agent:
	@aptos move run --profile=${profile} --function-id '${module}::agents::ungrant_access_to_agent' \
		--args string:${id} \
			address:0x0a525782dac776c8c35d016fb18365c697ddcb0948b9570285e2d81732b3c8b3 \
			'u8:[1, 2, 3, 4]'

.PHONY: add_issuer
add_issuer:
	@aptos move run --profile=${profile} --function-id '${module}::roles::add_issuer' \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_issuer
remove_issuer:
	@aptos move run --profile=${profile} --function-id '${module}::roles::remove_issuer' \
		--args string:${id}

.PHONY: add_transfer_agent
add_transfer_agent:
	@aptos move run --profile=${profile} --function-id '${module}::roles::add_transfer_agent' \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_transfer_agent
remove_transfer_agent:
	@aptos move run --profile=${profile} --function-id '${module}::roles::remove_transfer_agent' \
		--args string:${id}

.PHONY: add_tokenization_agent
add_tokenization_agent:
	@aptos move run --profile=${profile} --function-id '${module}::roles::add_tokenization_agent' \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_tokenization_agent
remove_tokenization_agent:
	@aptos move run --profile=${profile} --function-id '${module}::roles::remove_tokenization_agent' \
		--args string:${id}

.PHONY: create_token
create_token:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::create_token' \
		--args string:${id} \
			string:${name} \
			string:${symbol} \
			string:icon_uri \
			string:project_uri \
			u64:10000000000000000 \
			'u8:[1,91]' \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
			u64:0

.PHONY: mint_token
mint_token:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::mint_token' \
		--args string:${id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
            'u64:[150]'

.PHONY: burn_token
burn_token:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::burn_token' \
		--args string:${id} \
            'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
            'u64:[50]'

.PHONY: add_to_whitelist
add_to_whitelist:
	@aptos move run --profile=${profile} --function-id '${module}::whitelist::add' \
		--args string:${id} \
			'address:["0xb4ee9a782f410439abdcc2a1071ed6456e26f3744e14a80429f3114085d2ef19"]' \
            'u8:[91]'

.PHONY: transfer_token
transfer_token:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::transfer_token' \
		--args string:${id} \
			address:0xb4ee9a782f410439abdcc2a1071ed6456e26f3744e14a80429f3114085d2ef19 \
			u64:500

.PHONY: force_transfer
force_transfer:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::force_transfer' \
		--args string:${id} \
        	'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
        	'address:["0xb4ee9a782f410439abdcc2a1071ed6456e26f3744e14a80429f3114085d2ef19"]' \
        	'u64:[500]'

.PHONY: freeze_accounts
freeze_accounts:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::freeze_accounts' \
		--args string:${id} \
			'address:["0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9"]'

.PHONY: unfreeze_accounts
unfreeze_accounts:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::unfreeze_accounts' \
		--args string:${id} \
			'address:[0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9]'

.PHONY: update_token_limit
update_token_limit:
	@aptos move run --profile=${profile} --function-id '${module}::resource::update_token_limit' \
		--args string:${id} \
			u64:10000000000000000

.PHONY: partial_freeze
partial_freeze:
	@aptos move run --profile=${profile} --function-id '${module}::resource::partial_freeze' \
		--args string:${id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
			'u64:[50]'

.PHONY: partial_unfreeze
partial_unfreeze:
	@aptos move run --profile=${profile} --function-id '${module}::resource::partial_unfreeze' \
		--args string:${id} \
			'address:["0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9"]' \
            'u64:[50]'

.PHONY: remove_from_whitelist
remove_from_whitelist:
	@aptos move run --profile=${profile} --function-id '${module}::whitelist::remove' \
		--args string:${id} \
			'address:["0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9"]'

.PHONY: dvp
dvp:
	@aptos move run --profile=${profile} --function-id '${module}::asset_coin::dvp' \
		--args string:${id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
            'u64:[150]'

.PHONY: get_resource_address
get_resource_address:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_resource_address' \
		--args address:${deployer_address}

.PHONY: get_admin
get_admin:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_admin'

.PHONY: get_sub_admins
get_sub_admins:
	@aptos move view --profile=${profile} --function-id '${module}::maintainers::get_sub_admins'

.PHONY: get_balance
get_balance:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_balance' \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: get_country_code_by_address
get_country_code_by_address:
	@aptos move view --profile=${profile} --function-id '0x021919f5aff502c156e92cc86ce9e599269d596b9a46da419810a5cd4f98ed30::whitelist::get_country_code_by_addres' \
		--args string:1021 \
			address:0x9caa182b01b64769306bceab669d5a2823489f20114c2fab1bc20315a778bc50

.PHONY: get_mint_proposals
get_mint_proposals:
	@aptos move view --profile=${profile} --function-id '0x021919f5aff502c156e92cc86ce9e599269d596b9a46da419810a5cd4f98ed30::asset_coin::get_mint_proposals' \
		--args 'string:token_id'

.PHONY: get_burn_proposals
get_burn_proposals:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_burn_proposals' \
		--args 'string:token_id'

.PHONY: get_country_codes
get_country_codes:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_country_codes' \
		--args string:${id}

.PHONY: get_token_limit
get_token_limit:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_token_limit' \
		--args string:${id}

.PHONY: get_frozen_tokens
get_frozen_tokens:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_frozen_tokens' \
		--args string:${id}

.PHONY: get_frozen_balance
get_frozen_balance:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_frozen_balance' \
		--args string:${id} \
			address:0x1f4b510d436238fd3d04c352d34d203c75f2e3dbceaea5620761db160fb81114

.PHONY: get_holding_period
get_holding_period:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_holding_period' \
		--args string:${id}

.PHONY: get_issuer
get_issuer:
	@aptos move view --profile=${profile} --function-id '${module}::roles::get_issuer' \
		--args string:${id}

.PHONY: get_transfer_agent
get_transfer_agent:
	@aptos move view --profile=${profile} --function-id '${module}::roles::get_transfer_agent' \
		--args string:${id}

.PHONY: get_tokenization_agent
get_tokenization_agent:
	@aptos move view --profile=${profile} --function-id '${module}::roles::get_tokenization_agent' \
		--args string:${id}

.PHONY: get_metadata
get_metadata:
	@aptos move view --profile=${profile} --function-id '${module}::resource::get_metadata' \
		--args string:${id}

.PHONY: get_name
get_name:
	@aptos move view --profile=${profile} --function-id '0x021919f5aff502c156e92cc86ce9e599269d596b9a46da419810a5cd4f98ed30::asset_coin::get_name' \
		--args string:1021

.PHONY: get_supply
get_supply:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_supply' \
		--args string:${id}

.PHONY: get_max_supply
get_max_supply:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_max_supply' \
		--args string:${id}

.PHONY: get_symbol
get_symbol:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_symbol' \
		--args string:${id}

.PHONY: get_decimals
get_decimals:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_decimals' \
		--args string:${id}

.PHONY: get_roles
get_roles:
	@aptos move view --profile=${profile} --function-id '${module}::agents::get_roles_for_address' \
		--args string:${id} \
        	address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: get_circulating_supply
get_circulating_supply:
	@aptos move view --profile=${profile} --function-id '${module}::asset_coin::get_circulating_supply' \
		--args string:${id}

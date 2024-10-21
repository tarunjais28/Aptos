profile ?= default
res_address ?= 0xfcfb9a1ecf80e821710014e5fe752352f45c474d4d74cf4ae38baa3a9c7793fc
creator_address ?= 0xd65060a81770f47fd17d7187d4ea7cdf9f66a51e002dda2b1a61211f9f7b1be7

.PHONY: compile
compile:
	aptos move compile --named-addresses token_contract=default

.PHONY: test
test:
	aptos move test --named-addresses token_contract=default

.PHONY: custom_test
custom_test:
	@read -p "tests::" test_name; \
	aptos move test --named-addresses token_contract=default --filter tests::$$test_name


.PHONY: publish
publish:
	aptos move publish --named-addresses token_contract=default --profile=${profile}

.PHONY: init
init:
	aptos move run --function-id 'default::asset_coin::init' --profile=${profile}

.PHONY: add_sub_admins
add_sub_admins:
	aptos move run --profile=${profile} --function-id 'default::maintainers::add_sub_admins' \
		--args address:0xe3e40d29d24411265a90dc46853dd6c992e5d3381b77fef28b0809b5eb052ac7 \
		  'vector<address>:0xd9a516197e954e4babf431bdbf2ce6f109c0a9ae1e912010883f1f13790d0bdf'

.PHONY: remove_sub_admins
remove_sub_admins:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::remove_sub_admins' \
		--args address:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9
			'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045'

.PHONY: update_admin
update_admin:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::update_admin' \
		--args address:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9 \
			address:${creator_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: grant_access_to_agent
grant_access_to_agent:
	aptos move run --profile=${profile} --function-id 'default::agents::grant_access_to_agent' \
		--args address:${res_address} \
			'vector<address>:${res_address}' \
			'vector<u64>:0,1'

.PHONY: ungrant_access_to_agent
ungrant_access_to_agent:
	aptos move run --profile=${profile} --function-id 'default::agents::ungrant_access_to_agent' \
		--args address:${res_address} \
			'vector<address>:${res_address}' \
			'vector<u64>:0,1'

.PHONY: add_issuer
add_issuer:
	aptos move run --profile=${profile} --function-id 'default::roles::add_issuer' \
		--args address:${res_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_issuer
remove_issuer:
	aptos move run --profile=${profile} --function-id 'default::roles::remove_issuer' \
		--args address:${res_address}

.PHONY: add_transfer_agent
add_transfer_agent:
	aptos move run --profile=${profile} --function-id 'default::roles::add_transfer_agent' \
		--args address:${res_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_transfer_agent
remove_transfer_agent:
	aptos move run --profile=${profile} --function-id 'default::roles::remove_transfer_agent' \
		--args address:${res_address}

.PHONY: add_tokenization_agent
add_tokenization_agent:
	aptos move run --profile=${profile} --function-id 'default::roles::add_tokenization_agent' \
		--args address:${res_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_tokenization_agent
remove_tokenization_agent:
	aptos move run --profile=${profile} --function-id 'default::roles::remove_tokenization_agent' \
		--args address:${res_address}

.PHONY: create_token
create_token:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::create_token' \
		--args address:${res_address} \
			string:unique string:tarun string:symbol u64:10000 'vector<u8>:1,91' \
			address:0xd65060a81770f47fd17d7187d4ea7cdf9f66a51e002dda2b1a61211f9f7b1be7 \
			address:0x997ce6cc400f60ff6d320716dd8ac8663c18adf574062bef6a5b7295925ff900 \
			address:0x73c43475d3bb52e4897a26c8f28ef276b08a3e148fc01355e56d60c6ebf12aa7

.PHONY: register_account
register_account:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::register_account' \
		--args address:${res_address}

.PHONY: mint_token
mint_token:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::mint_token' \
		--args address:${res_address} \
			address:${creator_address} \
			'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \
            'vector<u64>:5000'

.PHONY: burn_token
burn_token:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::burn_token' \
		--args address:${res_address} \
			address:${creator_address} \
            'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \
            'vector<u64>:200'

.PHONY: add_to_whitelist
add_to_whitelist:
	aptos move run --profile=${profile} --function-id 'default::whitelist::add' \
		--args address:${res_address} \
			'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \
            'vector<u8>::91'

.PHONY: transfer_token
transfer_token:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::transfer_token' \
		--args address:${res_address} \
			address:${creator_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
			u64:200

.PHONY: freeze_accounts
freeze_accounts:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::freeze_accounts' \
		--args address:${res_address} \
			address:${creator_address} \
			'vector<address>:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9'

.PHONY: unfreeze_accounts
unfreeze_accounts:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::unfreeze_accounts' \
		--args address:${res_address} \
			address:${creator_address} \
			'vector<address>:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9'

.PHONY: partial_freeze
partial_freeze:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::partial_freeze' \
		--args address:${res_address} \
			address:${creator_address} \
			'vector<address>:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9' \
			'vector<u64>:100'

.PHONY: partial_unfreeze
partial_unfreeze:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::partial_unfreeze' \
		--args address:${res_address} \
			address:${creator_address} \
			'vector<address>:${res_address}'

.PHONY: remove_from_whitelist
remove_from_whitelist:
	aptos move run --profile=${profile} --function-id 'default::whitelist::remove' \
		--args address:${res_address} \
			'vector<address>:0x53a274dfcb652f2eaf9db544f067d2ad640fa6a294edca4a00c234ecb91f4df9'

.PHONY: enable_multisig
enable_multisig:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::enable_multisig' \
		--args address:${res_address} \
			'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \
            'u64:0'

.PHONY: disable_multisig
disable_multisig:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::disable_multisig' \
		--args address:${res_address}


.PHONY: add_signers
add_signers:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::add_signers' \
		--args address:${res_address} \
		'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \


.PHONY: remove_signers
remove_signers:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::remove_signers' \
		--args address:${res_address} \
		'vector<address>:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045' \


.PHONY: create_mint_request
create_mint_request:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::create_mint_request' \
		--args address:${res_address} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045 \
			u64:100000000


.PHONY: create_burn_request
create_burn_request:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::create_burn_request' \
		--args address:${res_address} \
			u64:100000000


.PHONY: cancel_mint_request
cancel_mint_request:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::cancel_mint_request' \
		--args address:${res_address} \
			u64:0


.PHONY: cancel_burn_request
cancel_burn_request:
	aptos move run --profile=${profile} --function-id 'default::asset_coin::create_burn_request' \
		--args address:${res_address} \
			u64:0

.PHONY: get_resource_address
get_resource_address:
	aptos move view --profile=${profile} --function-id 'default::resource::get_resource_address' \
		--args address:0xd65060a81770f47fd17d7187d4ea7cdf9f66a51e002dda2b1a61211f9f7b1be7

.PHONY: get_admin
get_admin:
	aptos move view --profile=${profile} --function-id 'default::maintainers::get_admin' \
        --args address:${res_address}

.PHONY: get_sub_admins
get_sub_admins:
	aptos move view --profile=${profile} --function-id 'default::maintainers::get_sub_admins' \
		--args address:${res_address}

.PHONY: get_balance
get_balance:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_balance' \
		--args address:${res_address}

.PHONY: get_country_code_by_address
get_country_code_by_address:
	aptos move view --profile=${profile} --function-id 'default::whitelist::get_country_code_by_address' \
		--args address:${res_address} \
			   address:${creator_address}

.PHONY: get_mint_proposals
get_mint_proposals:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_mint_proposals' \
		--args address:${res_address}


.PHONY: get_burn_proposals
get_burn_proposals:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_burn_proposals' \
		--args address:${res_address}


.PHONY: get_token_config
get_token_config:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_token_config' \
		--args address:${creator_address}

.PHONY: get_country_codes
get_country_codes:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_country_codes' \
		--args address:${creator_address}

.PHONY: get_token_limit
get_token_limit:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_token_limit' \
		--args address:${creator_address}

.PHONY: get_frozen_tokens
get_frozen_tokens:
	aptos move view --profile=${profile} --function-id 'default::asset_coin::get_frozen_tokens' \
		--args address:${creator_address}

.PHONY: get_issuer
get_issuer:
	aptos move view --profile=${profile} --function-id 'default::roles::get_issuer' \
		--args address:${res_address}

.PHONY: get_transfer_agent
get_transfer_agent:
	aptos move view --profile=${profile} --function-id 'default::roles::get_transfer_agent' \
		--args address:${res_address}

.PHONY: get_tokenization_agent
get_tokenization_agent:
	aptos move view --profile=${profile} --function-id 'default::roles::get_tokenization_agent' \
		--args address:${res_address}

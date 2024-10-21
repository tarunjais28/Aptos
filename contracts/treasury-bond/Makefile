profile ?= treasury_bond_gcp_dev
module ?= treasury_bond_gcp_dev

module_address ?= 0x28e7d080fef83786e428ccac3fe514ff4772369ecf953433152af9f9773aa061
deployer ?= 0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434
named_addresses ?= treasury_bond=${module},utils=${utils}

utils ?= utils_gcp_dev
usdt ?= 0x6f2cb8b97a4f19085c5d2110dc6114d3e3dace55c4f84a137ddce4c924c0c94e
usdc ?= 0x9f9cec0940a32f82d409a0d9948cbb6c9e88ffc11e508df103e3be232ebe5111
dai ?= 0xc9e72a58b8b0af82cb6ccf8c59d296fc497276e68d344801b7b7a80fdc1fd82b
c_t_dai ?= 0
c_t_usdt ?= 1
c_t_usdc ?= 2
token ?= 0
coin ?= 1
fiat ?= 2
token_name ?= test
id ?= 2

.PHONY: compile
compile:
	@aptos move compile --named-addresses ${named_addresses}

.PHONY: test
test:
	@aptos move test --named-addresses ${named_addresses}

.PHONY: custom_test
custom_test:
	@read -p "tests::" test_name; \
	@aptos move test --named-addresses ${named_addresses} --filter tests::$test_name

.PHONY: publish
publish:
	@aptos move publish --named-addresses ${named_addresses} --profile=${profile} --included-artifacts none

.PHONY: init
init:
	@aptos move run --function-id '${module}::treasury_bond::init' --profile=${profile} \
		--args address:${dai} \
			address:${usdt} \
			address:${usdc}

.PHONY: create
create:
	@aptos move run --function-id '${module}::treasury_bond::create' --profile=${profile} \
		--args string:${id} \
			string:${token_name} \
			u128:100 \
			u128:100 \
			u16:7 \
			u16:8 \
			u64:121322456 \
			string:issuer \
			string:Monthly

.PHONY: update_stable_coin_address
update_stable_coin_address:
	@aptos move run --function-id '${module}::stable_coin::update_stable_coin_address' --profile=${profile} \
		--args u8:${c_t_usdc} \
               			address:${usdc}

.PHONY: send_coins
send_coins:
	@aptos move run --function-id '${module}::stable_coin::send_stable_coins' --profile=${profile} \
		--args string:${id} \
        	u64:500 \
            u8:${c_t_usdt}

.PHONY: update_credit_rating
update_credit_rating:
	@aptos move run --function-id '${module}::resource::update_credit_rating' --profile=${profile} \
		--args string:${id} \
			string:"Rating"

.PHONY: share_stable_coins
share_stable_coins:
	@aptos move run --function-id '${module}::treasury_bond::share_stable_coins' --profile=${profile} \
		--args string:${id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045", \
					  "0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
			'u64:[200, 200]' \
			u8:${c_t_usdt}

.PHONY: add_admins
add_admins:
	@aptos move run --function-id '${module}::maintainer::add_admins' --profile=${profile} \
		--args 'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045", \
               			 "0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]'

.PHONY: remove_admins
remove_admins:
	@aptos move run --function-id '${module}::maintainer::remove_admins' --profile=${profile} \
		--args 'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045", \
               			 "0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]'

.PHONY: add_agent
add_agent:
	@aptos move run --function-id '${module}::agent::add_agent' --profile=${profile} \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_agent
remove_agent:
	@aptos move run --function-id '${module}::agent::remove_agent' --profile=${profile} \
		--args string:${id}

.PHONY: has_agent_rights
has_agent_rights:
	@aptos move view --function-id '${module}::agent::has_agent_rights' --profile=${profile} \
		--args string:${id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: get_agent
get_agent:
	@aptos move view --function-id '${module}::agent::get_agent_by_id' --profile=${profile} \
		--args string:${id}

.PHONY: get_admins
get_admins:
	@aptos move view --function-id '${module}::maintainer::get_admins' --profile=${profile}

.PHONY: get_config
get_config:
	@aptos move view --function-id '${module}::resource::get_config' --profile=${profile} \
		--args string:${id}

.PHONY: get_payments
get_payments:
	@aptos move view --function-id '${module}::treasury_bond::get_payments' --profile=${profile} \
		--args string:${id}

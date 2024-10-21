profile ?= fund_gcp_dev
module ?= fund_gcp_dev

module_address ?= 0x848734730150a556b0d0cab089b69c130b78fd86d313db930ff82c6c324df0a4
pyth ?= 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387
deployer ?= 0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434
wormhole ?= 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625
fungible_tokens ?= token_gcp_dev
utils ?= utils_gcp_dev
named_addresses ?= fund=${module},pyth=${pyth},deployer=${deployer},wormhole=${wormhole},fungible_tokens=${fungible_tokens},utils=${utils}

usdt ?= 0x6f2cb8b97a4f19085c5d2110dc6114d3e3dace55c4f84a137ddce4c924c0c94e
usdc ?= 0x9f9cec0940a32f82d409a0d9948cbb6c9e88ffc11e508df103e3be232ebe5111
dai ?= 0xc9e72a58b8b0af82cb6ccf8c59d296fc497276e68d344801b7b7a80fdc1fd82b
c_t_dai ?= 0
c_t_usdt ?= 1
c_t_usdc ?= 2
token ?= 0
coin ?= 1
fiat ?= 2
token_id ?= test

.PHONY: compile
compile:
	@aptos move compile --named-addresses ${named_addresses}

.PHONY: test
test:
	@aptos move test --named-addresses ${named_addresses}

.PHONY: custom_test
custom_test:
	@read -p "tests::" test_name; \
	@aptos move test --named-addresses ${named_addresses} --filter tests::$$test_name

.PHONY: publish
publish:
	@aptos move publish --named-addresses ${named_addresses} --profile=${profile} --included-artifacts none

.PHONY: init
init:
	@aptos move run --function-id '${module}::fund::init' --profile=${profile} \
		--args address:${dai} \
			address:${usdt} \
			address:${usdc}

.PHONY: create
create:
	@aptos move run --function-id '${module}::fund::create' --profile=${profile} \
		--args string:${token_id} \
			string:test-fund \
			u8:${token} \
			string:issuer \
			u64:1000 \
			u64:800

.PHONY: update_stable_coin_address
update_stable_coin_address:
	@aptos move run --function-id '${module}::stable_coin::update_stable_coin_address' --profile=${profile} \
		--args u8:${c_t_usdc} \
               			address:${usdc}

.PHONY: send_coins
send_coins:
	@aptos move run --function-id '${module}::stable_coin::send_stable_coins' --profile=${profile} \
		--args string:${token_id} \
        	u64:500 \
            u8:${c_t_usdt}


.PHONY: add_user_management_fees
add_user_management_fees:
	@aptos move run --function-id '${module}::fund::add_user_management_fees' --profile=${profile} \
		--args string:${token_id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
            'u64:[200]'

.PHONY: update_user_management_fees
update_user_management_fees:
	@aptos move run --function-id '${module}::fund::update_user_management_fees' --profile=${profile} \
		--args string:${token_id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
            'u64:[300]'

.PHONY: remove_user_management_fees
remove_user_management_fees:
	@aptos move run --function-id '${module}::fund::remove_user_management_fees' --profile=${profile} \
		--args string:${token_id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]'

.PHONY: share_dividend
share_dividend:
	@aptos move run --function-id '${module}::fund::share_dividend' --profile=${profile} \
		--args string:${token_id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045", \
					  "0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
			'u64:[200, 200]' \
			'u8:[${token}, ${coin}]' \
			u8:${c_t_usdt}

.PHONY: distribute_and_burn
distribute_and_burn:
	@aptos move run --function-id '${module}::fund::distribute_and_burn' --profile=${profile} \
		--args string:${token_id} \
			'address:["0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045"]' \
			'u64:[500]' \
			'u64:[200]' \
			u8:${c_t_usdt}

.PHONY: rescue_token
rescue_token:
	@aptos move run --function-id '${module}::fund::rescue_token' --profile=${profile} \
		--args string:${token_id} \
			address:0x5d9fb9dcbd4f8a61eff5d805e751b6941c0296f15484e786101f745a52ea590e \
			u64:100

.PHONY: update_admin
update_admin:
	@aptos move run --function-id '${module}::maintainer::update_admin' --profile=${profile} \
		--args address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: add_agent
add_agent:
	@aptos move run --function-id '${module}::agent::add_agent' --profile=${profile} \
		--args string:${token_id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: remove_agent
remove_agent:
	@aptos move run --function-id '${module}::agent::remove_agent' --profile=${profile} \
		--args string:${token_id}

.PHONY: fetch_price
fetch_price:
	@aptos move run --function-id '${module}::resource::fetch_price' --profile=${profile} \
		--args string:${token_id} \
			'u8:[21996482260991208577318051447261463560613210235434548549693894196113239010574]'

.PHONY: has_agent_rights
has_agent_rights:
	@aptos move view --function-id '${module}::agent::has_agent_rights' --profile=${profile} \
		--args string:${token_id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: get_agent
get_agent:
	@aptos move view --function-id '${module}::agent::get_agent_by_id' --profile=${profile} \
		--args string:${token_id}

.PHONY: get_admin
get_admin:
	@aptos move view --function-id '${module}::maintainer::get_admin' --profile=${profile}

.PHONY: get_aum
get_aum:
	@aptos move view --function-id '${module}::fund::get_aum' --profile=${profile} \
		--args string:${token_id}

.PHONY: get_management_fees
get_management_fees:
	@aptos move view --function-id '${module}::resource::get_management_fees' --profile=${profile} \
		--args string:${token_id} \
			address:0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045

.PHONY: get_nav
get_nav:
	@aptos move view --function-id '${module}::resource::get_nav' --profile=${profile} \
		--args string:${token_id}

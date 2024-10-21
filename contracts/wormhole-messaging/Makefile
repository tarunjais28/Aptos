profile ?= wormhole_gcp_dev
module ?= wormhole_gcp_dev

module_address ?= 0xd047accc45c4896b85110c35b681aee6c8a64558a83ce4761aaf587ba626c981
deployer ?= 0x0108bc32f7de18a5f6e1e7d6ee7aff9f5fc858d0d87ac0da94dd8d2a5d267d6b
wormhole ?= 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625
named_addresses ?= deployer=${deployer},wormhole=${wormhole},wormhole_messaging=${module}

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

.PHONY: send
send:
	@aptos move run --function-id '${module}::sender::send_message' --profile=${profile} \
		--args hex:0x02e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa04000000000000000000000000000000000000000000000000000000000000000454657374

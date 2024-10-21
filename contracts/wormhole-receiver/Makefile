profile ?= wormhole_gcp_dev
module ?= wormhole_gcp_dev

module_address ?= 0xe55dd53fecc8f2669e0ce3ef62d751ed3f4b1c7baa3768ca07788309474db776
named_addresses ?= wormhole_messaging=${module},utils=utils_gcp_dev,base_token_contract=base_gcp_dev

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

.PHONY: receive
receive:
	@aptos move run --function-id '${module}::wormhole_messaging::receiver' --profile=${profile} \
		--args hex:0x02e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa04000000000000000000000000000000000000000000000000000000000000000454657374

profile ?= utils_gcp_dev
module_address ?= utils_gcp_dev
module = 0xceaa2775d04d0e0f0332bd111b79c2bc4b0a3d2e713afbec280110336d4fb9e0

.PHONY: compile
compile:
	aptos move compile --named-addresses utils=${module_address}

.PHONY: test
test:
	aptos move test --named-addresses utils=${module_address}

.PHONY: custom_test
custom_test:
	@read -p "tests::" test_name; \
	aptos move test --named-addresses utils=${module_address} --filter tests::$$test_name

.PHONY: publish
publish:
	aptos move publish --named-addresses utils=${module_address} --profile=${profile}

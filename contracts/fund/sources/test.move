#[test_only]
module fund::test {

    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use pyth::pyth::init_test;
    use aptos_framework::account;
    use fund::fund::{init, create, add_user_management_fees, update_user_management_fees, remove_user_management_fees,
        share_dividend, distribute_and_burn};
    use fund::maintainer::{get_admin, init_maintainers, update_admin};
    use fund::agent::{has_agent_rights, get_agent_by_id, remove_agent, add_agent};
    use fund::resource::get_management_fees;
    use fungible_tokens::tests::init_and_create_token;
    use fungible_tokens::maintainers::add_sub_admins;
    use fungible_tokens::agents::{get_roles_for_address, init_agent_roles};
    use fungible_tokens::asset_coin::{mint_token, get_supply, create_token};
    use fungible_tokens::resource::{get_metadata, get_balance};
    use fund::stable_coin::{update_stable_coin_address, get_stable_coin_address, set_stable_coin};
    use aptos_framework::object::object_address;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::option::Self;
    use fund::events::initialize_event_store;

    // Initialize and create fund
    fun init_and_create(
        token_account: &signer,
        fund_account: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        token_id: String,
    ) {
        // Initialize and create token with token_id = unique
        init_and_create_token(token_account, issuer, transfer_agent, tokenization_agent, token_id);
        let fund_addr = signer::address_of(fund_account);
        aptos_framework::account::create_account_for_test(fund_addr);

        // Adding sub_admins
        add_sub_admins(token_account, vector[fund_addr]);

        // Initializing fund
        init(fund_account, dai, usdt, usdc);

        let fund_name = string::utf8(b"budz");
        let asset_type = fund::constants::token();
        let issuer_name = string::utf8(b"issuer");
        let target_aum = 1000;
        let nav_launch_price = 100;

        create(
            fund_account,
            token_id,
            fund_name,
            asset_type,
            issuer_name,
            target_aum,
            nav_launch_price,
        );
    }

    // Create test coin
    fun create_stable_coin(
        token_account: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        token_id: String,
    ) {
        let name = string::utf8(b"usdt");
        let symbol = string::utf8(b"usdt");
        let icon_uri = string::utf8(b"http://www.example.com/favicon.ico");
        let project_uri = string::utf8(b"http://www.example.com");
        let token_limit = 100000;
        let country_codes = vector[1, 91];

        create_token(
            token_account,
            token_id,
            name,
            symbol,
            icon_uri,
            project_uri,
            token_limit,
            country_codes,
            issuer,
            tokenization_agent,
            transfer_agent,
        );
    }

    #[test(
        account = @fund,
        dai = @0x1,
        usdt = @0x2,
        usdc = @0x3,
    )]
    fun test_init(account: &signer, dai: address, usdt: address, usdc: address) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        init(account, dai, usdt, usdc);

        assert!(get_admin() == addr, 0);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    fun test_create(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let addr = signer::address_of(fund_account);

        // Deploy and initialize a test instance of the Pyth contract
        let deployer = account::create_signer_with_capability(&
            account::create_test_signer_cap(@0x277fa055b6a73c42c0662d5236c65c864ccbf2d4abd21f174a30c8b786eab84b));
        let (_pyth, signer_capability) = account::create_resource_account(&deployer, b"pyth");
        init_test(
            signer_capability,
            500,
            23,
            x"5d1f252d5de865279b00c84bce362774c2804294ed53299bc4a0389a5defef92",
            vector[],
            50
        );

        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(has_agent_rights(token_id, addr), 0);

        assert!(
            get_roles_for_address(
                token_id, addr
            ) == vector[
                    string::utf8(b"mint"),
                    string::utf8(b"burn"),
                    string::utf8(b"transfer"),
                    string::utf8(b"force_transfer"),
                ],
            1
        )
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    fun test_add_user_management_fees(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        // Checking fees
        assert!(get_management_fees(token_id, user1) == user1_fees, 0);
        assert!(get_management_fees(token_id, user2) == user2_fees, 1);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 327685, location = fund::fund)]
    fun test_add_user_management_fees_with_account_other_than_agent(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];

        // Fails as issuer doesn't have the agent rights
        add_user_management_fees(issuer, token_id, users, fees);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 65545, location = fund::resource)]
    fun test_add_user_management_fees_with_unequal_number_of_arguements(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let fees = vector[user1_fees];

        // Fails as the number of arguements are unequal
        add_user_management_fees(fund_account, token_id, users, fees);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    fun test_update_user_management_fees(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        // Updating fees
        user1_fees = 300;
        user2_fees = 400;
        fees = vector[user1_fees, user2_fees];
        update_user_management_fees(fund_account, token_id, users, fees);

        // Checking fees
        assert!(get_management_fees(token_id, user1) == user1_fees, 0);
        assert!(get_management_fees(token_id, user2) == user2_fees, 1);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    fun test_update_user_management_fees_with_new_account(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];

        // Update will pass with new enteries user1 and user2
        update_user_management_fees(fund_account, token_id, users, fees);

        // Checking fees
        assert!(get_management_fees(token_id, user1) == user1_fees, 0);
        assert!(get_management_fees(token_id, user2) == user2_fees, 1);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 327685, location = fund::fund)]
    fun test_update_user_management_fees_with_account_other_than_agent(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        // Updating fees
        user1_fees = 300;
        user2_fees = 400;
        fees = vector[user1_fees, user2_fees];
        update_user_management_fees(issuer, token_id, users, fees);

    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 65545, location = fund::resource)]
    fun test_update_user_management_fees_with_unequal_number_of_arguements(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        // Updating fees
        user1_fees = 300;
        fees = vector[user1_fees];
        update_user_management_fees(fund_account, token_id, users, fees);

        // Fails as the number of arguements are unequal
        add_user_management_fees(fund_account, token_id, users, fees);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 65538, location = aptos_std::simple_map)]
    fun test_remove_user_management_fees(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        users = vector[user1];
        remove_user_management_fees(fund_account, token_id, users);

        // Checking fees, should fail as user1 is removed
        assert!(get_management_fees(token_id, user1) == user1_fees, 0);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 327685, location = fund::fund)]
    fun test_remove_user_management_fees_with_account_other_than_agent(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let users = vector[user1, user2];
        let user1_fees = 100;
        let user2_fees = 200;
        let fees = vector[user1_fees, user2_fees];
        add_user_management_fees(fund_account, token_id, users, fees);

        users = vector[user1];
        remove_user_management_fees(issuer, token_id, users);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    fun test_update_stable_coin_address(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);

        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        // Checking assigned addresses
        assert!(get_stable_coin_address(fund::constants::dai()) == dai, 0);
        assert!(get_stable_coin_address(fund::constants::usdt()) == usdt, 0);
        assert!(get_stable_coin_address(fund::constants::usdc()) == usdc, 0);

        // New addresses to be assigned
        let new_dai_addr = @07;
        let new_usdt_addr = @08;
        let new_usdc_addr = @09;

        // Updating addresses
        update_stable_coin_address(fund_account, fund::constants::dai(), new_dai_addr);
        update_stable_coin_address(fund_account, fund::constants::usdt(), new_usdt_addr);
        update_stable_coin_address(fund_account, fund::constants::usdc(), new_usdc_addr);

        // Checking new addresses
        assert!(get_stable_coin_address(fund::constants::dai()) == new_dai_addr, 0);
        assert!(get_stable_coin_address(fund::constants::usdt()) == new_usdt_addr, 0);
        assert!(get_stable_coin_address(fund::constants::usdc()) == new_usdc_addr, 0);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    #[expected_failure(abort_code = 393222, location = fund::maintainer)]
    fun test_update_stable_coin_address_with_non_admin_account(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);

        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(get_stable_coin_address(fund::constants::dai()) == dai, 0);

        let new_dai_addr = @07;

        // Updating addresses
        update_stable_coin_address(issuer, fund::constants::dai(), new_dai_addr);
    }

    #[test(
        account = @fund,
        dai = @0x1,
        usdt = @0x2,
        usdc = @0x3,
    )]
    #[expected_failure(abort_code = 524296, location = fund::stable_coin)]
    fun test_set_stable_coin(
        account: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        // Initializing fund
        init(account, dai, usdt, usdc);

        // Checking assigned addresses
        assert!(get_stable_coin_address(fund::constants::dai()) == dai, 0);
        assert!(get_stable_coin_address(fund::constants::usdt()) == usdt, 0);
        assert!(get_stable_coin_address(fund::constants::usdc()) == usdc, 0);

        // New addresses to be assigned
        let new_dai_addr = @04;
        let new_usdt_addr = @05;
        let new_usdc_addr = @06;

        // Fails as resouce already exists
        set_stable_coin(account, new_dai_addr, new_usdt_addr, new_usdc_addr);
    }

    #[test(
        account = @fund,
        dai = @0x1,
        usdt = @0x2,
        usdc = @0x3,
    )]
    #[expected_failure]
    fun test_set_stable_coin_without_init(
        account: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        // Fails as admin is not set
        set_stable_coin(account, dai, usdt, usdc);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    fun test_share_dividend(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let to_addresses = vector[user1, user2];
        let user1_dividend = 100;
        let user2_dividend = 200;
        let dividends = vector[user1_dividend, user2_dividend];
        let asset_types = vector[fund::constants::token(), fund::constants::stable_coin()];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);
        let supply = 1000;

        mint_token(token_account, stable_coin_id, vector[agent], vector[supply]);
        assert!(get_supply(stable_coin_id) == option::some((supply as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == supply, 0);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        share_dividend(fund_account, token_id, to_addresses, dividends, asset_types, fund::constants::usdt());

        // Checking balance for mint token
        assert!(get_balance(token_id, user1) == user1_dividend, 0);
        assert!(get_supply(token_id) == option::some((user1_dividend as u128)), 0);

        // Checking balance for stable coin transfer from agent account
        assert!(get_balance(stable_coin_id, user2) == user2_dividend, 0);
        assert!(get_balance(stable_coin_id, agent) == supply - user2_dividend , 0);
        assert!(get_supply(stable_coin_id) == option::some((supply as u128)), 0);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 327685, location = fund::fund)]
    fun test_share_dividend_with_non_admin_account(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let to_addresses = vector[user1, user2];
        let user1_dividend = 100;
        let user2_dividend = 200;
        let dividends = vector[user1_dividend, user2_dividend];
        let asset_types = vector[fund::constants::token(), fund::constants::stable_coin()];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);
        let supply = 1000;

        mint_token(token_account, stable_coin_id, vector[agent], vector[supply]);
        assert!(get_supply(stable_coin_id) == option::some((supply as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == supply, 0);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        share_dividend(issuer, token_id, to_addresses, dividends, asset_types, fund::constants::usdt());
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 65545, location = fund::fund)]
    fun test_share_dividend_with_different_number_of_arguements(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let to_addresses = vector[user1, user2];
        let user1_dividend = 100;
        let dividends = vector[user1_dividend];
        let asset_types = vector[fund::constants::token(), fund::constants::stable_coin()];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);
        let supply = 1000;

        mint_token(token_account, stable_coin_id, vector[agent], vector[supply]);
        assert!(get_supply(stable_coin_id) == option::some((supply as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == supply, 0);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        share_dividend(fund_account, token_id, to_addresses, dividends, asset_types, fund::constants::usdt());
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    fun test_distribute_and_burn(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let investors = vector[user1, user2];
        let user1_amount = 100;
        let user2_amount = 200;
        let amounts = vector[user1_amount, user2_amount];
        let user1_token = 300;
        let user2_token = 400;
        let agent_stable_coins = user1_amount + user2_amount;
        let tokens = vector[user1_token, user2_token];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);

        mint_token(token_account, stable_coin_id, vector[agent], vector[agent_stable_coins]);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);
        assert!(get_supply(stable_coin_id) == option::some((agent_stable_coins as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == agent_stable_coins, 0);

        // For test case same token is minted and treated as stable coin
        mint_token(token_account, token_id, investors, tokens);
        let supply = ((user1_token + user2_token) as u128);
        assert!(get_supply(token_id) == option::some(supply), 0);
        assert!(get_balance(token_id, user1) == user1_token, 0);
        assert!(get_balance(token_id, user2) == user2_token, 0);

        // Updating usdt address
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        distribute_and_burn(fund_account, token_id, investors, amounts, tokens, fund::constants::usdt());

        // Token balance must be 0 and supply become 0
        assert!(get_balance(token_id, user1) == 0, 0);
        assert!(get_balance(token_id, user2) == 0, 0);
        assert!(get_supply(token_id) == option::some(0), 0);

        // Stable coins must be transferred and stable coin supplt remains same
        assert!(get_balance(stable_coin_id, agent) == agent_stable_coins - user1_amount - user2_amount, 0);
        assert!(get_balance(stable_coin_id, user1) == user1_amount, 0);
        assert!(get_balance(stable_coin_id, user2) == user2_amount, 0);
        assert!(get_supply(stable_coin_id) == option::some((agent_stable_coins as u128)), 0);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 327685, location = fund::fund)]
    fun test_distribute_and_burn_with_non_admin_account(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let investors = vector[user1, user2];
        let user1_amount = 100;
        let user2_amount = 200;
        let amounts = vector[user1_amount, user2_amount];
        let user1_token = 300;
        let user2_token = 400;
        let agent_stable_coins = user1_amount + user2_amount;
        let tokens = vector[user1_token, user2_token];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);

        mint_token(token_account, stable_coin_id, vector[agent], vector[agent_stable_coins]);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);
        assert!(get_supply(stable_coin_id) == option::some((agent_stable_coins as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == agent_stable_coins, 0);

        // For test case same token is minted and treated as stable coin
        mint_token(token_account, token_id, investors, tokens);
        let supply = ((user1_token + user2_token) as u128);
        assert!(get_supply(token_id) == option::some(supply), 0);
        assert!(get_balance(token_id, user1) == user1_token, 0);
        assert!(get_balance(token_id, user2) == user2_token, 0);

        // Updating usdt address
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        distribute_and_burn(issuer, token_id, investors, amounts, tokens, fund::constants::usdt());
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
        user1 = @0x7,
        user2 = @0x8,
    )]
    #[expected_failure(abort_code = 65545, location = fund::fund)]
    fun test_distribute_and_burn_with_different_number_of_arguements(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
        user1: address,
        user2: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        let investors = vector[user1, user2];
        let user1_amount = 100;
        let user2_amount = 200;
        let amounts = vector[user1_amount];
        let user1_token = 300;
        let user2_token = 400;
        let agent_stable_coins = user1_amount + user2_amount;
        let tokens = vector[user1_token, user2_token];

        // Creating stable coin
        let stable_coin_id = string::utf8(b"usdt");
        create_stable_coin(token_account, issuer_addr, transfer_agent, tokenization_agent, stable_coin_id);

        mint_token(token_account, stable_coin_id, vector[agent], vector[agent_stable_coins]);
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);
        assert!(get_supply(stable_coin_id) == option::some((agent_stable_coins as u128)), 0);
        assert!(get_balance(stable_coin_id, agent) == agent_stable_coins, 0);

        // For test case same token is minted and treated as stable coin
        mint_token(token_account, token_id, investors, tokens);
        let supply = ((user1_token + user2_token) as u128);
        assert!(get_supply(token_id) == option::some(supply), 0);
        assert!(get_balance(token_id, user1) == user1_token, 0);
        assert!(get_balance(token_id, user2) == user2_token, 0);

        // Updating usdt address
        let metadata = get_metadata(stable_coin_id);
        let stable_coin = object_address<Metadata>(&metadata);
        update_stable_coin_address(fund_account, fund::constants::usdt(), stable_coin);

        distribute_and_burn(fund_account, token_id, investors, amounts, tokens, fund::constants::usdt());
    }

    #[test(account = @fund)]
    fun test_init_maintainers(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        initialize_event_store(account);
        init_maintainers(account);

        // Ensuring the admin is correct or not
        assert!(get_admin() == addr, 0);
    }

    #[test(account = @fund)]
    #[expected_failure]
    fun test_init_maintainers_without_event(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        // Will fail as event is not initialized
        init_maintainers(account);
    }

    #[test(account = @fund)]
    fun test_update_admin(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        initialize_event_store(account);
        init_maintainers(account);

        // Ensuring the admin is correct or not
        assert!(get_admin() == addr, 0);

        let new_admin = @0x1;
        update_admin(account, new_admin);

        // Ensuring the admin is correct or not
        assert!(get_admin() == new_admin, 0);
    }

    #[test(account = @fund, non_admin = @0x1)]
    #[expected_failure(abort_code = 393222, location = fund::maintainer)]
    fun test_update_admin_with_non_admin_account(account: &signer, non_admin: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        initialize_event_store(account);
        init_maintainers(account);

        // Ensuring the admin is correct or not
        assert!(get_admin() == addr, 0);

        let new_admin = @0x1;
        update_admin(non_admin, new_admin);
    }

    #[test(account = @fund)]
    fun test_init_agent_roles(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        initialize_event_store(account);
        init_agent_roles(account);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    fun test_remove_agent(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(has_agent_rights(token_id, agent), 0);
        assert!(get_agent_by_id(token_id) == agent, 0);

        remove_agent(fund_account, token_id);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    #[expected_failure(abort_code = 393222, location = fund::maintainer)]
    fun test_remove_agent_by_non_admin_account(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(has_agent_rights(token_id, agent), 0);
        assert!(get_agent_by_id(token_id) == agent, 0);

        remove_agent(issuer, token_id);
    }

    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    fun test_add_agent(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(has_agent_rights(token_id, agent), 0);
        assert!(get_agent_by_id(token_id) == agent, 0);

        // Agent removal
        remove_agent(fund_account, token_id);

        // Agent addition
        add_agent(fund_account, token_id, issuer_addr);
        assert!(has_agent_rights(token_id, issuer_addr), 0);
        assert!(get_agent_by_id(token_id) == issuer_addr, 0);
    }
    #[test(
        token_account = @fungible_tokens,
        fund_account = @fund,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        dai = @0x4,
        usdt = @0x5,
        usdc = @0x6,
    )]
    #[expected_failure(abort_code = 65537, location = aptos_std::simple_map)]
    fun test_add_agent_directly_without_remove(
        token_account: &signer,
        fund_account: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let agent = signer::address_of(fund_account);
        let token_id = string::utf8(b"unique");
        set_time_has_started_for_testing(issuer);
        let issuer_addr = signer::address_of(issuer);
        init_and_create(
            token_account,
            fund_account,
            issuer_addr,
            transfer_agent,
            tokenization_agent,
            dai,
            usdt,
            usdc,
            token_id
        );

        assert!(has_agent_rights(token_id, agent), 0);
        assert!(get_agent_by_id(token_id) == agent, 0);

        // Agent addition
        add_agent(fund_account, token_id, issuer_addr);
        assert!(has_agent_rights(token_id, issuer_addr), 0);
        assert!(get_agent_by_id(token_id) == issuer_addr, 0);
    }
}

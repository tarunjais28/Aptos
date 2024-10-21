#[test_only]
module base_token_contract::tests {
    use std::vector::{Self, is_empty};
    use std::unit_test;
    use std::signer;
    use base_token_contract::asset_coin::{init, create_token, mint_token, burn_token, transfer_token,
        freeze_accounts, unfreeze_accounts, get_symbol, get_decimals, get_supply, get_max_supply,
        get_circulating_supply};
    use base_token_contract::maintainers::{get_sub_admins, get_admin, add_sub_admins, remove_sub_admins, update_admin};
    use base_token_contract::resource::{get_balance, partial_freeze, get_frozen_tokens, partial_unfreeze};
    use base_token_contract::roles::{add_issuer, add_tokenization_agent, add_transfer_agent, has_issuer_rights,
    has_transfer_agent_rights, has_tokenization_agent_rights, remove_issuer, remove_tokenization_agent,
    remove_transfer_agent};
    use std::string;
    use std::option;
    use base_token_contract::agents::{grant_access_to_agent, ungrant_access_to_agent, has_mint_rights,
        get_roles_for_address};
    use std::string::{String};
    use utils::i128;
    use utils::error;
    use utils::i128::I128;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    fun get_accounts(n: u64): vector<signer> {
        unit_test::create_signers_for_testing(n)
    }

    fun init_and_add_sub_admin(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        init(account);

        let addresses = vector[addr];

        // Adding sub_admins
        add_sub_admins(account, addresses);
    }

    public fun init_and_create_token(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        name: String,
    ) {
        let id = string::utf8(b"unique");
        let symbol = string::utf8(b"bud");
        let icon_uri = string::utf8(b"http://www.example.com/favicon.ico");
        let project_uri = string::utf8(b"http://www.example.com");

        init_and_add_sub_admin(creator);

        // Create Token
        create_token(
            creator,
            id,
            name,
            symbol,
            icon_uri,
            project_uri,
            issuer,
            tokenization_agent,
            transfer_agent,
        );
    }

    fun init_and_mint_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user: &signer,
        token: String,
        amount: u64,
    ) {
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);
        let user_addr = signer::address_of(user);
        aptos_framework::account::create_account_for_test(user_addr);

        mint_token(issuer, token, vector[user_addr], vector[amount]);
    }

    #[test(
        account = @base_token_contract
    )]
    entry fun test_init(account: &signer) {
        aptos_framework::account::create_account_for_test(@base_token_contract);
        init(account);

        assert!(is_empty(&get_sub_admins()), 0);
        assert!(get_admin() == @base_token_contract, 0);
    }

    #[test(
        account = @base_token_contract
    )]
    entry fun test_update_admin(account: &signer) {
        let accounts = get_accounts(2);
        let account_1 = vector::pop_back(&mut accounts);
        let addr_0 = signer::address_of(account);
        let addr_1 = signer::address_of(&account_1);
        aptos_framework::account::create_account_for_test(addr_0);
        init(account);

        assert!(get_admin() == addr_0, 0);

        // Updating admin
        update_admin(account, addr_1);
        assert!(get_admin() == addr_1, 0);
    }

    #[test(
        account = @base_token_contract
    )]
    #[expected_failure]
    entry fun test_update_admin_with_other_account(account: &signer) {
        let accounts = get_accounts(2);
        let account_1 = vector::pop_back(&mut accounts);
        let addr_0 = signer::address_of(account);
        let addr_1 = signer::address_of(&account_1);
        aptos_framework::account::create_account_for_test(addr_0);
        init(account);

        // Updating admin should fail as caller is not admin
        update_admin(&account_1, addr_1);
    }

    #[test(
        account = @base_token_contract
    )]
    entry fun test_manage_sub_admins(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        init(account);

        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let address_1 = signer::address_of(&account_0);
        let address_2 = signer::address_of(&account_1);

        let addresses = vector[address_1, address_2];

        // Adding sub_admins
        add_sub_admins(account, addresses);

        let sub_admins = get_sub_admins();
        assert!(!is_empty(&sub_admins), 0);
        assert!(get_admin() == addr, 0);
        assert!(vector::contains(&sub_admins, &address_1), 0);
        assert!(vector::contains(&sub_admins, &address_2), 0);

        // Removing sub_admins
        remove_sub_admins(account, addresses);
        sub_admins = get_sub_admins();
        assert!(!vector::contains(&sub_admins, &address_1), 0);
        assert!(!vector::contains(&sub_admins, &address_2), 0);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        new_issuer = @0x4
    )]
    entry fun test_add_issuer(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        new_issuer: &signer,
    ) {
        let token = string::utf8(b"budz");
        let new_issuer_addr = signer::address_of(new_issuer);

        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Adding issuer
        add_issuer(creator, token, new_issuer_addr);

        // Checking issuer rights
        assert!(has_issuer_rights(token, new_issuer_addr), error::no_issue_rights());
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        new_transfer_agent = @0x4
    )]
    entry fun test_add_transfer_agent(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        new_transfer_agent: &signer,
    ) {
        let token = string::utf8(b"budz");
        let new_transfer_agent_addr = signer::address_of(new_transfer_agent);

        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Adding transfer agent
        add_transfer_agent(creator, token, new_transfer_agent_addr);

        // Checking transfer agent rights
        assert!(has_transfer_agent_rights(token, new_transfer_agent_addr), error::no_transfer_agent_rights());
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        new_tokenization_agent = @0x4
    )]
    entry fun test_add_tokenization_agent(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        new_tokenization_agent: &signer,
    ) {
        let token = string::utf8(b"budz");
        let new_tokenization_agent_addr = signer::address_of(new_tokenization_agent);

        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Adding tokenization agent
        add_tokenization_agent(creator, token, new_tokenization_agent_addr);

        // Checking tokenization agent rights
        assert!(has_tokenization_agent_rights(
                token,
                new_tokenization_agent_addr
            ),
            error::no_tokenization_agent_rights()
        );
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
    )]
    #[expected_failure]
    entry fun test_remove_issuer(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
    ) {
        let token = string::utf8(b"budz");
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Removing issuer
        remove_issuer(creator, token);

        // Should fail as issuer rights revoked
        assert!(has_issuer_rights(token, issuer), error::no_issue_rights());
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
    )]
    #[expected_failure]
    entry fun test_remove_transfer_agent(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
    ) {
        let token = string::utf8(b"budz");
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Removing transfer agent
        remove_transfer_agent(creator, token);

        // Should fail as transfer agent rights revoked
        assert!(has_transfer_agent_rights(token, transfer_agent), error::no_transfer_agent_rights());
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
    )]
    #[expected_failure]
    entry fun test_remove_tokenization_agent(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
    ) {
        let token = string::utf8(b"budz");
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, token);

        // Removing tokenization agent
        remove_tokenization_agent(creator, token);

        // Should fail as tokenization agent rights revoked
        assert!(has_tokenization_agent_rights(token, tokenization_agent), error::no_tokenization_agent_rights());
    }

    #[test(
        account = @base_token_contract,
    )]
    #[expected_failure]
    entry fun test_has_issuer_rights_with_other_address(account: &signer) {
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let issuer = signer::address_of(&account_0);
        let token = string::utf8(b"budz");

        init_and_add_sub_admin(account);

        // Adding issuer
        add_issuer(account, token, issuer);

        // Checking issuer rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_issuer_rights(token, other_addr), error::no_issue_rights());
    }

    #[test(
        account = @base_token_contract,
    )]
    #[expected_failure]
    entry fun test_has_transfer_agent_rights_with_other_address(account: &signer) {
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);
        let token = string::utf8(b"budz");

        init_and_add_sub_admin(account);

        // Adding transfer agent
        add_transfer_agent(account, token, transfer_agent);

        // Checking transfer agent rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_transfer_agent_rights(token, other_addr), error::no_transfer_agent_rights());
    }

    #[test(
        account = @base_token_contract,
    )]
    #[expected_failure]
    entry fun test_has_tokenization_agent_rights_with_other_address(account: &signer) {
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);
        let token = string::utf8(b"budz");

        init_and_add_sub_admin(account);

        // Adding tokenization agent
        add_tokenization_agent(account, token, transfer_agent);

        // Checking tokenization agent rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_tokenization_agent_rights(token, other_addr), error::no_tokenization_agent_rights());
    }

    #[test(creator = @base_token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3)]
    entry fun test_token_create(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
    ) {
        let name = string::utf8(b"budz");
        let symbol = string::utf8(b"bud");
        let decimals = 0;
        let supply = option::some(0);
        let token = string::utf8(b"budz");

        // This will pass only when `base_token_contract` account will be the creator
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, name);
        
        assert!(get_symbol(token) == symbol, 0);
        assert!(get_decimals(token) == decimals, 0);
        assert!(get_supply(token) == supply, 0);
        assert!(get_circulating_supply(token) == i128::from_u128(0), 0);
        assert!(get_max_supply(token) == option::none(), 0);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        second_creator = @0x4,
    )]
    entry fun test_token_create_second_time(
        creator: &signer,
        issuer: address,
        transfer_agent: address,
        tokenization_agent: address,
        second_creator: &signer,
    ) {
        let name = string::utf8(b"dummy");
        let symbol = string::utf8(b"dum");
        let icon_uri = string::utf8(b"http://www.example.com/favicon.ico");
        let project_uri = string::utf8(b"http://www.example.com");

        // This will pass only when `base_token_contract` account will be the creator
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent, name);

        let id = string::utf8(b"unique_1");
        let sec_addr = signer::address_of(second_creator);
        let name = string::utf8(b"dummy_1");

        // Adding sub_admins
        add_sub_admins(creator, vector[sec_addr]);

        // Create Token
        create_token(
            second_creator,
            id,
            name,
            symbol,
            icon_uri,
            project_uri,
            issuer,
            tokenization_agent,
            transfer_agent,
        );
    }

    #[test(
        account = @base_token_contract,
    )]
    #[expected_failure]
    entry fun test_grant_ungrant_agent_access(account: &signer) {
        let to_address = signer::address_of(&get_account());
        init_and_add_sub_admin(account);
        let token = string::utf8(b"budz");

        // Granting access
        grant_access_to_agent(account, token, to_address,vector[1]);

        assert!(get_roles_for_address(token, to_address) == vector[string::utf8(b"admin")], 1);

        // checking if access has assigned
        has_mint_rights(token, to_address);

        // Granting access to same addr agin will result in error
        grant_access_to_agent(account, token, to_address,vector[1]);

        // Ungranting access
        ungrant_access_to_agent(account, token, to_address, vector[1]);

        // checking if access have been unassigned
        has_mint_rights(token, to_address);
    }

    #[test(
        account = @base_token_contract,
    )]
    #[expected_failure]
    entry fun test_get_roles_for_address(account: &signer) {
        let to_address = signer::address_of(&get_account());
        init_and_add_sub_admin(account);
        let token = string::utf8(b"budz");

        // List will be empty as no access provided
        assert!(get_roles_for_address(token, to_address) == vector::empty<String>(), 1);

        // Granting access
        grant_access_to_agent(
            account,
            token,
            to_address,
            vector[
                    utils::constants::get_admin(),
                    utils::constants::get_mint(),
                    utils::constants::get_burn(),
                    utils::constants::get_transer(),
                    utils::constants::get_force_transer(),
                    utils::constants::get_freeze(),
                    utils::constants::get_unfreeze(),
                    utils::constants::get_deposit(),
                    utils::constants::get_delete(),
                    utils::constants::get_unspecified(),
                    utils::constants::get_withdraw(),
            ]
        );

        assert!(
            get_roles_for_address(
                token,
                to_address
            ) == vector[
                    string::utf8(b"admin"),
                    string::utf8(b"mint"),
                    string::utf8(b"burn"),
                    string::utf8(b"transfer"),
                    string::utf8(b"force_transfer"),
                    string::utf8(b"freeze"),
                    string::utf8(b"unfreeze"),
                    string::utf8(b"deposit"),
                    string::utf8(b"delete"),
                    string::utf8(b"unspecified"),
                    string::utf8(b"withdraw"),
                    string::utf8(b"unknown"),
                ],
            1
        );
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user1 = @0x4,
        user2 = @0x5,
        user3 = @0x6,
    )]
    #[expected_failure(abort_code = 65545, location = base_token_contract::asset_coin)]
    entry fun test_mint_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user1: &signer,
        user2: &signer,
        user3: &signer,
    ) {
        let token = string::utf8(b"budz");
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);

        assert!(get_circulating_supply(token) == i128::from_u128(0), 0);

        // testing batch mints
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let users = vector[user1_addr, user2_addr, user3_addr];
        let amount1 = 100;
        let amount2 = 200;
        let amount3 = 300;
        let total = amount1 + amount2 + amount3;
        let amounts = vector[amount1, amount2, amount3];
        mint_token(issuer, token, users, amounts);

        assert!(get_balance(token, user1_addr) == amount1, 0);
        assert!(get_balance(token, user2_addr) == amount2, 0);
        assert!(get_balance(token, user3_addr) == amount3, 0);
        assert!(get_circulating_supply(token) == i128::from_u128((total as u128)), 0);

        // test with unequal number of arguements
        amounts = vector[amount1, amount2];
        // fails as number of arguements are unequal
        mint_token(issuer, token, users, amounts);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user1 = @0x4,
        user2 = @0x5,
        user3 = @0x6,
    )]
    #[expected_failure(abort_code = 65545, location = base_token_contract::asset_coin)]
    entry fun test_burn_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user1: &signer,
        user2: &signer,
        user3: &signer,
    ) {
        let token = string::utf8(b"budz");
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);

        // testing batch burn
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let users = vector[user1_addr, user2_addr, user3_addr];
        let mint_amount1 = 100;
        let mint_amount2 = 200;
        let mint_amount3 = 300;
        let total_mint = mint_amount1 + mint_amount2 + mint_amount3;
        let mint_amounts = vector[mint_amount1, mint_amount2, mint_amount3];
        mint_token(issuer, token, users, mint_amounts);
        assert!(
            get_circulating_supply(token) == i128::from_u128((total_mint as u128)),
            0
        );

        let burn_amount1 = 50;
        let burn_amount2 = 100;
        let burn_amount3 = 150;
        let total_burn = burn_amount1 + burn_amount2 + burn_amount3;
        let burn_amounts = vector[burn_amount1, burn_amount2, burn_amount3];

        burn_token(issuer, token, users, burn_amounts);

        assert!(get_balance(token, user1_addr) == mint_amount1 - burn_amount1, 0);
        assert!(get_balance(token, user2_addr) == mint_amount2 - burn_amount2, 0);
        assert!(get_balance(token, user3_addr) == mint_amount3 - burn_amount3, 0);
        assert!(
            get_circulating_supply(token) == i128::from_u128(((total_mint - total_burn) as u128)),
            0
        );

        // test with unequal number of arguements
        burn_amounts = vector[burn_amount1, burn_amount2];
        // fails as number of arguements are unequal
        burn_token(issuer, token, users, burn_amounts);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
        receiver = @0x5,
    )]
    entry fun test_transfer_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user: &signer,
        receiver: &signer,
    ) {
        let token = string::utf8(b"budz");
        let init_mint_amt = 500;
        init_and_mint_token(creator, issuer, transfer_agent, tokenization_agent, user, token, init_mint_amt);
        let amount = 200;
        let to = signer::address_of(receiver);
        aptos_framework::account::create_account_for_test(to);

        assert!(get_balance(token, to) == 0, 0);
        transfer_token(user, token, to, amount);
        assert!(get_balance(token, to) == amount, 0);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    #[expected_failure(abort_code = 327683, location = aptos_framework::fungible_asset)]
    entry fun test_freeze_accounts(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user: &signer,
    ) {
        let issuer_addr = signer::address_of(issuer);
        let token = string::utf8(b"budz");
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);
        let user_addr = signer::address_of(user);
        aptos_framework::account::create_account_for_test(user_addr);
        let amount = 500;
        let users = vector[user_addr];

        // Freeze user account
        freeze_accounts(issuer, token, users);

        // Mint will fail as account is freezed
        mint_token(issuer, token, users, vector[amount]);

        // Transfer will fail as account is freezed
        mint_token(issuer, token, vector[issuer_addr], vector[amount]);
        transfer_token(issuer, token, user_addr, amount);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    entry fun test_unfreeze_accounts(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user: &signer,
    ) {
        let token = string::utf8(b"budz");
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);
        let user_addr = signer::address_of(user);
        let issuer_addr = signer::address_of(issuer);
        let amount = 500;
        let users = vector[user_addr];

        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(issuer_addr);

        // Freeze user account
        freeze_accounts(issuer, token, users);
        unfreeze_accounts(issuer, token, users);

        // Mint and Transfer will pass as account is unfreezed
        mint_token(issuer, token, users, vector[amount]);
        transfer_token(user, token, issuer_addr, amount);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user1 = @0x4,
        user2 = @0x5,
        user3 = @0x6,
    )]
    #[expected_failure(abort_code = 589864, location = base_token_contract::resource)]
    entry fun test_partial_freeze(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user1: &signer,
        user2: &signer,
        user3: &signer,
    ) {
        let token = string::utf8(b"budz");
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let users = vector[user1_addr, user2_addr, user3_addr];
        let mint_amount1 = 500;
        let mint_amount2 = 600;
        let mint_amount3 = 700;
        let tot_mint_amt = mint_amount1 + mint_amount2 + mint_amount3;
        let mint_amounts = vector[mint_amount1, mint_amount2, mint_amount3];
        let bal1 = 100;
        let bal2 = 200;
        let bal3 = 300;
        let tot_bal = bal1 + bal2 + bal3;
        let frozen_bal_u128 = (tot_bal as u128);
        let bals = vector[bal1, bal2, bal3];
        let first_burn = 200;
        let second_burn = 250;

        // mint tokens
        mint_token(issuer, token, users, mint_amounts);

        // Freeze user account
        partial_freeze(issuer, token, users, bals);
        assert!(get_frozen_tokens(token) == frozen_bal_u128, 0);
        let circulating_supply: I128 = i128::new((tot_mint_amt as u128), false);

        assert!(get_circulating_supply(token) == circulating_supply, 0);

        burn_token(issuer, token, vector[user1_addr], vector[first_burn]);

        assert!(get_balance(token, user1_addr) == mint_amount1 - first_burn, 0);

        // Burn will fail, as 100 coins are patially frozen
        burn_token(issuer, token, vector[user1_addr], vector[second_burn]);
    }

    #[test(
        creator = @base_token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user1 = @0x4,
        user2 = @0x5,
        user3 = @0x6,
    )]
    entry fun test_partial_unfreeze(
        creator: &signer,
        issuer: &signer,
        transfer_agent: address,
        tokenization_agent: address,
        user1: &signer,
        user2: &signer,
        user3: &signer,
    ) {
        let token = string::utf8(b"budz");
        let issuer_addr = signer::address_of(issuer);
        init_and_create_token(creator, issuer_addr, transfer_agent, tokenization_agent, token);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let users = vector[user1_addr, user2_addr, user3_addr];
        let mint_amount1 = 500;
        let mint_amount2 = 600;
        let mint_amount3 = 700;
        // let tot_mint_amt = mint_amount1 + mint_amount2 + mint_amount3;
        let mint_amounts = vector[mint_amount1, mint_amount2, mint_amount3];
        let bal1 = 100;
        let bal2 = 200;
        let bal3 = 300;
        let tot_bal = bal1 + bal2 + bal3;
        let frozen_bal_u128 = (tot_bal as u128);
        let bals = vector[bal1, bal2, bal3];
        let first_burn = 200;
        let second_burn = 250;

        // mint tokens
        mint_token(issuer, token, users, mint_amounts);

        // Partially freeze account
        partial_freeze(issuer, token, users, bals);
        assert!(get_frozen_tokens(token) == frozen_bal_u128, 0);

        // Burn will Pass, after burn 300 coins left
        burn_token(issuer, token ,vector[user1_addr], vector[first_burn]);

        assert!(get_balance(token, user1_addr) == mint_amount1 - first_burn, 0);

        // Partially unfreeze account
        partial_unfreeze(issuer, token, users, bals);
        assert!(get_frozen_tokens(token) == 0u128, 0);

        // Burn will pass patially unfrozen
        burn_token(issuer, token, vector[user1_addr], vector[second_burn]);
    }
}

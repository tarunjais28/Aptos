#[test_only]
module token_contract::tests {
    use std::vector::{Self, is_empty};
    use std::unit_test;
    use std::signer;
    use token_contract::asset_coin::{init, create_mint_request, cancel_mint_request, check_proposal_created,
        check_proposal_cancelled, enable_multisig, add_signers, remove_signers, approve_mint_request,
        check_proposal_approved, create_token, AssetCoin, register_account, cancel_mint_approval, mint_token,
        get_balance, burn_token, get_country_codes, remove_country_code, add_country_code, update_token_limit,
        get_token_limit, transfer_token, freeze_accounts, unfreeze_accounts, partial_freeze, partial_unfreeze,
        get_frozen_tokens, get_circulating_supply, get_supply};
    use token_contract::maintainers::{get_sub_admins, get_admin, add_sub_admins, remove_sub_admins, update_admin};
    use token_contract::resource::{get_resource_address, is_multisig_enabled, get_signers};
    use token_contract::roles::{add_issuer, add_tokenization_agent, add_transfer_agent, has_issuer_rights,
        has_transfer_agent_rights, has_tokenization_agent_rights, remove_issuer, remove_tokenization_agent,
        remove_transfer_agent};
    use aptos_framework::coin;
    use std::string;
    use std::option;
    use token_contract::agents::{grant_access_to_agent, ungrant_access_to_agent, has_mint_rights};
    use token_contract::whitelist::{add, remove, get_country_code_by_addres};
    use utils::i128;

    //:!:>constants
    const ERR_TEST_CASE_FAILED: u64 = 0;
    const ERR_NO_ISSUER_RIGHTS: u64 = 1;
    const ERR_NO_TRANASFER_AGENT_RIGHTS: u64 = 2;
    const ERR_NO_TOKENIZATION_AGENT_RIGHTS: u64 = 3;
    //:!:>constants

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    fun get_accounts(n: u64): vector<signer> {
        unit_test::create_signers_for_testing(n)
    }

    fun init_and_add_sub_admin(account: &signer): address {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        init(account);

        let addresses = vector[addr];

        let res_addr = get_resource_address(addr);

        // Adding sub_admins
        add_sub_admins(account, res_addr, addresses);

        res_addr
    }

    fun init_and_create_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
    ): address {
        let issuer = signer::address_of(issuer);
        let transfer_agent = signer::address_of(transfer_agent);
        let tokenization_agent = signer::address_of(tokenization_agent);
        let id = string::utf8(b"unique");
        let name = string::utf8(b"budz");
        let symbol = string::utf8(b"bud");
        let token_limit = 1000;
        let country_codes = vector[1, 91];

        let res_addr = init_and_add_sub_admin(creator);

        // Adding issuer
        add_issuer(creator, res_addr, issuer);

        // Create Token
        create_token(
            creator,
            res_addr,
            id,
            name,
            symbol,
            token_limit,
            country_codes,
            issuer,
            tokenization_agent,
            transfer_agent,
        );

        res_addr
    }

    fun init_and_mint_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ): address {
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let amount = 500;
        let user_addr = signer::address_of(user);
        let creator_addr = signer::address_of(creator);
        aptos_framework::account::create_account_for_test(user_addr);
        register_account(user, res_addr);

        mint_token(issuer, res_addr, creator_addr, vector[user_addr], vector[amount]);

        res_addr
    }

    #[test]
    entry fun test_init() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        init(&account);

        let res_addr = get_resource_address(addr);

        assert!(is_empty(&get_sub_admins(res_addr)), 0);
        assert!(get_admin(res_addr) == addr, 0);
    }

    #[test]
    entry fun test_update_admin() {
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let addr_0 = signer::address_of(&account_0);
        let addr_1 = signer::address_of(&account_1);
        aptos_framework::account::create_account_for_test(addr_0);
        init(&account_0);

        let res_addr = get_resource_address(addr_0);

        assert!(get_admin(res_addr) == addr_0, 0);

        // Updating admin
        update_admin(&account_0, res_addr, addr_1);
        assert!(get_admin(res_addr) == addr_1, 0);
    }

    #[test]
    #[expected_failure]
    entry fun test_update_admin_with_other_account() {
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let addr_0 = signer::address_of(&account_0);
        let addr_1 = signer::address_of(&account_1);
        aptos_framework::account::create_account_for_test(addr_0);
        init(&account_0);

        let res_addr = get_resource_address(addr_0);

        // Updating admin should fail as caller is not admin
        update_admin(&account_1, res_addr, addr_1);
    }

    #[test]
    entry fun test_manage_sub_admins() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        init(&account);

        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let address_1 = signer::address_of(&account_0);
        let address_2 = signer::address_of(&account_1);

        let addresses = vector[address_1, address_2];

        let res_addr = get_resource_address(addr);

        // Adding sub_admins
        add_sub_admins(&account, res_addr, addresses);

        let sub_admins = get_sub_admins(res_addr);
        assert!(!is_empty(&sub_admins), 0);
        assert!(get_admin(res_addr) == addr, 0);
        assert!(vector::contains(&sub_admins, &address_1), 0);
        assert!(vector::contains(&sub_admins, &address_2), 0);

        // Removing sub_admins
        remove_sub_admins(&account, res_addr, addresses);
        sub_admins = get_sub_admins(res_addr);
        assert!(!vector::contains(&sub_admins, &address_1), 0);
        assert!(!vector::contains(&sub_admins, &address_2), 0);
    }

    #[test]
    entry fun test_add_issuer() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let issuer = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding issuer
        add_issuer(&account, res_addr, issuer);

        // Checking issuer rights
        assert!(has_issuer_rights(res_addr, issuer), ERR_NO_ISSUER_RIGHTS);
    }

    #[test]
    entry fun test_add_transfer_agent() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding transfer agent
        add_transfer_agent(&account, res_addr, transfer_agent);

        // Checking transfer agent rights
        assert!(has_transfer_agent_rights(res_addr, transfer_agent), ERR_NO_TRANASFER_AGENT_RIGHTS);
    }

    #[test]
    entry fun test_add_tokenization_agent() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding tokenization agent
        add_tokenization_agent(&account, res_addr, transfer_agent);

        // Checking tokenization agent rights
        assert!(has_tokenization_agent_rights(res_addr, transfer_agent), ERR_NO_TOKENIZATION_AGENT_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_remove_issuer() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let issuer = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding issuer
        add_issuer(&account, res_addr, issuer);

        // Removing issuer
        remove_issuer(&account, res_addr);

        // Should fail as issuer rights revoked
        assert!(has_issuer_rights(res_addr, issuer), ERR_NO_ISSUER_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_remove_transfer_agent() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding transfer agent
        add_transfer_agent(&account, res_addr, transfer_agent);

        // Removing transfer agent
        remove_transfer_agent(&account, res_addr);

        // Should fail as transfer agent rights revoked
        assert!(has_transfer_agent_rights(res_addr, transfer_agent), ERR_NO_TRANASFER_AGENT_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_remove_tokenization_agent() {
        let account = get_account();
        let accounts = get_accounts(1);
        let account_0 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding tokenization agent
        add_tokenization_agent(&account, res_addr, transfer_agent);

        // Removing tokenization agent
        remove_tokenization_agent(&account, res_addr);

        // Should fail as tokenization agent rights revoked
        assert!(has_tokenization_agent_rights(res_addr, transfer_agent), ERR_NO_TOKENIZATION_AGENT_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_has_issuer_rights_with_other_address() {
        let account = get_account();
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let issuer = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding issuer
        add_issuer(&account, res_addr, issuer);

        // Checking issuer rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_issuer_rights(res_addr, other_addr), ERR_NO_ISSUER_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_has_transfer_agent_rights_with_other_address() {
        let account = get_account();
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding transfer agent
        add_transfer_agent(&account, res_addr, transfer_agent);

        // Checking transfer agent rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_transfer_agent_rights(res_addr, other_addr), ERR_NO_TRANASFER_AGENT_RIGHTS);
    }

    #[test]
    #[expected_failure]
    entry fun test_has_tokenization_agent_rights_with_other_address() {
        let account = get_account();
        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let transfer_agent = signer::address_of(&account_0);

        let res_addr = init_and_add_sub_admin(&account);

        // Adding tokenization agent
        add_tokenization_agent(&account, res_addr, transfer_agent);

        // Checking tokenization agent rights
        let other_addr = signer::address_of(&account_1);
        assert!(has_tokenization_agent_rights(res_addr, other_addr), ERR_NO_TOKENIZATION_AGENT_RIGHTS);
    }

    #[test]
    entry fun test_enable_multisig() {
        let account = get_account();
        let res_addr = init_and_add_sub_admin(&account);
        enable_multisig(&account,res_addr,vector::empty(),0);
        is_multisig_enabled(res_addr);
    }

    #[test]
    entry fun test_add_remove_signers() {
        let account = get_account();
        let res_addr = init_and_add_sub_admin(&account);
        enable_multisig(&account,res_addr,vector::empty(),0);
        is_multisig_enabled(res_addr);

        let accounts = get_accounts(2);
        let account_0 = vector::pop_back(&mut accounts);
        let account_1 = vector::pop_back(&mut accounts);
        let address_1 = signer::address_of(&account_0);
        let address_2 = signer::address_of(&account_1);

        let addresses = vector[address_1, address_2];

        // add signers
        add_signers(&account,res_addr,addresses);
        let signers=get_signers(res_addr);
        assert!(vector::length(&signers)==2, ERR_TEST_CASE_FAILED);

        // remove signers
        remove_signers(&account,res_addr,addresses);
        let signers=get_signers(res_addr);
        assert!(vector::length(&signers)==0, ERR_TEST_CASE_FAILED);
    }

    #[test]
    entry fun test_add_proposal() {
        let account = get_account();
        let addr = signer::address_of(&account);
        let to_address = signer::address_of(&get_account());
        let amount:u64=100000000;

        let res_addr = init_and_add_sub_admin(&account);

        enable_multisig(&account,res_addr,vector::empty(),0);
        is_multisig_enabled(res_addr);

        // Adding mint request
        create_mint_request(&account, res_addr,to_address,amount);

        // checking proposal created
        check_proposal_created(addr);

    }

    #[test]
    entry fun test_cancel_proposal() {
        let account = get_account();
        let addr = signer::address_of(&account);
        let to_address = signer::address_of(&get_account());
        let amount:u64=100000000;

        let res_addr = init_and_add_sub_admin(&account);

        enable_multisig(&account,res_addr,vector::empty(),0);
        is_multisig_enabled(res_addr);

        // Adding mint request
        create_mint_request(&account, res_addr,to_address,amount);

        // checking proposal created
        check_proposal_created(addr);

        // cancel proposal
        cancel_mint_request(&account,res_addr,0);

        //checking proposal is cancelled
        check_proposal_cancelled(addr,0);
    }

    #[test]
    entry fun test_approve_proposal() {
        let account = get_account();
        let addr = signer::address_of(&account);
        let to_address = signer::address_of(&get_account());
        let amount:u64=100000000;

        let res_addr = init_and_add_sub_admin(&account);


        let signer = vector[addr];
        enable_multisig(&account,res_addr,signer,5);
        is_multisig_enabled(res_addr);

        // Adding mint request
        create_mint_request(&account, res_addr,to_address,amount);

        // checking proposal created
        check_proposal_created(addr);

        // approve proposal
        approve_mint_request(&account,res_addr,addr,0);

        // checking proposal approved
        check_proposal_approved(addr,0);
    }

    #[test]
    #[expected_failure]
    entry fun test_approve_cancel_proposal(){
        let account = get_account();
        let addr = signer::address_of(&account);
        let to_address = signer::address_of(&get_account());
        let amount:u64=100000000;

        let res_addr = init_and_add_sub_admin(&account);


        let signer = vector[addr];
        enable_multisig(&account,res_addr,signer,5);
        is_multisig_enabled(res_addr);

        // Adding mint request
        create_mint_request(&account, res_addr,to_address,amount);

        // checking proposal created
        check_proposal_created(addr);

        // approve proposal
        approve_mint_request(&account,res_addr,addr,0);

        // checking proposal approved
        check_proposal_approved(addr,0);

        // cancel proposal
        cancel_mint_approval(&account,res_addr,addr,0);

        // checking proposal disapproved
        check_proposal_approved(addr,0);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3)]
    entry fun test_token_create(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
    ) {
        let symbol = string::utf8(b"bud");
        let decimals = 4;
        let supply = option::some(0);

        // This will pass only when `token_contract` account will be the creator
        init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);

        let creator_address = signer::address_of(creator);

        // Checking coin initialization
        assert!(coin::is_coin_initialized<AssetCoin>(), 0);
        assert!(!coin::is_account_registered<AssetCoin>(creator_address), 0);
        assert!(coin::symbol<AssetCoin>() == symbol, 0);
        assert!(coin::decimals<AssetCoin>() == decimals, 0);
        assert!(get_supply() == supply, 0);
        assert!(get_circulating_supply(creator_address) == i128::from_u128(0), 0);
    }

    #[test]
    entry fun test_register_account() {
        let account = get_account();
        let addr = signer::address_of(&account);

        let res_addr = init_and_add_sub_admin(&account);

        // Register account
        register_account(&account, res_addr);
        assert!(coin::is_account_registered<AssetCoin>(addr), 0);
    }

    #[test]
    #[expected_failure]
    entry fun test_grant_ungrant_agent_access() {
        let account = get_account();
        let to_address = signer::address_of(&get_account());
        let res_addr = init_and_add_sub_admin(&account);

        // Granting access
        grant_access_to_agent(&account, res_addr, to_address,vector[1]);

        // checking if access has assigned
        has_mint_rights(res_addr, to_address);

        // Granting access to same addr agin will result in error
        grant_access_to_agent(&account, res_addr, to_address,vector[1]);

        // Ungranting access
        ungrant_access_to_agent(&account, res_addr, to_address, vector[1]);

        // checking if access have been unassigned
        has_mint_rights(res_addr, to_address);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3, user = @0x4)]
    entry fun test_mint_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        init_and_mint_token(creator, issuer, transfer_agent, tokenization_agent, user);
        let amount = 500;
        let user_addr = signer::address_of(user);
        let creator_addr = signer::address_of(creator);

        assert!(coin::is_account_registered<AssetCoin>(user_addr), 0);
        assert!(get_balance(user_addr) == amount, 0);
        assert!(get_circulating_supply(creator_addr) == i128::from_u128((amount as u128)), 0);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3, user = @0x4)]
    entry fun test_burn_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        let res_addr = init_and_mint_token(creator, issuer, transfer_agent, tokenization_agent, user);
        let mint_amount = 500;
        let burn_amount = 200;
        let user_addr = signer::address_of(user);
        let creator_addr = signer::address_of(creator);

        burn_token(issuer, res_addr, creator_addr, vector[user_addr], vector[burn_amount]);
        assert!(get_balance(user_addr) == mint_amount - burn_amount, 0);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3, user = @0x4)]
    entry fun test_whitelisiting(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        // This will pass only when `token_contract` account will be the creator
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let country_code = 91;
        let user_addr = signer::address_of(user);
        let users = vector[user_addr];

        // Add to whitelist
        add(creator, res_addr, users, vector[country_code]);
        assert!(get_country_code_by_addres(res_addr, user_addr) == country_code, 0);

        // Remove from whitelist
        remove(creator, res_addr, users);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3, user = @0x4)]
    #[expected_failure(abort_code = 65538, location = aptos_std::simple_map)]
    entry fun test_whitelisting_after_removal(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        // This will pass only when `token_contract` account will be the creator
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let country_code = 91;
        let user_addr = signer::address_of(user);
        let users = vector[user_addr];

        // Add to whitelist
        add(creator, res_addr, users, vector[country_code]);
        assert!(get_country_code_by_addres(res_addr, user_addr) == country_code, 0);

        // Remove from whitelist
        remove(creator, res_addr, users);

        // Assertion will fail as already removed
        assert!(get_country_code_by_addres(res_addr, user_addr) == country_code, 0);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3, user = @0x4)]
    #[expected_failure(abort_code = 65538, location = aptos_std::simple_map)]
    entry fun test_whitelisting_on_random_account(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        // This will pass only when `token_contract` account will be the creator
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let country_code = 91;
        let user_addr = signer::address_of(user);

        // Assertion will fail as no present
        assert!(get_country_code_by_addres(res_addr, user_addr) == country_code, 0);
    }
    
    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3)]
    #[expected_failure]
    entry fun test_add_remove_country_codes(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
    ) {
        // This will pass only when `token_contract` account will be the creator
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let country_codes_res=get_country_codes(signer::address_of(creator));
        assert!(country_codes_res==vector[1,91],0);
        let country_codes = vector[72];

        // Add country_code
        add_country_code(creator,signer::address_of(creator),res_addr,country_codes);
        let country_codes_res=get_country_codes(signer::address_of(creator));
        assert!(country_codes_res==vector[1,91,72],0);

        // Remove country codes
        remove_country_code(creator,signer::address_of(creator),res_addr, country_codes);
        let country_codes_res=get_country_codes(signer::address_of(creator));
        assert!(country_codes_res==vector[1,91],0);

        // Add country_code which is already present and will give error
        add_country_code(creator,signer::address_of(creator),res_addr,vector[91]);

        // removing country_code which is not present and will give error
        remove_country_code(creator,signer::address_of(creator),res_addr,vector[58]);
    }

    #[test(creator = @token_contract, issuer = @0x1, transfer_agent = @0x2, tokenization_agent = @0x3)]
    entry fun test_update_token_limit(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
    ) {
        // This will pass only when `token_contract` account will be the creator
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let token_limit = 2000;

        // update_token_limt
        update_token_limit(creator,signer::address_of(creator),res_addr,token_limit);
        assert!(get_token_limit(signer::address_of(creator))==2000,0);
    }

  #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
        receiver = @0x5,
    )]
    entry fun test_transfer_token(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
        receiver: &signer,
    ) {
        let res_addr = init_and_mint_token(creator, issuer, transfer_agent, tokenization_agent, user);
        let amount = 200;
        let creator_addr = signer::address_of(creator);
        let to = signer::address_of(receiver);
        aptos_framework::account::create_account_for_test(to);

        // Registering receiver account
        register_account(receiver, res_addr);

        // Whitelisting
        add(creator, res_addr, vector[to], vector[91]);

        assert!(get_balance(to) == 0, 0);
        transfer_token(user, res_addr, creator_addr, to, amount);
        assert!(get_balance(to) == amount, 0);
    }

    #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
        receiver = @0x5,
    )]
    #[expected_failure(abort_code = 65538, location = aptos_std::simple_map)]
    entry fun test_transfer_token_without_whitelisting(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
        receiver: &signer,
    ) {
        let res_addr = init_and_mint_token(creator, issuer, transfer_agent, tokenization_agent, user);
        let amount = 200;
        let creator_addr = signer::address_of(creator);
        let to = signer::address_of(receiver);
        aptos_framework::account::create_account_for_test(to);

        // Registering receiver account
        register_account(receiver, res_addr);

        transfer_token(issuer, res_addr, creator_addr, to, amount);
        assert!(get_balance(to) == amount, 0);
    }

    #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    #[expected_failure(abort_code = 327690, location = aptos_framework::coin)]
    entry fun test_freeze_accounts(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);
        let issuer_addr = signer::address_of(issuer);
        aptos_framework::account::create_account_for_test(user_addr);
        let amount = 500;
        let users = vector[user_addr];

        // Registering receiver account
        register_account(user, res_addr);

        // Freeze user account
        freeze_accounts(issuer, res_addr, creator_addr, users);

        // Mint will fail as account is freezed
        mint_token(issuer, res_addr, creator_addr, users, vector[amount]);

        // Transfer will fail as account is freezed
        mint_token(issuer, res_addr, creator_addr, vector[issuer_addr], vector[amount]);
        transfer_token(issuer, res_addr, creator_addr, user_addr, amount);
    }

    #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    entry fun test_unfreeze_accounts(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);
        let issuer_addr = signer::address_of(issuer);
        let amount = 500;
        let users = vector[user_addr];

        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(issuer_addr);

        // Registering accounts
        register_account(user, res_addr);
        register_account(issuer, res_addr);

        // Whitelist account
        add(creator, res_addr, vector[issuer_addr], vector[91]);

        // Freeze user account
        freeze_accounts(issuer, res_addr, creator_addr, users);
        unfreeze_accounts(issuer, res_addr, creator_addr, users);

        // Mint and Transfer will pass as account is unfreezed
        mint_token(issuer, res_addr, creator_addr, users, vector[amount]);
        transfer_token(user, res_addr, creator_addr, issuer_addr, amount);
    }

    #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    #[expected_failure(abort_code = 327700, location = token_contract::asset_coin)]
    entry fun test_partial_freeze(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);
        let amount = 500;
        let users = vector[user_addr];
        let bal = 100;
        let bal_u128 = (bal as u128);
        let bals = vector[bal];
        let first_burn = 200;
        let second_burn = 250;

        aptos_framework::account::create_account_for_test(user_addr);

        // Registering receiver account
        register_account(user, res_addr);

        // Freeze user account
        partial_freeze(issuer, res_addr, creator_addr, users, bals);
        assert!(get_frozen_tokens(creator_addr) == (bal as u128), 0);

        let neg_bal_u128 = i128::new(bal_u128, true);
        assert!(get_circulating_supply(creator_addr) == neg_bal_u128, 0);

        // Burn will Pass, after burn 300 coins left
        mint_token(issuer, res_addr, creator_addr, users, vector[amount]);

        let circulating_supply = i128::from_u128((amount - bal as u128));
        assert!(get_circulating_supply(creator_addr) == circulating_supply, 0);

        burn_token(issuer, res_addr, creator_addr, users, vector[first_burn]);
        assert!(get_balance(user_addr) == amount - first_burn, 0);

        // Burn will fail, as 100 coins are patially frozen
        burn_token(issuer, res_addr, creator_addr, users, vector[second_burn]);
    }

    #[test(
        creator = @token_contract,
        issuer = @0x1,
        transfer_agent = @0x2,
        tokenization_agent = @0x3,
        user = @0x4,
    )]
    entry fun test_partial_unfreeze(
        creator: &signer,
        issuer: &signer,
        transfer_agent: &signer,
        tokenization_agent: &signer,
        user: &signer,
    ) {
        let res_addr = init_and_create_token(creator, issuer, transfer_agent, tokenization_agent);
        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);
        let amount = 500;
        let users = vector[user_addr];
        let bal = 100;
        let bals = vector[bal];
        let first_burn = 200;
        let second_burn = 250;

        aptos_framework::account::create_account_for_test(user_addr);

        // Registering receiver account
        register_account(user, res_addr);

        // Partially freeze account
        partial_freeze(issuer, res_addr, creator_addr, users, bals);
        assert!(get_frozen_tokens(creator_addr) == (bal as u128), 0);

        // Burn will Pass, after burn 300 coins left
        mint_token(issuer, res_addr, creator_addr, users, vector[amount]);
        burn_token(issuer, res_addr, creator_addr, users, vector[first_burn]);
        assert!(get_balance(user_addr) == amount - first_burn, 0);

        // Partially unfreeze account
        partial_unfreeze(issuer, res_addr, creator_addr, users);
        assert!(get_frozen_tokens(creator_addr) == 0u128, 0);

        // Burn will pass patially unfrozen
        burn_token(issuer, res_addr, creator_addr, users, vector[second_burn]);
    }
}

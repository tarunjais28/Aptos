module base_token_contract::asset_coin {
    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::fungible_asset::{Self, mint_to, burn_from, mint_ref_metadata, burn_ref_metadata,
        transfer_ref_metadata, transfer, FungibleStore, transfer_with_ref, set_frozen_flag, Metadata};
    use aptos_framework::object::{Self};
    use aptos_framework::primary_fungible_store::{create_primary_store_enabled_fungible_asset,
        ensure_primary_store_exists};
    use base_token_contract::resource::{create_with_admin, get_metadata, ensure_holding_period_passed};
    use std::vector;
    use base_token_contract::maintainers::{is_sub_admin, has_sub_admin_rights};
    use base_token_contract::roles::{assign_all_roles, has_issuer_rights, has_tokenization_agent_rights,
        has_transfer_agent_rights};
    use base_token_contract::events::{emit_token_creation_event, emit_mint_event, emit_burn_event, emit_transfer_event,
        emit_freeze_event, emit_unfreeze_event, emit_request_order_event};
    use base_token_contract::agents::{has_mint_rights, has_burn_rights, has_freeze_rights, has_unfreeze_rights,
        has_force_transfer_rights};
    use std::option::{Self, none, Option};
    use base_token_contract::resource::{create_token_config, ensure_balance_not_frozen};
    use aptos_framework::fungible_asset::{MintRef, BurnRef, TransferRef};
    use aptos_std::simple_map::{Self, SimpleMap};
    use utils::i128::{Self, I128};
    use utils::error;
    use utils::interop_constants;

    struct AssetCoin {}

    //:!:>resources
    struct CoinCap has key, drop {
        cap: SimpleMap<String, CoinRef<AssetCoin>>
    }

    struct CoinRef<phantom AssetCoin> has store, drop {
        mint_ref: MintRef,
        burn_ref: BurnRef,
        transfer_ref: TransferRef,
    }

    struct Requests has key, drop {
        requests: SimpleMap<u256, Request>,
    }

    struct Request has store, drop, copy {
        request_type: String,
        requester: address,
        responder: address,
        amount: u64,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function to get mint_ref
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - CoinCap doesn't mapped with gievn id
    ///
    /// Returns MintRef for minting tokens
    inline fun get_mint_ref(
        token: String
    ): &MintRef acquires CoinCap {
        let coin_cap = &borrow_global<CoinCap>(@base_token_contract).cap;
        &simple_map::borrow(coin_cap, &token).mint_ref
    }

    /// Function to get burn_ref
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - CoinCap doesn't mapped with gievn id
    ///
    /// Returns BurnRef for burning tokens
    inline fun get_burn_ref(
        token: String
    ): &BurnRef acquires CoinCap {
        let coin_cap = &borrow_global<CoinCap>(@base_token_contract).cap;
        &simple_map::borrow(coin_cap, &token).burn_ref
    }

    /// Function to get transfer_ref
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - CoinCap doesn't mapped with gievn id
    ///
    /// Returns TransferRef for transfer tokens
    inline fun get_transfer_ref(
        token: String
    ): &TransferRef acquires CoinCap {
        let coin_cap = &borrow_global<CoinCap>(@base_token_contract).cap;
        &simple_map::borrow(coin_cap, &token).transfer_ref
    }
    //:!:>helper functions

    /// Function for initialization
    ///
    /// Arguements:-
    ///     @admin - Sender / Caller of the transaction
    ///
    /// Fails when:-
    ///     - signer is not the deployer of the contract
    public entry fun init(admin: &signer) {
        let acc_addr = signer::address_of(admin);
        assert!(acc_addr == @base_token_contract, error::unauthorised_caller());

        create_with_admin(admin);

        // Initialize coin capability
        move_to(
            admin,
            CoinCap {
                cap: simple_map::create(),
            }
        );

        // Initializing Requests
        move_to(admin,
            Requests {
                requests: simple_map::create(),
            }
        );
    }

    /// Function for token creation
    ///
    /// Arguements:-
    ///     @creator - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @name - Name of the token
    ///     @symbol - Symbol of the token
    ///     @icon_uri - uri of icon
    ///     @project_uri - uri of project
    ///     @token_limit - Maximum number of tokens that an individual can hold
    ///     @country_codes - List of authorized countries that can use tokens
    ///     @issuer - Address which is going to assigned as Issuer
    ///     @tokenization_agent - Address which is going to assigned as Tokenization agent
    ///     @transfer_agent - Address which is going to assigned as Transfer agent
    ///     @holding_period - Holding Period of the token transmission
    ///
    /// Fails when:-
    ///     - signer is not one of the sub admins
    ///
    /// Emits token creation event
    public entry fun create_token(
        creator: &signer,
        id: String,
        name: String,
        symbol: String,
        icon_uri: String,
        project_uri: String,
        issuer: address,
        tokenization_agent: address,
        transfer_agent: address,
        holding_period: u64,
    ) acquires CoinCap {
        let creator_address = signer::address_of(creator);

        // Fixed decimals upto 0 places
        let decimals = 0;

        // Check authetication
        is_sub_admin(creator_address);

        let seed = *string::bytes(&name);
        vector::append(&mut seed, *string::bytes(&name));
        vector::append(&mut seed, *string::bytes(&symbol));
        let creator_ref = object::create_named_object(creator, seed);

        create_primary_store_enabled_fungible_asset(
            &creator_ref,
            none(),
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        );

        let mint_ref = fungible_asset::generate_mint_ref(&creator_ref);
        let burn_ref = fungible_asset::generate_burn_ref(&creator_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(&creator_ref);
        let metadata = mint_ref_metadata(&mint_ref);

        let coin_cap = &mut borrow_global_mut<CoinCap>(@base_token_contract).cap;
        // Fails when the simple_map already contains the token
        simple_map::add(
            coin_cap,
            name,
            CoinRef {
                mint_ref,
                burn_ref,
                transfer_ref,
            }
        );

        // Assigning roles
        assign_all_roles(
            name,
            option::some(issuer),
            option::some(transfer_agent),
            option::some(tokenization_agent),
        );

        // Create token config
        create_token_config(
            name,
            symbol,
            metadata,
            holding_period,
        );

        // Emitting token creation event
        emit_token_creation_event(
            id,
            name,
            symbol,
            decimals,
            creator_address,
            issuer,
            tokenization_agent,
            transfer_agent,
        );
    }

    /// Function for minting of token
    /// This function supports batch minting
    /// The users and amounts must be passed in ordered manner, such as users[0] corresponds to amounts[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique token mapped to each token
    ///     @users - Addresses that are going to be minted
    ///     @amounts - The amount of tokens that are going to be minted
    ///
    /// Fails when:-
    ///     - quantity of users and amounts are different
    ///     - sender doesn't have either of issuer, tokenization agent, mint or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - token limit exceeds after minting
    ///
    /// Emits mint event
    public entry fun mint_token(
        account: &signer,
        token: String,
        users: vector<address>,
        amounts: vector<u64>,
    ) acquires CoinCap {
        let account_address = signer::address_of(account);

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&amounts),
            error::arguements_mismatched()
        );

        // Ensure authroized caller
        if (!has_issuer_rights(token, account_address)
            && !has_tokenization_agent_rights(token, account_address)
            && !has_mint_rights(token, account_address)
            && !has_sub_admin_rights(account_address)) {
            abort error::unauthorized()
        };

        let mint_ref = get_mint_ref(token);
        let metadata = mint_ref_metadata(mint_ref);
        while (vector::length(&users) > 0) {
            let user = vector::pop_back(&mut users);
            let wallet = ensure_primary_store_exists(user, metadata);
            let amount = vector::pop_back(&mut amounts);

            mint_to(mint_ref, wallet, amount);

            // Emit mint event
            emit_mint_event(user, amount);
        };
    }

    /// Function for burn token
    /// This function supports batch burning
    /// The users and amounts must be passed in ordered manner, such as users[0] corresponds to amounts[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @users - Addresses that are going to be burned
    ///     @amounts - The amount of tokens that are going to be burned
    ///
    /// Fails when:-
    ///     - quantity of users and amounts are different
    ///     - sender doesn't have either of issuer, tokenization agent, burn or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - token are frozen partially
    ///
    /// Emits burn event
    public entry fun burn_token(
        account: &signer,
        token: String,
        users: vector<address>,
        amounts: vector<u64>,
    ) acquires CoinCap {
        let account_address = signer::address_of(account);

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&amounts),
            error::arguements_mismatched()
        );

        // Ensure authroized caller
        if (!has_issuer_rights(token, account_address)
            && !has_tokenization_agent_rights(token, account_address)
            && !has_burn_rights(token, account_address)
            && !has_sub_admin_rights(account_address)) {
            abort error::unauthorized()
        };

        let burn_ref = get_burn_ref(token);
        let metadata = burn_ref_metadata(burn_ref);

        while (vector::length(&users) > 0) {
            let user = vector::pop_back(&mut users);
            let wallet = ensure_primary_store_exists(user, metadata);
            let amount = vector::pop_back(&mut amounts);

            // Ensure balance not frozen
            ensure_balance_not_frozen(token, user, amount);

            burn_from(burn_ref, wallet, amount);

            // Emit burn event
            emit_burn_event(user, amount);
        };
    }

    /// Function to transfer token to someone
    ///
    /// Arguements:-
    ///     @from - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @to - Receipient address that are going to receive tokens
    ///     @amount - The amount of tokens that are going to be transfered
    ///
    /// Fails when:-
    ///     - missing CoinCap struct initialization
    ///     - token limit exceeds
    ///     - receipient account is not whitelisted
    ///     - sender's balance is frozen
    ///
    /// Emits transfer event
    public entry fun transfer_token(
        from: &signer,
        token: String,
        to: address,
        amount: u64
    ) acquires CoinCap {
        let from_address = signer::address_of(from);
        let transfer_ref = get_transfer_ref(token);
        let metadata = transfer_ref_metadata(transfer_ref);
        let from_wallet = ensure_primary_store_exists(from_address, metadata);
        let to_wallet = ensure_primary_store_exists(to, metadata);

        // Ensure token hold period is passed
        ensure_holding_period_passed(token);

        // Ensure balance exists and not frozen
        ensure_balance_not_frozen(token, from_address, amount);

        // Transfer
        transfer<FungibleStore>(from, from_wallet, to_wallet, amount);

        // Emitting event
        emit_transfer_event(from_address, to, amount)
    }

    /// Function for force transfer
    /// This function supports batch force transfer
    /// The from_addresses, to_addresses and amounts must be passed in ordered manner, such as from_addresses[0]
    /// corresponds to to_addresses[0] and amounts[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @from_addresses - Addresses from which the amounts get debited
    ///     @to_addresses - Addresses to which the amounts get credited
    ///     @amounts - The amount of tokens that are going to force transfered
    ///
    /// Fails when:-
    ///     - quantity of from_addresses, to_addresses and amounts are different
    ///     - sender doesn't have either of issuer, transfer agent, force transfer or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - token limit exceeds
    ///     - receipient account is not whitelisted
    ///     - sender's balance is frozen
    ///
    /// Emits transfer event
    public entry fun force_transfer(
        account: &signer,
        token: String,
        from_addresses: vector<address>,
        to_addresses: vector<address>,
        amounts: vector<u64>,
    ) acquires CoinCap {
        let sender = signer::address_of(account);
        let transfer_ref = get_transfer_ref(token);

        // Ensure authroized caller
        if (!has_issuer_rights(token, sender)
            && !has_transfer_agent_rights(token ,sender)
            && !has_force_transfer_rights(token, sender)
            && !has_sub_admin_rights(sender)) {
            abort error::unauthorized()
        };

        // Ensure token hold period is passed
        ensure_holding_period_passed(token);

        // Ensuring arguements are correct
        assert!(
            vector::length(&from_addresses) == vector::length(&amounts)
                && vector::length(&to_addresses) == vector::length(&amounts),
            error::arguements_mismatched()
        );

        while (vector::length(&from_addresses) > 0) {
            let from = vector::pop_back(&mut from_addresses);
            let to = vector::pop_back(&mut to_addresses);
            let amount = vector::pop_back(&mut amounts);
            let metadata = transfer_ref_metadata(transfer_ref);
            let from_wallet = ensure_primary_store_exists(from, metadata);
            let to_wallet = ensure_primary_store_exists(to, metadata);

            // Ensure balance exists and not frozen
            ensure_balance_not_frozen(token, sender, amount);

            // Transfer
            transfer_with_ref<FungibleStore>(transfer_ref, from_wallet, to_wallet, amount);

            // Emitting event
            emit_transfer_event(from, to, amount)
        };
    }

    /// Function to freeze accounts
    /// This function supports batch account freezing
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @addrs - Addresses that are going to be freezed
    ///
    /// Fails when:-
    ///     - sender doesn't have either of issuer, transfer agent, freeze or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///
    /// Emits freeze event
    public entry fun freeze_accounts(
        sender: &signer,
        token: String,
        addrs: vector<address>,
    ) acquires CoinCap {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(token, sender_addr)
            && !has_transfer_agent_rights(token, sender_addr)
            && !has_freeze_rights(token, sender_addr)
            && !has_sub_admin_rights(sender_addr)) {
            abort error::unauthorized()
        };

        let transfer_ref = get_transfer_ref(token);
        let metadata = transfer_ref_metadata(transfer_ref);

        vector::for_each(addrs, |addr| {
            let wallet = ensure_primary_store_exists(addr, metadata);
            set_frozen_flag(transfer_ref, wallet, true);

            // Emitting freeze event
            emit_freeze_event(addr);
        });
    }

    /// Function to unfreeze accounts
    /// This function supports batch account unfreezing
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @addrs - Addresses that are going to be unfreezed
    ///
    /// Fails when:-
    ///     - sender doesn't have either of issuer, transfer agent, unfreeze or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///
    /// Emits unfreeze event
    public entry fun unfreeze_accounts(
        sender: &signer,
        token: String,
        addrs: vector<address>,
    ) acquires CoinCap {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(token, sender_addr)
            && !has_transfer_agent_rights(token, sender_addr)
            && !has_unfreeze_rights(token, sender_addr)
            && !has_sub_admin_rights(sender_addr)) {
            abort error::unauthorized()
        };

        let transfer_ref = get_transfer_ref(token);
        let metadata = transfer_ref_metadata(transfer_ref);

        vector::for_each(addrs, |addr| {
            let wallet = ensure_primary_store_exists(addr, metadata);
            set_frozen_flag(transfer_ref, wallet, false);

            // Emitting freeze event
            emit_unfreeze_event(addr);
        });
    }

    /// Function to request orders
    /// This function supports batch account unfreezing
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token - Token Name
    ///     @addrs - Addresses that are going to be unfreezed
    ///
    /// Fails when:-
    ///     - sender doesn't have either of issuer, transfer agent, unfreeze or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - amount lesser than 0
    ///     - request_type is other than mint or burn
    ///     - order_id already exist
    ///     - any issue with mint or burn
    ///
    /// Emits request order event
    public entry fun request_order(
        sender: &signer,
        order_id: u256,
        token: String,
        from: address,
        amount: u64,
        request_type: u8,
    ) acquires CoinCap, Requests {
        let sender = signer::address_of(sender);

        // Check authetication
        is_sub_admin(sender);

        assert!(
            amount > 0,
            error::amount_must_be_greater_than_zero()
        );

        if (request_type == interop_constants::get_mint()) {
            let mint_ref = get_mint_ref(token);
            let metadata = mint_ref_metadata(mint_ref);
            let wallet = ensure_primary_store_exists(from, metadata);

            mint_to(mint_ref, wallet, amount);
        } else if (request_type == interop_constants::get_burn()) {
            let burn_ref = get_burn_ref(token);
            let metadata = burn_ref_metadata(burn_ref);
            let wallet = ensure_primary_store_exists(from, metadata);

            burn_from(burn_ref, wallet, amount);
        } else {
            abort error::invalid_request()
        };

        let requests = &mut borrow_global_mut<Requests>(@base_token_contract).requests;
        if (simple_map::contains_key(requests, &order_id)) {
            abort error::id_exists()
        } else {
            simple_map::add(
                requests,
                order_id,
                Request {
                    request_type: interop_constants::get_operation(request_type),
                    requester: from,
                    responder: sender,
                    amount,
                },
            );
        };

        // Emit request order event
        emit_request_order_event(request_type, order_id, from, amount);
    }
    //:!:>view functions
    #[view]
    /// Function to get supply of the token
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - Metadata is not mapped with the given id
    ///
    /// Returns either None or Some(value)
    public fun get_supply(token: String): Option<u128> {
        let metadata = get_metadata(token);
        fungible_asset::supply<Metadata>(metadata)
    }

    #[view]
    /// Function to get maximum permissible supply of the token
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - Metadata is not mapped with the given id
    ///
    /// Returns either None or Some(value)
    public fun get_max_supply(token: String): Option<u128> {
        let metadata = get_metadata(token);
        fungible_asset::maximum<Metadata>(metadata)
    }

    #[view]
    /// Function to get symbol of a token
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - Metadata is not mapped with the given id
    ///
    /// Returns token symbol
    public fun get_symbol(token: String): String {
        let metadata = get_metadata(token);
        fungible_asset::symbol<Metadata>(metadata)
    }

    #[view]
    /// Function to get decimals of a token
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - Metadata is not mapped with the given id
    ///
    /// Returns allowabke decimals
    public fun get_decimals(token: String): u8 {
        let metadata = get_metadata(token);
        fungible_asset::decimals<Metadata>(metadata)
    }

    #[view]
    /// Function to get circulating supply
    /// This is the total number of token that are in circulation
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Returns circulating supply
    public fun get_circulating_supply(token: String): I128 {
        let supply_opt = get_supply(token);
        let supply = *option::borrow(&supply_opt);

        i128::from_u128(supply)
    }

    #[view]
    /// Function to get order request
    ///
    /// Arguements:-
    ///     @token - Token Name
    ///
    /// Fails when:-
    ///     - Metadata is not mapped with the given id
    ///
    /// Returns either None or Some(value)
    public fun get_order_request(order_id: u256): Request acquires Requests {
        let requests = borrow_global<Requests>(@base_token_contract).requests;
        *simple_map::borrow(&requests, &order_id)
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}

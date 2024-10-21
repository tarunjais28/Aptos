module fungible_tokens::resource {
    use std::signer;
    use std::option;
    use fungible_tokens::events::{initialize_event_store, emit_admin_update_event, emit_init_event,
        emit_update_countrycode_event, emit_update_token_limt_event, emit_partial_freeze_event,
        emit_partial_unfreeze_event};
    use fungible_tokens::roles::{init_rights, has_issuer_rights, has_transfer_agent_rights};
    use fungible_tokens::maintainers::{init_maintainers, is_sub_admin, has_sub_admin_rights};
    use fungible_tokens::whitelist::{init_whitelisting, get_country_code_by_addres};
    use std::vector;
    use fungible_tokens::agents::{init_agent_roles, has_unfreeze_rights, has_freeze_rights};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::object::Object;
    use std::string::{Self, String};
    use utils::error;
    use aptos_framework::primary_fungible_store::ensure_primary_store_exists;
    use aptos_framework::timestamp;

    friend fungible_tokens::asset_coin;

    //:!:>resources
    struct TokenConfig has key, drop {
        tokens: vector<String>,
        symbols: vector<String>,
        token_data: SimpleMap<String, TokenData>,
    }

    struct TokenData has store, drop, copy {
        token_limit: u64,
        country_codes: vector<u8>,
        metadata: Object<Metadata>,
        holding_period: u64,
        partial_freeze: SimpleMap<address, u64>,
        total_freezed_amount: u128,
    }
    //:!:>resources

    /// Function for maintainer creation with admin account
    ///
    /// Here following initialization takes place with default configurations:-
    ///     - Event Store for event handling
    ///     - Maintainers
    ///     - Various authorities like issuers, tokenization and transfer agents
    ///     - Agents
    ///     - Whitelisting Storage
    ///     - Token configuration storage
    ///
    /// This function emits following events:-
    ///     - Init Event
    ///     - Admin Update Event
    public fun create_with_admin(account: &signer) {
        let admin = signer::address_of(account);

        // Initializing events
        initialize_event_store(account);

        // Init maintaner and make caller as admin
        init_maintainers(account, admin);

        // Initializing rights
        init_rights(account);

        // Initializing Agent roles
        init_agent_roles(account);

        // Initializing whitelisting
        init_whitelisting(account);

        // Initializing Token Config
        move_to(account,
            TokenConfig {
                tokens: vector::empty(),
                symbols: vector::empty(),
                token_data: simple_map::create(),
            }
        );

        // Emitting events
        emit_init_event(admin);
        emit_admin_update_event(option::none(), option::some(vector[admin]));
    }

    //:!:>helper functions
    /// Function to create Token Config
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @name - Name of the token
    ///     @symbol - Symbol of the token
    ///     @token_limit - Maximum number of tokens that an individual can hold
    ///     @country_codes - List of authorized countries that can use tokens
    ///     @metadata - Meta data of the created token
    ///     @holding_period - Holding Period of the token transmission
    ///
    /// Fails when:-
    ///     - missing TokenConfig struct initialization
    ///     - token name already exists
    ///     - token symbol already exists
    ///     - id already exists
    public fun create_token_config(
        id: String,
        name: String,
        symbol: String,
        token_limit: u64,
        country_codes: vector<u8>,
        metadata: Object<Metadata>,
        holding_period: u64,
    ) acquires TokenConfig {
        let token_config = borrow_global_mut<TokenConfig>(@fungible_tokens);

        // Check unique token name
        let tokens = &mut token_config.tokens;
        if (vector::contains(tokens, &name)) {
            abort error::name_exists()
        } else {
            vector::push_back(tokens, name);
        };

        // Check unique token symbol
        let symbols = &mut token_config.symbols;
        if (vector::contains(symbols, &symbol)) {
            abort error::symbol_exists()
        } else {
            vector::push_back(symbols, symbol);
        };

        // Adding token data
        let token_data = &mut token_config.token_data;
        if (simple_map::contains_key(token_data, &id)) {
            abort error::id_exists()
        } else {
            simple_map::add(
                token_data,
                id,
                TokenData {
                    token_limit,
                    country_codes,
                    metadata,
                    holding_period,
                    partial_freeze: simple_map::create(),
                    total_freezed_amount: 0,
                },
            );
        };
    }

    /// Function to check balance frozen state
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address whose balance is going to be ensured as freezed or not
    ///     @amount - Amount of balance to be transferred / use
    ///
    /// Fails when:-
    ///     - balance requested is greater than frozen balance
    ///     - missing TokenConfig struct initialization
    public fun ensure_balance_not_frozen(
        id: String,
        addr: address,
        amount: u64,
    ) acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        let freeze = simple_map::borrow(&token_data, &id).partial_freeze;

        let frozen_balance = if (simple_map::contains_key(&freeze, &addr)) {
            *simple_map::borrow(&freeze, &addr)
        } else {
            0
        };

        let balance = get_balance(id, addr);
        assert!(
            balance >= amount,
            error::insufficient_balance()
        );

        assert!(
            frozen_balance <= balance - amount,
            error::balance_frozen()
        )
    }

    /// Function to check balance exists for an account or not
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address whose balance is going to be ensured as freezed or not
    ///     @amount - Amount of balance to be transferred / use
    ///
    /// Fails when:-
    ///     - amount requested is greater than the user balance
    ///     - missing TokenConfig struct initialization
    fun ensure_balance_exists(
        id: String,
        addr: address,
        amount: u64,
    ) acquires TokenConfig {
        let balance = get_balance(id, addr);
        assert!(
            balance >= amount,
            error::insufficient_balance()
        )
    }

    /// Ensuring account is whitelisted
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address whose balance is going to be ensured as authorized or not
    ///
    /// Fails when:-
    ///     - the given address is not whitelisted
    ///     - missing TokenConfig struct initialization
    public fun ensure_account_whitelisted(
        id: String,
        addr: address
    ) acquires TokenConfig {
        let country_code = get_country_code_by_addres(id, addr);
        let country_codes = get_country_codes(id);

        assert!(
            vector::contains(&country_codes, &country_code),
            error::not_whitelisted()
        )
    }

    /// Ensuring holding period is passed
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - the token is on hold
    public fun ensure_holding_period_passed(
        id: String,
    ) acquires TokenConfig {
        let holding_period = get_holding_period(id);

        assert!(
            timestamp::now_seconds() > holding_period,
            error::token_held()
        );
    }

    /// Ensuring token limit maintained
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @amount - Amount to be added
    ///     @addr - Address whose balance is going to be ensured for token limit
    ///
    /// Fails when:-
    ///     - the sum of curent holding and incomming balances exceeds the maximum allowable holdings
    ///     - missing TokenConfig struct initialization
    public fun ensure_token_limit(
        id: String,
        amount: u64,
        addr: address,
    ) acquires TokenConfig {
        let bal = get_balance(id, addr);
        let token_limit = get_token_limit(id);

        assert!(
            bal + amount <= token_limit,
            error::token_limit_exceeded()
        );
    }

    /// Function to add country codes
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @country_codes - New country codes, that are going to be added to the list
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///     - the given country codes are already present in the list
    ///     - missing TokenConfig struct initialization
    ///     - stored country code list doesn't mapped with gievn id
    ///
    /// Emits update country code event
    public entry fun add_country_code(
        account: &signer,
        id: String,
        country_codes: vector<u8>
    ) acquires TokenConfig {
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(address);

        let token_data = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        let stored_country_codes = &mut simple_map::borrow_mut(token_data, &id).country_codes;

        vector::for_each(country_codes,|element| {
            let (res, _) = vector::index_of(stored_country_codes,&element);
            assert!(!res, error::country_code_exists());
            vector::push_back(stored_country_codes, element);
        });

        emit_update_countrycode_event(
            string::utf8(b"add_country_codes"),
            country_codes
        );
    }

    /// Function to remove country codes
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @country_codes - Country codes, that are going to be removed from the list
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///     - the given country codes not present in the list
    ///     - missing token config
    ///     - stored country code list doesn't mapped with gievn id
    ///
    /// Emits update country code event
    public entry fun remove_country_code(
        account: &signer,
        id: String,
        country_codes: vector<u8>
    ) acquires TokenConfig {
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(address);

        let token_data = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        let stored_country_codes = &mut simple_map::borrow_mut(token_data, &id).country_codes;

        vector::for_each(country_codes,|element| {
            let (res, index) = vector::index_of(stored_country_codes,&element);
            assert!(res, error::country_code_not_exists());
            vector::remove(stored_country_codes, index);
        });

        emit_update_countrycode_event(
            string::utf8(b"remove_country_codes"),
            country_codes
        );

    }

    /// Function to update token limit
    /// Token Limit is the maximum amount of token that an account can hold
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @limit - New limit of token that an account can hold
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///     - missing token config
    ///     - token data doesn't mapped with gievn id
    ///
    /// Emits update token limit event
    public entry fun update_token_limit(
        account: &signer,
        id: String,
        limit: u64
    ) acquires TokenConfig{
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(address);

        let token_data = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow_mut(token_data, &id).token_limit = limit;

        emit_update_token_limt_event(string::utf8(b"update_token_limit"), limit);
    }
    //:!:>helper functions

    /// Function for partial freeze balance
    /// Some part of tokens are freezed
    /// This function supports batch partial freeze
    /// The address and balances must be passed in ordered manner, such as addresses[0] corresponds to balances[0]
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @addrs - Addresses that are going to be freezed partially
    ///     @balances - The amount of tokens that are going to freezed
    ///
    /// Fails when:-
    ///     - 1uantity of addresses and balances are different
    ///     - sender doesn't have either of issuer, transfer agent, freeze or sub_admin rights
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn id
    ///
    /// Emits partial freeze event
    public entry fun partial_freeze(
        sender: &signer,
        id: String,
        addrs: vector<address>,
        balances: vector<u64>,
    ) acquires TokenConfig {
        let sender_addr = signer::address_of(sender);

        // Ensuring arguements are correct
        assert!(
            vector::length(&addrs) == vector::length(&balances),
            error::arguements_mismatched()
        );

        // Ensure authroized caller
        if (!has_issuer_rights(id, sender_addr)
            && !has_transfer_agent_rights(id, sender_addr)
            && !has_freeze_rights(id, sender_addr)
            && !has_sub_admin_rights(sender_addr)) {
            abort error::unauthorized()
        };

        let temp_addrs = addrs;
        let temp_bals = balances;

        // Ensure balance exists
        // Here 2 while loops are used to avoid dangling effect of TokenConfig struct
        while (vector::length(&temp_addrs) > 0) {
            let addr = vector::pop_back(&mut temp_addrs);
            let bal = vector::pop_back(&mut temp_bals);

            // Ensure balance exists
            ensure_balance_exists(id, addr, bal);

        };

        let token_data_map = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        let token_data = simple_map::borrow_mut(token_data_map, &id);
        let freeze = &mut token_data.partial_freeze;

        while (vector::length(&addrs) > 0) {
            let addr = vector::pop_back(&mut addrs);
            let bal = vector::pop_back(&mut balances);

            if (simple_map::contains_key(freeze, &addr)) {
                let freezed_bal = simple_map::borrow_mut(freeze, &addr);
                *freezed_bal = *freezed_bal + bal;
            } else {
                simple_map::add(freeze, addr, bal);
            };
            token_data.total_freezed_amount = token_data.total_freezed_amount + (bal as u128);

            // Emitting freeze event
            emit_partial_freeze_event(addr, bal);
        };
    }

    /// Function for partial unfreeze balance
    /// Some part of tokens are unfreezed
    /// This function supports batch partial unfreeze
    /// The address and balances must be passed in ordered manner, such as address[0] corresponds to balance[0]
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @addrs - Addresses that are going to be unfreezed partially
    ///     @balances - The amount of tokens that are going to unfreezed
    ///
    /// Fails when:-
    ///     - quantity of addresses and balances are different
    ///     - sender doesn't have either of issuer, transfer agent, unfreeze or sub_admin rights
    ///     - address not present in the list
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn id
    ///
    /// Emits partial unfreeze event
    public entry fun partial_unfreeze(
        sender: &signer,
        id: String,
        addrs: vector<address>,
        balances: vector<u64>,
    ) acquires TokenConfig {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(id, sender_addr)
            && !has_transfer_agent_rights(id, sender_addr)
            && !has_unfreeze_rights(id, sender_addr)
            && !has_sub_admin_rights(sender_addr)) {
            abort error::unauthorized()
        };

        let token_data_map = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        let token_data = simple_map::borrow_mut(token_data_map, &id);
        let freeze = &mut token_data.partial_freeze;

        let rem_bal;
        while (vector::length(&addrs) > 0) {
            let addr = vector::pop_back(&mut addrs);
            let bal = vector::pop_back(&mut balances);

            if (simple_map::contains_key(freeze, &addr)) {
                let freezed_bal = simple_map::borrow_mut(freeze, &addr);

                // Underflow check
                assert!(*freezed_bal >= bal, error::underflow());

                *freezed_bal = *freezed_bal - bal;
                rem_bal = *freezed_bal;
            } else {
                abort error::addr_not_found()
            };

            token_data.total_freezed_amount = token_data.total_freezed_amount - (bal as u128);

            if (rem_bal == 0) {
                // Fails when the simple_map doesn't contain the address
                simple_map::remove(freeze, &addr);
            };

            // Emitting unfreeze event
            emit_partial_unfreeze_event(addr, bal);
        }
    }

    /// Function for partial freeze balance for delivery vs payment flow
    /// Newly minted tokens are freezed so no need to check the balance before partial freezing
    /// This function can be accessed only by Asset coin module
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address that are going to be freezed partially
    ///     @balance - The amount of tokens that are going to freezed
    ///
    /// Fails when:-
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn id
    ///
    /// Emits partial freeze event
    public(friend) fun partial_freeze_dvp(
        id: String,
        addr: address,
        balance: u64,
    ) acquires TokenConfig {
        let token_data_map = &mut borrow_global_mut<TokenConfig>(@fungible_tokens).token_data;
        let token_data = simple_map::borrow_mut(token_data_map, &id);
        let freeze = &mut token_data.partial_freeze;

        if (simple_map::contains_key(freeze, &addr)) {
            let freezed_bal = simple_map::borrow_mut(freeze, &addr);
            *freezed_bal = *freezed_bal + balance;
        } else {
            simple_map::add(freeze, addr, balance);
        };
        token_data.total_freezed_amount = token_data.total_freezed_amount + (balance as u128);

        // Emitting freeze event
        emit_partial_freeze_event(addr, balance);
    }

    //:!:>view functions
    #[view]
    /// Function to get balance of an account
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address for which the balance will going to be fetched
    ///
    /// Fails when
    ///     - primary token stoarge doesn't have the address and metadata combination
    ///
    /// Returns balance of the address
    public fun get_balance(
        id: String,
        addr: address
    ): u64 acquires TokenConfig {
        let metadata = get_metadata(id);
        let wallet = ensure_primary_store_exists(addr, metadata);
        fungible_asset::balance<FungibleStore>(wallet)
    }

    #[view]
    /// Function to get country codes
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the list of authorized country codes
    public fun get_country_codes(id: String): vector<u8> acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow(&token_data, &id).country_codes
    }

    #[view]
    /// Function to get token limit
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the current token limit
    public fun get_token_limit(id: String): u64 acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow(&token_data, &id).token_limit
    }

    #[view]
    /// Function to get holding period
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the holding period in seconds
    public fun get_holding_period(id: String): u64 acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow(&token_data, &id).holding_period
    }

    #[view]
    /// Function to get frozen balance of an account
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address for which the frozen balance will going to be fetched
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns frozen balance of the address
    public fun get_frozen_balance(id: String, addr: address): u64 acquires TokenConfig {
        let token_data_map = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        let freeze_data = simple_map::borrow(&token_data_map, &id).partial_freeze;
        if (simple_map::contains_key(&freeze_data, &addr)) {
            *simple_map::borrow(&freeze_data, &addr)
        } else {
            0
        }
    }

    #[view]
    /// Function to get frozen tokens
    /// This is the total number of frozen tokens
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the total number of frozen tokens
    public fun get_frozen_tokens(id: String): u128 acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow(&token_data, &id).total_freezed_amount
    }

    #[view]
    /// Function to get metadata
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the metadata of the token
    public fun get_metadata(id: String): Object<Metadata> acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@fungible_tokens).token_data;
        simple_map::borrow(&token_data, &id).metadata
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
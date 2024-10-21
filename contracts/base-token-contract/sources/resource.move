module base_token_contract::resource {
    use std::signer;
    use std::option;
    use base_token_contract::events::{initialize_event_store, emit_admin_update_event, emit_init_event,
        emit_partial_freeze_event, emit_partial_unfreeze_event};
    use base_token_contract::roles::{init_rights, has_issuer_rights, has_transfer_agent_rights};
    use base_token_contract::maintainers::{init_maintainers, has_sub_admin_rights};
    use std::vector;
    use base_token_contract::agents::{init_agent_roles, has_unfreeze_rights, has_freeze_rights};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::object::Object;
    use std::string::String;
    use utils::error;
    use aptos_framework::primary_fungible_store::ensure_primary_store_exists;
    use aptos_framework::timestamp;

    //:!:>resources
    struct TokenConfig has key, drop {
        tokens: vector<String>,
        symbols: vector<String>,
        token_data: SimpleMap<String, TokenData>,
    }

    struct TokenData has store, drop, copy {
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
    ///     @token: Token Name
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
        name: String,
        symbol: String,
        metadata: Object<Metadata>,
        holding_period: u64,
    ) acquires TokenConfig {
        let token_config = borrow_global_mut<TokenConfig>(@base_token_contract);

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
        if (simple_map::contains_key(token_data, &name)) {
            abort error::name_exists()
        } else {
            simple_map::add(
                token_data,
                name,
                TokenData {
                    metadata,
                    holding_period,
                    partial_freeze: simple_map::create(),
                    total_freezed_amount: 0,
                },
            );
        };
    }

    /// Ensuring holding period is passed
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - the token is on hold
    public fun ensure_holding_period_passed(
        token: String,
    ) acquires TokenConfig {
        let holding_period = get_holding_period(token);

        assert!(
            timestamp::now_seconds() > holding_period,
            error::token_held()
        );
    }

    /// Function to check balance frozen state
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address whose balance is going to be ensured as freezed or not
    ///     @amount - Amount of balance to be transferred / use
    ///
    /// Fails when:-
    ///     - balance requested is greater than frozen balance
    ///     - missing TokenConfig struct initialization
    public fun ensure_balance_not_frozen(
        token: String,
        addr: address,
        amount: u64,
    ) acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@base_token_contract).token_data;
        let freeze = simple_map::borrow(&token_data, &token).partial_freeze;

        let frozen_balance = if (simple_map::contains_key(&freeze, &addr)) {
            *simple_map::borrow(&freeze, &addr)
        } else {
            0
        };

        let balance = get_balance(token, addr);
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
    ///     @token: Token Name
    ///     @addr - Address whose balance is going to be ensured as freezed or not
    ///     @amount - Amount of balance to be transferred / use
    ///
    /// Fails when:-
    ///     - amount requested is greater than the user balance
    ///     - missing TokenConfig struct initialization
    fun ensure_balance_exists(
        token: String,
        addr: address,
        amount: u64,
    ) acquires TokenConfig {
        let balance = get_balance(token, addr);
        assert!(
            balance >= amount,
            error::insufficient_balance()
        )
    }
    //:!:>helper functions

    /// Function for partial freeze balance
    /// Some part of tokens are freezed
    /// This function supports batch partial freeze
    /// The address and balances must be passed in ordered manner, such as addresses[0] corresponds to balances[0]
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token: Token Name
    ///     @addrs - Addresses that are going to be freezed partially
    ///     @balances - The amount of tokens that are going to freezed
    ///
    /// Fails when:-
    ///     - 1uantity of addresses and balances are different
    ///     - sender doesn't have either of issuer, transfer agent, freeze or sub_admin rights
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn token
    ///
    /// Emits partial freeze event
    public entry fun partial_freeze(
        sender: &signer,
        token: String,
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
        if (!has_issuer_rights(token, sender_addr)
            && !has_transfer_agent_rights(token, sender_addr)
            && !has_freeze_rights(token, sender_addr)
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
            ensure_balance_exists(token, addr, bal);

        };

        let token_data_map = &mut borrow_global_mut<TokenConfig>(@base_token_contract).token_data;
        let token_data = simple_map::borrow_mut(token_data_map, &token);
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
    ///     @token: Token Name
    ///     @addrs - Addresses that are going to be unfreezed partially
    ///     @balances - The amount of tokens that are going to unfreezed
    ///
    /// Fails when:-
    ///     - quantity of addresses and balances are different
    ///     - sender doesn't have either of issuer, transfer agent, unfreeze or sub_admin rights
    ///     - address not present in the list
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn token
    ///
    /// Emits partial unfreeze event
    public entry fun partial_unfreeze(
        sender: &signer,
        token: String,
        addrs: vector<address>,
        balances: vector<u64>,
    ) acquires TokenConfig {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(token, sender_addr)
            && !has_transfer_agent_rights(token, sender_addr)
            && !has_unfreeze_rights(token, sender_addr)
            && !has_sub_admin_rights(sender_addr)) {
            abort error::unauthorized()
        };

        let token_data_map = &mut borrow_global_mut<TokenConfig>(@base_token_contract).token_data;
        let token_data = simple_map::borrow_mut(token_data_map, &token);
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

    //:!:>view functions
    #[view]
    /// Function to get balance of an account
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address for which the balance will going to be fetched
    ///
    /// Fails when
    ///     - primary token stoarge doesn't have the address and metadata combination
    ///
    /// Returns balance of the address
    public fun get_balance(
        token: String,
        addr: address
    ): u64 acquires TokenConfig {
        let metadata = get_metadata(token);
        let wallet = ensure_primary_store_exists(addr, metadata);
        fungible_asset::balance<FungibleStore>(wallet)
    }

    #[view]
    /// Function to get frozen balance of an account
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address for which the frozen balance will going to be fetched
    ///
    /// Fails when:-
    ///     - missing Token Config for the given token
    ///     - token data doesn't mapped with gievn token
    ///
    /// Returns frozen balance of the address
    public fun get_frozen_balance(token: String, addr: address): u64 acquires TokenConfig {
        let token_data_map = borrow_global<TokenConfig>(@base_token_contract).token_data;
        let freeze_data = simple_map::borrow(&token_data_map, &token).partial_freeze;
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
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - missing Token Config for the given token
    ///     - token data doesn't mapped with gievn token
    ///
    /// Returns the total number of frozen tokens
    public fun get_frozen_tokens(token: String): u128 acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@base_token_contract).token_data;
        simple_map::borrow(&token_data, &token).total_freezed_amount
    }

    #[view]
    /// Function to get metadata
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - missing Token Config for the given token
    ///     - token data doesn't mapped with gievn token
    ///
    /// Returns the metadata of the token
    public fun get_metadata(token: String): Object<Metadata> acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@base_token_contract).token_data;
        simple_map::borrow(&token_data, &token).metadata
    }

    #[view]
    /// Function to get holding period
    ///
    /// Arguements:-
    ///     @token - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Token Config for the given id
    ///     - token data doesn't mapped with gievn id
    ///
    /// Returns the holding period in seconds
    public fun get_holding_period(token: String): u64 acquires TokenConfig {
        let token_data = borrow_global<TokenConfig>(@base_token_contract).token_data;
        simple_map::borrow(&token_data, &token).holding_period
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
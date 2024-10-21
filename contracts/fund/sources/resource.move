module fund::resource {

    use std::string::{Self, String};
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::signer;
    use aptos_framework::timestamp;
    use std::vector;
    use fund::events::{initialize_event_store, emit_init_event, emit_create_fund_event, emit_user_management_fees_event,
        emit_user_dividend_event, emit_fetch_price_event};
    use fund::agent::init_agent_roles;
    use fund::maintainer::{init_maintainers, is_admin};
    use fund::constants;
    use fund::stable_coin::set_stable_coin;
    use pyth::price::{Self, Price};
    use pyth::price_identifier;
    use pyth::pyth;
    use pyth::i64;
    use utils::error;

    friend fund::fund;

    //:!:>resources
    struct Resources has key {
        global_config: SimpleMap<vector<u8>, GlobalConfig>
    }

    struct GlobalConfig has store, drop, copy {
        fund_name: String,
        asset_type: u8,
        issuer_name: String,
        target_aum: u64,
        nav_launch_price: u64,
        issue_timestamp: u64,
        management_fees: SimpleMap<address, u64>,
        dividend: SimpleMap<address, Dividend>,
        nav_latest_price: Price,
    }

    struct Dividend has store, drop, copy {
        token: u64,
        stable_coin: u64,
        fiat: u64,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function to initialize resources
    /// This function can only be called by fund module
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @dai - DAI address for DAI related transactions
    ///     @usdt - USDT address for USDT related transactions
    ///     @usdc - USDC address for USDC related transactions
    ///
    /// Fails when:-
    ///     Resources struct is already initialized
    ///
    /// Emits init event
    public(friend) fun init_resources(
        account: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let acc_addr = signer::address_of(account);

        // Initializing events
        initialize_event_store(account);

        // Init maintaner and make caller as admin
        init_maintainers(account);

        // Initializing agent
        init_agent_roles(account);

        assert!(!exists<Resources>(acc_addr), error::resource_already_exists());
        move_to(
            account,
            Resources {
                global_config: simple_map::create(),
            }
        );

        // Setting stable coin addresses
        set_stable_coin(account, dai, usdt, usdc);

        // Emitting event
        emit_init_event(acc_addr);
    }

    /// Function to create fund configuration
    /// Global variable configuration and initialization
    /// Function to initialize resources
    /// This function can only be called by fund module
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @fund_name - Name of the fund
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @issuer_name - Name of the issuer
    ///     @target_aum - Target Asset Under Management
    ///     @nav_launch_price - Net Asset Value during launch
    ///
    /// Fails when:-
    ///     - Resources struct is not initialized
    ///
    /// Emits create fund event
    public(friend) fun create_and_store_fund(
        token_id: String,
        fund_name: String,
        asset_type: u8,
        issuer_name: String,
        target_aum: u64,
        nav_launch_price: u64,
    ) acquires Resources {
        let global_config=
            &mut borrow_global_mut<Resources>(@fund).global_config;

        let key = *string::bytes(&token_id);
        let def_i64 = i64::new(0, false);
        let def_price = price::new(def_i64, 0, def_i64, 0);

        // Fails when the simple_map already contains the key
        simple_map::add(
            global_config,
            key,
            GlobalConfig {
                fund_name,
                asset_type,
                issuer_name,
                target_aum,
                nav_launch_price,
                issue_timestamp: timestamp::now_seconds(),
                management_fees: simple_map::create(),
                dividend: simple_map::create(),
                nav_latest_price: def_price,
            }
        );

        // Emitting event
        emit_create_fund_event(token_id, fund_name, asset_type, issuer_name);
    }

    /// Function to add user management fees
    /// This function can only be called by fund module
    /// This function supports batch operation
    /// The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be added
    ///     @fees - Fees of management to be added
    ///
    /// Fails when:-
    ///     - management fees map already contains the user and fee combination
    ///     - resource is not mapped with given token_id
    ///     - Resources struct is not initialized
    ///
    /// Emits user management fees event with type Add
    public(friend) fun add_user_management_fees(
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    ) acquires Resources {
        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&fees),
            error::arguements_mismatched()
        );

        let resources= &mut borrow_global_mut<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resources, key);
        let management_fees = &mut global_config.management_fees;
        while (vector::length(&users) > 0) {
            let user = vector::pop_back(&mut users);
            let fee = vector::pop_back(&mut fees);
            // Fails when the simple_map already contains the user
            simple_map::add(management_fees, user, fee);

            // Emitting event
            emit_user_management_fees_event(string::utf8(b"Add"), token_id, user, fee);
        };
    }

    /// Function to update user management fees
    /// Insert value if not exist already
    /// This function can only be called by fund module
    /// This function supports batch operation
    /// The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be updated
    ///     @fees - Fees of management to be updated
    ///
    /// Fails when:-
    ///     - management fees map already contains the user and fee combination
    ///     - resource is not mapped with given token_id
    ///     - Resources struct is not initialized
    ///
    /// Emits user management fees event with type Update
    public(friend) fun update_user_management_fees(
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    ) acquires Resources {
        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&fees),
            error::arguements_mismatched()
        );

        let resources= &mut borrow_global_mut<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resources, key);
        let management_fees = &mut global_config.management_fees;
        while (vector::length(&users) > 0) {
            let user = vector::pop_back(&mut users);
            let fee = &mut vector::pop_back(&mut fees);
            if (simple_map::contains_key(management_fees, &user)) {
                simple_map::remove(management_fees, &user);
            };
            simple_map::add(management_fees, user, *fee);

            // Emitting event
            emit_user_management_fees_event(string::utf8(b"Update"), token_id, user, *fee);
        };
    }

    /// Function to remove user management fees
    /// This function can only be called by fund module
    /// This function supports batch operation
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be removed
    ///
    /// Fails when:-
    ///     - management fees map already contains the user and fee combination
    ///     - resource is not mapped with given token_id
    ///     - Resources struct is not initialized
    ///
    /// Emits user management fees event with type Remove
    public(friend) fun remove_user_management_fees(
        token_id: String,
        users: vector<address>,
    ) acquires Resources {
        let resources= &mut borrow_global_mut<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resources, key);
        let management_fees = &mut global_config.management_fees;
        vector::for_each(users, |user| {
            // Fails when the simple_map doesn't contain the key
            let (addr, fee) = simple_map::remove(management_fees, &user);

            // Emitting event
            emit_user_management_fees_event(string::utf8(b"Remove"), token_id, addr, fee);
        });
    }

    /// Function to add user dividend
    /// This function can only be called by fund module
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @user - Address of the user
    ///     @dividend - Amount of tokens and stable coins going to be shared
    ///
    /// Fails when:-
    ///     - Resources struct is not initialized
    ///
    /// Emits user dividend event
    public(friend) fun add_user_dividend(
        token_id: String,
        asset_type: u8,
        user: address,
        dividend: u64,
    ) acquires Resources {
        let resource= &mut borrow_global_mut<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resource, key);

        let div = Dividend {
            token: 0,
            stable_coin: 0,
            fiat: 0,
        };

        if (asset_type == constants::token()) {
            div.token = dividend;
        } else if (asset_type == constants::stable_coin()) {
            div.stable_coin = dividend;
        } else {
            div.fiat = dividend;
        };

        if (simple_map::contains_key(&global_config.dividend, &user)) {
            let g_div = simple_map::borrow_mut(&mut global_config.dividend, &user);
            *g_div= div;
        } else {
            simple_map::add(&mut global_config.dividend, user, div);
        };

        // Emitting event
        emit_user_dividend_event(string::utf8(b"Add"), token_id, asset_type, user, dividend);
    }

    /// Private function to get current price
    ///
    /// Arguements:-
    ///     @currency_pair - Currency Pair, can be found from here 
    ///                        https://pyth.network/developers/price-feed-ids#aptos-testnet
    ///
    /// Returns current price of given currency pair
    fun fetch_current_price(currency_pair: vector<u8>): Price {
        let price_id = price_identifier::from_byte_vec(currency_pair);
        pyth::get_price_unsafe(price_id)
    }

    /// Private function to get u64 from price
    ///
    /// Arguements:-
    ///     @price - Value in Price format
    /// 
    /// Returns value in u64
    fun get_u64_from_price(price: &Price): u64 {
        let price_i64 = &price::get_price(price);
        i64::get_magnitude_if_positive(price_i64)
    }

    /// Function to get current price
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @currency_pair - Currency Pair
    ///
    /// Fails when:-
    ///     - Resources struct is not initialized
    ///     - sender is not admin
    ///     - resource is not mapped with given token_id
    /// 
    /// Emits fetch price event
    public entry fun fetch_price(
        account: &signer,
        token_id: String,
        currency_pair: vector<u8>,
    ) acquires Resources {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(sender);

        let resource= &mut borrow_global_mut<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resource, key);
        global_config.nav_latest_price = fetch_current_price(currency_pair);

        // Emitting event
        emit_fetch_price_event(token_id, get_u64_from_price(&global_config.nav_latest_price))
    }
    //:!:>helper functions

    //:!:>view functions
    #[view]
    /// Function to get management fees
    /// 
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @user - Address of user for which fees has to fetch
    /// 
    /// Fails when:-
    ///     - Resources struct is not initialized
    ///     - resource is not mapped with given token_id
    /// 
    /// Returns management fees
    public fun get_management_fees(token_id: String, user: address): u64 acquires Resources {
        let resources= &borrow_global<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow(resources, key);
        let management_fees = &global_config.management_fees;
        *simple_map::borrow(management_fees, &user)
    }

    #[view]
    /// Function to get management fees
    /// 
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    /// 
    /// Fails when:-
    ///     - Resources struct is not initialized
    ///     - resource is not mapped with given token_id
    /// 
    /// Return NAV price in u64
    public fun get_nav(token_id: String): u64 acquires Resources {
        let resources= &borrow_global<Resources>(@fund).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow(resources, key);
        let nav_latest_price = &global_config.nav_latest_price;
        get_u64_from_price(nav_latest_price)
    }
    //:!:>view functions
}
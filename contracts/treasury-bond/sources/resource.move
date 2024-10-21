module treasury_bond::resource {

    use std::string::{Self, String};
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::signer;
    use aptos_framework::timestamp;
    use treasury_bond::events::{initialize_event_store, emit_init_event, emit_create_fund_event,
        emit_update_credit_rating};
    use treasury_bond::agent::{init_agent_roles, is_agent};
    use treasury_bond::maintainer::init_maintainers;
    use treasury_bond::stable_coin::set_stable_coin;
    use utils::error;

    friend treasury_bond::treasury_bond;

    //:!:>resources
    struct Resources has key {
        global_config: SimpleMap<vector<u8>, GlobalConfig>
    }

    struct GlobalConfig has store, drop, copy {
        bond_name: String,
        issue_size: u128,
        face_value: u128,
        coupon_rate: u16,
        accrued_interest: u16,
        issue_date: u64,
        maturity_date: u64,
        issuer_name: String,
        coupon_frequency: String,
        credit_rating: String,
    }

    struct Dividend has store, drop, copy {
        token: u64,
        stable_coin: u64,
        fiat: u64,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function to initialize resources
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

    /// Function to create treasury_bond configuration
    public(friend) fun create_and_store_fund(
        token_id: String,
        bond_name: String,
        issue_size: u128,
        face_value: u128,
        coupon_rate: u16,
        accrued_interest: u16,
        maturity_date: u64,
        issuer_name: String,
        coupon_frequency: String,
    ) acquires Resources {
        let global_config= &mut borrow_global_mut<Resources>(@treasury_bond).global_config;
        let key = *string::bytes(&token_id);

        simple_map::add(
            global_config,
            key,
            GlobalConfig {
                bond_name,
                issue_size,
                face_value,
                coupon_rate: coupon_rate * 100,
                accrued_interest,
                issue_date: timestamp::now_seconds(),
                maturity_date,
                issuer_name,
                coupon_frequency,
                credit_rating: string::utf8(b""),
            }
        );

        // Emitting event
        emit_create_fund_event(token_id, bond_name);
    }

    /// Function to update credit rating
    entry fun update_credit_rating(
        sender: &signer,
        token_id: String,
        rating: String,
    ) acquires Resources {
        let sender_addr = signer::address_of(sender);

        // Ensuring authorised sender
        is_agent(token_id, sender_addr);

        let resources= &mut borrow_global_mut<Resources>(@treasury_bond).global_config;
        let key = string::bytes(&token_id);
        let global_config = simple_map::borrow_mut(resources, key);
        let credit_rating = global_config.credit_rating;
        let old = credit_rating;
        credit_rating = rating;

        // Emit credit rating update event
        emit_update_credit_rating(token_id, old, credit_rating);
    }
    //:!:>helper functions

    //:!:>view functions
    #[view]
    /// Function to get global config by token
    public fun get_config(token: String): GlobalConfig acquires Resources {
        let resources= &borrow_global<Resources>(@treasury_bond).global_config;
        let key = string::bytes(&token);
        *simple_map::borrow(resources, key)
    }
    //:!:>view functions
}
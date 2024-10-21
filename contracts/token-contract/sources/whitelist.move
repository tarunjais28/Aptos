module token_contract::whitelist {
    use std::signer;
    use std::error;
    use token_contract::events::emit_whitelist_event;
    use token_contract::maintainers::has_sub_admin_rights;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string;
    use std::vector;
    use token_contract::roles::has_tokenization_agent_rights;

    //:!:>constants
    const ERR_ALREADY_EXIST: u64 = 0;
    const ERR_ARGUMENTS_MISMATCHED: u64 = 1;
    const ERR_UNAUTHORIZED: u64 = 2;
    //:!:>constants

    //:!:>resources
    struct Whitelist has key {
        accounts: SimpleMap<address, u8>,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for initialization
    public fun init_whitelisting(res_signer: &signer) {
        let res_addr = signer::address_of(res_signer);
        assert!(!exists<Whitelist>(res_addr), error::already_exists(ERR_ALREADY_EXIST));

        // Initialization
        move_to(
            res_signer,
            Whitelist {
                accounts: simple_map::create(),
            }
        );
    }
    //:!:>helper functions

    /// Function to add to whitelist
    public entry fun add(
        account: &signer,
        res_addr: address,
        users: vector<address>,
        country_codes: vector<u8>,
    ) acquires Whitelist {
        let addr = signer::address_of(account);

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&country_codes),
            error::invalid_argument(ERR_ARGUMENTS_MISMATCHED)
        );

        // Ensuring authorised sender
        if (!has_sub_admin_rights(res_addr, addr)
            && !has_tokenization_agent_rights(res_addr, addr)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let whitelist = &mut borrow_global_mut<Whitelist>(res_addr).accounts;
        vector::for_each(users, |user| {
           let country_code = vector::pop_back(&mut country_codes);
            simple_map::add(whitelist, user, country_code);

            // Emitting events
            emit_whitelist_event(res_addr, string::utf8(b"add_whitelist"), user, country_code);
        });
    }

    /// Function to remove to whitelist
    public entry fun remove(
        account: &signer,
        res_addr: address,
        users: vector<address>
    ) acquires Whitelist {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        if (!has_sub_admin_rights(res_addr, addr)
            && !has_tokenization_agent_rights(res_addr, addr)) {
          abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let whitelist = &mut borrow_global_mut<Whitelist>(res_addr).accounts;

        vector::for_each(users, |user| {
            let (whitelist_user, country_code) = simple_map::remove(whitelist, &user);

            // Emitting events
            emit_whitelist_event(res_addr, string::utf8(b"remove_whitelist"), whitelist_user, country_code);
        });
    }

    //:!:>view functions
    #[view]
    /// Function to get country code by address
    public fun get_country_code_by_addres(
        res_addr: address,
        addr: address
    ): u8 acquires Whitelist {
        let whitelist = borrow_global<Whitelist>(res_addr).accounts;
        *simple_map::borrow(&whitelist, &addr)
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}

module fungible_tokens::whitelist {
    use std::signer;
    use utils::error;
    use fungible_tokens::events::emit_whitelist_event;
    use fungible_tokens::maintainers::has_sub_admin_rights;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string;
    use std::vector;
    use fungible_tokens::roles::has_tokenization_agent_rights;
    use std::string::String;
    use std::bcs::to_bytes;

    //:!:>resources
    struct Whitelist has key {
        accounts: SimpleMap<vector<u8>, u8>,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for initialization
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///
    /// Fails when:-
    ///     - Whitelist struct is already initialized
    public fun init_whitelisting(account: &signer) {
        assert!(!exists<Whitelist>(@fungible_tokens), error::already_exists());

        // Initialization
        move_to(
            account,
            Whitelist {
                accounts: simple_map::create(),
            }
        );
    }

    /// Helper function to get stoage key
    /// By combining id and address fields to get some unique key for storage mapping
    /// This way the multiple maps can be avoided
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - address that will be used as key
    ///
    /// Returns byte array
    fun get_key(id: String, addr: address): vector<u8> {
        let key = to_bytes(&id);
        vector::append(&mut key, to_bytes(&addr));
        key
    }
    //:!:>helper functions

    /// Function to add to whitelist
    /// This function supports batch whitelisting
    /// The users and country_codes must be passed in ordered manner, such as users[0] corresponds to country_codes[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @users - Addresses that are going to be whitelisted
    ///     @country_codes - The country codes that will be going to be added to corresponding addresses
    ///
    /// Fails when:-
    ///     - quantity of users and country_codes are different
    ///     - sender doesn't have either of tokenization agent or sub_admin rights
    ///     - missing Whitelist struct initilization
    ///     - Whitelist doesn't contains the given id and addr key combination
    ///
    /// Emits whitelisting event
    public entry fun add(
        account: &signer,
        id: String,
        users: vector<address>,
        country_codes: vector<u8>,
    ) acquires Whitelist {
        let addr = signer::address_of(account);

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&country_codes),
            error::arguements_mismatched()
        );

        // Ensuring authorised sender
        if (!has_sub_admin_rights(addr)
            && !has_tokenization_agent_rights(id, addr)) {
            abort error::arguements_mismatched()
        };

        let whitelist = &mut borrow_global_mut<Whitelist>(@fungible_tokens).accounts;
        while (vector::length(&users) > 0) {
            let user = vector::pop_back(&mut users);
            let key = get_key(id, user);
            let country_code = vector::pop_back(&mut country_codes);

            // Fails when the simple_map already contains the key
            simple_map::add(whitelist, key, country_code);

            // Emitting events
            emit_whitelist_event(string::utf8(b"add_whitelist"), user, country_code);
        };
    }

    /// Function to remove to whitelist
    /// This function supports batch whitelisting removal
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @users - Addresses that are going to be removed from whitelist
    ///
    /// Fails when:-
    ///     - sender doesn't have either of tokenization agent or sub_admin rights
    ///     - missing Whitelist struct initilization
    ///     - Whitelist doesn't contains the given id and addr key combination
    ///
    /// Emits whitelisting event
    public entry fun remove(
        account: &signer,
        id: String,
        users: vector<address>,
    ) acquires Whitelist {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        if (!has_sub_admin_rights(addr)
            && !has_tokenization_agent_rights(id, addr)) {
            abort error::unauthorized()
        };

        let whitelist = &mut borrow_global_mut<Whitelist>(@fungible_tokens).accounts;

        vector::for_each(users, |user| {
            let key = get_key(id, user);

            // Fails when the simple_map doesn't contain the key
            let (_, country_code) = simple_map::remove(whitelist, &key);

            // Emitting events
            emit_whitelist_event(string::utf8(b"remove_whitelist"), user, country_code);
        });
    }

    //:!:>view functions
    #[view]
    /// Function to get country code by address
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address for which the country code will be obtained
    ///
    /// Fails when:-
    ///     - missing Whitelist struct initilization
    ///     - Whitelist doesn't contains the given id and addr key combination
    ///
    /// Returns the country code
    public fun get_country_code_by_addres(
        id: String,
        addr: address
    ): u8 acquires Whitelist {
        let whitelist = borrow_global<Whitelist>(@fungible_tokens).accounts;
        let key = get_key(id, addr);
        *simple_map::borrow(&whitelist, &key)
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
module fungible_tokens::maintainers {
    use std::signer;
    use std::vector;
    use fungible_tokens::events::{emit_sub_admins_update_event, emit_admin_update_event};
    use std::option;
    use utils::error;

    //:!:>resources
    struct Maintainers has key {
        admin: address,
        sub_admins: vector<address>,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for initialization
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///     @addr - Address that will be assigned as admin
    ///
    /// Fails when:-
    ///     - Maintainers are already initialized
    public fun init_maintainers(account: &signer, addr: address) {
        assert!(!exists<Maintainers>(@fungible_tokens), error::already_exists());

        // Setting caller as admin
        move_to(
            account,
            Maintainers {
                admin: addr,
                sub_admins: vector::empty(),
            }
        );
    }

    /// Ensuring the given account is admin
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for admin rights
    ///
    /// Fails when:-
    ///     - given address is not admin
    public fun is_admin(addr: address) acquires Maintainers {
        let admin = get_admin();
        assert!(addr == admin, error::not_an_admin());
    }

    /// Ensuring the given account is one of sub_admins
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for sub admin rights
    ///
    /// Fails when:-
    ///     - given address is not one of sub admins
    public fun is_sub_admin(addr: address) acquires Maintainers {
        let sub_admins = get_sub_admins();
        assert!(vector::contains(&sub_admins, &addr), error::not_sub_admin());
    }

    /// Ensuring the given account is one of sub_admins
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for sub admin rights
    ///
    /// Returns:-
    ///     true - when given address has sub admin rights
    ///     false - when given address doesn't have sub admin rights
    public fun has_sub_admin_rights(addr: address): bool acquires Maintainers {
        let sub_admins = get_sub_admins();
        vector::contains(&sub_admins, &addr)
    }
    //:!:>helper functions

    /// Function to update admin
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @new_admin - Address that are going to be new admin
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update admin event
    public entry fun update_admin(account: &signer, new_admin: address) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@fungible_tokens);
        let old_admin = maintainers.admin;

        maintainers.admin = new_admin;

        // Emitting events
        emit_admin_update_event( option::some(vector[old_admin]), option::some(vector[new_admin]))
    }

    /// Function for addition of sub_admins
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addrs - Addresses that are going to be added to sub admins list
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update sub admin event
    public entry fun add_sub_admins(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@fungible_tokens);
        let old_sub_admins = maintainers.sub_admins;

        // Checking for duplicates
        let dup_addresses = vector::filter(addrs, |addr| vector::contains(&old_sub_admins, addr));
        assert!(vector::length(&dup_addresses) == 0, error::already_exists());

        vector::append(&mut maintainers.sub_admins, addrs);

        // Emitting events
        emit_sub_admins_update_event(old_sub_admins, maintainers.sub_admins)
    }

    /// Function for removal of sub_admins
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addrs - Addresses that are going to be removed from sub admins list
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update sub admin event
    public entry fun remove_sub_admins(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@fungible_tokens);
        let old_sub_admins = maintainers.sub_admins;

        let sub_admins = vector::filter(maintainers.sub_admins, |addr| !vector::contains(&addrs, addr));

        // Checking if the addresses to be removed are present or not
        assert!(vector::length(&old_sub_admins) != vector::length(&sub_admins), error::addr_not_found());

        maintainers.sub_admins = sub_admins;

        // Emitting events
        emit_sub_admins_update_event(old_sub_admins, maintainers.sub_admins)
    }

    //:!:>view functions
    #[view]
    /// Function to get all sub_admins
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns list of sub admin addresses
    public fun get_sub_admins(): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(@fungible_tokens).sub_admins
    }

    #[view]
    /// Function to get admin
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns admin address
    public fun get_admin(): address acquires Maintainers {
        borrow_global<Maintainers>(@fungible_tokens).admin
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
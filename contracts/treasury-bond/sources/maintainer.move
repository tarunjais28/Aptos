module treasury_bond::maintainer {
    use std::signer;
    use std::vector;
    use treasury_bond::events::emit_admins_update_event;
    use utils::error;

    //:!:>resources
    struct Maintainers has key {
        admins: vector<address>,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for initialization
    public fun init_maintainers(account: &signer) {
        let addr = signer::address_of(account);
        assert!(!exists<Maintainers>(@treasury_bond), error::already_exists());

        // Setting caller as admin
        move_to(
            account,
            Maintainers {
                admins: vector[addr],
            }
        );

        // Emitting event
        emit_admins_update_event(vector::empty(), vector[addr]);
    }

    /// Ensuring the given account is admin
    public fun is_admin(addr: address) acquires Maintainers {
        let admins = get_admins();
        assert!(vector::contains(&admins, &addr), error::not_an_admin());
    }
    //:!:>helper functions

    //:!:>entry functions
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
    public entry fun add_admins(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@treasury_bond);
        let old_admins = maintainers.admins;

        // Checking for duplicates
        let dup_addresses = vector::filter(addrs, |addr| vector::contains(&old_admins, addr));
        assert!(vector::length(&dup_addresses) == 0, error::already_exists());

        vector::append(&mut maintainers.admins, addrs);

        // Emitting events
        emit_admins_update_event(old_admins, maintainers.admins)
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
    /// Emits update admin event
    public entry fun remove_admins(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@treasury_bond);
        let old_sub_admins = maintainers.admins;

        let admins = vector::filter(maintainers.admins, |addr| !vector::contains(&addrs, addr));

        // Checking if the addresses to be removed are present or not
        assert!(vector::length(&old_sub_admins) != vector::length(&admins), error::addr_not_found());

        maintainers.admins = admins;

        // Emitting events
        emit_admins_update_event(old_sub_admins, maintainers.admins)
    }
    //:!:>entry functions

    //:!:>view functions
    #[view]
    /// Function to get admin
    public fun get_admins(): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(@treasury_bond).admins
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
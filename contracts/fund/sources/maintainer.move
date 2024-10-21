module fund::maintainer {
    use std::signer;
    use aptos_framework::account::SignerCapability;
    use std::vector;
    use std::option;
    use fund::events::emit_admin_update_event;
    use utils::error;

    //:!:>resources
    struct Maintainers has key {
        admin: address,
        sub_admins: vector<address>,
    }

    struct ResourceAccount has key, drop, store {
        resource_address: address,
        resource_capability: SignerCapability,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for initialization
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///
    /// Fails when:-
    ///     - Maintainers are already initialized
    ///
    /// Emits admin update event
    public fun init_maintainers(account: &signer) {
        let addr = signer::address_of(account);
        assert!(!exists<Maintainers>(@fund), error::already_exists());

        // Setting caller as admin
        move_to(
            account,
            Maintainers {
                admin: addr,
                sub_admins: vector::empty(),
            }
        );

        // Emitting event
        emit_admin_update_event(option::none(), addr);
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
    //:!:>helper functions

    //:!:>entry functions
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

        let maintainers = borrow_global_mut<Maintainers>(@fund);
        let old_admin = maintainers.admin;

        maintainers.admin = new_admin;

        // Emitting events
        emit_admin_update_event(option::some(old_admin), new_admin)
    }
    //:!:>entry functions

    //:!:>view functions
    #[view]
    /// Function to get admin
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Return the address of the admin
    public fun get_admin(): address acquires Maintainers {
        borrow_global<Maintainers>(@fund).admin
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
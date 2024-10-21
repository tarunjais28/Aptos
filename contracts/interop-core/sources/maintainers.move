module interop_core::maintainers {
    use std::signer;
    use std::vector;
    use interop_core::events::{emit_admins_update_event, emit_update_executer_event};
    use utils::error;

    //:!:>resources
    struct Maintainers has key {
        admins: vector<address>,
        executer: address,
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
    public fun init_maintainers(account: &signer, addr: address, executer: address) {
        assert!(!exists<Maintainers>(@interop_core), error::already_exists());

        // Setting caller as admin
        move_to(
            account,
            Maintainers {
                admins: vector[addr],
                executer
            }
        );
    }

    /// Ensuring the given account is one of admins
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for admin rights
    ///
    /// Fails when:-
    ///     - given address is not one of admins
    public fun is_admin(addr: address) acquires Maintainers {
        let admins = get_admins();
        assert!(vector::contains(&admins, &addr), error::not_an_admin());
    }

    /// Ensuring the given account is one of admins
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for admin rights
    ///
    /// Returns:-
    ///     true - when given address has admin rights
    ///     false - when given address doesn't have admin rights
    public fun has_admin_rights(addr: address): bool acquires Maintainers {
        let admins = get_admins();
        vector::contains(&admins, &addr)
    }

    /// Ensuring the given account is executer
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for executer rights
    ///
    /// Fails when:-
    ///     - given address is not executer
    public fun is_executer(addr: address) acquires Maintainers {
        let executer = get_executer();
        assert!(executer == addr, error::not_an_executer());
    }

    /// Ensuring the given account is executer
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for admin rights
    ///
    /// Returns:-
    ///     true - when given address has executer rights
    ///     false - when given address doesn't have executer rights
    public fun has_executer_rights(addr: address): bool acquires Maintainers {
        let executer = get_executer();
        executer == addr
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

        let maintainers = borrow_global_mut<Maintainers>(@interop_core);
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

        let maintainers = borrow_global_mut<Maintainers>(@interop_core);
        let old_sub_admins = maintainers.admins;

        let admins = vector::filter(maintainers.admins, |addr| !vector::contains(&addrs, addr));

        // Checking if the addresses to be removed are present or not
        assert!(vector::length(&old_sub_admins) != vector::length(&admins), error::addr_not_found());

        maintainers.admins = admins;

        // Emitting events
        emit_admins_update_event(old_sub_admins, maintainers.admins)
    }

    /// Function for updation of executer
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addr - Address that are going to be added as executer
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update sub admin event
    public entry fun update_executer(account: &signer, addr: address) acquires Maintainers {
        let caller = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(caller);

        let maintainers = borrow_global_mut<Maintainers>(@interop_core);
        let old = maintainers.executer;

        maintainers.executer = addr;

        // Emitting events
        emit_update_executer_event(old, maintainers.executer)
    }

    //:!:>view functions
    #[view]
    /// Function to get all sub_admins
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns list of sub admin addresses
    public fun get_admins(): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(@interop_core).admins
    }

    #[view]
    /// Function to get executer
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns list of admin addresses
    public fun get_executer(): address acquires Maintainers {
        borrow_global<Maintainers>(@interop_core).executer
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
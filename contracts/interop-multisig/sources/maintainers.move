module interop_multisig::maintainers {
    use std::signer;
    use std::vector;
    use interop_multisig::events::{emit_admins_update_event, emit_validator_update_event};
    use utils::error;

    //:!:>resources
    struct Maintainers has key {
        admins: vector<address>,
        validators: vector<address>,
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
        assert!(!exists<Maintainers>(@interop_multisig), error::already_exists());

        // Setting caller as admin
        move_to(
            account,
            Maintainers {
                admins: vector[addr],
                validators: vector::empty(),
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

    /// Ensuring the given account is one of validators
    ///
    /// Arguements:-
    ///     @addr - Address going to be checked for admin rights
    ///
    /// Fails when:-
    ///     - given address is not one of validators
    public fun is_validator(addr: address) acquires Maintainers {
        let validators = get_validators();
        assert!(vector::contains(&validators, &addr), error::not_an_validator());
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
    //:!:>helper functions

    //:!:>entry functions
    /// Function for addition of admins
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addrs - Addresses that are going to be added to admins list
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update admin event
    public entry fun add_admins(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@interop_multisig);
        let old_admins = maintainers.admins;

        // Checking for duplicates
        let dup_addresses = vector::filter(addrs, |addr| vector::contains(&old_admins, addr));
        assert!(vector::length(&dup_addresses) == 0, error::already_exists());

        vector::append(&mut maintainers.admins, addrs);

        // Emitting events
        emit_admins_update_event(old_admins, maintainers.admins)
    }

    /// Function for removal of admins
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

        let maintainers = borrow_global_mut<Maintainers>(@interop_multisig);
        let old_admins = maintainers.admins;

        let admins = vector::filter(maintainers.admins, |addr| !vector::contains(&addrs, addr));

        // Checking if the addresses to be removed are present or not
        assert!(vector::length(&old_admins) != vector::length(&admins), error::addr_not_found());

        maintainers.admins = admins;

        // Emitting events
        emit_admins_update_event(old_admins, maintainers.admins)
    }

    /// Function for addition of validators
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addrs - Addresses that are going to be added to validator list
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update validator event
    public entry fun add_validators(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@interop_multisig);
        let old_validators = maintainers.validators;

        // Checking for duplicates
        let dup_addresses = vector::filter(addrs, |addr| vector::contains(&old_validators, addr));
        assert!(vector::length(&dup_addresses) == 0, error::already_exists());

        vector::append(&mut maintainers.validators, addrs);

        // Emitting events
        emit_validator_update_event(old_validators, maintainers.validators)
    }

    /// Function for removal of validators
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @addrs - Addresses that are going to be removed from validator list
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update validator event
    public entry fun remove_validators(account: &signer, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(addr);

        let maintainers = borrow_global_mut<Maintainers>(@interop_multisig);
        let old_validators = maintainers.validators;

        let validators = vector::filter(maintainers.validators, |addr| !vector::contains(&addrs, addr));

        // Checking if the addresses to be removed are present or not
        assert!(vector::length(&old_validators) != vector::length(&validators), error::addr_not_found());

        maintainers.validators = validators;

        // Emitting events
        emit_validator_update_event(old_validators, maintainers.validators)
    }
    //:!:>entry functions

    //:!:>view functions
    #[view]
    /// Function to get all sub_admins
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns list of sub admin addresses
    public fun get_admins(): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(@interop_multisig).admins
    }

    #[view]
    /// Function to get validators
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns list of admin addresses
    public fun get_validators(): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(@interop_multisig).validators
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
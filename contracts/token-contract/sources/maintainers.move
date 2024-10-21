module token_contract::maintainers {
    use std::signer;
    use std::error;
    use aptos_framework::account::SignerCapability;
    use std::vector;
    use token_contract::events::{emit_sub_admins_update_event, emit_admin_update_event};
    use std::option;

    //:!:>constants
    const ERR_NOT_ADMIN: u64 = 0;
    const ERR_NOT_SUB_ADMIN: u64 = 1;
    const ERR_ALREADY_EXIST: u64 = 3;
    //:!:>constants

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
    public fun init_maintainers(res_signer: &signer, addr: address) {
        let res_addr = signer::address_of(res_signer);
        assert!(!exists<Maintainers>(res_addr), error::already_exists(ERR_ALREADY_EXIST));

        // Setting caller as admin
        move_to(
            res_signer,
            Maintainers {
                admin: addr,
                sub_admins: vector::empty(),
            }
        );
    }

    /// Ensuring the given account is admin
    public fun is_admin(res_addr: address, addr: address) acquires Maintainers {
        let admin = get_admin(res_addr);
        assert!(addr == admin, error::not_found(ERR_NOT_ADMIN));
    }

    /// Ensuring the given account is one of sub_admins
    public fun is_sub_admin(res_addr: address, addr: address) acquires Maintainers {
        let sub_admins = get_sub_admins(res_addr);
        assert!(vector::contains(&sub_admins, &addr), error::not_found(ERR_NOT_SUB_ADMIN));
    }

    /// Ensuring the given account is one of sub_admins
    public fun has_sub_admin_rights(res_addr: address, addr: address): bool acquires Maintainers {
        let sub_admins = get_sub_admins(res_addr);
        vector::contains(&sub_admins, &addr)
    }
    //:!:>helper functions

    /// Function to update admin
    public entry fun update_admin(account: &signer, res_addr: address, new_admin: address) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(res_addr, addr);

        let maintainers = borrow_global_mut<Maintainers>(res_addr);
        let old_admin = maintainers.admin;

        maintainers.admin = new_admin;

        // Emitting events
        emit_admin_update_event(res_addr, option::some(vector[old_admin]), option::some(vector[new_admin]))
    }

    /// Function for addition of sub_admins
    public entry fun add_sub_admins(account: &signer, res_addr: address, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(res_addr, addr);

        let maintainers = borrow_global_mut<Maintainers>(res_addr);
        let old_sub_admins = maintainers.sub_admins;

        vector::append(&mut maintainers.sub_admins, addrs);

        // Emitting events
        emit_sub_admins_update_event(res_addr, old_sub_admins, maintainers.sub_admins)
    }

    /// Function for removal of sub_admins
    public entry fun remove_sub_admins(account: &signer, res_addr: address, addrs: vector<address>) acquires Maintainers {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(res_addr, addr);

        let maintainers = borrow_global_mut<Maintainers>(res_addr);
        let old_sub_admins = maintainers.sub_admins;

        let sub_admins = vector::filter(maintainers.sub_admins, |addr| !vector::contains(&addrs, addr));
        maintainers.sub_admins = sub_admins;

        // Emitting events
        emit_sub_admins_update_event(res_addr, old_sub_admins, maintainers.sub_admins)
    }

    //:!:>view functions
    #[view]
    /// Function to get all sub_admins
    public fun get_sub_admins(addr: address): vector<address> acquires Maintainers {
        borrow_global<Maintainers>(addr).sub_admins
    }

    #[view]
    /// Function to get admin
    public fun get_admin(addr: address): address acquires Maintainers {
        borrow_global<Maintainers>(addr).admin
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
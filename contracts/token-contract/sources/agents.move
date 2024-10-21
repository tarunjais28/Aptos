module token_contract::agents {

    use std::signer;
    use std::error;
    use std::vector;
    use token_contract::maintainers::is_sub_admin;
    use token_contract::events::emit_agent_access_update_event;

    //:!:>constants
    const ERR_ALREADY_ASSIGNED: u64 = 0;
    const ERR_NO_ADMIN_ACCESS: u64 = 1;
    const ERR_NO_MINT_ACCESS: u64 = 2;
    const ERR_NO_BURN_ACCESS: u64 = 3;
    const ERR_NO_TRANSFER_ACCESS: u64 = 4;
    const ERR_NO_FORCE_TRANSFER_ACCESS: u64 = 5;
    const ERR_NO_FREEZE_ACCESS: u64 = 6;
    const ERR_NO_UNFREEZE_ACCESS: u64 = 7;
    const ERR_NO_DEPOSIT_ACCESS: u64 = 8;
    const ERR_NO_DELETE_ACCESS: u64 = 9;
    const ERR_NO_UNSPECIFIED_ACCESS: u64 = 10;
    const ERR_NO_WITHDRAW_ACCESS: u64 = 11;
    const ERR_ALREADY_ASSIGNED_ACCESS: u64 = 12;

    const ADMIN: u64 = 0;
    const MINT: u64 = 1;
    const BURN: u64 = 2;
    const TRANSFER: u64 = 3;
    const FORCE_TRANSFER: u64 = 4;
    const FREEZE: u64 = 5;
    const UNFREEZE: u64 = 6;
    const DEPOSIT: u64 = 7;
    const DELETE: u64 = 8;
    const UNSPECIFIED: u64 = 9;
    const WITHDRAW: u64 = 10;
    //:!:>constants

    //:!:>resources
    struct Agent has key, copy {
         admin: vector<address>,
         mint: vector<address>,
         burn:vector<address>,
         transfer: vector<address>,
         force_transfer: vector<address>,
         freeze: vector<address>,
         unfreeze: vector<address>,
         deposit: vector<address>,
         delete: vector<address>,
         unspecified: vector<address>,
         withdraw: vector<address>
    }
    //:!:>resources

    //:!:>helper functions
    /// Function initialize issuer, transfer_agent and tokenization_agent
    public fun init_agent_roles(res_account: &signer) {
        init_agent(res_account);
    }

    /// Function for default issuer
    public fun create_default_agent(): Agent {
        Agent {
            admin: vector::empty(),
            mint: vector::empty(),
            burn: vector::empty(),
            transfer:vector::empty(),
            force_transfer: vector::empty(),
            freeze: vector::empty(),
            unfreeze: vector::empty(),
            deposit: vector::empty(),
            delete: vector::empty(),
            unspecified: vector::empty(),
            withdraw: vector::empty(),
        }
    }

    /// Function to initialize issuer
    fun init_agent(res_account: &signer) {
        let res_addr = signer::address_of(res_account);
        assert!(!exists<Agent>(res_addr), error::already_exists(ERR_ALREADY_ASSIGNED));

        move_to(res_account, create_default_agent());
    }

    /// Function to asign agent roles
    fun assign_agent_role(res_addr: address, addr: address, role: vector<u64>) acquires Agent {
        let agents=borrow_global_mut<Agent>(res_addr);
        vector::for_each(role, |role| {
            if(role == ADMIN) {
                assert!(vector::contains(&agents.admin,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.admin, addr);
            };
            if(role == MINT) {
                assert!(vector::contains(&agents.mint,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.mint, addr);
            };
            if(role == BURN) {
                assert!(vector::contains(&agents.burn,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.burn, addr);
            };
            if(role == TRANSFER) {
                assert!(vector::contains(&agents.transfer,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.transfer, addr);
            };
            if(role == FORCE_TRANSFER) {
                assert!(vector::contains(&agents.force_transfer,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.force_transfer, addr);
            };
            if(role == FREEZE) {
                assert!(vector::contains(&agents.freeze,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.freeze, addr);
            };
            if(role == UNFREEZE) {
                assert!(vector::contains(&agents.unfreeze,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.unfreeze, addr);
            };
            if(role == DEPOSIT) {
                assert!(vector::contains(&agents.deposit,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.deposit, addr);
            };
            if(role == DELETE) {
                assert!(vector::contains(&agents.delete,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.delete, addr);
            };
            if(role == UNSPECIFIED) {
                assert!(vector::contains(&agents.unspecified,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.unspecified, addr);
            };
            if(role == WITHDRAW) {
                assert!(vector::contains(&agents.withdraw,&addr), error::already_exists(ERR_ALREADY_ASSIGNED_ACCESS));
                vector::push_back(&mut agents.withdraw, addr);
            };
        });
    }

    /// Function to unassign agent role
    fun unassign_agent_role(res_addr: address, addr: address, role: vector<u64>) acquires Agent {
        let agents=borrow_global_mut<Agent>(res_addr);
        vector::for_each(role, |role| {
            if(role == ADMIN) {
                let (res, index) = vector::index_of(&agents.admin,&addr);
                assert!(res, error::unauthenticated(ERR_NO_ADMIN_ACCESS));
                vector::remove(&mut agents.admin, index);
            };
            if(role == MINT) {
                let (res, index) = vector::index_of(&agents.mint,&addr);
                assert!(res, error::unauthenticated(ERR_NO_MINT_ACCESS));
                vector::remove(&mut agents.mint, index);
            };
            if(role == BURN) {
                let (res, index) = vector::index_of(&agents.burn,&addr);
                assert!(res, error::unauthenticated(ERR_NO_BURN_ACCESS));
                vector::remove(&mut agents.burn, index);
            };
            if(role == TRANSFER) {
                let (res, index) = vector::index_of(&agents.transfer,&addr);
                assert!(res, error::unauthenticated(ERR_NO_TRANSFER_ACCESS));
                vector::remove(&mut agents.transfer, index);
            };
            if(role == FORCE_TRANSFER) {
                let (res, index) = vector::index_of(&agents.force_transfer,&addr);
                assert!(res, error::unauthenticated(ERR_NO_FORCE_TRANSFER_ACCESS));
                vector::remove(&mut agents.force_transfer, index);
            };
            if(role == FREEZE) {
                let (res, index) = vector::index_of(&agents.freeze,&addr);
                assert!(res, error::unauthenticated(ERR_NO_FREEZE_ACCESS));
                vector::remove(&mut agents.freeze, index);
            };
            if(role == UNFREEZE) {
                let (res, index) = vector::index_of(&agents.unfreeze,&addr);
                assert!(res, error::unauthenticated(ERR_NO_UNFREEZE_ACCESS));
                vector::remove(&mut agents.unfreeze, index);
            };
            if(role == DEPOSIT) {
                let (res, index) = vector::index_of(&agents.deposit,&addr);
                assert!(res, error::unauthenticated(ERR_NO_DEPOSIT_ACCESS));
                vector::remove(&mut agents.deposit, index);
            };
            if(role == DELETE) {
                let (res, index) = vector::index_of(&agents.delete,&addr);
                assert!(res, error::unauthenticated(ERR_NO_DELETE_ACCESS));
                vector::remove(&mut agents.delete, index);
            };
            if(role == UNSPECIFIED) {
                let (res, index) = vector::index_of(&agents.unspecified,&addr);
                assert!(res, error::unauthenticated(ERR_NO_UNSPECIFIED_ACCESS));
                vector::remove(&mut agents.unspecified, index);
            };
            if(role == WITHDRAW) {
                let (res, index) = vector::index_of(&agents.withdraw,&addr);
                assert!(res, error::unauthenticated(ERR_NO_WITHDRAW_ACCESS));
                vector::remove(&mut agents.withdraw, index);
            };
        });
    }

    /// Function to check admin rights
    public fun has_admin_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.admin, &addr)
    }

    /// Function to check mint rights
    public fun has_mint_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.mint, &addr)
    }

    /// Function to check burn rights
    public fun has_burn_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.burn, &addr)
    }

    /// Function to check transfer rights
    public fun has_transfer_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.transfer, &addr)
    }

    /// Function to check force transfer rights
    public fun has_force_transfer_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.force_transfer, &addr)
    }

    /// Function to check freeze rights
    public fun has_freeze_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.freeze, &addr)
    }

    /// Function to check unfreeze rights
    public fun has_unfreeze_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.unfreeze, &addr)
    }

    /// Function to check deposit rights
    public fun has_deposit_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.deposit, &addr)
    }

    /// Function to check delete rights
    public fun has_delete_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.delete, &addr)
    }

    /// Function to check unspecified rights
    public fun has_unspecified_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.unspecified, &addr)
    }

    /// Function to check withdraw rights
    public fun has_withdraw_rights(res_addr: address, addr: address): bool acquires Agent {
        let agents= borrow_global_mut<Agent>(res_addr);
        vector::contains(&agents.withdraw, &addr)
    }
    //:!:>helper functions

    /// Function to grant agent roles
    public entry fun grant_access_to_agent(
        account: &signer, 
        res_addr: address, 
        addrs: address, 
        roles: vector<u64>
    ) acquires Agent {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        assign_agent_role(res_addr, addrs,roles);

        // Emitting events
        emit_agent_access_update_event(
            res_addr,
            roles,
            addrs,
        );
    }

    /// Function to ungrant agent roles
    public entry fun ungrant_access_to_agent(
        account: &signer, 
        res_addr: address, 
        addrs: address,
        roles: vector<u64>
    ) acquires Agent {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        unassign_agent_role(res_addr, addrs,roles);

        // Emitting events
        emit_agent_access_update_event(
            res_addr,
            roles,
            addrs,
        );
    }
}

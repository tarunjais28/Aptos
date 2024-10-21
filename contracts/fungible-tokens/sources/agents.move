module fungible_tokens::agents {

    use std::signer;
    use std::vector;
    use fungible_tokens::maintainers::is_sub_admin;
    use fungible_tokens::events::emit_agent_access_update_event;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string::String;
    use utils::constants;
    use utils::error;

    //:!:>resources
    struct AgentRights has key, copy {
        rights: SimpleMap<String, Agents>
    }

    struct Agents has store, copy, drop {
         admin: vector<address>,
         mint: vector<address>,
         burn: vector<address>,
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
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///
    /// Fails when:-
    ///     - Agents are already initialized
    public fun init_agent_roles(account: &signer) {
        assert!(!exists<AgentRights>(@fungible_tokens), error::already_exists());

        move_to(
            account,
            AgentRights {
                rights: simple_map::create()
            }
        );
    }

    /// Function to create new agents with default values
    public fun create_new_agents(): Agents {
        Agents {
            admin: vector::empty(),
            mint: vector::empty(),
            burn: vector::empty(),
            transfer: vector::empty(),
            force_transfer: vector::empty(),
            freeze: vector::empty(),
            unfreeze: vector::empty(),
            deposit: vector::empty(),
            delete: vector::empty(),
            unspecified: vector::empty(),
            withdraw: vector::empty(),
        }
    }

    /// Function for adding roles
    ///
    /// Arguements:-
    ///     @agents - Instance of agents struct
    ///     @roles - List of roles to be assigned
    ///     @addr - Address to which the roles are getting assigned
    ///
    /// Fails when:-
    ///     - trying to assign same role again
    fun add_roles(agents: &mut Agents, roles: vector<u8>, addr: address) {
        vector::for_each(roles, |role| {
            if(role == constants::get_admin()) {
                assert!(!vector::contains(&agents.admin,&addr), error::already_assigned());
                vector::push_back(&mut agents.admin, addr);
            };
            if(role == constants::get_mint()) {
                assert!(!vector::contains(&agents.mint,&addr), error::already_assigned());
                vector::push_back(&mut agents.mint, addr);
            };
            if(role == constants::get_burn()) {
                assert!(!vector::contains(&agents.burn,&addr), error::already_assigned());
                vector::push_back(&mut agents.burn, addr);
            };
            if(role == constants::get_transer()) {
                assert!(!vector::contains(&agents.transfer,&addr), error::already_assigned());
                vector::push_back(&mut agents.transfer, addr);
            };
            if(role == constants::get_force_transer()) {
                assert!(!vector::contains(&agents.force_transfer,&addr), error::already_assigned());
                vector::push_back(&mut agents.force_transfer, addr);
            };
            if(role == constants::get_freeze()) {
                assert!(!vector::contains(&agents.freeze,&addr), error::already_assigned());
                vector::push_back(&mut agents.freeze, addr);
            };
            if(role == constants::get_unfreeze()) {
                assert!(!vector::contains(&agents.unfreeze,&addr), error::already_assigned());
                vector::push_back(&mut agents.unfreeze, addr);
            };
            if(role == constants::get_deposit()) {
                assert!(!vector::contains(&agents.deposit,&addr), error::already_assigned());
                vector::push_back(&mut agents.deposit, addr);
            };
            if(role == constants::get_delete()) {
                assert!(!vector::contains(&agents.delete,&addr), error::already_assigned());
                vector::push_back(&mut agents.delete, addr);
            };
            if(role == constants::get_unspecified()) {
                assert!(!vector::contains(&agents.unspecified,&addr), error::already_assigned());
                vector::push_back(&mut agents.unspecified, addr);
            };
            if(role == constants::get_withdraw()) {
                assert!(!vector::contains(&agents.withdraw,&addr), error::already_assigned());
                vector::push_back(&mut agents.withdraw, addr);
            };
        });
    }

    /// Function to assign agent roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which the roles are getting assigned
    ///     @roles - List of roles to be assigned
    ///
    /// Fails when:-
    ///     - AgentRights struct is not initialized
    fun assign_agent_role(id: String, addr: address, roles: vector<u8>) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@fungible_tokens).rights;

        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow_mut(rights, &id);
            add_roles(agents, roles, addr);
        } else {
            let agents = create_new_agents();
            add_roles(&mut agents, roles, addr);
            simple_map::add(rights, id, agents);
        };
    }

    /// Function for removing roles
    ///
    /// Arguements:-
    ///     @agents - Instance of agents struct
    ///     @roles - List of roles to be removed
    ///     @addr - Address to which the roles are getting removed
    ///
    /// Fails when:-
    ///     - any role is not assigned
    fun remove_roles(agents: &mut Agents, roles: vector<u8>, addr: address) {
        vector::for_each(roles, |role| {
            if(role == constants::get_admin()) {
                let (res, index) = vector::index_of(&agents.admin,&addr);
                assert!(res, error::no_admin_access());
                vector::remove(&mut agents.admin, index);
            };
            if(role == constants::get_mint()) {
                let (res, index) = vector::index_of(&agents.mint,&addr);
                assert!(res, error::no_mint_access());
                vector::remove(&mut agents.mint, index);
            };
            if(role == constants::get_burn()) {
                let (res, index) = vector::index_of(&agents.burn,&addr);
                assert!(res, error::no_burn_access());
                vector::remove(&mut agents.burn, index);
            };
            if(role == constants::get_transer()) {
                let (res, index) = vector::index_of(&agents.transfer,&addr);
                assert!(res, error::no_transfer_access());
                vector::remove(&mut agents.transfer, index);
            };
            if(role == constants::get_force_transer()) {
                let (res, index) = vector::index_of(&agents.force_transfer,&addr);
                assert!(res, error::no_force_transfer_access());
                vector::remove(&mut agents.force_transfer, index);
            };
            if(role == constants::get_freeze()) {
                let (res, index) = vector::index_of(&agents.freeze,&addr);
                assert!(res, error::no_freeze_access());
                vector::remove(&mut agents.freeze, index);
            };
            if(role == constants::get_unfreeze()) {
                let (res, index) = vector::index_of(&agents.unfreeze,&addr);
                assert!(res, error::no_unfreeze_access());
                vector::remove(&mut agents.unfreeze, index);
            };
            if(role == constants::get_deposit()) {
                let (res, index) = vector::index_of(&agents.deposit,&addr);
                assert!(res, error::no_deposit_access());
                vector::remove(&mut agents.deposit, index);
            };
            if(role == constants::get_delete()) {
                let (res, index) = vector::index_of(&agents.delete,&addr);
                assert!(res, error::no_delete_access());
                vector::remove(&mut agents.delete, index);
            };
            if(role == constants::get_unspecified()) {
                let (res, index) = vector::index_of(&agents.unspecified,&addr);
                assert!(res, error::no_unspecified_access());
                vector::remove(&mut agents.unspecified, index);
            };
            if(role == constants::get_withdraw()) {
                let (res, index) = vector::index_of(&agents.withdraw,&addr);
                assert!(res, error::no_withdraw_access());
                vector::remove(&mut agents.withdraw, index);
            };
        });
    }

    /// Function to unassign agent role
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which the roles are getting removed
    ///     @roles - List of roles to be removed
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///     - rights is not mapped with given id
    fun unassign_agent_role(id: String, addr: address, roles: vector<u8>) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@fungible_tokens).rights;
        let agents = simple_map::borrow_mut(rights, &id);
        remove_roles(agents, roles, addr);
    }

    /// Function to check admin rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which admin rights is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has admin rights
    ///     - false, when the given address doesn't have admin rights
    public fun has_admin_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.admin, &addr)
        } else {
            false
        }
    }

    /// Function to check mint rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which mint rights is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has mint rights
    ///     - false, when the given address doesn't have mint rights
    public fun has_mint_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.mint, &addr)
        } else {
            false
        }
    }

    /// Function to check burn rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which burn rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has burn rights
    ///     - false, when the given address doesn't have burn rights
    public fun has_burn_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.burn, &addr)
        } else {
            false
        }
    }

    /// Function to check transfer rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which transfer rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has transfer rights
    ///     - false, when the given address doesn't have transfer rights
    public fun has_transfer_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.transfer, &addr)
        } else {
            false
        }
    }

    /// Function to check force transfer rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which force transfer rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has force transfer rights
    ///     - false, when the given address doesn't have force transfer rights
    public fun has_force_transfer_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.force_transfer, &addr)
        } else {
            false
        }
    }

    /// Function to check freeze rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which freeze rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has freeze rights
    ///     - false, when the given address doesn't have freeze rights
    public fun has_freeze_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.freeze, &addr)
        } else {
            false
        }
    }

    /// Function to check unfreeze rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which unfreeze rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has unfreeze rights
    ///     - false, when the given address doesn't have unfreeze rights
    public fun has_unfreeze_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.unfreeze, &addr)
        } else {
            false
        }
    }

    /// Function to check deposit rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which deposit rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has deposit rights
    ///     - false, when the given address doesn't have deposit rights
    public fun has_deposit_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.deposit, &addr)
        } else {
            false
        }
    }

    /// Function to check delete rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which delete rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has delete rights
    ///     - false, when the given address doesn't have delete rights
    public fun has_delete_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.delete, &addr)
        } else {
            false
        }
    }

    /// Function to check unspecified rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which unspecified rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has unspecified rights
    ///     - false, when the given address doesn't have unspecified rights
    public fun has_unspecified_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.unspecified, &addr)
        } else {
            false
        }
    }

    /// Function to check withdraw rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address to which withdraw rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has withdraw rights
    ///     - false, when the given address doesn't have withdraw rights
    public fun has_withdraw_rights(id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fungible_tokens).rights;
        if (simple_map::contains_key(rights, &id)) {
            let agents = simple_map::borrow(rights, &id);
            vector::contains(&agents.withdraw, &addr)
        } else {
            false
        }
    }
    //:!:>helper functions

    /// Function to grant agent roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addrs - Address to which accesses are going to be granted
    ///     @roles - List of roles to be assigned
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///     - sender doesn't have admin rights
    ///
    /// Emits agent access update event role
    public entry fun grant_access_to_agent(
        account: &signer, 
        id: String,
        addrs: address, 
        roles: vector<u8>
    ) acquires AgentRights {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(addr);

        assign_agent_role(id, addrs, roles);

        // Emitting events
        emit_agent_access_update_event(
            roles,
            addrs,
        );
    }

    /// Function to ungrant agent roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addrs - Address to which accesses are going to be removed
    ///     @roles - List of roles to be removed
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///     - sender doesn't have admin rights
    ///
    /// Emits agent access update event role
    public entry fun ungrant_access_to_agent(
        account: &signer,
        id: String,
        addrs: address,
        roles: vector<u8>
    ) acquires AgentRights {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(addr);

        unassign_agent_role(id, addrs, roles);

        // Emitting events
        emit_agent_access_update_event(
            roles,
            addrs,
        );
    }

    //:!:>view functions
    #[view]
    /// Function to get roles for an address
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address whose roles will be fetched
    ///
    /// Returns either the list of roles of the given address or none
    public fun get_roles_for_address(
        id: String,
        addr: address,
    ): vector<String> acquires AgentRights {
        let roles = vector::empty<String>();
        let rights = &borrow_global_mut<AgentRights>(@fungible_tokens).rights;
        let agents = simple_map::borrow(rights, &id);
        if (vector::contains(&agents.admin, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_admin()) )
        };
        if (vector::contains(&agents.mint, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_mint()) )
        };
        if (vector::contains(&agents.burn, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_burn()) )
        };
        if (vector::contains(&agents.transfer, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_transer()) )
        };
        if (vector::contains(&agents.force_transfer, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_force_transer()) )
        };
        if (vector::contains(&agents.freeze, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_freeze()) )
        };
        if (vector::contains(&agents.unfreeze, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_unfreeze()) )
        };
        if (vector::contains(&agents.deposit, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_deposit()) )
        };
        if (vector::contains(&agents.delete, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_delete()) )
        };
        if (vector::contains(&agents.unspecified, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_unspecified()) )
        };
        if (vector::contains(&agents.withdraw, &addr)) {
            vector::push_back(&mut roles, constants::get_role(constants::get_withdraw()) )
        };

        roles
    }
    //:!:>view functions
}

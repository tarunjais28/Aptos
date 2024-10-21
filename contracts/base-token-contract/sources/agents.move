module base_token_contract::agents {

    use std::signer;
    use std::vector;
    use base_token_contract::maintainers::is_sub_admin;
    use base_token_contract::events::emit_agent_access_update_event;
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
        assert!(!exists<AgentRights>(@base_token_contract), error::already_exists());

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
        // Iterate through each role provided
        vector::for_each(roles, |role| {
            // Check if the role is admin
            if(role == constants::get_admin()) {
                // Ensure the address is not already assigned as admin
                assert!(!vector::contains(&agents.admin,&addr), error::already_assigned());
                // Add the address to the admin role
                vector::push_back(&mut agents.admin, addr);
            };

            // Check if the role is mint
            if(role == constants::get_mint()) {
                // Ensure the address is not already assigned as mint
                assert!(!vector::contains(&agents.mint,&addr), error::already_assigned());
                // Add the address to the mint role
                vector::push_back(&mut agents.mint, addr);
            };

            // Check if the role is burn
            if(role == constants::get_burn()) {
                // Ensure the address is not already assigned as burn
                assert!(!vector::contains(&agents.burn,&addr), error::already_assigned());
                // Add the address to the burn role
                vector::push_back(&mut agents.burn, addr);
            };

            // Check if the role is transfer
            if(role == constants::get_transer()) {
                // Ensure the address is not already assigned as transfer
                assert!(!vector::contains(&agents.transfer,&addr), error::already_assigned());
                // Add the address to the transfer role
                vector::push_back(&mut agents.transfer, addr);
            };

            // Check if the role is force_transfer
            if(role == constants::get_force_transer()) {
                // Ensure the address is not already assigned as force_transfer
                assert!(!vector::contains(&agents.force_transfer,&addr), error::already_assigned());
                // Add the address to the force_transfer role
                vector::push_back(&mut agents.force_transfer, addr);
            };

            // Check if the role is freeze
            if(role == constants::get_freeze()) {
                // Ensure the address is not already assigned as freeze
                assert!(!vector::contains(&agents.freeze,&addr), error::already_assigned());
                // Add the address to the freeze role
                vector::push_back(&mut agents.freeze, addr);
            };

            // Check if the role is unfreeze
            if(role == constants::get_unfreeze()) {
                // Ensure the address is not already assigned as unfreeze
                assert!(!vector::contains(&agents.unfreeze,&addr), error::already_assigned());
                // Add the address to the unfreeze role
                vector::push_back(&mut agents.unfreeze, addr);
            };

            // Check if the role is deposit
            if(role == constants::get_deposit()) {
                // Ensure the address is not already assigned as deposit
                assert!(!vector::contains(&agents.deposit,&addr), error::already_assigned());
                // Add the address to the deposit role
                vector::push_back(&mut agents.deposit, addr);
            };

            // Check if the role is delete
            if(role == constants::get_delete()) {
                // Ensure the address is not already assigned as delete
                assert!(!vector::contains(&agents.delete,&addr), error::already_assigned());
                // Add the address to the delete role
                vector::push_back(&mut agents.delete, addr);
            };

            // Check if the role is unspecified
            if(role == constants::get_unspecified()) {
                // Ensure the address is not already assigned as unspecified
                assert!(!vector::contains(&agents.unspecified,&addr), error::already_assigned());
                // Add the address to the unspecified role
                vector::push_back(&mut agents.unspecified, addr);
            };

            // Check if the role is withdraw
            if(role == constants::get_withdraw()) {
                // Ensure the address is not already assigned as withdraw
                assert!(!vector::contains(&agents.withdraw,&addr), error::already_assigned());
                // Add the address to the withdraw role
                vector::push_back(&mut agents.withdraw, addr);
            };
        });
    }

    /// Function to assign agent roles
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which the roles are getting assigned
    ///     @roles - List of roles to be assigned
    ///
    /// Fails when:-
    ///     - AgentRights struct is not initialized
    fun assign_agent_role(token: String, addr: address, roles: vector<u8>) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@base_token_contract).rights;

        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow_mut(rights, &token);
            add_roles(agents, roles, addr);
        } else {
            let agents = create_new_agents();
            add_roles(&mut agents, roles, addr);
            simple_map::add(rights, token, agents);
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
        // Iterate through each role provided
        vector::for_each(roles, |role| {
            // Check if the role is admin
            if(role == constants::get_admin()) {
                // Find the index of the address in the admin role
                let (res, index) = vector::index_of(&agents.admin,&addr);
                // Ensure the address has admin access
                assert!(res, error::no_admin_access());
                // Remove the address from the admin role
                vector::remove(&mut agents.admin, index);
            };

            // Check if the role is mint
            if(role == constants::get_mint()) {
                // Find the index of the address in the mint role
                let (res, index) = vector::index_of(&agents.mint,&addr);
                // Ensure the address has mint access
                assert!(res, error::no_mint_access());
                // Remove the address from the mint role
                vector::remove(&mut agents.mint, index);
            };

            // Check if the role is burn
            if(role == constants::get_burn()) {
                // Find the index of the address in the burn role
                let (res, index) = vector::index_of(&agents.burn,&addr);
                // Ensure the address has burn access
                assert!(res, error::no_burn_access());
                // Remove the address from the burn role
                vector::remove(&mut agents.burn, index);
            };

            // Check if the role is transfer
            if(role == constants::get_transer()) {
                // Find the index of the address in the transfer role
                let (res, index) = vector::index_of(&agents.transfer,&addr);
                // Ensure the address has transfer access
                assert!(res, error::no_transfer_access());
                // Remove the address from the transfer role
                vector::remove(&mut agents.transfer, index);
            };

            // Check if the role is force_transfer
            if(role == constants::get_force_transer()) {
                // Find the index of the address in the force_transfer role
                let (res, index) = vector::index_of(&agents.force_transfer,&addr);
                // Ensure the address has force_transfer access
                assert!(res, error::no_force_transfer_access());
                // Remove the address from the force_transfer role
                vector::remove(&mut agents.force_transfer, index);
            };

            // Check if the role is freeze
            if(role == constants::get_freeze()) {
                // Find the index of the address in the freeze role
                let (res, index) = vector::index_of(&agents.freeze,&addr);
                // Ensure the address has freeze access
                assert!(res, error::no_freeze_access());
                // Remove the address from the freeze role
                vector::remove(&mut agents.freeze, index);
            };

            // Check if the role is unfreeze
            if(role == constants::get_unfreeze()) {
                // Find the index of the address in the unfreeze role
                let (res, index) = vector::index_of(&agents.unfreeze,&addr);
                // Ensure the address has unfreeze access
                assert!(res, error::no_unfreeze_access());
                // Remove the address from the unfreeze role
                vector::remove(&mut agents.unfreeze, index);
            };

            // Check if the role is deposit
            if(role == constants::get_deposit()) {
                // Find the index of the address in the deposit role
                let (res, index) = vector::index_of(&agents.deposit,&addr);
                // Ensure the address has deposit access
                assert!(res, error::no_deposit_access());
                // Remove the address from the deposit role
                vector::remove(&mut agents.deposit, index);
            };

            // Check if the role is delete
            if(role == constants::get_delete()) {
                // Find the index of the address in the delete role
                let (res, index) = vector::index_of(&agents.delete,&addr);
                // Ensure the address has delete access
                assert!(res, error::no_delete_access());
                // Remove the address from the delete role
                vector::remove(&mut agents.delete, index);
            };

            // Check if the role is unspecified
            if(role == constants::get_unspecified()) {
                // Find the index of the address in the unspecified role
                let (res, index) = vector::index_of(&agents.unspecified,&addr);
                // Ensure the address has unspecified access
                assert!(res, error::no_unspecified_access());
                // Remove the address from the unspecified role
                vector::remove(&mut agents.unspecified, index);
            };

            // Check if the role is withdraw
            if(role == constants::get_withdraw()) {
                // Find the index of the address in the withdraw role
                let (res, index) = vector::index_of(&agents.withdraw,&addr);
                // Ensure the address has withdraw access
                assert!(res, error::no_withdraw_access());
                // Remove the address from the withdraw role
                vector::remove(&mut agents.withdraw, index);
            };
        });
    }

    /// Function to unassign agent role
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which the roles are getting removed
    ///     @roles - List of roles to be removed
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///     - rights is not mapped with given id
    fun unassign_agent_role(token: String, addr: address, roles: vector<u8>) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@base_token_contract).rights;
        let agents = simple_map::borrow_mut(rights, &token);
        remove_roles(agents, roles, addr);
    }

    /// Function to check admin rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which admin rights is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has admin rights
    ///     - false, when the given address doesn't have admin rights
    public fun has_admin_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.admin, &addr)
        } else {
            false
        }
    }

    /// Function to check mint rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which mint rights is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has mint rights
    ///     - false, when the given address doesn't have mint rights
    public fun has_mint_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.mint, &addr)
        } else {
            false
        }
    }

    /// Function to check burn rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which burn rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has burn rights
    ///     - false, when the given address doesn't have burn rights
    public fun has_burn_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.burn, &addr)
        } else {
            false
        }
    }

    /// Function to check transfer rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which transfer rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has transfer rights
    ///     - false, when the given address doesn't have transfer rights
    public fun has_transfer_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.transfer, &addr)
        } else {
            false
        }
    }

    /// Function to check force transfer rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which force transfer rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has force transfer rights
    ///     - false, when the given address doesn't have force transfer rights
    public fun has_force_transfer_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.force_transfer, &addr)
        } else {
            false
        }
    }

    /// Function to check freeze rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which freeze rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has freeze rights
    ///     - false, when the given address doesn't have freeze rights
    public fun has_freeze_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.freeze, &addr)
        } else {
            false
        }
    }

    /// Function to check unfreeze rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which unfreeze rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has unfreeze rights
    ///     - false, when the given address doesn't have unfreeze rights
    public fun has_unfreeze_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.unfreeze, &addr)
        } else {
            false
        }
    }

    /// Function to check deposit rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which deposit rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has deposit rights
    ///     - false, when the given address doesn't have deposit rights
    public fun has_deposit_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.deposit, &addr)
        } else {
            false
        }
    }

    /// Function to check delete rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which delete rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has delete rights
    ///     - false, when the given address doesn't have delete rights
    public fun has_delete_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.delete, &addr)
        } else {
            false
        }
    }

    /// Function to check unspecified rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which unspecified rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has unspecified rights
    ///     - false, when the given address doesn't have unspecified rights
    public fun has_unspecified_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.unspecified, &addr)
        } else {
            false
        }
    }

    /// Function to check withdraw rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address to which withdraw rightes is going to be checked
    ///
    /// Fails when:-
    ///     - AgentRights are not initialized
    ///
    /// Returns:-
    ///     - true, when the given address has withdraw rights
    ///     - false, when the given address doesn't have withdraw rights
    public fun has_withdraw_rights(token: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@base_token_contract).rights;
        if (simple_map::contains_key(rights, &token)) {
            let agents = simple_map::borrow(rights, &token);
            vector::contains(&agents.withdraw, &addr)
        } else {
            false
        }
    }
    //:!:>helper functions

    /// Function to grant agent roles
    ///
    /// Arguements:-
    ///     @token: Token Name
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
        token: String,
        addrs: address, 
        roles: vector<u8>
    ) acquires AgentRights {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(addr);

        assign_agent_role(token, addrs, roles);

        // Emitting events
        emit_agent_access_update_event(
            roles,
            addrs,
        );
    }

    /// Function to ungrant agent roles
    ///
    /// Arguements:-
    ///     @token: Token Name
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
        token: String,
        addrs: address,
        roles: vector<u8>
    ) acquires AgentRights {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(addr);

        unassign_agent_role(token, addrs, roles);

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
    ///     @token: Token Name
    ///     @addr - Address whose roles will be fetched
    ///
    /// Returns either the list of roles of the given address or none
    public fun get_roles_for_address(
        token: String, // The token for which roles are requested
        addr: address, // The address for which roles are requested
    ): vector<String> acquires AgentRights { // Acquires AgentRights resource for read access

        // Initialize an empty vector to store roles
        let roles = vector::empty<String>();

        // Borrow global mutable reference to AgentRights
        let rights = &borrow_global_mut<AgentRights>(@base_token_contract).rights;

        // Borrow the agents map for the specified token
        let agents = simple_map::borrow(rights, &token);

        // Check if the address has admin role
        if (vector::contains(&agents.admin, &addr)) {
            // Add admin role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_admin()) )
        };

        // Check if the address has mint role
        if (vector::contains(&agents.mint, &addr)) {
            // Add mint role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_mint()) )
        };

        // Check if the address has burn role
        if (vector::contains(&agents.burn, &addr)) {
            // Add burn role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_burn()) )
        };

        // Check if the address has transfer role
        if (vector::contains(&agents.transfer, &addr)) {
            // Add transfer role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_transer()) )
        };

        // Check if the address has force_transfer role
        if (vector::contains(&agents.force_transfer, &addr)) {
            // Add force_transfer role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_force_transer()) )
        };

        // Check if the address has freeze role
        if (vector::contains(&agents.freeze, &addr)) {
            // Add freeze role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_freeze()) )
        };

        // Check if the address has unfreeze role
        if (vector::contains(&agents.unfreeze, &addr)) {
            // Add unfreeze role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_unfreeze()) )
        };

        // Check if the address has deposit role
        if (vector::contains(&agents.deposit, &addr)) {
            // Add deposit role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_deposit()) )
        };

        // Check if the address has delete role
        if (vector::contains(&agents.delete, &addr)) {
            // Add delete role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_delete()) )
        };

        // Check if the address has unspecified role
        if (vector::contains(&agents.unspecified, &addr)) {
            // Add unspecified role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_unspecified()) )
        };

        // Check if the address has withdraw role
        if (vector::contains(&agents.withdraw, &addr)) {
            // Add withdraw role to the roles vector
            vector::push_back(&mut roles, constants::get_role(constants::get_withdraw()) )
        };

        // Return the vector of roles associated with the address
        roles
    }
    //:!:>view functions
}

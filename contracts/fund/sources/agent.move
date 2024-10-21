module fund::agent {
    use std::signer;
    use fund::events::emit_manage_agent_event;
    use fund::maintainer::is_admin;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string::{Self, String};
    use utils::error;

    friend fund::fund;

    //:!:>resources
    struct AgentRights has key, copy {
        rights: SimpleMap<vector<u8>, address>
    }
    //:!:>resources

    //:!:>helper functions
    /// Function initialize agent
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///
    /// Fails when:-
    ///     - AgentRights are already initialized
    public fun init_agent_roles(account: &signer) {
        let res_addr = signer::address_of(account);
        assert!(!exists<AgentRights>(res_addr), error::already_assigned());

        move_to(
            account,
            AgentRights {
                rights: simple_map::create()
            }
        );
    }

    /// Function for adding agent
    /// Only fund module can call this helper function
    /// 
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @agent - Address that is going to assign as agent
    ///
    /// Fails when:-
    ///     - missing AgentRights struct initialization
    ///     - rights is not mapped with given token id
    ///
    /// Emits manage agent event
    public(friend) fun set_agent(token_id: String, agent: address) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@fund).rights;
        let key = string::bytes(&token_id);
        // Fails when the simple_map already contains the key
        simple_map::add(rights, *key, agent);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Add"), token_id, agent);
    }

    /// Function for adding agent
    /// 
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @agent - Address that is going to assign as agent
    ///
    /// Fails when:-
    ///     - missing AgentRights struct initialization
    ///     - caller doesn't have admin rights
    ///     - rights is not mapped with given token id
    ///
    /// Emits manage agent event with type Add
    public entry fun add_agent(account: &signer, token_id: String, agent: address) acquires AgentRights {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(sender);

        let rights= &mut borrow_global_mut<AgentRights>(@fund).rights;
        let key = string::bytes(&token_id);
        // Fails when the simple_map already contains the key
        simple_map::add(rights, *key, agent);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Add"), token_id, agent);
    }

    /// Function for removing agent
    /// 
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing AgentRights struct initialization
    ///     - caller doesn't have admin rights
    ///     - rights is not mapped with given token id
    ///     - key is not present
    ///
    /// Emits manage agent event with type Remove
    public entry fun remove_agent(account: &signer, token_id: String) acquires AgentRights {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(sender);

        let rights= &mut borrow_global_mut<AgentRights>(@fund).rights;
        let key = string::bytes(&token_id);
        // Fails when the simple_map doesn't contain the key
        let (id_vec, agent) = simple_map::remove(rights, key);
        let id = string::utf8(id_vec);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Remove"), id, agent);
    }
    //:!:>helper functions

    //:!:>view functions
    #[view]
    /// Function to check wheather an address has agent rights or not
    /// 
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @addr - Address that is going to check for agent rights
    ///
    /// Fails when:-
    ///     - missing AgentRights struct initialization
    ///     - rights is not mapped with given token id
    ///
    /// Returns
    ///     - true, when the given address has agent rights
    ///     - false, when the given address doesn't have agent rights
    public fun has_agent_rights(token_id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fund).rights;
        let key = string::bytes(&token_id);
        let agent = simple_map::borrow(rights, key);
        agent == &addr
    }

    #[view]
    /// Function to get agent by token_id
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing AgentRights struct initialization
    ///     - rights is not mapped with given token id
    ///
    /// Returns
    ///     - the agent address
    public fun get_agent_by_id(token_id: String): address acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@fund).rights;
        let key = string::bytes(&token_id);
        *simple_map::borrow(rights, key)
    }
    //:!:>view functions
}

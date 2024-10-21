module treasury_bond::agent {
    use std::signer;
    use treasury_bond::events::emit_manage_agent_event;
    use treasury_bond::maintainer::is_admin;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string::{Self, String};
    use utils::error;

    friend treasury_bond::treasury_bond;

    //:!:>resources
    struct AgentRights has key, copy {
        rights: SimpleMap<vector<u8>, address>
    }
    //:!:>resources

    //:!:>helper functions
    /// Function initialize agent
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
    public(friend) fun set_agent(token_id: String, agent: address) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token_id);
        simple_map::add(rights, *key, agent);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Add"), token_id, agent);
    }

    /// Function for adding agent
    public(friend) entry fun add_agent(account: &signer, token_id: String, agent: address) acquires AgentRights {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(sender);

        let rights= &mut borrow_global_mut<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token_id);
        simple_map::add(rights, *key, agent);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Add"), token_id, agent);
    }

    /// Function for removing agent
    public entry fun remove_agent(account: &signer, token: String) acquires AgentRights {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(sender);

        let rights= &mut borrow_global_mut<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token);
        let (id_vec, agent) = simple_map::remove(rights, key);
        let id = string::utf8(id_vec);

        // Emitting event
        emit_manage_agent_event(string::utf8(b"Remove"), id, agent);
    }

    /// Function for removing agent
    public fun is_agent(token_id: String, addr: address) acquires AgentRights {
        let rights= &mut borrow_global_mut<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token_id);
        let agent = simple_map::borrow(rights, key);

        assert!(agent == &addr, error::not_an_agent());
    }
    //:!:>helper functions

    //:!:>view functions
    #[view]
    public fun has_agent_rights(token_id: String, addr: address): bool acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token_id);
        let agent = simple_map::borrow(rights, key);
        agent == &addr
    }

    #[view]
    public fun get_agent_by_id(token_id: String): address acquires AgentRights {
        let rights= &borrow_global<AgentRights>(@treasury_bond).rights;
        let key = string::bytes(&token_id);
        *simple_map::borrow(rights, key)
    }
    //:!:>view functions
}

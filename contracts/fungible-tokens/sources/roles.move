module fungible_tokens::roles {
    use std::signer;
    use utils::error;
    use std::string;
    use std::option::{Self, Option};
    use fungible_tokens::events::emit_role_update_event;
    use fungible_tokens::maintainers::is_sub_admin;
    use aptos_std::simple_map::{Self, SimpleMap};
    use std::string::String;

    //:!:>resources
    struct Rights has key, copy {
        rights: SimpleMap<String, RightType>,
    }

    struct RightType has store, copy {
        issuer: Issuer,
        tokenization_agent: TokenizationAgent,
        transfer_agent: TransferAgent,
    }

    struct Issuer has store, copy, drop {
        addr: Option<address>,
        roles: vector<u8>,
    }

    struct TransferAgent has store, copy, drop {
        addr: Option<address>,
        roles: vector<u8>,
    }

    struct TokenizationAgent has store, copy, drop {
        addr: Option<address>,
        roles: vector<u8>,
    }
    //:!:>resources

    //:!:>helper functions

    /// Function initialize issuer, transfer_agent and tokenization_agent
    ///
    /// Arguements:-
    ///     @account - Signer of the transaction
    ///
    /// Fails when:-
    ///     - Rights struct are already initialized
    public fun init_rights(account: &signer) {
        assert!(!exists<Rights>(@fungible_tokens), error::already_assigned());

        move_to(
            account,
            Rights {
                rights: simple_map::create(),
            }
        );
    }

    /// Function for assigning issuer roles
    public fun create_issuer_roles(): vector<u8> {
        vector[
            utils::constants::get_mint(),
            utils::constants::get_burn(),
            utils::constants::get_force_transer(),
            utils::constants::get_freeze(),
            utils::constants::get_unfreeze(),
        ]
    }

    /// Function for assigning transfer agent roles
    public fun create_transfer_agent_roles(): vector<u8> {
        vector[
            utils::constants::get_force_transer(),
            utils::constants::get_freeze(),
            utils::constants::get_unfreeze(),
        ]
    }

    /// Function for assigning tokenizaion agent roles
    public fun create_tokenization_agent_roles(): vector<u8> {
        vector[
            utils::constants::get_mint(),
            utils::constants::get_burn(),
        ]
    }

    /// Function to assign all roles, i.e. issuer, transfer agent and tokenization agent
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @issuer - Address which is going to be assigned as Issuer, can be None as well
    ///     @tokenization_agent - Address which is going to be assigned as Tokenization agent, can be None as well
    ///     @transfer_agent - Address which is going to be assigned as Transfer agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    public fun assign_all_roles(
        id: String,
        issuer: Option<address>,
        transfer_agent: Option<address>,
        tokenization_agent: Option<address>,
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@fungible_tokens).rights;

        let right_type = RightType {
            issuer: Issuer {
              addr: issuer,
              roles: create_issuer_roles(),
            },
            transfer_agent: TransferAgent {
                addr: transfer_agent,
                roles: create_transfer_agent_roles(),
            },
            tokenization_agent: TokenizationAgent {
                addr: tokenization_agent,
                roles: create_tokenization_agent_roles()
            }
        };

        // Fails when the simple_map already contains the id
        simple_map::add(rights, id, right_type);
    }

    /// Function to asign issuer roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be assigned as Issuer, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given id
    public fun assign_issuer_roles(
        id: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow_mut(rights, &id).issuer.addr = addr;
    }

    /// Function to asign transfer agent roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be assigned as Tokenization agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given id
    public fun assign_transfer_agent_roles(
        id: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow_mut(rights, &id).transfer_agent.addr = addr;
    }

    /// Function to asign tokenization agent roles
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be assigned as Transfer agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given id
    public fun assign_tokenization_agent_roles(
        id: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow_mut(rights, &id).tokenization_agent.addr = addr;
    }

    /// Function to check issuer rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be checked for Issuer rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given id
    ///
    /// Returns
    ///     - true, when the given address has issuer rights
    ///     - false, when the given address doesn't have issuer rights
    public fun has_issuer_rights(
        id: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        let issuer = simple_map::borrow(rights, &id).issuer.addr;
        option::contains(&issuer, &addr)
    }

    /// Function to check transfer agent rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be checked for Transfer Agent rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given id
    ///
    /// Returns
    ///     - true, when the given address has transfer_agent rights
    ///     - false, when the given address doesn't have transfer_agent  rights
    public fun has_transfer_agent_rights(
        id: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        let transfer_agent = simple_map::borrow(rights, &id).transfer_agent.addr;
        option::contains(&transfer_agent, &addr)
    }

    /// Function to check tokenization agent rights
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @addr - Address which is going to be checked for Transfer Agent rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given id
    ///
    /// Returns
    ///     - true, when the given address has tokenization_agent rights
    ///     - false, when the given address doesn't have tokenization_agent rights
    public fun has_tokenization_agent_rights(
        id: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        let tokenization_agent = simple_map::borrow(rights, &id).tokenization_agent.addr;
        option::contains(&tokenization_agent, &addr)
    }
    //:!:>helper functions

    /// Function for addition of issuer
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @new_issuer - Address which is going to be assigned as Issuer
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Issuer role update event
    public entry fun add_issuer(
        account: &signer, 
        id: String,
        new_issuer: address
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_issuer_opt = option::some(new_issuer);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let issuer = get_issuer(id);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(id, new_issuer_opt);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Issuer"),
            roles,
            from,
            new_issuer_opt,
        );
    }

    /// Function for removal of issuer
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Issuer role update event
    public entry fun remove_issuer(
        account: &signer, 
        id: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_issuer = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let issuer = get_issuer(id);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(id, new_issuer);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Issuer"),
            roles,
            from,
            new_issuer,
        );
    }

    /// Function for addition of transfer agent
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @new_transfer_agent - Address which is going to be assigned as Transfer Agent
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Transfer Agent role update event
    public entry fun add_transfer_agent(
        account: &signer, 
        id: String,
        new_transfer_agent: address,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_transfer_agent_opt = option::some(new_transfer_agent);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let transfer_agent = get_transfer_agent(id);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(id, new_transfer_agent_opt);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Transfer Agent"),
            roles,
            from,
            new_transfer_agent_opt,
        );
    }

    /// Function for removal of transfer agent
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Transfer Agent role update event
    public entry fun remove_transfer_agent(
        account: &signer, 
        id: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_transfer_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let transfer_agent = get_transfer_agent(id);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(id, new_transfer_agent);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Transfer Agent"),
            roles,
            from,
            new_transfer_agent,
        );
    }

    /// Function for addition of tokenization agent
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///     @new_tokenization_agent - Address which is going to be assigned as Tokenization Agent
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Tokenization Agent role update event
    public entry fun add_tokenization_agent(
        account: &signer, 
        id: String,
        new_tokenization_agent: address,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_tokenization_agent_opt = option::some(new_tokenization_agent);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let tokenization_agent = get_tokenization_agent(id);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(id, new_tokenization_agent_opt);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Tokenization Agent"),
            roles,
            from,
            new_tokenization_agent_opt,
        );
    }

    /// Function for removal of tokenization agent
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Tokenization Agent role update event
    public entry fun remove_tokenization_agent(
        account: &signer, 
        id: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_tokenization_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let tokenization_agent = get_tokenization_agent(id);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(id, new_tokenization_agent);

        // Emitting events
        emit_role_update_event(
            string::utf8(b"Tokenization Agent"),
            roles,
            from,
            new_tokenization_agent,
        );
    }

    //:!:>view functions
    #[view]
    /// Function to get issuer
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given id
    ///
    /// Returns either Some(Issuer) or None
    public fun get_issuer(id: String): Issuer acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow(rights, &id).issuer
    }

    #[view]
    /// Function to get transfer agent
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given id
    ///
    /// Returns either Some(Transfer Agent) or None
    public fun get_transfer_agent(id: String): TransferAgent acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow(rights, &id).transfer_agent
    }

    #[view]
    /// Function to get tokenization agent
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given id
    ///
    /// Returns either Some(Tokenization Agent) or None
    public fun get_tokenization_agent(id: String): TokenizationAgent acquires Rights {
        let rights = &borrow_global_mut<Rights>(@fungible_tokens).rights;
        simple_map::borrow(rights, &id).tokenization_agent
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
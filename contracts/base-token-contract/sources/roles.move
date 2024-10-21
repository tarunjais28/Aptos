module base_token_contract::roles {
    use std::signer;
    use utils::error;
    use std::string;
    use std::option::{Self, Option};
    use base_token_contract::events::emit_role_update_event;
    use base_token_contract::maintainers::is_sub_admin;
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
        assert!(!exists<Rights>(@base_token_contract), error::already_assigned());

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
    ///     @token: Token Name
    ///     @issuer - Address which is going to be assigned as Issuer, can be None as well
    ///     @tokenization_agent - Address which is going to be assigned as Tokenization agent, can be None as well
    ///     @transfer_agent - Address which is going to be assigned as Transfer agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    public fun assign_all_roles(
        token: String,
        issuer: Option<address>,
        transfer_agent: Option<address>,
        tokenization_agent: Option<address>,
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@base_token_contract).rights;

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

        // Fails when the simple_map already contains the token
        simple_map::add(rights, token, right_type);
    }

    /// Function to asign issuer roles
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be assigned as Issuer, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given token
    public fun assign_issuer_roles(
        token: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow_mut(rights, &token).issuer.addr = addr;
    }

    /// Function to asign transfer agent roles
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be assigned as Tokenization agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given token
    public fun assign_transfer_agent_roles(
        token: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow_mut(rights, &token).transfer_agent.addr = addr;
    }

    /// Function to asign tokenization agent roles
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be assigned as Transfer agent, can be None as well
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given token
    public fun assign_tokenization_agent_roles(
        token: String,
        addr: Option<address>
    ) acquires Rights {
        let rights = &mut borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow_mut(rights, &token).tokenization_agent.addr = addr;
    }

    /// Function to check issuer rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be checked for Issuer rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given token
    ///
    /// Returns
    ///     - true, when the given address has issuer rights
    ///     - false, when the given address doesn't have issuer rights
    public fun has_issuer_rights(
        token: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        let issuer = simple_map::borrow(rights, &token).issuer.addr;
        option::contains(&issuer, &addr)
    }

    /// Function to check transfer agent rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be checked for Transfer Agent rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given token
    ///
    /// Returns
    ///     - true, when the given address has transfer_agent rights
    ///     - false, when the given address doesn't have transfer_agent  rights
    public fun has_transfer_agent_rights(
        token: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        let transfer_agent = simple_map::borrow(rights, &token).transfer_agent.addr;
        option::contains(&transfer_agent, &addr)
    }

    /// Function to check tokenization agent rights
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address which is going to be checked for Transfer Agent rights
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given token
    ///
    /// Returns
    ///     - true, when the given address has tokenization_agent rights
    ///     - false, when the given address doesn't have tokenization_agent rights
    public fun has_tokenization_agent_rights(
        token: String,
        addr: address
    ): bool acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        let tokenization_agent = simple_map::borrow(rights, &token).tokenization_agent.addr;
        option::contains(&tokenization_agent, &addr)
    }
    //:!:>helper functions

    /// Function for addition of issuer
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token: Token Name
    ///     @new_issuer - Address which is going to be assigned as Issuer
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Issuer role update event
    public entry fun add_issuer(
        account: &signer, 
        token: String,
        new_issuer: address
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_issuer_opt = option::some(new_issuer);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let issuer = get_issuer(token);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(token, new_issuer_opt);

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
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Issuer role update event
    public entry fun remove_issuer(
        account: &signer, 
        token: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_issuer = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let issuer = get_issuer(token);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(token, new_issuer);

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
    ///     @token: Token Name
    ///     @new_transfer_agent - Address which is going to be assigned as Transfer Agent
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Transfer Agent role update event
    public entry fun add_transfer_agent(
        account: &signer, 
        token: String,
        new_transfer_agent: address,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_transfer_agent_opt = option::some(new_transfer_agent);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let transfer_agent = get_transfer_agent(token);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(token, new_transfer_agent_opt);

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
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Transfer Agent role update event
    public entry fun remove_transfer_agent(
        account: &signer, 
        token: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_transfer_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let transfer_agent = get_transfer_agent(token);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(token, new_transfer_agent);

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
    ///     @token: Token Name
    ///     @new_tokenization_agent - Address which is going to be assigned as Tokenization Agent
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Tokenization Agent role update event
    public entry fun add_tokenization_agent(
        account: &signer, 
        token: String,
        new_tokenization_agent: address,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_tokenization_agent_opt = option::some(new_tokenization_agent);

        // Ensuring authorised sender
        is_sub_admin(addr);

        let tokenization_agent = get_tokenization_agent(token);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(token, new_tokenization_agent_opt);

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
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - the sender is not sub-admin
    ///
    /// Emits Tokenization Agent role update event
    public entry fun remove_tokenization_agent(
        account: &signer, 
        token: String,
    ) acquires Rights {
        let addr = signer::address_of(account);
        let new_tokenization_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(addr);

        let tokenization_agent = get_tokenization_agent(token);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(token, new_tokenization_agent);

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
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - issuer is not mapped with given token
    ///
    /// Returns either Some(Issuer) or None
    public fun get_issuer(token: String): Issuer acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow(rights, &token).issuer
    }

    #[view]
    /// Function to get transfer agent
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - transfer_agent is not mapped with given token
    ///
    /// Returns either Some(Transfer Agent) or None
    public fun get_transfer_agent(token: String): TransferAgent acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow(rights, &token).transfer_agent
    }

    #[view]
    /// Function to get tokenization agent
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///
    /// Fails when:-
    ///     - missing Rights struct initialization
    ///     - tokenization_agent is not mapped with given token
    ///
    /// Returns either Some(Tokenization Agent) or None
    public fun get_tokenization_agent(token: String): TokenizationAgent acquires Rights {
        let rights = &borrow_global_mut<Rights>(@base_token_contract).rights;
        simple_map::borrow(rights, &token).tokenization_agent
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
module token_contract::roles {
    use std::signer;
    use std::error;
    use std::string;
    use std::option::{Self, Option};
    use token_contract::events::emit_role_update_event;
    use token_contract::maintainers::is_sub_admin;

    //:!:>constants
    const ERR_ALREADY_ASSIGNED: u64 = 0;

    const MINT: u64 = 0;
    const BURN: u64 = 1;
    const FORCE_TRANSFER: u64 = 2;
    const FREEZE: u64 = 3;
    const UNFREEZE: u64 = 4;
    //:!:>constants

    //:!:>resources
    struct Issuer has key, copy {
        addr: Option<address>,
        roles: vector<u64>,
    }

    struct TransferAgent has key, copy {
        addr: Option<address>,
        roles: vector<u64>,
    }

    struct TokenizationAgent has key, copy {
        addr: Option<address>,
        roles: vector<u64>,
    }
    //:!:>resources

    //:!:>helper functions

    /// Function initialize issuer, transfer_agent and tokenization_agent
    public fun init_all_roles(res_account: &signer) {
        init_issuer(res_account);
        init_transfer_agent(res_account);
        init_tokenization_agent(res_account);
    }

    /// Function for default issuer
    public fun create_default_issuer(): Issuer {
        Issuer {
            addr: option::none(),
            roles: vector[MINT, BURN, FORCE_TRANSFER, FREEZE, UNFREEZE]
        }
    }

    /// Function for default transfer agent
    public fun create_default_transfer_agent(): TransferAgent {
        TransferAgent {
            addr: option::none(),
            roles: vector[FORCE_TRANSFER, FREEZE, UNFREEZE]
        }
    }

    /// Function for default tokenizaion agent
    public fun create_default_tokenization_agent(): TokenizationAgent {
        TokenizationAgent {
            addr: option::none(),
            roles: vector[MINT, BURN]
        }
    }

    /// Function to initialize issuer
    fun init_issuer(res_account: &signer) {
        let res_addr = signer::address_of(res_account);
        assert!(!exists<Issuer>(res_addr), error::already_exists(ERR_ALREADY_ASSIGNED));

        move_to(res_account, create_default_issuer());
    }

    /// Function to initialize transfer agent
    fun init_transfer_agent(res_account: &signer) {
        let res_addr = signer::address_of(res_account);
        assert!(!exists<TransferAgent>(res_addr), error::already_exists(ERR_ALREADY_ASSIGNED));

        move_to(res_account, create_default_transfer_agent());
    }

    /// Function to initialize tokenization agent
    fun init_tokenization_agent(res_account: &signer) {
        let res_addr = signer::address_of(res_account);
        assert!(!exists<TokenizationAgent>(res_addr), error::already_exists(ERR_ALREADY_ASSIGNED));

        move_to(res_account, create_default_tokenization_agent());
    }

    /// Function to asign issuer roles
    public fun assign_issuer_roles(res_addr: address, addr: Option<address>) acquires Issuer {
        borrow_global_mut<Issuer>(res_addr).addr = addr;
    }

    /// Function to asign transfer agent roles
    public fun assign_transfer_agent_roles(res_addr: address, addr: Option<address>) acquires TransferAgent {
        borrow_global_mut<TransferAgent>(res_addr).addr = addr;
    }

    /// Function to asign tokenization agent roles
    public fun assign_tokenization_agent_roles(res_addr: address, addr: Option<address>) acquires TokenizationAgent {
        borrow_global_mut<TokenizationAgent>(res_addr).addr = addr;
    }

    /// Function to check issuer rights
    public fun has_issuer_rights(res_addr: address, addr: address): bool acquires Issuer {
        let issuer = borrow_global<Issuer>(res_addr).addr;
        option::contains(&issuer, &addr)
    }

    /// Function to check transfer agent rights
    public fun has_transfer_agent_rights(res_addr: address, addr: address): bool acquires TransferAgent {
        let transfer_agent = borrow_global<TransferAgent>(res_addr).addr;
        option::contains(&transfer_agent, &addr)
    }

    /// Function to check tokenization agent rights
    public fun has_tokenization_agent_rights(res_addr: address, addr: address): bool acquires TokenizationAgent {
        let tokenization_agent = borrow_global<TokenizationAgent>(res_addr).addr;
        option::contains(&tokenization_agent, &addr)
    }
    //:!:>helper functions

    /// Function for addition of issuer
    public entry fun add_issuer(
        account: &signer, 
        res_addr: address, 
        new_issuer: address
    ) acquires Issuer {
        let addr = signer::address_of(account);
        let new_issuer_opt = option::some(new_issuer);

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let issuer = borrow_global<Issuer>(res_addr);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(res_addr, new_issuer_opt);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Issuer"),
            roles,
            from,
            new_issuer_opt,
        );
    }

    /// Function for removal of issuer
    public entry fun remove_issuer(
        account: &signer, 
        res_addr: address
    ) acquires Issuer {
        let addr = signer::address_of(account);
        let new_issuer = option::none();

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let issuer = borrow_global<Issuer>(res_addr);
        let roles = issuer.roles;
        let from = issuer.addr;

        assign_issuer_roles(res_addr, new_issuer);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Issuer"),
            roles,
            from,
            new_issuer,
        );
    }

    /// Function for addition of transfer agent
    public entry fun add_transfer_agent(
        account: &signer, 
        res_addr: address,
        new_transfer_agent: address
    ) acquires TransferAgent {
        let addr = signer::address_of(account);
        let new_transfer_agent_opt = option::some(new_transfer_agent);

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let transfer_agent = borrow_global<TransferAgent>(res_addr);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(res_addr, new_transfer_agent_opt);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Transfer Agent"),
            roles,
            from,
            new_transfer_agent_opt,
        );
    }

    /// Function for removal of transfer agent
    public entry fun remove_transfer_agent(
        account: &signer, 
        res_addr: address
    ) acquires TransferAgent {
        let addr = signer::address_of(account);
        let new_transfer_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let transfer_agent = borrow_global<TransferAgent>(res_addr);
        let roles = transfer_agent.roles;
        let from = transfer_agent.addr;

        assign_transfer_agent_roles(res_addr, new_transfer_agent);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Transfer Agent"),
            roles,
            from,
            new_transfer_agent,
        );
    }

    /// Function for addition of tokenization agent
    public entry fun add_tokenization_agent(
        account: &signer, 
        res_addr: address, 
        new_tokenization_agent: address
    ) acquires TokenizationAgent {
        let addr = signer::address_of(account);
        let new_tokenization_agent_opt = option::some(new_tokenization_agent);

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let tokenization_agent = borrow_global<TokenizationAgent>(res_addr);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(res_addr, new_tokenization_agent_opt);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Tokenization Agent"),
            roles,
            from,
            new_tokenization_agent_opt,
        );
    }

    /// Function for removal of tokenization agent
    public entry fun remove_tokenization_agent(
        account: &signer, 
        res_addr: address
    ) acquires TokenizationAgent {
        let addr = signer::address_of(account);
        let new_tokenization_agent = option::none();

        // Ensuring authorised sender
        is_sub_admin(res_addr, addr);

        let tokenization_agent = borrow_global<TokenizationAgent>(res_addr);
        let roles = tokenization_agent.roles;
        let from = tokenization_agent.addr;

        assign_tokenization_agent_roles(res_addr, new_tokenization_agent);

        // Emitting events
        emit_role_update_event(
            res_addr,
            string::utf8(b"Tokenization Agent"),
            roles,
            from,
            new_tokenization_agent,
        );
    }

    //:!:>view functions
    #[view]
    /// Function to get issuer
    public fun get_issuer(res_addr: address): Issuer acquires Issuer {
        *borrow_global<Issuer>(res_addr)
    }

    #[view]
    /// Function to get transfer agent
    public fun get_transfer_agent(res_addr: address): TransferAgent acquires TransferAgent {
        *borrow_global<TransferAgent>(res_addr)
    }

    #[view]
    /// Function to get tokenization agent
    public fun get_tokenization_agent(res_addr: address): TokenizationAgent acquires TokenizationAgent {
        *borrow_global<TokenizationAgent>(res_addr)
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
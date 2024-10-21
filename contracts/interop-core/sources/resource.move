module interop_core::resource {
    use std::signer;
    use interop_core::events::{initialize_event_store, emit_init_event, emit_update_source_config_event};
    use interop_core::maintainers::{init_maintainers, is_admin};
    use std::string::{Self, String};

    //:!:>resources
    struct SourceConfig has key, drop {
        chain: String
    }
    //:!:>resources

    //:!:>helper functions
    /// Function for maintainer creation with admin account
    ///
    /// Here following initialization takes place with default configurations:-
    ///     - Event Store for event handling
    ///     - Maintainers
    ///     - Various authorities like issuers, tokenization and transfer agents
    ///     - Agents
    ///     - Whitelisting Storage
    ///     - Token configuration storage
    ///
    /// This function emits following events:-
    ///     - Init Event
    ///     - Admin Update Event
    public fun create_with_admin(account: &signer, executer: address) {
        let admin = signer::address_of(account);

        // Initializing events
        initialize_event_store(account);

        // Init maintaner and make caller as admin
        init_maintainers(account, admin, executer);

        // Initializing Source Chain
        move_to(account,
            SourceConfig {
                chain: string::utf8(b"Aptos"),
            }
        );

        // Emitting events
        emit_init_event(admin);
    }
    //:!:>helper functions

    /// Function for partial unfreeze balance
    /// Some part of tokens are unfreezed
    /// This function supports batch partial unfreeze
    /// The address and balances must be passed in ordered manner, such as address[0] corresponds to balance[0]
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token: Token Name
    ///     @addrs - Addresses that are going to be unfreezed partially
    ///     @balances - The amount of tokens that are going to unfreezed
    ///
    /// Fails when:-
    ///     - quantity of addresses and balances are different
    ///     - sender doesn't have either of issuer, transfer agent, unfreeze or sub_admin rights
    ///     - address not present in the list
    ///     - missing TokenConfig struct initialization
    ///     - token data doesn't mapped with gievn token
    ///
    /// Emits partial unfreeze event
    public entry fun update_source_config(
        sender: &signer,
        chain: String,
    ) acquires SourceConfig {
        let caller = signer::address_of(sender);

        // Ensuring caller has the admin rights
        is_admin(caller);

        let source_config = borrow_global_mut<SourceConfig>(@interop_core);
        let old = source_config.chain;
        source_config.chain = chain;

        // Emitting update source config event
        emit_update_source_config_event(old, source_config.chain)
    }

    //:!:>view functions
    #[view]
    /// Function to get balance of an account
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address for which the balance will going to be fetched
    ///
    /// Fails when
    ///     - primary token stoarge doesn't have the address and metadata combination
    ///
    /// Returns balance of the address
    public fun get_source_config(): String acquires SourceConfig {
        let source_config = borrow_global<SourceConfig>(@interop_core);
        source_config.chain
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
module multisig::resource {
    use std::signer;
    use multisig::events::{initialize_event_store, emit_init_event, emit_update_threshold_event};
    use multisig::maintainers::{init_maintainers, is_admin};

    //:!:>resources
    struct Threshold has key, drop {
        value: u8,
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
    public fun create_with_admin(account: &signer, threshold: u8) {
        let admin = signer::address_of(account);

        // Initializing events
        initialize_event_store(account);

        // Init maintaner and make caller as admin
        init_maintainers(account, admin);

        // Initializing Threshold
        move_to(account,
            Threshold {
                value: threshold,
            }
        );

        // Emitting events
        emit_init_event(admin, threshold);
    }
    //:!:>helper functions

    /// Function for updation of threshold
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @threshold - Threshold value
    ///
    /// Fails when:-
    ///     - sender doesn't have admin rights
    ///     - missing Maintainers struct initialization
    ///
    /// Emits update sub admin event
    public entry fun update_threshold(account: &signer, threshold: u8) acquires Threshold {
        let caller = signer::address_of(account);

        // Ensuring authorised sender
        is_admin(caller);

        let threshold_value = borrow_global_mut<Threshold>(@multisig).value;
        let old = threshold_value;

        threshold_value = threshold;

        // Emitting events
        emit_update_threshold_event(old, threshold_value)
    }

    //:!:>view functions
    #[view]
    /// Function to get threshold
    ///
    /// Arguements:-
    ///     @token: Token Name
    ///     @addr - Address for which the balance will going to be fetched
    ///
    /// Fails when
    ///     - primary token stoarge doesn't have the address and metadata combination
    ///
    /// Returns balance of the address
    public fun get_threshold(): u8 acquires Threshold {
        let threshold = borrow_global<Threshold>(@multisig);
        threshold.value
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}
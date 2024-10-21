module multisig::events {
    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::{new_event_handle};

    //:!:>events
    struct MaintainerChangeEvent has drop, store {
        role: String,
        from: vector<address>,
        to: vector<address>,
    }

    struct InitEvent has drop, store {
        admin: address,
        threshold: u8,
    }

    struct UpdateThresholdEvent has drop, store {
        old: u8,
        new: u8,
    }

    struct CastVoteEvent has drop, store {
        tx_hash: String,
        can_transact: bool,
    }

    struct SendInstructionEvent has drop, store {
        source_chain: String,
        source_address: address,
        dest_chain: String,
        dest_address: String,
        sender: address,
        payload: vector<u8>,
    }

    struct ExecuteTransactionEvent has drop, store {
        source_chain: String,
        source_address: String,
        tx_hash: String,
        payload: vector<u8>,
    }

    /// Struct containing event handler of various functions
    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        threshold: EventHandle<UpdateThresholdEvent>,
        cast_vote: EventHandle<CastVoteEvent>,
        execute_transaction: EventHandle<ExecuteTransactionEvent>,
    }
    //:!:>events

    /// Function to initialize event store
    ///
    /// Arguements:-
    ///     @acc - Sender / Caller of the transaction
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun initialize_event_store(acc: &signer) {
        if (!exists<AssetEventStore>(signer::address_of(acc))) {
            move_to(acc,
                AssetEventStore {
                    init_event: new_event_handle<InitEvent>(acc),
                    maintainer_change_events: new_event_handle<MaintainerChangeEvent>(acc),
                    threshold: new_event_handle<UpdateThresholdEvent>(acc),
                    cast_vote: new_event_handle<CastVoteEvent>(acc),
                    execute_transaction: new_event_handle<ExecuteTransactionEvent>(acc),
                }
            );
        };
    }

    /// Function for init module event
    ///
    /// Arguements:-
    ///     @addr - Address of the admin
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_init_event(
        addr: address,
        threshold: u8,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<InitEvent>(
            &mut event_store.init_event,
            InitEvent {
                admin: addr,
                threshold,
            },
        );
    }

    /// Function for admin update event
    ///
    /// Arguements:-
    ///     @old - Can be list of old admin addresss
    ///     @new - Can be list of new admin addresss
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_admins_update_event(
        old: vector<address>,
        new: vector<address>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Admin"),
                from: old,
                to: new,
            },
        );
    }

    /// Function for validator update event
    ///
    /// Arguements:-
    ///     @old - Can be list of old validator addresses
    ///     @new - Can be list of new validator addresses
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_validator_update_event(
        old: vector<address>,
        new: vector<address>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Validator"),
                from: old,
                to: new,
            },
        );
    }

    /// Function for whitelist event
    ///
    /// Arguements:-
    ///     @type - Type of whitelisting, can be either add or remove
    ///     @addr - Address which is whitelisted
    ///     @country_code - Country Code of the address
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_update_threshold_event(
        old: u8,
        new: u8,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<UpdateThresholdEvent>(
            &mut event_store.threshold,
            UpdateThresholdEvent {
                old,
                new,
            },
        );
    }

    /// Function for cast vote event
    ///
    /// Arguements:-
    ///     @type - Type of whitelisting, can be either add or remove
    ///     @addr - Address which is whitelisted
    ///     @country_code - Country Code of the address
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_cast_vote_event(
        tx_hash: String,
        can_transact: bool,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<CastVoteEvent>(
            &mut event_store.cast_vote,
            CastVoteEvent {
                tx_hash,
                can_transact,
            },
        );
    }

    /// Function for execute instruction event
    ///
    /// Arguements:-
    ///     @type - Type of whitelisting, can be either add or remove
    ///     @addr - Address which is whitelisted
    ///     @country_code - Country Code of the address
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_execute_transaction_event(
        source_chain: String,
        source_address: String,
        tx_hash: String,
        payload: vector<u8>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@multisig);

        event::emit_event<ExecuteTransactionEvent>(
            &mut event_store.execute_transaction,
            ExecuteTransactionEvent {
                source_chain,
                source_address,
                tx_hash,
                payload,
            },
        );
    }
}

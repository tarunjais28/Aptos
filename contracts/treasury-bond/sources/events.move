module treasury_bond::events {
    
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::new_event_handle;
    use std::string::String;

    //:!:>events
    struct InitEvent has drop, store {
        admin: address,
    }

    struct MaintainerChangeEvent has drop, store {
        from: vector<address>,
        to: vector<address>,
    }

    struct CreateBondEvent has drop, store {
        token_id: String,
        name: String,
    }

    struct CreditRatingUpdateEvent has drop, store {
        token_id: String,
        old: String,
        new: String,
    }

    struct TreasuryManagerUpdateEvent has drop, store {
        token_id: String,
        old: address,
        new: address,
    }

    struct ManageAgentEvent has drop, store {
        type: String,
        token_id: String,
        agent: address,
    }

    struct ShareStableCoinEvent has drop, store {
        token_id: String,
        from: address,
        to: address,
        payment: u64,
    }

    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        create_event: EventHandle<CreateBondEvent>,
        credit_rating_update_event: EventHandle<CreditRatingUpdateEvent>,
        treasury_manager_update_event: EventHandle<TreasuryManagerUpdateEvent>,
        manage_agent_event: EventHandle<ManageAgentEvent>,
        share_stable_coins_event: EventHandle<ShareStableCoinEvent>,
    }
    //:!:>events

    /// Function to initialize event store
    public fun initialize_event_store(acc: &signer) {
        if (!exists<AssetEventStore>(signer::address_of(acc))) {
            move_to(acc,
                AssetEventStore {
                    init_event: new_event_handle<InitEvent>(acc),
                    maintainer_change_events: new_event_handle<MaintainerChangeEvent>(acc),
                    create_event: new_event_handle<CreateBondEvent>(acc),
                    credit_rating_update_event: new_event_handle<CreditRatingUpdateEvent>(acc),
                    treasury_manager_update_event: new_event_handle<TreasuryManagerUpdateEvent>(acc),
                    manage_agent_event: new_event_handle<ManageAgentEvent>(acc),
                    share_stable_coins_event: new_event_handle<ShareStableCoinEvent>(acc),
                }
            );
        };
    }

    /// Function for init module event
    public fun emit_init_event(
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<InitEvent>(
            &mut event_store.init_event,
            InitEvent {
                admin: addr,
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
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                from: old,
                to: new,
            },
        );
    }

    /// Function for create treasury_bond event
    public fun emit_create_fund_event(
        token_id: String,
        name: String,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<CreateBondEvent>(
            &mut event_store.create_event,
            CreateBondEvent {
                token_id,
                name,
            },
        );
    }

    /// Function for update credit rating event
    public fun emit_update_credit_rating(
        token_id: String,
        old: String,
        new: String,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<CreditRatingUpdateEvent>(
            &mut event_store.credit_rating_update_event,
            CreditRatingUpdateEvent {
                token_id,
                old,
                new,
            },
        );
    }

    /// Function for update treasury manager address
    public fun emit_update_treasury_manager(
        token_id: String,
        old: address,
        new: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<TreasuryManagerUpdateEvent>(
            &mut event_store.treasury_manager_update_event,
            TreasuryManagerUpdateEvent {
                token_id,
                old,
                new,
            },
        );
    }

    /// Function for user payment event
    public fun emit_manage_agent_event(
        type: String,
        token_id: String,
        agent: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<ManageAgentEvent>(
            &mut event_store.manage_agent_event,
            ManageAgentEvent {
                type,
                token_id,
                agent
            },
        );
    }

    /// Function for share stable coins event
    public fun emit_share_stable_coins_event(
        token_id: String,
        from: address,
        to: address,
        payment: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@treasury_bond);

        event::emit_event<ShareStableCoinEvent>(
            &mut event_store.share_stable_coins_event,
            ShareStableCoinEvent {
                token_id,
                from,
                to,
                payment,
            },
        );
    }
}

module fund::events {
    
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::new_event_handle;
    use std::string::String;
    use std::option::Option;
    
    //:!:>events
    struct InitEvent has drop, store {
        admin: address,
    }

    struct MaintainerChangeEvent has drop, store {
        from: Option<address>,
        to: address,
    }

    struct CreateFundEvent has drop, store {
        token_id: String,
        fund_name: String,
        asset_type: u8,
        issuer_name: String,
    }

    struct UserManagementFeesEvent has drop, store {
        type: String,
        token_id: String,
        user: address,
        fee: u64,
    }

    struct UserDividendEvent has drop, store {
        type: String,
        token_id: String,
        asset_type: u8,
        user: address,
        dividend: u64,
    }

    struct ManageAgentEvent has drop, store {
        type: String,
        token_id: String,
        agent: address,
    }

    struct PriceFetchEvent has drop, store {
        token_id: String,
        price: u64,
    }

    struct ShareDividendEvent has drop, store {
        token_id: String,
        from: address,
        to: address,
        dividend: u64,
        asset_type: String,
    }

    struct DistributeAndBurnEvent has drop, store {
        token_id: String,
        from: address,
        investor: address,
        amount: u64,
        token: u64,
    }

    struct RescueTokenEvent has drop, store {
        token_id: String,
        to: address,
        amount: u64,
    }

    /// Struct containing event handler of various functions
    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        create_event: EventHandle<CreateFundEvent>,
        user_management_fees_event: EventHandle<UserManagementFeesEvent>,
        user_dividend_event: EventHandle<UserDividendEvent>,
        manage_agent_event: EventHandle<ManageAgentEvent>,
        price_fetch_event: EventHandle<PriceFetchEvent>,
        share_dividend_event: EventHandle<ShareDividendEvent>,
        dist_burn_event: EventHandle<DistributeAndBurnEvent>,
        rescue_token: EventHandle<RescueTokenEvent>,
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
                    create_event: new_event_handle<CreateFundEvent>(acc),
                    user_management_fees_event: new_event_handle<UserManagementFeesEvent>(acc),
                    user_dividend_event: new_event_handle<UserDividendEvent>(acc),
                    manage_agent_event: new_event_handle<ManageAgentEvent>(acc),
                    price_fetch_event: new_event_handle<PriceFetchEvent>(acc),
                    share_dividend_event: new_event_handle<ShareDividendEvent>(acc),
                    dist_burn_event: new_event_handle<DistributeAndBurnEvent>(acc),
                    rescue_token: new_event_handle<RescueTokenEvent>(acc),
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
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

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
    ///     @old - Can be list of old admin addresss or None
    ///     @new - Can be list of new admin addresss or None
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_admin_update_event(
        old: Option<address>,
        new: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                from: old,
                to: new,
            },
        );
    }

    /// Function for create fund event
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @fund_name - Name of the fund
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @issuer_name - Name of the issuer
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_create_fund_event(
        token_id: String,
        fund_name: String,
        asset_type: u8,
        issuer_name: String,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<CreateFundEvent>(
            &mut event_store.create_event,
            CreateFundEvent {
                token_id,
                fund_name,
                asset_type,
                issuer_name,
            },
        );
    }

    /// Function for user management fees event
    ///
    /// Arguements:-
    ///     @type - Type of user management operation, can be Add, Remove and Update
    ///     @token_id - Unique id mapped to each token
    ///     @user - Address of the user
    ///     @fee - Fees of management
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_user_management_fees_event(
        type: String,
        token_id: String,
        user: address,
        fee: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<UserManagementFeesEvent>(
            &mut event_store.user_management_fees_event,
            UserManagementFeesEvent {
                type,
                token_id,
                user,
                fee,
            },
        );
    }

    /// Function for user dividend event
    ///
    /// Arguements:-
    ///     @type - Type of user management operation, can be Add at the moment
    ///     @token_id - Unique id mapped to each token
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @user - Address of the user
    ///     @dividend - Amount of token / stable coin that was distributed
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_user_dividend_event(
        type: String,
        token_id: String,
        asset_type: u8,
        user: address,
        dividend: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<UserDividendEvent>(
            &mut event_store.user_dividend_event,
            UserDividendEvent {
                type,
                token_id,
                asset_type,
                user,
                dividend,
            },
        );
    }

    /// Function for user dividend event
    ///
    /// Arguements:-
    ///     @type - Type of user management operation, can be Add and Remove
    ///     @token_id - Unique id mapped to each token
    ///     @agent - Address of the agent
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_manage_agent_event(
        type: String,
        token_id: String,
        agent: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<ManageAgentEvent>(
            &mut event_store.manage_agent_event,
            ManageAgentEvent {
                type,
                token_id,
                agent
            },
        );
    }

    /// Function for fetch price event
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @price - Fetched price
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_fetch_price_event(
        token_id: String,
        price: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<PriceFetchEvent>(
            &mut event_store.price_fetch_event,
            PriceFetchEvent {
                token_id,
                price,
            },
        );
    }

    /// Function for share dividend event
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @from - Address of the sender
    ///     @to - Address of the receiver
    ///     @dividend - Amount of token / stable coin that was distributed
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_share_dividend_event(
        token_id: String,
        from: address,
        to: address,
        dividend: u64,
        asset_type: String,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<ShareDividendEvent>(
            &mut event_store.share_dividend_event,
            ShareDividendEvent {
                token_id,
                from,
                to,
                dividend,
                asset_type,
            },
        );
    }

    /// Function for distribute and burn event
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @from - Address of the sender
    ///     @investor - Address of the investor
    ///     @amount - Amount of stable coin exchanged with token
    ///     @token - Amount of token exchanged with stable coins
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_distribute_and_burn_event(
        token_id: String,
        from: address,
        investor: address,
        amount: u64,
        token: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<DistributeAndBurnEvent>(
            &mut event_store.dist_burn_event,
            DistributeAndBurnEvent {
                token_id,
                from,
                investor,
                amount,
                token,
            },
        );
    }

    /// Function for rescue token event
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///     @to - Address of the receipient
    ///     @amount - Amount of token returned
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_rescue_token_event(
        token_id: String,
        to: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fund);

        event::emit_event<RescueTokenEvent>(
            &mut event_store.rescue_token,
            RescueTokenEvent {
                token_id,
                to,
                amount,
            },
        );
    }
}

module fungible_tokens::events {
    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::{new_event_handle};
    use std::option::{Option, some};

    //:!:>events
    struct MaintainerChangeEvent has drop, store {
        role: String,
        from: Option<vector<address>>,
        to: Option<vector<address>>,
    }

    struct RoleChangeEvent has drop, store {
        type: String,
        roles: vector<u8>,
        from: Option<address>,
        to: Option<address>,
    }

    struct ManageAgentAccessEvent has drop, store {
        roles: vector<u8>,
        to: address,
    }

    struct TokenCreationEvent has drop, store {
        id: String,
        name: String,
        symbol: String,
        decimals: u8,
        creator: address,
        issuer: address,
        tokenization_agent: address,
        transfer_agent: address,
    }

    struct MintBurnEvents has drop, store {
        addr: address,
        amount: u64,
    }

    struct InitEvent has drop, store {
        admin: address,
    }

    struct WhitelistEvent has drop, store {
        type: String,
        addr: address,
        country_code: u8,
    }

    struct UpdateCountryCodeEvent has drop, store {
        type: String,
        country_codes: vector<u8>,
    }

    struct UpdateTokenLimitEvent has drop, store {
        type: String,
        token_limit: u64,
    }

    struct TransferEvent has drop, store {
        from: address,
        to: address,
        amount: u64,
    }

    struct FreezeEvent has drop, store {
        addr: address,
    }

    struct UnfreezeEvent has drop, store {
        addr: address,
    }

    struct PartialFreezeEvent has drop, store {
        addr: address,
        bal: u64
    }

    struct PartialUnfreezeEvent has drop, store {
        addr: address,
        bal: u64
    }

    /// Struct containing event handler of various functions
    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        role_change_events: EventHandle<RoleChangeEvent>,
        manage_agent_access_event: EventHandle<ManageAgentAccessEvent>,
        token_creation_events: EventHandle<TokenCreationEvent>,
        mint_event: EventHandle<MintBurnEvents>,
        burn_event: EventHandle<MintBurnEvents>,
        whitelist_event: EventHandle<WhitelistEvent>,
        update_countrycodes_event: EventHandle<UpdateCountryCodeEvent>,
        update_token_limit_event: EventHandle<UpdateTokenLimitEvent>,
        transfer_event: EventHandle<TransferEvent>,
        freeze_event: EventHandle<FreezeEvent>,
        unfreeze_event: EventHandle<UnfreezeEvent>,
        partial_freeze_event: EventHandle<PartialFreezeEvent>,
        partial_unfreeze_event: EventHandle<PartialUnfreezeEvent>,
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
                    role_change_events: new_event_handle<RoleChangeEvent>(acc),
                    manage_agent_access_event: new_event_handle<ManageAgentAccessEvent>(acc),
                    token_creation_events: new_event_handle<TokenCreationEvent>(acc),
                    mint_event: new_event_handle<MintBurnEvents>(acc),
                    burn_event: new_event_handle<MintBurnEvents>(acc),
                    whitelist_event: new_event_handle<WhitelistEvent>(acc),
                    update_countrycodes_event: new_event_handle<UpdateCountryCodeEvent>(acc),
                    update_token_limit_event: new_event_handle<UpdateTokenLimitEvent>(acc),
                    transfer_event: new_event_handle<TransferEvent>(acc),
                    freeze_event: new_event_handle<FreezeEvent>(acc),
                    unfreeze_event: new_event_handle<UnfreezeEvent>(acc),
                    partial_freeze_event: new_event_handle<PartialFreezeEvent>(acc),
                    partial_unfreeze_event: new_event_handle<PartialUnfreezeEvent>(acc),
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
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

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
        old: Option<vector<address>>,
        new: Option<vector<address>>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Admin"),
                from: old,
                to: new,
            },
        );
    }

    /// Function for sub_admins update event
    ///
    /// Arguements:-
    ///     @old_addresses - List of old addresss that had sub admin rights
    ///     @addresses - List of new addresss that have sub admin rights
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_sub_admins_update_event(
        old_addresses: vector<address>,
        addresses: vector<address>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Sub Admin"),
                from: some<vector<address>>(old_addresses),
                to: some<vector<address>>(addresses),
            },
        );
    }

    /// Function for role update event
    ///
    /// Arguements:-
    ///     @type - Type of roles, can be either Issuer, Transfer Agent or Tokenization Agent
    ///     @rolse - List of roles
    ///     @from - Old address that was holding roles
    ///     @to - New address that is holding roles
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_role_update_event(
        type: String,
        roles: vector<u8>,
        from: Option<address>,
        to: Option<address>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<RoleChangeEvent>(
            &mut event_store.role_change_events,
            RoleChangeEvent {
                type,
                roles,
                from,
                to,
            },
        );
    }

    /// Function for grant access update event
    ///
    /// Arguements:-
    ///     @rolse - List of roles
    ///     @to - Address that is holding agent access
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_agent_access_update_event(
        roles: vector<u8>,
        to: address
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<ManageAgentAccessEvent>(
            &mut event_store.manage_agent_access_event,
            ManageAgentAccessEvent {
                roles,
                to,
            },
        );
    }

    /// Function for token creation event
    ///
    /// Arguements:-
    ///     @id - Unique id mapped to each token
    ///     @name - Name of the token
    ///     @symbol - Symbol of the tokent
    ///     @decimals - Number of decimal places
    ///     @creator - Creator of the token
    ///     @issuer - Address of the Issuer
    ///     @tokenization_agent - Address of the Tokenization agent
    ///     @transfer_agent - Address of the Transfer agent
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_token_creation_event(
        id: String,
        name: String,
        symbol: String,
        decimals: u8,
        creator: address,
        issuer: address,
        tokenization_agent: address,
        transfer_agent: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<TokenCreationEvent>(
            &mut event_store.token_creation_events,
            TokenCreationEvent {
                id,
                name,
                symbol,
                decimals,
                creator,
                issuer,
                tokenization_agent,
                transfer_agent,
            },
        );
    }

    /// Function for mint event
    ///
    /// Arguements:-
    ///     @addr - Address to which the token is minted
    ///     @amount - Amount of token to be minted
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_mint_event(
        addr: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<MintBurnEvents>(
            &mut event_store.mint_event,
            MintBurnEvents {
                addr,
                amount,
            },
        );
    }

    /// Function for burn event
    ///
    /// Arguements:-
    ///     @addr - Address from which the token is burn
    ///     @amount - Amount of token to be burned
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_burn_event(
        addr: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<MintBurnEvents>(
            &mut event_store.burn_event,
            MintBurnEvents {
                addr,
                amount,
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
    public fun emit_whitelist_event(
        type: String,
        addr: address,
        country_code: u8,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<WhitelistEvent>(
            &mut event_store.whitelist_event,
            WhitelistEvent {
                type,
                addr,
                country_code,
            },
        );
    }

    /// Function for update country code  event
    ///
    /// Arguements:-
    ///     @type - Type of updation, can be either add or remove
    ///     @country_codes - List of updated country codes
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_update_countrycode_event(
        type: String,
        country_codes: vector<u8>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<UpdateCountryCodeEvent>(
            &mut event_store.update_countrycodes_event,
            UpdateCountryCodeEvent {
                type,
                country_codes,
            },
        );
    }

    /// Function for update token limit  event
    ///
    /// Arguements:-
    ///     @type - Type of updation, can be update_token_limit
    ///     @token_limit - New token limit that is set
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_update_token_limt_event(
        type: String,
        token_limit: u64
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<UpdateTokenLimitEvent>(
            &mut event_store.update_token_limit_event,
            UpdateTokenLimitEvent {
                type,
                token_limit,
            },
        );
    }
    
    /// Function for transfer event
    ///
    /// Arguements:-
    ///     @from - Sender address that has sent tokens
    ///     @to - Receipient address that has received tokens
    ///     @amount - The amount of tokens that is transfered
    ///
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_transfer_event(
        from: address,
        to: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<TransferEvent>(
            &mut event_store.transfer_event,
            TransferEvent {
                from,
                to,
                amount,
            },
        );
    }

    /// Function for freeze event
    ///
    /// Arguements:-
    ///     @addr - Address that is freezed
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_freeze_event(
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<FreezeEvent>(
            &mut event_store.freeze_event,
            FreezeEvent {
                addr,
            },
        );
    }

    /// Function for unfreeze event
    ///
    /// Arguements:-
    ///     @addr - Address that is unfreezed
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_unfreeze_event(
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<UnfreezeEvent>(
            &mut event_store.unfreeze_event,
            UnfreezeEvent {
                addr,
            },
        );
    }

    /// Function for partial freeze event
    ///
    /// Arguements:-
    ///     @addr - Address that is partially freezed
    ///     @bal - Amount that are freezed
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_partial_freeze_event(
        addr: address,
        bal: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<PartialFreezeEvent>(
            &mut event_store.partial_freeze_event,
            PartialFreezeEvent {
                addr,
                bal,
            },
        );
    }

    /// Function for partial unfreeze event
    ///
    /// Arguements:-
    ///     @addr - Address that is partially unfreezed
    ///     @bal - Amount that are unfreezed
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_partial_unfreeze_event(
        addr: address,
        bal: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@fungible_tokens);

        event::emit_event<PartialUnfreezeEvent>(
            &mut event_store.partial_unfreeze_event,
            PartialUnfreezeEvent {
                addr,
                bal,
            },
        );
    }
}

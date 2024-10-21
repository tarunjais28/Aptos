module token_contract::events {
    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::{new_event_handle, SignerCapability};
    use std::option::{Option, some};

    //:!:>events
    struct MaintainerChangeEvent has drop, store {
        role: String,
        from: Option<vector<address>>,
        to: Option<vector<address>>,
    }

    struct ResourceAccountEvent has key, drop, store {
        resource_address: address,
        resource_capability: SignerCapability,
    }

    struct RoleChangeEvent has drop, store {
        type: String,
        roles: vector<u64>,
        from: Option<address>,
        to: Option<address>,
    }

    struct ManageAgentAccessEvent has drop, store {
        roles: vector<u64>,
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

    struct AccountRegisterEvent has drop, store {
        addr: address,
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

    struct MultisigEvent has drop, store {
        type: String,
        value: bool,
        signers: vector<address>,
        approvals: u64,
    }

    struct MintBurnProposalEvent has drop, store {
        type: String,
        proposer_address: address,
        proposal_id: u64,
        amount: u64,
    }

    struct UpdateCountryCodeEvent has drop, store {
        type: String,
        country_code: vector<u8>,
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

    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        resource_events: EventHandle<ResourceAccountEvent>,
        role_change_events: EventHandle<RoleChangeEvent>,
        manage_agent_access_event: EventHandle<ManageAgentAccessEvent>,
        token_creation_events: EventHandle<TokenCreationEvent>,
        account_registered_event: EventHandle<AccountRegisterEvent>,
        mint_event: EventHandle<MintBurnEvents>,
        burn_event: EventHandle<MintBurnEvents>,
        whitelist_event: EventHandle<WhitelistEvent>,
        multisig_event: EventHandle<MultisigEvent>,
        mint_burn_proposals_event: EventHandle<MintBurnProposalEvent>,
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
    public fun initialize_event_store(acc: &signer) {
        if (!exists<AssetEventStore>(signer::address_of(acc))) {
            move_to(acc,
                AssetEventStore {
                    init_event: new_event_handle<InitEvent>(acc),
                    maintainer_change_events: new_event_handle<MaintainerChangeEvent>(acc),
                    resource_events: new_event_handle<ResourceAccountEvent>(acc),
                    role_change_events: new_event_handle<RoleChangeEvent>(acc),
                    manage_agent_access_event: new_event_handle<ManageAgentAccessEvent>(acc),
                    token_creation_events: new_event_handle<TokenCreationEvent>(acc),
                    account_registered_event: new_event_handle<AccountRegisterEvent>(acc),
                    mint_event: new_event_handle<MintBurnEvents>(acc),
                    burn_event: new_event_handle<MintBurnEvents>(acc),
                    whitelist_event: new_event_handle<WhitelistEvent>(acc),
                    multisig_event: new_event_handle<MultisigEvent>(acc),
                    mint_burn_proposals_event: new_event_handle<MintBurnProposalEvent>(acc),
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
    public fun emit_init_event(
        res_addr: address,
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<InitEvent>(
            &mut event_store.init_event,
            InitEvent {
                admin: addr,
            },
        );
    }

    /// Function for admin update event
    public fun emit_admin_update_event(
        res_addr: address,
        old: Option<vector<address>>,
        new: Option<vector<address>>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

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
    public fun emit_sub_admins_update_event(
        res_addr: address,
        old_addresses: vector<address>,
        addresses: vector<address>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

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
    public fun emit_role_update_event(
        res_addr: address,
        type: String,
        roles: vector<u64>,
        from: Option<address>,
        to: Option<address>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

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

    // Function for grant access update event
    public fun emit_agent_access_update_event(
        res_addr: address,
        roles: vector<u64>,
        to: address
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<ManageAgentAccessEvent>(
            &mut event_store.manage_agent_access_event,
            ManageAgentAccessEvent {
                roles,
                to,
            },
        );
    }

    /// Function for token creation event
    public fun emit_token_creation_event(
        res_addr: address,
        id: String,
        name: String,
        symbol: String,
        decimals: u8,
        creator: address,
        issuer: address,
        tokenization_agent: address,
        transfer_agent: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

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

    /// Function for account register event
    public fun emit_account_reister_event(
        res_addr: address,
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<AccountRegisterEvent>(
            &mut event_store.account_registered_event,
            AccountRegisterEvent {
                addr
            },
        );
    }

    /// Function for mint event
    public fun emit_mint_event(
        res_addr: address,
        addr: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<MintBurnEvents>(
            &mut event_store.mint_event,
            MintBurnEvents {
                addr,
                amount,
            },
        );
    }

    /// Function for burn event
    public fun emit_burn_event(
        res_addr: address,
        addr: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<MintBurnEvents>(
            &mut event_store.burn_event,
            MintBurnEvents {
                addr,
                amount,
            },
        );
    }

    /// Function for whitelist event
    public fun emit_whitelist_event(
        res_addr: address,
        type: String,
        addr: address,
        country_code: u8,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<WhitelistEvent>(
            &mut event_store.whitelist_event,
            WhitelistEvent {
                type,
                addr,
                country_code,
            },
        );
    }

 /// Function for multisig event
    public fun emit_multisig_event(
        res_addr: address,
        type: String,
        value: bool,
        signers: vector<address>,
        approvals: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<MultisigEvent>(
            &mut event_store.multisig_event,
            MultisigEvent {
                type,
                value,
                signers,
                approvals
            },
        );
    }

    /// Function for mint burn proposal  event
    public fun emit_mintburn_proposal_event(
        res_addr: address,
        type: String,
        proposer_address: address,
        proposal_id: u64,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<MintBurnProposalEvent>(
            &mut event_store.mint_burn_proposals_event,
            MintBurnProposalEvent {
                type,
                proposer_address,
                proposal_id,
                amount,
            },
        );
    }

    /// Function for update country code  event
    public fun emit_update_countrycode_event(
        res_addr: address,
        type: String,
        country_code: vector<u8>
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<UpdateCountryCodeEvent>(
            &mut event_store.update_countrycodes_event,
            UpdateCountryCodeEvent {
                type,
                country_code,
            },
        );
    }

    /// Function for update token limit  event
    public fun emit_update_token_limt_event(
        res_addr: address,
        type: String,
        token_limit: u64
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<UpdateTokenLimitEvent>(
            &mut event_store.update_token_limit_event,
            UpdateTokenLimitEvent {
                type,
                token_limit,
            },
        );
    }
    
    /// Function for transfer event
    public fun emit_transfer_event(
        res_addr: address,
        from: address,
        to: address,
        amount: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

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
    public fun emit_freeze_event(
        res_addr: address,
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<FreezeEvent>(
            &mut event_store.freeze_event,
            FreezeEvent {
                addr,
            },
        );
    }

    /// Function for unfreeze event
    public fun emit_unfreeze_event(
        res_addr: address,
        addr: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<UnfreezeEvent>(
            &mut event_store.unfreeze_event,
            UnfreezeEvent {
                addr,
            },
        );
    }

    /// Function for partial freeze event
    public fun emit_partial_freeze_event(
        res_addr: address,
        addr: address,
        bal: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<PartialFreezeEvent>(
            &mut event_store.partial_freeze_event,
            PartialFreezeEvent {
                addr,
                bal,
            },
        );
    }

    /// Function for partial unfreeze event
    public fun emit_partial_unfreeze_event(
        res_addr: address,
        addr: address,
        bal: u64,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(res_addr);

        event::emit_event<PartialUnfreezeEvent>(
            &mut event_store.partial_unfreeze_event,
            PartialUnfreezeEvent {
                addr,
                bal,
            },
        );
    }
}

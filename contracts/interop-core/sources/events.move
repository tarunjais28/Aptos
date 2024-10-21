module interop_core::events {
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

    struct MintBurnEvents has drop, store {
        addr: address,
        amount: u64,
    }

    struct InitEvent has drop, store {
        admin: address,
    }

    struct UpdateSourceConfigEvent has drop, store {
        old: String,
        new: String,
    }

    struct SendInstructionEvent has drop, store {
        source_chain: String,
        source_address: address,
        dest_chain: String,
        dest_address: String,
        sender: address,
        payload: vector<u8>,
    }

    struct ExecuteInstructionEvent has drop, store {
        source_chain: String,
        source_address: address,
        dest_chain: String,
        dest_address: String,
        sender: address,
        payload: vector<u8>,
    }

    /// Struct containing event handler of various functions
    struct AssetEventStore has key {
        init_event: EventHandle<InitEvent>,
        maintainer_change_events: EventHandle<MaintainerChangeEvent>,
        mint_event: EventHandle<MintBurnEvents>,
        burn_event: EventHandle<MintBurnEvents>,
        source_config: EventHandle<UpdateSourceConfigEvent>,
        send_instruction: EventHandle<SendInstructionEvent>,
        execute_instruction: EventHandle<ExecuteInstructionEvent>,
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
                    mint_event: new_event_handle<MintBurnEvents>(acc),
                    burn_event: new_event_handle<MintBurnEvents>(acc),
                    source_config: new_event_handle<UpdateSourceConfigEvent>(acc),
                    send_instruction: new_event_handle<SendInstructionEvent>(acc),
                    execute_instruction: new_event_handle<ExecuteInstructionEvent>(acc),
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
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

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
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Admin"),
                from: old,
                to: new,
            },
        );
    }

    /// Function for executer update event
    ///
    /// Arguements:-
    ///     @old - Can be list of old executer addresss
    ///     @new - Can be list of new executer addresss
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_update_executer_event(
        old: address,
        new: address,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

        event::emit_event<MaintainerChangeEvent>(
            &mut event_store.maintainer_change_events,
            MaintainerChangeEvent {
                role: string::utf8(b"Executer"),
                from: vector[old],
                to: vector[new],
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
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

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
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

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
    public fun emit_update_source_config_event(
        old: String,
        new: String,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

        event::emit_event<UpdateSourceConfigEvent>(
            &mut event_store.source_config,
            UpdateSourceConfigEvent {
                old,
                new,
            },
        );
    }

    /// Function for send instruction event
    ///
    /// Arguements:-
    ///     @type - Type of whitelisting, can be either add or remove
    ///     @addr - Address which is whitelisted
    ///     @country_code - Country Code of the address
    ///
    /// Fails when:-
    ///     - AssetEventStore struct is already initialized
    public fun emit_send_instruction_event(
        source_chain: String,
        source_address: address,
        dest_chain: String,
        dest_address: String,
        sender: address,
        payload: vector<u8>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

        event::emit_event<SendInstructionEvent>(
            &mut event_store.send_instruction,
            SendInstructionEvent {
                source_chain,
                source_address,
                dest_chain,
                dest_address,
                sender,
                payload,
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
    public fun emit_execute_instruction_event(
        source_chain: String,
        source_address: address,
        dest_chain: String,
        dest_address: String,
        sender: address,
        payload: vector<u8>,
    ) acquires AssetEventStore {
        let event_store = borrow_global_mut<AssetEventStore>(@interop_core);

        event::emit_event<ExecuteInstructionEvent>(
            &mut event_store.execute_instruction,
            ExecuteInstructionEvent {
                source_chain,
                source_address,
                dest_chain,
                dest_address,
                sender,
                payload,
            },
        );
    }
}

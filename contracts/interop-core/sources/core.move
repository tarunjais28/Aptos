module interop_core::core {
    use std::string::String;
    use std::signer;
    use interop_core::resource::{create_with_admin, get_source_config};
    use interop_core::events::{emit_mint_event, emit_burn_event, emit_send_instruction_event,
        emit_execute_instruction_event};
    use utils::error;
    use utils::interop_constants;
    use base_token_contract::asset_coin::request_order;
    use std::vector;
    use interop_core::maintainers::is_executer;
    use utils::payload::{new_send_payload, encrypt_send_payload, decrypt_receive_payload, get_order_id, get_token,
        get_investor, get_amount, get_action, update_action_in_payload};

    //:!:>resources
    //:!:>resources

    //:!:>helper functions
    //:!:>helper functions

    /// Function for initialization
    ///
    /// Arguements:-
    ///     @admin - Sender / Caller of the transaction
    ///     @executer - Executer Address
    ///
    /// Fails when:-
    ///     - signer is not the deployer of the contract
    public entry fun init(admin: &signer, executer: address) {
        let acc_addr = signer::address_of(admin);
        assert!(acc_addr == @interop_core, error::unauthorised_caller());

        create_with_admin(admin, executer);
    }

    /// Function for minting of token
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @order_id - OrderId of the request
    ///     @token - Token name
    ///     @user - Address from where the tokens are going to be minted
    ///     @amounts - The amount of tokens that are going to be minted
    ///
    /// Fails when:-
    ///     - any issues with request_order functionality
    ///
    /// Emits mint event
    public entry fun mint_token(
        sender: &signer,
        order_id: u256,
        token: String,
        user: address,
        amount: u64,
    ) {
        request_order(sender, order_id, token, user, amount, interop_constants::get_mint());

        // Emit mint event
        emit_mint_event(user, amount);
    }

    /// Function for burning of token
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @order_id - OrderId of the request
    ///     @token - Token name
    ///     @user - Address from where the tokens are going to be burned
    ///     @amounts - The amount of tokens that are going to be burned
    ///
    /// Fails when:-
    ///     - any issues with request_order functionality
    ///
    /// Emits burn event
    public entry fun burn_token(
        sender: &signer,
        order_id: u256,
        token: String,
        user: address,
        amount: u64,
    ) {
        request_order(sender, order_id, token, user, amount, interop_constants::get_burn());

        // Emit burn event
        emit_burn_event(user, amount);
    }

    /// Function for sending instruction
    /// This function supports batch minting
    /// The users and amounts must be passed in ordered manner, such as users[0] corresponds to amounts[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique token mapped to each token
    ///     @users - Addresses that are going to be minted
    ///     @amounts - The amount of tokens that are going to be minted
    ///
    /// Fails when:-
    ///     - quantity of users and amounts are different
    ///     - sender doesn't have either of issuer, tokenization agent, mint or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - token limit exceeds after minting
    ///
    /// Emits send instruction event
    public entry fun send_instruction(
        sender: &signer,
        dest_chain: String,
        dest_addr: String,
        order_id: u256,
        token: address,
        investor: address,
        amount: u256,
        action: u256,
    ) {
        let sender_addr = signer::address_of(sender);
        let source_chain = get_source_config();

        // Creating payload
        let payload = new_send_payload(
            order_id,
            token,
            investor,
            amount,
            sender_addr,
            action,
        );

        let encrypted = encrypt_send_payload(payload);

        // Emit send instruction event
        emit_send_instruction_event(source_chain, @interop_core, dest_chain, dest_addr, sender_addr, encrypted);
    }

    /// Function for sending batch instructions
    /// This function supports batch instructions
    /// The dest_chains, dest_addrs, order_ids, tokens, investors, amounts and actions must be passed in ordered manner,
    /// such as dest_chains[0] corresponds to dest_addrs[0], dest_addrs[0] corresponds to order_ids[0],....so on
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @dest_chains - List of destination chains
    ///     @dest_addrs - List of destination addresses
    ///     @order_ids - List of order ids
    ///     @tokens - List of tokens
    ///     @investors - List of investors
    ///     @amounts - List of amounts
    ///     @actions - List of actions
    ///
    /// Fails when:-
    ///     - quantity of elements are different
    ///
    /// Emits send instruction events
    public entry fun send_batch_instructions(
        sender: &signer,
        dest_chains: vector<String>,
        dest_addrs: vector<String>,
        order_ids: vector<u256>,
        tokens: vector<address>,
        investors: vector<address>,
        amounts: vector<u256>,
        actions: vector<u256>,
    ) {
        let sender_addr = signer::address_of(sender);
        let source_chain = get_source_config();

        // Ensuring arguements are correct
        assert!(
            vector::length(&dest_chains) == vector::length(&dest_addrs)
                && vector::length(&dest_addrs) == vector::length(&order_ids)
                && vector::length(&order_ids) == vector::length(&tokens)
                && vector::length(&tokens) == vector::length(&investors)
                && vector::length(&investors) == vector::length(&amounts)
                && vector::length(&amounts) == vector::length(&actions),
            error::arguements_mismatched()
        );

        while (vector::length(&dest_chains) > 0) {
            let dest_chain = vector::pop_back(&mut dest_chains);
            let dest_addr = vector::pop_back(&mut dest_addrs);
            let order_id = vector::pop_back(&mut order_ids);
            let token = vector::pop_back(&mut tokens);
            let investor = vector::pop_back(&mut investors);
            let amount = vector::pop_back(&mut amounts);
            let action = vector::pop_back(&mut actions);

            // Creating payload
            let payload = new_send_payload(
                order_id,
                token,
                investor,
                amount,
                sender_addr,
                action,
            );

            let encrypted = encrypt_send_payload(payload);

            // Emit send instruction event
            emit_send_instruction_event(source_chain, @interop_core, dest_chain, dest_addr, sender_addr, encrypted);
        };
    }

    /// Function for execute instruction
    /// This function supports batch minting
    /// The users and amounts must be passed in ordered manner, such as users[0] corresponds to amounts[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @id - Unique token mapped to each token
    ///     @users - Addresses that are going to be minted
    ///     @amounts - The amount of tokens that are going to be minted
    ///
    /// Fails when:-
    ///     - quantity of users and amounts are different
    ///     - sender doesn't have either of issuer, tokenization agent, mint or sub_admin rights
    ///     - missing CoinCap struct initialization
    ///     - token limit exceeds after minting
    ///
    /// Emits mint event
    public entry fun execute_instruction(
        sender: &signer,
        source_chain: String,
        source_address: String,
        payload: vector<u8>,
    ) {
        let sender_addr = signer::address_of(sender);

        // Ensure valid sender
        is_executer(sender_addr);

        let chain = get_source_config();
        
        let decrypted = decrypt_receive_payload(payload);
        request_order(
            sender,
            get_order_id(&decrypted),
            get_token(&decrypted),
            get_investor(&decrypted),
            get_amount(&decrypted),
            get_action(&decrypted),
        );

        let ack_payload = update_action_in_payload(payload);

        // Emit execute instruction event
        emit_execute_instruction_event(
            chain,
            @interop_core,
            source_chain,
            source_address,
            sender_addr,
            ack_payload
        );
    }

    //:!:>view functions
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}

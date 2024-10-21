module fund::fund {

    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use fund::resource::{Self, init_resources, create_and_store_fund, get_nav};
    use fund::agent::{set_agent, has_agent_rights};
    use fund::constants;
    use fund::events::{emit_share_dividend_event, emit_distribute_and_burn_event};
    use utils::error;
    use utils::i256::{Self, I256};
    use utils::i128;
    use fungible_tokens::asset_coin::{get_circulating_supply, mint_token, burn_token, transfer_token};
    use fungible_tokens::agents::grant_access_to_agent;
    use aptos_framework::primary_fungible_store::transfer;
    use fund::stable_coin::get_metadata_for_coin;

    //:!:>entry functions
    /// Function for initialization
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @dai - DAI address for DAI related transactions
    ///     @usdt - USDT address for USDT related transactions
    ///     @usdc - USDC address for USDC related transactions
    public entry fun init(
        account: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let acc_addr = signer::address_of(account);
        assert!(acc_addr == @fund, error::unauthorised_caller());

        init_resources(account, dai, usdt, usdc);
    }

    /// Function for creation of fund contract
    ///
    /// Given account must be registered as sub_admin on token contract
    ///
    /// `currency_pair` can be found from the Price feed by searching for respective currency pairs
    /// Price Feed address for testnet https://pyth.network/developers/price-feed-ids#aptos-testnet
    /// Price Feed address for mainnet https://pyth.network/developers/price-feed-ids#aptos-mainnet
    ///
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @fund_name - Name of the fund
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @issuer_name - Name of the issuer
    ///     @target_aum - Target Asset Under Management
    ///     @nav_launch_price - Net Asset Value during launch
    public entry fun create(
        account: &signer,
        token_id: String,
        fund_name: String,
        asset_type: u8,
        issuer_name: String,
        target_aum: u64,
        nav_launch_price: u64,
    ) {
        let sender = signer::address_of(account);

        // Set agent
        set_agent(token_id, sender);

        // Grant agent access of token contract
        // Account must be registered as sub_admin on token contract
        grant_access_to_agent(
            account,
            token_id,
            sender,
            vector[
                utils::constants::get_mint(),
                utils::constants::get_burn(),
                utils::constants::get_transer(),
                utils::constants::get_force_transer(),
            ]
        );

        create_and_store_fund(
            token_id,
            fund_name,
            asset_type,
            issuer_name,
            target_aum,
            nav_launch_price,
        );
    }

    /// Function for add user management
    /// This function supports batch operation
    /// The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be added
    ///     @fees - Fees of management to be added
    ///
    /// Fails when:-
    ///     - the sender is not the agent
    public entry fun add_user_management_fees(
        account: &signer,
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        resource::add_user_management_fees(token_id, users, fees);
    }

    /// Function for update user management fees
    /// This function supports batch operation
    /// The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be updated
    ///     @fees - Fees of management to be updated
    ///
    /// Fails when:-
    ///     - the sender is not the agent
    public entry fun update_user_management_fees(
        account: &signer,
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        resource::update_user_management_fees(token_id, users, fees);
    }

    /// Function for remove user management fees
    /// This function supports batch operation
    ///
    /// This function is not currently in use, may be used in future versions
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @users - Addresses of the users to be removed
    ///
    /// Fails when:-
    ///     - the sender is not the agent
    public entry fun remove_user_management_fees(
        account: &signer,
        token_id: String,
        users: vector<address>,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        resource::remove_user_management_fees(token_id, users,);
    }

    /// Function for share dividend
    /// Stable coins must be transferred from `from` account to agent account before this function call
    /// This function supports batch operation
    /// The receipients, asset_types and dividends must be passed in ordered manner, such as receipients[0] corresponds
    /// to asset_types[0] and dividends[0]
    ///
    /// For asset_type = Token, dividends are shared in form of tokens
    /// For asset_type = Stable Coin, dividends are shared in form of stable coins, either in DAI, USDT or USDC
    /// For asset_type = Fiat, not yet implemented, will be introduced in future versions
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @to_addresses - Recipients addresses
    ///     @dividends - Amount of tokens and stable coins going to be shared
    ///     @asset_type - Asset Type, can be either Stable Coin, Token or Fiat
    ///     @coin_type - Coin Type, coin used for the transaction, can be either of DAI, USDC or USDT
    ///
    /// Fails when:-
    ///     - quantity of to_addresses, dividendens and coin_type are different
    ///     - sender doesn't have agent rights
    ///
    /// Emits share dividends event
    public entry fun share_dividend(
        account: &signer,
        token_id: String,
        to_addresses: vector<address>,
        dividends: vector<u64>,
        asset_types: vector<u8>,
        coin_type: u8,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        // Ensuring arguements are correct
        assert!(
            vector::length(&to_addresses) == vector::length(&dividends)
                && vector::length(&to_addresses) == vector::length(&asset_types),
            error::arguements_mismatched()
        );

        // Local variables for batch mint operations
        let mint_users = vector::empty<address>();
        let mint_amounts = vector::empty<u64>();

        // Fetching token metadata for token transfer
        let metadata = get_metadata_for_coin(coin_type);

        while (vector::length(&asset_types) > 0) {
            let asset_type = vector::pop_back(&mut asset_types);
            let to_address = vector::pop_back(&mut to_addresses);
            let dividend = vector::pop_back(&mut dividends);

            // For token transactions
            if (asset_type == constants::token()) {
                vector::push_back(&mut mint_users, to_address);
                vector::push_back(&mut mint_amounts, dividend);

                // Emitting event
                emit_share_dividend_event(
                    token_id,
                    sender,
                    to_address,
                    dividend,
                    string::utf8(b"Token"),
                );
                // For stable coin transactions
            } else if (asset_type == constants::stable_coin()) {
                // Transfer stable coins from agent account
                transfer(account, metadata, to_address, dividend);

                // Emitting event
                emit_share_dividend_event(
                    token_id,
                    sender,
                    to_address,
                    dividend,
                    string::utf8(b"Stable Coin"),
                );
            };
            resource::add_user_dividend(
                token_id,
                asset_type,
                to_address,
                dividend
            );
        };

        // Batch minting of tokens
        mint_token(
            account,
            token_id,
            mint_users,
            mint_amounts,
        );
    }

    /// Function for distribute and burn
    /// Stable coins must be transferred from `from` account to agent account before this function call
    /// This function supports batch operation
    /// The investors, amounts and tokens must be passed in ordered manner, such as investors[0] corresponds
    /// to amounts[0] and tokens[0]
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @investors - Addresses of investors
    ///     @amounts - Amount of tokens stable coins transferred to investor's account in exchange with the specific
    ///                tokens burned
    ///     @tokens - Tokens to be burned
    ///     @coin_type - Coin Type, coin used for the transaction, can be either of DAI, USDC or USDT
    ///
    /// Fails when:-
    ///     - quantity of investors, amounts and tokens are different
    ///     - sender doesn't have agent rights
    ///
    /// Emits distribute and burn event
    public entry fun distribute_and_burn(
        account: &signer,
        token_id: String,
        investors: vector<address>,
        amounts: vector<u64>,
        tokens: vector<u64>,
        coin_type: u8,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        // Ensuring arguements are correct
        assert!(
            vector::length(&investors) == vector::length(&amounts)
                && vector::length(&amounts) == vector::length(&tokens),
            error::arguements_mismatched()
        );

        // Local variables for batch burn operations
        let burn_users = vector::empty<address>();
        let burn_amounts = vector::empty<u64>();

        // Fetching token metadata for token transfer
        let metadata = get_metadata_for_coin(coin_type);

        while (vector::length(&investors) > 0) {
            let investor = vector::pop_back(&mut investors);
            let token = vector::pop_back(&mut tokens);
            let amount = vector::pop_back(&mut amounts);

            vector::push_back(&mut burn_users, investor);
            vector::push_back(&mut burn_amounts, token);

            // Transfer stable coins from agent account to investor's account
            transfer(account, metadata, investor, amount);

            // Emitting event
            emit_distribute_and_burn_event(
                token_id,
                sender,
                investor,
                amount,
                token,
            );
        };

        // Batch burning of tokens from investor's account
        burn_token(
            account,
            token_id,
            burn_users,
            burn_amounts
        );
    }

    /// Function for rescue token
    /// The extra tokens can be claimed or rescued from the agent
    ///
    /// Arguements:-
    ///     @account - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @to - Address of the recipient
    ///     @amount - Amount of stable coins to be rescued
    ///
    /// Fails when:-
    ///     - sender doesn't have agent rights
    public entry fun rescue_token(
        account: &signer,
        token_id: String,
        to: address,
        amount: u64,
    ) {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        assert!(has_agent_rights(token_id, sender), error::unauthorised_caller());

        transfer_token(
            account,
            token_id,
            to,
            amount
        )
    }
    //:!:>entry functions

    //:!:>view functions
    #[view]
    /// Function to get asset under management
    /// AUM = Circulating Supply x NAV Price
    ///
    /// Arguements:-
    ///     @token_id - Unique id mapped to each token
    ///
    /// Returns AUM with positive and negative flags
    /// Ideally negative = true is not possible but if negative = true, then it indicates the error in calculation
    public fun get_aum(id: String): I256 {
        // Fetching circulating supply of token
        let circulating_supply = get_circulating_supply(id);

        // Fetching NAV price in I128
        let nav_u128 = (get_nav(id) as u128);
        let nav_i128 = i128::from_u128(nav_u128);

        // Multiplying NAV price with circulating supply to get AUM
        let mult = i128::mult_magnitude(circulating_supply, nav_i128);
        if (!i128::get_is_negative(&circulating_supply)) {
            i256::new(mult, false)
        } else {
            i256::new(mult, true)
        }
    }
    //:!:>view functions
}
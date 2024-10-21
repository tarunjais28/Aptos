module fund::stable_coin {
    use std::signer;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object};
    use fund::maintainer::is_admin;
    use fund::constants;
    use utils::error::resource_already_exists;
    use fund::agent::get_agent_by_id;
    use std::string::String;
    use aptos_framework::primary_fungible_store::transfer;

    //:!:>resources
    struct StableCoins has key, store, drop {
        dai: address,
        usdt: address,
        usdc: address,
    }
    //:!:>resources

    //:!:>helper functions
    /// Private function for token creation
    ///
    /// Arguements:-
    ///     @coin_type - Coin Type, can be either of DAI, USDC or USDT from constant module
    ///
    /// Fails when:-
    ///     - StableCoins struct is not initialized
    ///
    /// Returns address of the stable coin
    public fun get_stable_coin_address(
        coin_type: u8
    ): address acquires StableCoins {
        let stable_coins = borrow_global<StableCoins>(@fund);
        if (coin_type == constants::dai()) {
            stable_coins.dai
        } else if (coin_type == constants::usdt()) {
            stable_coins.usdt
        } else {
            stable_coins.usdc
        }
    }
    //:!:>helper functions

    //:!:>entry functions
    /// Function for set stable coin addresses
    /// Can only be called during initiaization
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @dai - DAI address for DAI related transactions
    ///     @usdt - USDT address for USDT related transactions
    ///     @usdc - USDC address for USDC related transactions
    ///
    ///
    /// Fails when:-
    ///     - StableCoins struct is not initialized
    ///     - sender is not admin
    public fun set_stable_coin(
        sender: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let sender_address = signer::address_of(sender);

        // Check authetication
        is_admin(sender_address);

        assert!(!exists<StableCoins>(sender_address), resource_already_exists());

        // Set Stable Coin addresses
        move_to(
            sender,
            StableCoins {
                dai,
                usdt,
                usdc,
            }
        );
    }

    /// Function for token creation
    ///
    /// Arguements:-
    ///     @coin_type - Coin Type, can be either of DAI, USDC or USDT from constant module
    ///
    /// Returns Metadata of the stable coin
    public fun get_metadata_for_coin(
        coin_type: u8
    ): Object<Metadata> acquires StableCoins {
        let stable_coin = get_stable_coin_address(coin_type);
        object::address_to_object<Metadata>(stable_coin)
    }

    /// Function for update stable coin address
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @coin_type - Coin Type, can be either of DAI, USDC or USDT from constant module
    ///     @addr - New address of the stable coin
    ///
    /// Fails when:-
    ///     - StableCoins struct is not initialized
    ///     - sender is not admin
    public entry fun update_stable_coin_address(
        sender: &signer,
        coin_type: u8,
        addr: address,
    ) acquires StableCoins {
        let sender_address = signer::address_of(sender);

        // Check authetication
        is_admin(sender_address);

        let stable_coins = borrow_global_mut<StableCoins>(@fund);
        if (coin_type == constants::dai()) {
            stable_coins.dai = addr;
        } else if (coin_type == constants::usdt()) {
            stable_coins.usdt = addr;
        } else {
            stable_coins.usdc = addr;
        };
    }

    /// Function for sending stable coins to agent
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @token_id - Unique id mapped to each token
    ///     @amount - Amount of token to be sent
    ///     @coin_type - Coin Type, can be either of DAI, USDC or USDT from constant module
    public entry fun send_stable_coins(
        sender: &signer,
        token_id: String,
        amount: u64,
        coin_type: u8,
    ) acquires StableCoins {
        let agent = get_agent_by_id(token_id);
        let metadata = get_metadata_for_coin(coin_type);

        // Transfer stable coins to agent account
        transfer(sender, metadata, agent, amount);
    }
    //:!:>entry functions
}

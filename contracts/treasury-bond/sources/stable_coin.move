module treasury_bond::stable_coin {
    use std::signer;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object};
    use treasury_bond::maintainer::is_admin;
    use treasury_bond::constants;
    use utils::error::resource_already_exists;
    use treasury_bond::agent::get_agent_by_id;
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
    /// Function for token creation
    fun get_stable_coin_address(
        coin_type: u8
    ): address acquires StableCoins {
        let stable_coins = borrow_global<StableCoins>(@treasury_bond);
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
    public fun get_metadata_for_coin(
        coin_type: u8
    ): Object<Metadata> acquires StableCoins {
        let stable_coin = get_stable_coin_address(coin_type);
        object::address_to_object<Metadata>(stable_coin)
    }

    /// Function for update stable coin address
    public entry fun update_stable_coin_address(
        sender: &signer,
        coin_type: u8,
        addr: address,
    ) acquires StableCoins {
        let sender_address = signer::address_of(sender);

        // Check authetication
        is_admin(sender_address);

        let stable_coins = borrow_global_mut<StableCoins>(@treasury_bond);
        if (coin_type == constants::dai()) {
            stable_coins.dai = addr;
        } else if (coin_type == constants::usdt()) {
            stable_coins.usdt = addr;
        } else {
            stable_coins.usdc = addr;
        };
    }

    /// Function for sending stable coins to agent
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

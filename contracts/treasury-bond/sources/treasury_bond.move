module treasury_bond::treasury_bond {

    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use treasury_bond::resource::{init_resources, create_and_store_fund};
    use treasury_bond::agent::{set_agent, is_agent};
    use treasury_bond::events::emit_share_stable_coins_event;
    use utils::error;
    use aptos_framework::primary_fungible_store::transfer;
    use treasury_bond::stable_coin::get_metadata_for_coin;
    use aptos_std::simple_map::{Self, SimpleMap};

    //:!:>resources
    struct Payments has key {
        payments: SimpleMap<vector<u8>, Payment>
    }

    struct Payment has store, copy, drop {
        total_coupon_payment: u64,
        coupon_payment_paid: u64,
    }
    //:!:>resources

    //:!:>helper functions
    fun new_payment(payment: u64): Payment {
        Payment {
            total_coupon_payment: payment,
            coupon_payment_paid: payment,
        }
    }

    fun add_payments(payment: &mut Payment, amount: u64) {
        payment.total_coupon_payment = payment.total_coupon_payment + amount;
        payment.coupon_payment_paid = payment.coupon_payment_paid + amount;
    }
    //:!:>helper functions

    //:!:>entry functions
    /// Function for initialization
    public entry fun init(
        account: &signer,
        dai: address,
        usdt: address,
        usdc: address,
    ) {
        let acc_addr = signer::address_of(account);
        assert!(acc_addr == @treasury_bond, error::unauthorised_caller());

        assert!(!exists<Payments>(acc_addr), error::resource_already_exists());
        move_to(
            account,
            Payments {
                payments: simple_map::create(),
            }
        );

        init_resources(account, dai, usdt, usdc);
    }

    /// Function for creation of treasury_bond contract
    ///
    /// Given account must be registered as sub_admin on token contract
    ///
    /// `currency_pair` can be found from the Price feed by searching for respective currency pairs
    /// Price Feed address for testnet https://pyth.network/developers/price-feed-ids#aptos-testnet
    /// Price Feed address for mainnet https://pyth.network/developers/price-feed-ids#aptos-mainnet
    public entry fun create(
        account: &signer,
        token_id: String,
        bond_name: String,
        issue_size: u128,
        face_value: u128,
        coupon_rate: u16,
        accrued_interest: u16,
        maturity_date: u64,
        issuer_name: String,
        coupon_frequency: String,
    ) {
        let sender = signer::address_of(account);

        // Set agent
        set_agent(token_id, sender);

        create_and_store_fund(
            token_id,
            bond_name,
            issue_size,
            face_value,
            coupon_rate,
            accrued_interest,
            maturity_date,
            issuer_name,
            coupon_frequency,
        );
    }

    /// Function for share stable coins
    /// Stable coins must be transferred from `from` account to agent account before this function call
    public entry fun share_stable_coins(
        account: &signer,
        token_id: String,
        coin_type: u8,
        to_addresses: vector<address>,
        payments: vector<u64>,
    ) acquires Payments {
        let sender = signer::address_of(account);

        // Ensuring authorised sender
        is_agent(token_id, sender);

        // Ensuring arguements are correct
        assert!(
            vector::length(&to_addresses) == vector::length(&payments),
            error::arguements_mismatched()
        );

        let metadata = get_metadata_for_coin(coin_type);

        let payment_map= &mut borrow_global_mut<Payments>(@treasury_bond).payments;
        let key = string::bytes(&token_id);
        let pay = new_payment(0);

        if (!simple_map::contains_key(payment_map, key)) {
            simple_map::add(payment_map, *key, pay);
        };

        let payment_store = simple_map::borrow_mut(payment_map, key);

        vector::for_each(to_addresses, |to_address| {
            let payment = vector::pop_back(&mut payments);
            add_payments(payment_store, payment);

            // Transfer stable coins from agent account
            transfer(account, metadata, to_address, payment);

            // Emitting event
            emit_share_stable_coins_event(
                token_id,
                sender,
                to_address,
                payment,
            );
        });
    }
    //:!:>entry functions

    //:!:>view functions
    #[view]
    /// Function to get payments
    public fun get_payments(token: String): Payment acquires Payments {
        let payments= borrow_global<Payments>(@treasury_bond).payments;
        let key = string::bytes(&token);
        *simple_map::borrow(&payments, key)
    }
    //:!:>view functions
}
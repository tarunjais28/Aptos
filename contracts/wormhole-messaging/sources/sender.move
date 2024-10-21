/// A simple contracts that demonstrates how to send messages with wormhole.
module wormhole_messaging::sender {
    use wormhole::wormhole;
    use aptos_framework::coin;

    struct State has key {
        emitter_cap: wormhole::emitter::EmitterCapability,
    }

    // Define a public entry function named `send_message` which takes a mutable reference to `user` and a vector of
    // unsigned 8-bit integers `payload`.
    // This function acquires the State resource.
    public entry fun send_message(user: &signer, payload: vector<u8>) acquires State {
        // Retrieve emitter capability from the state
        let emitter_cap = &mut borrow_global_mut<State>(@wormhole_messaging).emitter_cap;

        // Set nonce to 0 (this field is not interesting for regular messages,
        // only batch VAAs)
        let nonce: u64 = 0;

        // Retrieve the fee for sending a message from the wormhole state
        let message_fee = wormhole::state::get_message_fee();

        // Withdraw the message fee from the user's account
        let fee_coins = coin::withdraw(user, message_fee);

        // Publish the message using the wormhole, storing the result in `_sequence`
        let _sequence = wormhole::publish_message(
            emitter_cap,
            nonce,
            payload,
            fee_coins
        );
    }
}

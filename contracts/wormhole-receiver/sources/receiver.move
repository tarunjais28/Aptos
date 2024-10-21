/// A simple contracts that demonstrates how to send messages with wormhole.
module wormhole_messaging::receiver {
    use utils::payload::{decrypt_receive_payload, get_order_id, get_token, get_investor, get_amount, get_action};
    use base_token_contract::asset_coin::request_order;

    /// Define a public entry function named `receive` which takes a mutable reference to `sender` and a vector of
    /// unsigned 8-bit integers `payload`.
    public entry fun receive(sender: &signer, payload: vector<u8>) {
        // Decrypt the payload received using a decryption function and store the result in `decrypted`
        let decrypted = decrypt_receive_payload(payload);

        // Request an order using the extracted information from the decrypted payload,
        // including sender, order ID, token, investor, amount, and action.
        request_order(
            sender,
            get_order_id(&decrypted),
            get_token(&decrypted),
            get_investor(&decrypted),
            get_amount(&decrypted),
            get_action(&decrypted),
        );
    }
}

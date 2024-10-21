module utils::payload {
    use std::string::{Self, String, utf8};
    use std::bcs;
    use std::vector;
    use aptos_std::from_bcs;
    use utils::interop_constants;

    //:!:>resources
    /// Define resource structures for send payloads
    struct SendPayload has drop, store {
        action: u256,
        investor: address,
        amount: u256,
        token: address,
        sender: address,
        order_id: u256,
    }

    /// Define resource structures for receive payloads
    struct ReceivePayload has drop, store {
        action: u8,
        investor: address,
        amount: u64,
        sender: address,
        order_id: u256,
        token: String,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function to create a new send payload
    public fun new_send_payload(
        order_id: u256,
        token: address,
        investor: address,
        amount: u256,
        sender: address,
        action: u256,
    ): SendPayload {
        // Construct and return a new SendPayload instance
        SendPayload {
            action,
            investor,
            amount,
            token,
            sender,
            order_id,
        }
    }

    /// Function to encrypt a send payload
    public fun encrypt_send_payload(payload: SendPayload): vector<u8> {
        // Serialize each field of the payload to bytes and concatenate them into a vector
        let encrypted = bcs::to_bytes(&payload.action);
        vector::append(&mut encrypted, bcs::to_bytes(&payload.investor));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.amount));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.token));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.sender));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.order_id));

        // Return the concatenated bytes as the encrypted payload
        encrypted
    }

    /// Function to decrypt a send payload
    public fun decrypt_send_payload(encrypted: vector<u8>): SendPayload {
        // Deserialize each field from the encrypted bytes and construct a SendPayload instance
        SendPayload {
            action: from_bcs::to_u256(vector::slice(&encrypted, 0, 32)),
            investor: from_bcs::to_address(vector::slice(&encrypted, 32, 64)),
            amount: from_bcs::to_u256(vector::slice(&encrypted, 64, 96)),
            token: from_bcs::to_address(vector::slice(&encrypted, 96, 128)),
            sender: from_bcs::to_address(vector::slice(&encrypted, 128, 160)),
            order_id: from_bcs::to_u256(vector::slice(&encrypted, 160, 192)),
        }
    }

    /// Function to create a new receive payload
    public fun new_receive_payload(
        order_id: u256,
        token: String,
        investor: address,
        amount: u64,
        sender: address,
        action: u8,
    ): ReceivePayload {
        // Construct and return a new ReceivePayload instance
        ReceivePayload {
            action,
            investor,
            amount,
            sender,
            order_id,
            token,
        }
    }

    /// Function to encrypt a receive payload
    public fun encrypt_receive_payload(payload: ReceivePayload): vector<u8> {
        let encrypted = bcs::to_bytes(&payload.action);
        vector::append(&mut encrypted, bcs::to_bytes(&payload.investor));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.amount));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.sender));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.order_id));
        vector::append(&mut encrypted, bcs::to_bytes(&payload.token));

        encrypted
    }

    /// Function to decrypt an encrypted receive payload
    public fun decrypt_receive_payload(encrypted: vector<u8>): ReceivePayload {
        // Deserialize each field of the encrypted payload from bytes
        ReceivePayload {
            action: from_bcs::to_u8(vector::slice(&encrypted, 0, 1)),
            investor: from_bcs::to_address(vector::slice(&encrypted, 1, 33)),
            amount: from_bcs::to_u64(vector::slice(&encrypted, 33, 41)),
            sender: from_bcs::to_address(vector::slice(&encrypted, 41, 73)),
            order_id: from_bcs::to_u256(vector::slice(&encrypted, 73, 105)),
            token: from_bcs::to_string(vector::slice(&encrypted, 105, vector::length(&encrypted))),
        }
    }

    /// Function to decode a vector of bytes into a vector of strings using a delimiter "|"
    public fun decode_payload(payload: vector<u8>): vector<String> {
        // Convert the payload bytes to a string
        let raw = aptos_std::from_bcs::to_string(payload);
        let i = 0;
        let j = string::index_of(&raw, &utf8(b"|")); // Find the index of the delimiter "|"
        let l = string::length(&raw); // Calculate the length of the string
        let decoded = vector::empty<String>(); // Initialize an empty vector to store decoded strings

        // Loop until the delimiter is found in the string
        while (j != l) {
            // Extract substring from position i to j (excluding j) as a string
            let str = string::sub_string(&raw, i, j);
            // Update raw string to exclude the processed part
            raw = string::sub_string(&raw, j + 1, l);
            // Update j to find the next occurrence of delimiter
            j = string::index_of(&raw, &utf8(b"|"));
            // Update the length of raw string
            l = string::length(&raw);
            // Push the extracted string into the decoded vector
            vector::push_back(&mut decoded, str);
        };
        // Push the remaining part of raw string into the decoded vector
        vector::push_back(&mut decoded, raw);

        // Return the vector of decoded strings
        decoded
    }

    /// Function to retrieve the order ID from a receive payload
    public fun get_order_id(payload: &ReceivePayload): u256 {
        // Return the order ID field from the receive payload
        payload.order_id
    }

    /// Function to retrieve the token from a receive payload
    public fun get_token(payload: &ReceivePayload): String {
        // Return the token field from the receive payload
        payload.token
    }

    /// Function to retrieve the investor address from a receive payload
    public fun get_investor(payload: &ReceivePayload): address {
        // Return the investor address field from the receive payload
        payload.investor
    }

    /// Function to retrieve the amount from a receive payload
    public fun get_amount(payload: &ReceivePayload): u64 {
        // Return the amount field from the receive payload
        payload.amount
    }

    /// Function to retrieve the action from a receive payload
    public fun get_action(payload: &ReceivePayload): u8 {
        // Return the action field from the receive payload
        payload.action
    }

    /// Function to update action and return encrypted payload
    public fun update_action_in_payload(payload: vector<u8>): vector<u8> {
        let decrypted = decrypt_receive_payload(payload);
        decrypted.action = interop_constants::get_ack();

        // Return the updated receive payload
        encrypt_receive_payload(decrypted)
    }
    //:!:>helper functions

    //:!:>view functions
    #[view]
    /// Function to create a payload for receiving data
    ///
    /// Arguements:-
    ///     @sender: Sender Address
    ///     @order_id: Order Id
    ///     @token: Token name / address
    ///     @investor: Investor address
    ///     @amount: Token amount
    ///     @action: Action, 1 for mint, 2 for burn and 3 for acknowledgement
    ///
    /// Returns balance of the address
    public fun create_payload(
        sender: address,
        order_id: u256,
        token: String,
        investor: address,
        amount: u64,
        action: u8,
    ): vector<u8> {
        // Create a new receive payload
        let payload = new_receive_payload(
            order_id,
            token,
            investor,
            amount,
            sender,
            action,
        );

        // Encrypt the receive payload and return it
        encrypt_receive_payload(payload)
    }

    #[view]
    /// Function to retrieve a receive payload from encrypted data
    ///
    /// Arguements:-
    ///     @encrypted: Encrypted byte array
    ///
    public fun get_payload(encrypted: vector<u8>): ReceivePayload {
        // Decrypt the encrypted payload and return it
        decrypt_receive_payload(encrypted)
    }
    //:!:>view functions
}

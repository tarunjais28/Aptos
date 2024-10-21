module utils::interop_constants {

    use std::string::{Self, String};

    //:!:>constants
    const MINT: u8 = 1;
    const BURN: u8 = 2;
    const ACKNOWLEDGEMENT: u8 = 3;
    //:!:>constants

    /// Function to get the MINT operation code
    public fun get_mint(): u8 {
        // Return the MINT operation code
        MINT
    }

    /// Function to get the BURN operation code
    public fun get_burn(): u8 {
        // Return the BURN operation code
        BURN
    }

    /// Function to get the ACKNOWLEDGEMENT operation code
    public fun get_ack(): u8 {
        // Return the ACKNOWLEDGEMENT operation code
        ACKNOWLEDGEMENT
    }

    /// Function to get the operation name based on role
    public fun get_operation(role: u8): String {
        // Check the role and return the corresponding operation name
        if (role == MINT) {
            string::utf8(b"mint")
        } else if (role == BURN) {
            string::utf8(b"burn")
        } else if (role == ACKNOWLEDGEMENT) {
            string::utf8(b"acknowledgement")
        } else {
            // Return "unknown" if the role does not match any predefined operation
            string::utf8(b"unknown")
        }
    }
}

module utils::status {

    use std::string::{Self, String};

    //:!:>constants
    const INIT: u8 = 1;
    const PENDING: u8 = 2;
    const READY: u8 = 3;
    const APPROVED: u8 = 4;
    const CANCELLED: u8 = 5;
    //:!:>constants

    /// Function to get the INIT status
    public fun get_init(): u8 {
        // Return the INIT status
        INIT
    }

    /// Function to get the PENDING status
    public fun get_pending(): u8 {
        // Return the PENDING status
        PENDING
    }

    /// Function to get the READY status
    public fun get_ready(): u8 {
        // Return the READY status
        READY
    }

    /// Function to get the APPROVED status
    public fun get_approved(): u8 {
        // Return the APPROVED status
        APPROVED
    }

    /// Function to get the CANCELLED status
    public fun get_cancelled(): u8 {
        // Return the CANCELLED status
        CANCELLED
    }

    /// Function to get the operation name based on role
    public fun get_operation(role: u8): String {
        // Check the role and return the corresponding operation name
        if (role == INIT) {
            string::utf8(b"Init")
        } else if (role == PENDING) {
            string::utf8(b"Pending")
        } else if (role == READY) {
            string::utf8(b"Ready")
        } else if (role == APPROVED) {
            string::utf8(b"Approved")
        } else if (role == CANCELLED) {
            string::utf8(b"Cancelled")
        } else {
            // Return "Unknown" if the role does not match any predefined status
            string::utf8(b"Unknown")
        }
    }
}

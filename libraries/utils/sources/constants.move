module utils::constants {

    use std::string::{Self, String};

    //:!:>constants
    const ADMIN: u8 = 0;
    const MINT: u8 = 1;
    const BURN: u8 = 2;
    const TRANSFER: u8 = 3;
    const FORCE_TRANSFER: u8 = 4;
    const FREEZE: u8 = 5;
    const UNFREEZE: u8 = 6;
    const DEPOSIT: u8 = 7;
    const DELETE: u8 = 8;
    const UNSPECIFIED: u8 = 9;
    const WITHDRAW: u8 = 10;
    //:!:>constants

    // Function to get the ADMIN role
    public fun get_admin(): u8 {
        ADMIN
    }

    // Function to get the MINT role
    public fun get_mint(): u8 {
        MINT
    }

    // Function to get the BURN role
    public fun get_burn(): u8 {
        BURN
    }

    // Function to get the TRANSFER role
    public fun get_transer(): u8 {
        TRANSFER
    }

    // Function to get the FORCE_TRANSFER role
    public fun get_force_transer(): u8 {
        FORCE_TRANSFER
    }

    // Function to get the FREEZE role
    public fun get_freeze(): u8 {
        FREEZE
    }

    // Function to get the UNFREEZE role
    public fun get_unfreeze(): u8 {
        UNFREEZE
    }

    // Function to get the DEPOSIT role
    public fun get_deposit(): u8 {
        DEPOSIT
    }

    // Function to get the DELETE role
    public fun get_delete(): u8 {
        DELETE
    }

    // Function to get the UNSPECIFIED role
    public fun get_unspecified(): u8 {
        UNSPECIFIED
    }

    // Function to get the WITHDRAW role
    public fun get_withdraw(): u8 {
        WITHDRAW
    }

    // Function to get the role name based on the provided role ID
    public fun get_role(role: u8): String {
        if (role == ADMIN) {
            string::utf8(b"admin")
        } else if (role == MINT) {
            string::utf8(b"mint")
        } else if (role == BURN) {
            string::utf8(b"burn")
        } else if (role == TRANSFER) {
            string::utf8(b"transfer")
        } else if (role == FORCE_TRANSFER) {
            string::utf8(b"force_transfer")
        } else if (role == FREEZE) {
            string::utf8(b"freeze")
        } else if (role == UNFREEZE) {
            string::utf8(b"unfreeze")
        } else if (role == DEPOSIT) {
            string::utf8(b"deposit")
        } else if (role == DELETE) {
            string::utf8(b"delete")
        } else if (role == UNSPECIFIED) {
            string::utf8(b"unspecified")
        } else if (role == WITHDRAW) {
            string::utf8(b"withdraw")
        } else {
            string::utf8(b"unknown")
        }
    }
}

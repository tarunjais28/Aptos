module utils::error {
    use std::error;

    //:!:>constants
    const ERR_NEGATIVE_VALUE: u64 = 1;
    const ERR_POSITIVE_VALUE: u64 = 2;
    const ERR_MAGNITUDE_TO_LARGE: u64 = 3;
    const ERR_ALREADY_ASSIGNED: u64 = 4;
    const ERR_UNAUTHORISED_CALLER: u64 = 5;
    const ERR_NOT_ADMIN: u64 = 6;
    const ERR_ALREADY_EXIST: u64 = 7;
    const ERR_RESOURCE_ALREADY_REGISTERED: u64 = 8;
    const ERR_ARGUMENTS_MISMATCHED: u64 = 9;
    const ERR_NO_ADMIN_ACCESS: u64 = 10;
    const ERR_NO_MINT_ACCESS: u64 = 11;
    const ERR_NO_BURN_ACCESS: u64 = 12;
    const ERR_NO_TRANSFER_ACCESS: u64 = 13;
    const ERR_NO_FORCE_TRANSFER_ACCESS: u64 = 14;
    const ERR_NO_FREEZE_ACCESS: u64 = 15;
    const ERR_NO_UNFREEZE_ACCESS: u64 = 16;
    const ERR_NO_DEPOSIT_ACCESS: u64 = 17;
    const ERR_NO_DELETE_ACCESS: u64 = 18;
    const ERR_NO_UNSPECIFIED_ACCESS: u64 = 19;
    const ERR_NO_WITHDRAW_ACCESS: u64 = 20;
    const ERR_NO_TOKENIZATION_AGENT_RIGHTS: u64 = 21;
    const ERR_NOT_SUB_ADMIN: u64 = 22;
    const ERR_INVALID_PROPOSAL_ID: u64 = 23;
    const ERR_NOT_OWNER: u64 = 24;
    const ERR_ALREADY_APPROVED: u64 = 25;
    const ERR_COMPLETED: u64 = 26;
    const ERR_ALREADY_ENABLED: u64 = 27;
    const ERR_ALREADY_DISABLED: u64 = 28;
    const ERR_NOT_A_SIGNER: u64 = 29;
    const ERR_PROPOSAL_CANCELLED: u64 = 30;
    const ERR_MULTISIG_NOT_ENABLED: u64 = 31;
    const ERR_NOT_APPROVED: u64 = 32;
    const ERR_PROPOSAL_NOT_CANCELLED: u64 = 33;
    const ERR_UNAUTHORIZED: u64 = 34;
    const ERR_MULTISIG_ENABLED: u64 = 35;
    const ERR_PROPOSAL_NOT_FOUND: u64 = 36;
    const ERR_ID_EXIST: u64 = 37;
    const ERR_NAME_EXIST: u64 = 38;
    const ERR_SYMBOL_EXIST: u64 = 39;
    const ERR_BALANCE_FROZEN: u64 = 40;
    const ERR_ACCOUNT_NOT_WHITELISTED: u64 = 41;
    const ERR_COUNTRY_CODE_ALREADY_PRESENT: u64 = 42;
    const ERR_COUNTRY_CODE_NOT_PRESENT: u64 = 43;
    const ERR_TOKEN_LIMIT_EXCEEDED: u64 = 44;
    const ERR_TEST_CASE_FAILED: u64 = 45;
    const ERR_NO_ISSUER_RIGHTS: u64 = 46;
    const ERR_NO_TRANASFER_AGENT_RIGHTS: u64 = 47;
    const ERR_ADDRESS_NOT_FOUND: u64 = 48;
    const ERR_UNDERFLOW: u64 = 49;
    const ERR_INSUFFICIENT_BALANCE: u64 = 50;
    const ERR_INVALID_REQUEST: u64 = 51;
    const ERR_AMOUNT_MUST_BE_GREATER_THAN_ZERO: u64 = 52;
    const ERR_NOT_AN_EXECUTER: u64 = 53;
    const ERR_NOT_AN_VALIDATOR: u64 = 54;
    const ERR_THRESHOLD_NOT_MET: u64 = 55;
    const ERR_NOT_AN_AGENT: u64 = 56;
    const ERR_TOKEN_ON_HOLD: u64 = 57;
    //:!:>constants

    /// Error message for when a negative value is encountered
    public fun negative_value(): u64 {
        error::invalid_state(ERR_NEGATIVE_VALUE)
    }

    /// Error message for when a positive value is expected but a negative value is encountered
    public fun positive_value(): u64 {
        error::invalid_state(ERR_POSITIVE_VALUE)
    }

    /// Error message for when the magnitude of a value exceeds the allowed limit
    public fun magnitude_too_large(): u64 {
        error::invalid_argument(ERR_MAGNITUDE_TO_LARGE)
    }

    /// Error message for when attempting to assign to a value that is already assigned
    public fun already_assigned(): u64 {
        error::already_exists(ERR_ALREADY_ASSIGNED)
    }

    /// Error message for unauthorized caller
    public fun unauthorised_caller(): u64 {
        error::permission_denied(ERR_UNAUTHORISED_CALLER)
    }

    /// Error message for when an operation is performed by a non-admin user
    public fun not_an_admin(): u64 {
        error::not_found(ERR_NOT_ADMIN)
    }

    /// Error message for when an item already exists
    public fun already_exists(): u64 {
        error::already_exists(ERR_ALREADY_EXIST)
    }

    /// Error message for when a resource already exists
    public fun resource_already_exists(): u64 {
        error::already_exists(ERR_RESOURCE_ALREADY_REGISTERED)
    }

    /// Error message for when the arguments provided do not match the expected format
    public fun arguements_mismatched(): u64 {
        error::invalid_argument(ERR_ARGUMENTS_MISMATCHED)
    }

    /// Error message for when there is no admin access
    public fun no_admin_access(): u64 {
        error::permission_denied(ERR_NO_ADMIN_ACCESS)
    }

    /// Error message for when there is no mint access
    public fun no_mint_access(): u64 {
        error::permission_denied(ERR_NO_MINT_ACCESS)
    }

    /// Error message for when there is no burn access
    public fun no_burn_access(): u64 {
        error::permission_denied(ERR_NO_BURN_ACCESS)
    }

    /// Error message for when there is no transfer access
    public fun no_transfer_access(): u64 {
        error::permission_denied(ERR_NO_TRANSFER_ACCESS)
    }

    /// Error message for when there is no force transfer access
    public fun no_force_transfer_access(): u64 {
        error::permission_denied(ERR_NO_FORCE_TRANSFER_ACCESS)
    }

    /// Error message for when there is no freeze access
    public fun no_freeze_access(): u64 {
        error::permission_denied(ERR_NO_FREEZE_ACCESS)
    }

    /// Error message for when there is no unfreeze access
    public fun no_unfreeze_access(): u64 {
        error::permission_denied(ERR_NO_UNFREEZE_ACCESS)
    }

    /// Error message for when there is no deposit access
    public fun no_deposit_access(): u64 {
        error::permission_denied(ERR_NO_DEPOSIT_ACCESS)
    }

    /// Error message for when there is no delete access
    public fun no_delete_access(): u64 {
        error::permission_denied(ERR_NO_DELETE_ACCESS)
    }

    /// Error message for when there is no unspecified access
    public fun no_unspecified_access(): u64 {
        error::permission_denied(ERR_NO_UNSPECIFIED_ACCESS)
    }

    /// Error message for when there is no withdraw access
    public fun no_withdraw_access(): u64 {
        error::permission_denied(ERR_NO_WITHDRAW_ACCESS)
    }

    /// Error message for when there are no tokenization agent rights
    public fun no_tokenization_agent_rights(): u64 {
        error::permission_denied(ERR_NO_TOKENIZATION_AGENT_RIGHTS)
    }

    /// Error message for when the user is not a sub-admin
    public fun not_sub_admin(): u64 {
        error::permission_denied(ERR_NOT_SUB_ADMIN)
    }

    /// Error message for when an invalid proposal ID is encountered
    public fun invalid_proposal_id(): u64 {
        error::invalid_argument(ERR_INVALID_PROPOSAL_ID)
    }

    /// Error message for when the user is not the owner
    public fun not_owner(): u64 {
        error::unauthenticated(ERR_NOT_OWNER)
    }

    /// Error message for when an operation is already approved
    public fun already_approved(): u64 {
        error::already_exists(ERR_ALREADY_APPROVED)
    }

    /// Error message for when an operation is completed
    public fun completed(): u64 {
        error::already_exists(ERR_ALREADY_APPROVED)
    }

    /// Error message for when an operation is already enabled
    public fun already_enabled(): u64 {
        error::already_exists(ERR_ALREADY_ENABLED)
    }

    /// Error message for when an operation is already disabled
    public fun already_disabled(): u64 {
        error::already_exists(ERR_ALREADY_DISABLED)
    }

    /// Error message for when the user is not a signer
    public fun not_a_signer(): u64 {
        error::permission_denied(ERR_NOT_A_SIGNER)
    }

    /// Error message for when a proposal is cancelled
    public fun proposal_cancelled(): u64 {
        error::permission_denied(ERR_PROPOSAL_CANCELLED)
    }

    /// Error message for when multisig is not enabled
    public fun multisig_not_enabled(): u64 {
        error::permission_denied(ERR_MULTISIG_NOT_ENABLED)
    }

    /// Error message for when an operation is not approved
    public fun not_approved(): u64 {
        error::invalid_state(ERR_NOT_APPROVED)
    }

    /// Error message for when a proposal is not cancelled
    public fun proposal_not_cancelled(): u64 {
        error::invalid_state(ERR_PROPOSAL_NOT_CANCELLED)
    }

    /// Error message for unauthorized access
    public fun unauthorized(): u64 {
        error::unauthenticated(ERR_UNAUTHORIZED)
    }

    /// Error message for when multisig is enabled
    public fun multisig_enabled(): u64 {
        error::permission_denied(ERR_MULTISIG_ENABLED)
    }

    /// Error message for when a proposal is not found
    public fun proposal_not_found(): u64 {
        error::not_found(ERR_PROPOSAL_NOT_FOUND)
    }

    /// Error message for when an ID already exists
    public fun id_exists(): u64 {
        error::already_exists(ERR_ID_EXIST)
    }

    /// Error message for when a name already exists
    public fun name_exists(): u64 {
        error::already_exists(ERR_NAME_EXIST)
    }

    /// Error message for when a symbol already exists
    public fun symbol_exists(): u64 {
        error::already_exists(ERR_SYMBOL_EXIST)
    }

    /// Error message for when a balance is frozen
    public fun balance_frozen(): u64 {
        error::resource_exhausted(ERR_BALANCE_FROZEN)
    }

    /// Error message for when a user is not whitelisted
    public fun not_whitelisted(): u64 {
        error::permission_denied(ERR_ACCOUNT_NOT_WHITELISTED)
    }

    /// Error message for when a country code already exists
    public fun country_code_exists(): u64 {
        error::already_exists(ERR_COUNTRY_CODE_ALREADY_PRESENT)
    }

    /// Error message for when a country code does not exist
    public fun country_code_not_exists(): u64 {
        error::not_found(ERR_COUNTRY_CODE_NOT_PRESENT)
    }

    /// Error message for when the token limit is exceeded
    public fun token_limit_exceeded(): u64 {
        error::resource_exhausted(ERR_TOKEN_LIMIT_EXCEEDED)
    }

    /// Error message for when a test case fails
    public fun test_case_failed(): u64 {
        error::resource_exhausted(ERR_TEST_CASE_FAILED)
    }

    /// Error message for when there are no issuer rights
    public fun no_issue_rights(): u64 {
        error::resource_exhausted(ERR_NO_ISSUER_RIGHTS)
    }

    /// Error message for when there are no transfer agent rights
    public fun no_transfer_agent_rights(): u64 {
        error::resource_exhausted(ERR_NO_TRANASFER_AGENT_RIGHTS)
    }

    /// Error message for when an address is not found
    public fun addr_not_found(): u64 {
        error::not_found(ERR_ADDRESS_NOT_FOUND)
    }

    /// Error message for when there is an underflow
    public fun underflow(): u64 {
        error::resource_exhausted(ERR_UNDERFLOW)
    }

    /// Error message for when there is insufficient balance
    public fun insufficient_balance(): u64 {
        error::not_found(ERR_INSUFFICIENT_BALANCE)
    }

    /// Error message for when a request is invalid
    public fun invalid_request(): u64 {
        error::invalid_argument(ERR_INVALID_REQUEST)
    }

    /// Error message for when the amount must be greater than zero
    public fun amount_must_be_greater_than_zero(): u64 {
        error::invalid_argument(ERR_AMOUNT_MUST_BE_GREATER_THAN_ZERO)
    }

    /// Error message for when the user is not an executer
    public fun not_an_executer(): u64 {
        error::unauthenticated(ERR_NOT_AN_EXECUTER)
    }

    /// Error message for when the user is not a validator
    public fun not_an_validator(): u64 {
        error::unauthenticated(ERR_NOT_AN_VALIDATOR)
    }

    /// Error message for when the threshold is not met
    public fun threshold_not_met(): u64 {
        error::unauthenticated(ERR_THRESHOLD_NOT_MET)
    }

    /// Error message for when the user is not an agent
    public fun not_an_agent(): u64 {
        error::permission_denied(ERR_NOT_AN_AGENT)
    }

    /// Error message for when the token is on hold
    public fun token_held(): u64 {
        error::permission_denied(ERR_TOKEN_ON_HOLD)
    }
}

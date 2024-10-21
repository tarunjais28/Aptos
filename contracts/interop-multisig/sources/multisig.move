module interop_multisig::multisig {
    use std::string::{Self, String};
    use std::signer;
    use interop_multisig::resource::{create_with_admin, get_threshold};
    use interop_multisig::events::{emit_execute_transaction_event, emit_cast_vote_event};
    use interop_multisig::maintainers::is_validator;
    use utils::error;
    use std::vector;
    use aptos_std::simple_map::SimpleMap;
    use aptos_std::simple_map;
    use utils::status;
    use utils::status::{get_ready, get_approved};
    use interop_core::core::execute_instruction;

    //:!:>resources
    struct Votes has key, store {
        votes: SimpleMap<vector<u8>, Vote>
    }

    struct Vote has store, copy, drop {
        yes: u8,
        no: u8,
        voters: vector<address>,
        status: u8,
    }
    struct Payload has drop, store {
        action: u256,
        investor: address,
        amount: u256,
        token: address,
        sender: address,
        order_id: u256,
    }
    //:!:>resources

    //:!:>helper functions
    /// Function to create a new vote
    fun vote(can_transact: bool, voters: vector<address>): Vote {

        // Determine the initial vote counts based on whether transaction is allowed or not
        let (yes, no) = if (can_transact) { (1, 0) } else { (0, 1) };

        // Create and return a new Vote object with initial parameters
        Vote {
            yes, // Number of votes supporting the transaction
            no, // Number of votes against the transaction
            voters, // Vector of addresses eligible to vote
            status: status::get_pending(), // Initial status of the vote set to pending
        }
    }

    //:!:>helper functions

    /// Function for initialization
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @threshold - Threshold of the multisig contract, vote will be in favour only when this threshold is met
    ///
    /// Fails when:-
    ///     - signer is not the deployer of the contract
    public entry fun init(admin: &signer, threshold: u8) {
        let acc_addr = signer::address_of(admin);
        assert!(acc_addr == @interop_multisig, error::unauthorised_caller());

        // Initializing Votes
        move_to(admin,
            Votes {
                votes: simple_map::create(),
            }
        );

        create_with_admin(admin, threshold);
    }

    /// Function for a validator to cast a vote on a transaction
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @tx_hash - Hash of the transaction being voted on
    ///     @can_transact - Whether the transaction is allowed or not
    ///
    /// Fails when:-
    ///     - sender is not the one of the validators
    ///     - vote is already made by same voter
    ///
    /// Emits cast vote event
    public entry fun cast_vote(
        sender: &signer,
        tx_hash: String,
        can_transact: bool,
    ) acquires Votes {

        // Get the address of the sender
        let sender_addr = signer::address_of(sender);

        // Ensure the sender has validator rights
        is_validator(sender_addr);

        // Create a new vote object representing the sender's vote
        let vote = vote(can_transact, vector[sender_addr]);

        // Convert transaction hash to bytes for use as map key
        let key = string::bytes(&tx_hash);

        // Get the voting threshold
        let threshold = get_threshold();

        // Borrow global mutable reference to Votes
        let votes = &mut borrow_global_mut<Votes>(@interop_multisig).votes;

        // Check if a vote for this transaction already exists
        if (simple_map::contains_key(votes, key)) {
            // If a vote already exists, update it
            let stored_vote = simple_map::borrow_mut(votes, key);
            // Ensure the sender has not already voted on this transaction
            assert!(!vector::contains(&stored_vote.voters, &sender_addr), error::unauthorized());
            // Update yes and no counts with sender's vote
            stored_vote.yes = stored_vote.yes + vote.yes;
            stored_vote.no = stored_vote.no + vote.no;
            // Add sender to list of voters
            vector::append(&mut stored_vote.voters, vote.voters);
            // Check if the vote threshold is reached
            if (stored_vote.yes >= threshold) {
                stored_vote.status = get_ready(); // Set status to ready if threshold reached
            }
        } else {
            // If no vote exists for this transaction, add a new one
            simple_map::add(votes, *key, vote);
        };

        // Emit cast vote event
        emit_cast_vote_event(tx_hash, can_transact);
    }


    /// Function for execute instruction
    ///
    /// Arguements:-
    ///     @sender - Sender / Caller of the transaction
    ///     @source_chain - The source chain of the transaction
    ///     @source_address - The source address of the transaction
    ///     @tx_hash - Hash of the transaction to execute
    ///     @payload - Payload of the transaction
    ///
    /// Fails when:-
    ///     - Votes instance is empty
    ///     - threshold is not met
    ///     - any error occur during inter contract call
    ///
    /// Emits mint event
    public entry fun execute_transaction(
        sender: &signer,
        source_chain: String,
        source_address: String,
        tx_hash: String,
        payload: vector<u8>,
    ) acquires Votes {

        // Convert transaction hash to bytes for use as map key
        let key = string::bytes(&tx_hash);

        // Get the voting threshold
        let threshold = get_threshold();

        // Borrow global mutable reference to Votes
        let votes = borrow_global_mut<Votes>(@interop_multisig).votes;

        // Borrow mutable reference to stored vote for the transaction
        let stored_vote = simple_map::borrow_mut(&mut votes, key);

        // Ensure enough votes have been cast for the transaction
        assert!(stored_vote.yes >= threshold, error::threshold_not_met());

        // Set the status of the vote to approved
        stored_vote.status = get_approved();

        // Execute the transaction
        execute_instruction(
            sender,
            source_chain,
            source_address,
            payload,
        );

        // Emit execute transaction event
        emit_execute_transaction_event(source_chain, source_address, tx_hash, payload);
    }

    //:!:>view functions
    #[view]
    /// Function to retrieve the vote for a given transaction hash
    ///
    /// Fails when:-
    ///     - missing Maintainers struct initialization
    ///
    /// Returns vote struct
    public fun get_vote(tx_hash: String): Vote acquires Votes { // Acquires Votes resource for read access

        // Convert transaction hash to bytes for use as map key
        let key = string::bytes(&tx_hash);

        // Borrow global reference to Votes
        let votes = borrow_global<Votes>(@interop_multisig).votes;

        // Borrow the stored vote for the specified transaction hash
        *simple_map::borrow(&mut votes, key)
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}

module token_contract::asset_coin {
    use std::string::{Self, String};
    use std::signer;
    use std::error;
    use aptos_framework::coin::{Self, mint, deposit, transfer, is_account_registered, register, burn_from, freeze_coin_store,
        unfreeze_coin_store};
    use token_contract::resource::{create_with_admin, is_multisig_enabled, set_multisig_info, try_add_signers,
        try_remove_signers, try_enable_disable_multisig, get_multisig_info};
    use std::vector;
    use token_contract::maintainers::{is_sub_admin, has_sub_admin_rights};
    use aptos_std::type_info;
    use token_contract::roles::{assign_issuer_roles, assign_tokenization_agent_roles, assign_transfer_agent_roles,
        has_issuer_rights, has_tokenization_agent_rights, has_transfer_agent_rights};
    use token_contract::events::{emit_token_creation_event, emit_account_reister_event, emit_mint_event, emit_burn_event,
        emit_multisig_event, emit_mintburn_proposal_event, emit_update_countrycode_event, emit_update_token_limt_event,
        emit_transfer_event, emit_freeze_event, emit_unfreeze_event, emit_partial_freeze_event,
        emit_partial_unfreeze_event};
    use std::option::{Self, Option};
    use token_contract::agents::{has_mint_rights, has_burn_rights, has_freeze_rights, has_unfreeze_rights};
    use token_contract::whitelist::get_country_code_by_addres;
    use aptos_std::simple_map::{Self, SimpleMap};
    use utils::i128::{Self, I128};

    struct AssetCoin {}

    //:!:>constants
    const ERR_ACCOUNT_ALREADY_REGISTERED: u64 = 0;
    const ERR_INVALID_PROPOSAL_ID: u64 = 1;
    const ERR_NOT_OWNER: u64 = 2;
    const ERR_ALREADY_APPROVED: u64 = 3;
    const ERR_COMPLETED: u64 = 4;
    const ERR_ALREADY_ENABLED: u64 = 5;
    const ERR_ALREADY_DISABLED: u64 = 6;
    const ERR_NOT_A_SIGNER: u64 = 7;
    const ERR_PROPOSAL_CANCELLED: u64 = 8;
    const ERR_MULTISIG_NOT_ENABLED: u64 = 9;
    const ERR_NOT_APPROVED: u64 = 10;
    const ERR_PROPOSAL_NOT_CANCELLED: u64 = 11;
    const ERR_COIN_EXIST: u64 = 12;
    const ERR_UNAUTHORIZED: u64 = 13;
    const ERR_ACCOUNT_NOT_WHITELISTED: u64 = 14;
    const ERR_ARGUMENTS_MISMATCHED: u64 = 15;
    const ERR_COUNTRY_CODE_NOT_PRESENT: u64 = 16;
    const ERR_COUNTRY_CODE_ALREADY_PRESENT: u64 = 17;
    const ERR_MULTISIG_ENABLED: u64 = 18;
    const ERR_TOKEN_LIMIT_EXCEEDED: u64 = 19;
    const ERR_BALANCE_FROZEN: u64 = 20;
    //:!:>constants

    //:!:>resources

    struct MintProposalList has key {
        proposals: vector<MintProposal>,
        proposal_counter:u64,
    }

    struct MintProposal has store, drop, copy {
        id: u64,
        creator: address,
        to_address: address,
        amount: u64,
        signers: vector<address>,
        completed: bool,
        cancelled: bool,
    }

    struct BurnProposalList has key {
        proposals: vector<BurnProposal>,
        proposal_counter:u64,
    }

    struct BurnProposal has store, drop, copy {
        id: u64,
        creator: address,
        amount: u64,
        signers: vector<address>,
        completed: bool,
        cancelled: bool,
    }

    struct CoinCapabilities<phantom AssetCoin> has key {
        mint_cap: coin::MintCapability<AssetCoin>,
        burn_cap: coin::BurnCapability<AssetCoin>,
        freeze_cap: coin::FreezeCapability<AssetCoin>,
    }

    struct TokenConfig has key, copy, drop {
        token_limit: u64,
        country_codes: vector<u8>
    }

    struct PartialFreeze has key {
        freeze: SimpleMap<address, u64>,
        amount: u128,
    }
    //:!:>resources

    //:!:>helper functions
    /// Ensuring balance not frozen
    public fun ensure_balance_not_frozen(
        creator_addr: address,
        addr: address
    ) acquires PartialFreeze {
        let freeze = borrow_global<PartialFreeze>(creator_addr).freeze;

        let frozen_balance = if (simple_map::contains_key(&freeze, &addr)) {
            *simple_map::borrow(&freeze, &addr)
        } else {
            0
        };

        let balance = get_balance(addr);

        assert!(
            frozen_balance <= balance,
            error::permission_denied(ERR_BALANCE_FROZEN)
        )
    }

    /// Ensuring account is whitelisted
    public fun ensure_account_whitelisted(
        res_addr: address,
        creator: address,
        addr: address
    ) acquires TokenConfig {
        let country_code = get_country_code_by_addres(res_addr, addr);
        let token_config = get_token_config(creator);

        assert!(
            vector::contains(&token_config.country_codes, &country_code),
            error::unauthenticated(ERR_ACCOUNT_NOT_WHITELISTED)
        )
    }

    /// Ensuring token limit maintained
    public fun ensure_token_limit(
        creator_addres: address,
        addr: address,
        amount: u64,
    ) acquires TokenConfig {
        let bal = get_balance(addr);
        let token_config = get_token_config(creator_addres);

        assert!(
            bal + amount <= token_config.token_limit,
            error::unauthenticated(ERR_TOKEN_LIMIT_EXCEEDED)
        );
    }

    /// Helper function to check if proposal is created
    public fun check_proposal_created(addr: address): vector<MintProposal> acquires MintProposalList {
        borrow_global<MintProposalList>(addr).proposals
    }

    /// Helper function to check if proposal is cancelled
    public fun check_proposal_cancelled(addr: address, id: u64)  acquires MintProposalList {
        let proposal_list=borrow_global_mut<MintProposalList>(addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,id);
        assert!(proposal.cancelled==true,ERR_PROPOSAL_NOT_CANCELLED);
    }

    /// Helper function to check if proposal is approved
    public fun check_proposal_approved(addr:address , id: u64)  acquires MintProposalList {
        let proposal_list=borrow_global_mut<MintProposalList>(addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,id);
        assert!(vector::length(&proposal.signers)>0,ERR_NOT_APPROVED);
    }
    //:!:>helper functions

    /// Function for initialization
    public entry fun init(account: &signer) {
        create_with_admin(account);
    }

    /// Function for token config
    fun create_token_config(creator: &signer, token_limit: u64, country_codes: vector<u8>) {
        let creator_address = signer::address_of(creator);
        assert!(!exists<TokenConfig>(creator_address), error::already_exists(ERR_ACCOUNT_ALREADY_REGISTERED));

        move_to(creator, TokenConfig {
            token_limit,
            country_codes,
        });
    }

    /// Function for token creation
    public entry fun create_token(
        creator: &signer,
        res_address: address,
        id: String,
        name: String,
        symbol: String,
        token_limit: u64,
        country_codes: vector<u8>,
        issuer: address,
        tokenization_agent: address,
        transfer_agent: address,
    ) {
        let creator_address = signer::address_of(creator);

        // Fixed decimals upto 4 places
        let decimals = 4;

        // Check authetication
        is_sub_admin(res_address, creator_address);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AssetCoin>(
            creator,
            name,
            symbol,
            decimals,
            true,
        );

        // Assigning roles
        assign_issuer_roles(res_address, option::some(issuer));
        assign_tokenization_agent_roles(res_address, option::some(tokenization_agent));
        assign_transfer_agent_roles(res_address, option::some(transfer_agent));

        // Create token config
        create_token_config(creator, token_limit, country_codes);

        assert!(!exists<CoinCapabilities<AssetCoin>>(creator_address), error::already_exists(ERR_COIN_EXIST));
        move_to<CoinCapabilities<AssetCoin>>(
            creator,
            CoinCapabilities<AssetCoin> {
                mint_cap,
                burn_cap,
                freeze_cap
            }
        );

        // Initializing Partial Freeze with creator's address
        move_to(creator, PartialFreeze {
           freeze: simple_map::create(),
            amount: 0,
        });

        // Emitting token creation event
        emit_token_creation_event(
            res_address,
            id,
            name,
            symbol,
            decimals,
            creator_address,
            issuer,
            tokenization_agent,
            transfer_agent,
        );
    }

    /// Function for register account
    /// All accounts are required to be register before any other operation
    public entry fun register_account(account: &signer, res_addr: address) {
        let account_address = signer::address_of(account);
        assert!(
            !is_account_registered<AssetCoin>(account_address),
            error::already_exists(ERR_ACCOUNT_ALREADY_REGISTERED)
        );

        register<AssetCoin>(account);

        // Emit account register event
        emit_account_reister_event(res_addr, account_address);
    }

    /// Function for minting of token
    public entry fun mint_token(
        account: &signer,
        res_addr: address,
        creator: address,
        users: vector<address>,
        amounts: vector<u64>,
    ) acquires CoinCapabilities, TokenConfig {
        let account_address = signer::address_of(account);

        assert!(!is_multisig_enabled(res_addr), error::permission_denied(ERR_MULTISIG_ENABLED));

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&amounts),
            error::invalid_argument(ERR_ARGUMENTS_MISMATCHED)
        );

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, account_address)
            && !has_tokenization_agent_rights(res_addr, account_address)
            && !has_mint_rights(res_addr, account_address)
            && !has_sub_admin_rights(res_addr, account_address)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let mint_cap = &borrow_global<CoinCapabilities<AssetCoin>>(creator).mint_cap;

        vector::for_each(users, |user| {
            let amount = vector::pop_back(&mut amounts);
            let coin = mint<AssetCoin>(amount, mint_cap);

            // Ensuring token limit
            ensure_token_limit(creator, user, amount);

            deposit<AssetCoin>(user, coin);

            // Emit mint event
            emit_mint_event(res_addr, user, amount);
        });
    }

    /// Function for burn token
    public entry fun burn_token(
        account: &signer,
        res_addr: address,
        creator: address,
        users: vector<address>,
        amounts: vector<u64>,
    ) acquires CoinCapabilities, PartialFreeze {
        let account_address = signer::address_of(account);

        assert!(!is_multisig_enabled(res_addr), error::permission_denied(ERR_MULTISIG_ENABLED));

        // Ensuring arguements are correct
        assert!(
            vector::length(&users) == vector::length(&amounts),
            error::invalid_argument(ERR_ARGUMENTS_MISMATCHED)
        );

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, account_address)
            && !has_tokenization_agent_rights(res_addr, account_address)
            && !has_burn_rights(res_addr, account_address)
            && !has_sub_admin_rights(res_addr, account_address)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let burn_cap = &borrow_global<CoinCapabilities<AssetCoin>>(creator).burn_cap;

        vector::for_each(users, |user| {
            let amount = vector::pop_back(&mut amounts);

            burn_from<AssetCoin>(user, amount, burn_cap);

            // Ensure balance not frozen
            ensure_balance_not_frozen(creator, user);

            // Emit burn event
            emit_burn_event(res_addr, user, amount);
        });
    }

    /// Function to transfer token to someone
    public entry fun transfer_token(
        from: &signer,
        res_addr: address,
        creator: address,
        to: address,
        amount: u64
    ) acquires TokenConfig, PartialFreeze {
        let from_address = signer::address_of(from);

        // Ensuring token limit
        ensure_token_limit(creator, to, amount);

        // Ensuring receiver is whitelisted
        ensure_account_whitelisted(res_addr, creator, to);

        // Ensure balance not frozen
        ensure_balance_not_frozen(creator, from_address);

        // Transfer
        transfer<AssetCoin>(from, to, amount);

        // Emitting event
        emit_transfer_event(res_addr, from_address, to, amount)
    }

    /// Function to freeze accounts
    public entry fun freeze_accounts(
        sender: &signer,
        res_addr: address,
        creator: address,
        addrs: vector<address>,
    ) acquires CoinCapabilities {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, sender_addr)
            && !has_transfer_agent_rights(res_addr, sender_addr)
            && !has_freeze_rights(res_addr, sender_addr)
            && !has_sub_admin_rights(res_addr, sender_addr)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let freeze_cap = &borrow_global<CoinCapabilities<AssetCoin>>(creator).freeze_cap;

        vector::for_each(addrs, |addr| {
            freeze_coin_store(addr, freeze_cap);

            // Emitting freeze event
            emit_freeze_event(res_addr, addr);
        });
    }

    /// Function to unfreeze accounts
    public entry fun unfreeze_accounts(
        sender: &signer,
        res_addr: address,
        creator: address,
        addrs: vector<address>,
    ) acquires CoinCapabilities {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, sender_addr)
            && !has_transfer_agent_rights(res_addr, sender_addr)
            && !has_unfreeze_rights(res_addr, sender_addr)
            && !has_sub_admin_rights(res_addr, sender_addr)
            && !has_sub_admin_rights(res_addr, sender_addr)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let freeze_cap = &borrow_global<CoinCapabilities<AssetCoin>>(creator).freeze_cap;

        vector::for_each(addrs, |addr| {
            unfreeze_coin_store(addr, freeze_cap);

            // Emitting freeze event
            emit_unfreeze_event(res_addr, addr);
        });
    }

    /// Function for partial freeze balance
    public entry fun partial_freeze(
        sender: &signer,
        res_addr: address,
        creator: address,
        addrs: vector<address>,
        balances: vector<u64>,
    ) acquires PartialFreeze {
        let sender_addr = signer::address_of(sender);

        // Ensuring arguements are correct
        assert!(
            vector::length(&addrs) == vector::length(&balances),
            error::invalid_argument(ERR_ARGUMENTS_MISMATCHED)
        );

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, sender_addr)
            && !has_transfer_agent_rights(res_addr, sender_addr)
            && !has_freeze_rights(res_addr, sender_addr)
            && !has_sub_admin_rights(res_addr, sender_addr)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let partial_freeze = borrow_global_mut<PartialFreeze>(creator);
        let freeze = &mut partial_freeze.freeze;
        vector::for_each(addrs, |addr| {
            let bal = vector::pop_back(&mut balances);
            simple_map::add(freeze, addr, bal);
            partial_freeze.amount = partial_freeze.amount + (bal as u128);

            // Emitting freeze event
            emit_partial_freeze_event(res_addr, addr, bal);
        });
    }

    /// Function for partial unfreeze balance
    public entry fun partial_unfreeze(
        sender: &signer,
        res_addr: address,
        creator: address,
        addrs: vector<address>
    ) acquires PartialFreeze {
        let sender_addr = signer::address_of(sender);

        // Ensure authroized caller
        if (!has_issuer_rights(res_addr, sender_addr)
            && !has_transfer_agent_rights(res_addr, sender_addr)
            && !has_unfreeze_rights(res_addr, sender_addr)
            && !has_sub_admin_rights(res_addr, sender_addr)) {
            abort error::permission_denied(ERR_UNAUTHORIZED)
        };

        let partial_freeze = borrow_global_mut<PartialFreeze>(creator);
        let freeze = &mut partial_freeze.freeze;

        vector::for_each(addrs, |addr| {
            let (user, amount) = simple_map::remove(freeze, &addr);
            partial_freeze.amount = partial_freeze.amount - (amount as u128);

            // Emitting freeze event
            emit_partial_unfreeze_event(res_addr, user, amount);
        })
    }

    // Function to enable multisig
    public  fun enable_multisig(account: &signer, res_addr: address, signers: vector<address>, approvs: u64)  {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr,addr);
        assert!(is_multisig_enabled(res_addr)==false,ERR_ALREADY_ENABLED);
        try_enable_disable_multisig(res_addr,true);
        set_multisig_info(res_addr,signers,approvs);

        emit_multisig_event(res_addr,string::utf8(b"enable_multisig"),true,signers,approvs);
    }

    // Function to disable multisig
    public  fun disable_multisig(account: &signer, res_addr: address)  {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr,addr);
        assert!(is_multisig_enabled(res_addr)==true,ERR_ALREADY_DISABLED);
        try_enable_disable_multisig(res_addr,false);

        emit_multisig_event(res_addr,string::utf8(b"disable_multisig"),true,vector::empty(),0);
    }

    // Function to add more signers
    public  fun add_signers(account: &signer, res_addr: address, addrs: vector<address>) {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr,addr);
        try_add_signers(res_addr,addrs);
    }

    // Function to remove signers
    public  fun remove_signers(account:&signer,res_addr:address,addrs:vector<address>) {
        let addr = signer::address_of(account);

        // Ensuring authorised sender
        is_sub_admin(res_addr,addr);
        try_remove_signers(res_addr,addrs);

    }

    // Function to create mint request
    public  fun create_mint_request(account: &signer, res_addr: address, to_address: address, amount: u64) acquires  MintProposalList {
        assert!(is_multisig_enabled(res_addr)==true,ERR_MULTISIG_NOT_ENABLED);
        let signer_address=signer::address_of(account);
        if(!exists<MintProposalList>(signer::address_of(account))){
            let proposal_list = MintProposalList {
                proposals: vector::empty(),
                proposal_counter: 0,
            };
            move_to(account, proposal_list);
        };
        let proposal_list=borrow_global_mut<MintProposalList>(signer_address);
        let counter = proposal_list.proposal_counter + 1;
        let new_proposal = MintProposal {
            id: proposal_list.proposal_counter,
            creator: signer::address_of(account),
            to_address,
            amount,
            signers: vector::empty(),
            completed: false,
            cancelled: false,
        };
        vector::push_back(&mut proposal_list.proposals, new_proposal);
        proposal_list.proposal_counter = counter;

        emit_mintburn_proposal_event(res_addr,string::utf8(b"create_mint_proposal"),signer_address,new_proposal.id,amount);
    }

    // Function to create burn request
    public  fun create_burn_request(account: &signer, res_addr: address, amount: u64) acquires  BurnProposalList {
        assert!(is_multisig_enabled(res_addr)==true,ERR_MULTISIG_NOT_ENABLED);
        let signer_address=signer::address_of(account);
        if(!exists<BurnProposalList>(signer::address_of(account))){
            let proposal_list = BurnProposalList {
                proposals: vector::empty(),
                proposal_counter: 0,
            };
            move_to(account, proposal_list);
        };
        let proposal_list=borrow_global_mut<BurnProposalList>(signer_address);
        let counter = proposal_list.proposal_counter + 1;
        let new_proposal = BurnProposal {
            id: proposal_list.proposal_counter,
            creator: signer::address_of(account),
            amount,
            signers: vector::empty(),
            completed: false,
            cancelled: false,
        };
        vector::push_back(&mut proposal_list.proposals,new_proposal);
        proposal_list.proposal_counter = counter;

        emit_mintburn_proposal_event(res_addr,string::utf8(b"create_burn_proposal"),signer_address,new_proposal.id,amount);

    }

    // Function to cancel mint request
    public  fun cancel_mint_request(account: &signer, res_addr:address, proposal_id: u64) acquires MintProposalList{
        let proposal_list=borrow_global_mut<MintProposalList>(signer::address_of(account));
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.creator==signer::address_of(account),ERR_NOT_OWNER);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(proposal.cancelled==false,ERR_PROPOSAL_CANCELLED);
        proposal.cancelled=true;

        emit_mintburn_proposal_event(res_addr,string::utf8(b"cancel_mint_proposal"),signer::address_of(account),proposal_id,proposal.amount);


    }

    // Function to cancel burn request
    public  fun cancel_burn_request(account: &signer, res_addr:address, proposal_id: u64) acquires BurnProposalList{
        let proposal_list=borrow_global_mut<BurnProposalList>(signer::address_of(account));
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.creator==signer::address_of(account),ERR_NOT_OWNER);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(proposal.cancelled==false,ERR_PROPOSAL_CANCELLED);
        proposal.cancelled=true;

        emit_mintburn_proposal_event(res_addr,string::utf8(b"cancel_burn_proposal"),signer::address_of(account),proposal_id,proposal.amount);
    }

    // Function to approve mint request
    public  fun approve_mint_request(account: &signer, res_addr: address, proposer_addr: address, proposal_id: u64) acquires MintProposalList, CoinCapabilities {
        let admin=type_info::account_address(&type_info::type_of<AssetCoin>());
        let (signers,approvs) = get_multisig_info(res_addr);
        let proposal_list=borrow_global_mut<MintProposalList>(proposer_addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.id==proposal_id,ERR_INVALID_PROPOSAL_ID);
        assert!(vector::contains(&signers,&signer::address_of(account)),ERR_NOT_A_SIGNER);
        assert!(proposal.cancelled==false,ERR_PROPOSAL_CANCELLED);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(vector::contains(&proposal.signers,&signer::address_of(account))==false,ERR_ALREADY_APPROVED);
        vector::push_back(&mut proposal.signers,signer::address_of(account));
        if(vector::length(&proposal.signers)>approvs){
            let mint_cap = &borrow_global<CoinCapabilities<AssetCoin>>(admin).mint_cap;
            let coin = mint<AssetCoin>(proposal.amount, mint_cap);
            deposit<AssetCoin>(proposal.to_address, coin);
            proposal.completed=true;
        };

        emit_mintburn_proposal_event(res_addr,string::utf8(b"approve_mint_proposal"),signer::address_of(account),proposal_id,proposal.amount);

    }

    // Function to approve burn request
    public  fun approve_burn_request(account: &signer, res_addr: address, proposer_addr: address, proposal_id: u64) acquires BurnProposalList, CoinCapabilities {
        let (signers,approvs) = get_multisig_info(res_addr);
        let proposal_list=borrow_global_mut<BurnProposalList>(proposer_addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.id==proposal_id,ERR_INVALID_PROPOSAL_ID);
        assert!(vector::contains(&signers,&signer::address_of(account)),ERR_NOT_A_SIGNER);
        assert!(proposal.cancelled==false,ERR_PROPOSAL_CANCELLED);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(vector::contains(&proposal.signers,&signer::address_of(account))==false,ERR_ALREADY_APPROVED);
        vector::push_back(&mut proposal.signers,signer::address_of(account));
        if(vector::length(&proposal.signers)>approvs){
            let burn_cap = &borrow_global<CoinCapabilities<AssetCoin>>(@token_contract).burn_cap;
            burn_from<AssetCoin>(proposal.creator, proposal.amount, burn_cap);
            proposal.completed=true;
        };

        emit_mintburn_proposal_event(res_addr,string::utf8(b"approve_burn_proposal"),signer::address_of(account),proposal_id,proposal.amount);

    }

    // Function to cancel mint approval
    public  fun cancel_mint_approval(account: &signer, res_addr: address, proposer_addr: address, proposal_id: u64) acquires MintProposalList{
        let (signers,_) = get_multisig_info(res_addr);
        let proposal_list=borrow_global_mut<MintProposalList>(proposer_addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.id==proposal_id,ERR_INVALID_PROPOSAL_ID);
        assert!(vector::contains(&signers,&signer::address_of(account)),ERR_NOT_A_SIGNER);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(vector::contains(&proposal.signers,&signer::address_of(account))==true,ERR_NOT_APPROVED);
        let (_,index)=vector::index_of(&proposal.signers,&signer::address_of(account));
        vector::remove(&mut proposal.signers,index);

        emit_mintburn_proposal_event(res_addr,string::utf8(b"cancel_mint_approval"),signer::address_of(account),proposal_id,proposal.amount);

    }

    // Function to cancel burn approval
    public  fun cancel_burn_approval(account: &signer, res_addr: address, proposer_addr: address, proposal_id: u64) acquires BurnProposalList{
        let (signers,_) = get_multisig_info(res_addr);
        let proposal_list=borrow_global_mut<BurnProposalList>(proposer_addr);
        let proposal=vector::borrow_mut(&mut proposal_list.proposals,proposal_id);
        assert!(proposal.id==proposal_id,ERR_INVALID_PROPOSAL_ID);
        assert!(vector::contains(&signers,&signer::address_of(account)),ERR_NOT_A_SIGNER);
        assert!(proposal.completed==false,ERR_COMPLETED);
        assert!(vector::contains(&proposal.signers,&signer::address_of(account))==true,ERR_NOT_APPROVED);
        let (_,index)=vector::index_of(&proposal.signers,&signer::address_of(account));
        vector::remove(&mut proposal.signers,index);

        emit_mintburn_proposal_event(res_addr,string::utf8(b"cancel_burn_approval"),signer::address_of(account),proposal_id,proposal.amount);

    }

    // Function to add country codes
    public  fun add_country_code(account: &signer, creator_addr: address, res_addr: address, country_codes: vector<u8>) acquires TokenConfig{
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(res_addr, address);
        let token_config=borrow_global_mut<TokenConfig>(creator_addr);
        vector::for_each(country_codes,|element|{
            let (res,_)=vector::index_of(&token_config.country_codes,&element);
            assert!(!res,ERR_COUNTRY_CODE_ALREADY_PRESENT);
            vector::push_back(&mut token_config.country_codes,element);
        });

        emit_update_countrycode_event(res_addr,string::utf8(b"add_country_codes"),country_codes);
    }

    // Function to remove country codes
    public  fun remove_country_code(account: &signer, creator_addr: address, res_addr: address, country_codes: vector<u8>) acquires TokenConfig{
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(res_addr, address);
        let token_config=borrow_global_mut<TokenConfig>(creator_addr);
        vector::for_each(country_codes,|element|{
            let (res,index)=vector::index_of(&token_config.country_codes,&element);
            assert!(res,ERR_COUNTRY_CODE_NOT_PRESENT);
            vector::remove(&mut token_config.country_codes,index);
        });

        emit_update_countrycode_event(res_addr,string::utf8(b"remove_country_codes"),country_codes);

    }

    // Function to update token limit
    public  fun update_token_limit(account: &signer, creator_addr: address, res_addr: address, token_limit: u64) acquires TokenConfig{
        let address = signer::address_of(account);

        // Check authentication
        is_sub_admin(res_addr, address);
        borrow_global_mut<TokenConfig>(creator_addr).token_limit=token_limit;

        emit_update_token_limt_event(res_addr,string::utf8(b"update_tokenLimitt"),token_limit);
    }

    //:!:>view functions
    #[view]
    /// Function to get all mint proposal for a address
    public fun get_mint_proposals(addr:address): vector<MintProposal> acquires MintProposalList{
        borrow_global<MintProposalList>(addr).proposals
    }

    #[view]
    /// Function to get all burn proposal for a address
    public fun get_burn_proposals(addr:address): vector<BurnProposal> acquires BurnProposalList{
        borrow_global<BurnProposalList>(addr).proposals
    }

    #[view]
    /// Function to get balance of an account
    public fun get_balance(addr: address): u64 {
        coin::balance<AssetCoin>(addr)
    }

    #[view]
    /// Function to get token config
    public fun get_token_config(creator_addr: address): TokenConfig acquires TokenConfig {
        *borrow_global<TokenConfig>(creator_addr)
    }

    #[view]
    /// Function to get token config
    public fun get_country_codes(creator_addr: address): vector<u8> acquires TokenConfig {
        borrow_global<TokenConfig>(creator_addr).country_codes
    }

    #[view]
    /// Function to get token limit
    public fun get_token_limit(creator_addr: address): u64 acquires TokenConfig {
        borrow_global<TokenConfig>(creator_addr).token_limit
    }

    #[view]
    /// Function to get frozen tokens
    public fun get_frozen_tokens(creator_addr: address): u128 acquires PartialFreeze {
        borrow_global<PartialFreeze>(creator_addr).amount
    }

    #[view]
    /// Function to get token supply
    public fun get_supply(): Option<u128> {
        coin::supply<AssetCoin>()
    }

    #[view]
    /// Function to get circulating supply
    public fun get_circulating_supply(creator_addr: address): I128 acquires PartialFreeze{
        let supply_opt = get_supply();
        let supply = *option::borrow(&supply_opt);
        let frozen = get_frozen_tokens(creator_addr);

        if (supply > frozen) {
            i128::new(supply - frozen, false)
        } else {
            i128::new(frozen - supply, true)
        }
    }
    //:!:>view functions

    //:!:>test cases for module
    //:!:>test cases for module
}

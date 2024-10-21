module token_contract::resource {
    use std::signer;
    use aptos_framework::account::{SignerCapability, create_resource_account, get_sequence_number};
    use std::bcs::to_bytes;
    use std::option;
    use token_contract::events::{initialize_event_store, emit_admin_update_event, emit_init_event};
    use token_contract::roles::init_all_roles;
    use token_contract::maintainers::init_maintainers;
    use token_contract::whitelist::init_whitelisting;
    use std::vector;
    use token_contract::agents::init_agent_roles;

    //:!:>constants
    const E_NOT_A_SIGNER: u64 = 0;

    //:!:>constants

    //:!:>resources
    struct ResourceAccount has key, drop, store {
        resource_address: address,
        resource_capability: SignerCapability,
    }

    struct MultsigEnabled has key {
        value: bool
    }

    struct MultisigInfo has key, drop {
        signers: vector<address>,
        approvs: u64,
    }
    //:!:>resources

    /// Function for maintainer creation with admin account
    public fun create_with_admin(account: &signer) {
        let admin = signer::address_of(account);
        let account_nonce = get_sequence_number(admin);
        let (res_signer, res_cap) = create_resource_account(account, to_bytes(&account_nonce));
        let res_addr = signer::address_of(&res_signer);

        // Initializing events
        initialize_event_store(&res_signer);

        // Storing resource account details to admin's address
        move_to(
            account,
            ResourceAccount {
                resource_address: res_addr,
                resource_capability: res_cap
            }
        );

        // Init maintaner and make caller as admin
        init_maintainers(&res_signer, admin);

        // Init multisig enabled and multisig info to default
        move_to(&res_signer,MultsigEnabled{value:false});
        move_to(&res_signer,MultisigInfo{signers:vector::empty(),approvs:0});

        // Initializing roles
        init_all_roles(&res_signer);

        // Initializing Agent roles
        init_agent_roles(&res_signer);

        // Initializing whitelisting
        init_whitelisting(&res_signer);

        // Emitting events
        emit_init_event(res_addr, admin);
        emit_admin_update_event(res_addr, option::none(), option::some(vector[admin]));
    }

    //:!:>view functions
    #[view]
    public fun get_resource_address(addr: address): address acquires ResourceAccount {
        borrow_global<ResourceAccount>(addr).resource_address
    }

    #[view]
    public fun get_signers(addr: address): vector<address> acquires MultisigInfo {
        borrow_global<MultisigInfo>(addr).signers
    }
    //:!:>view functions

    //:!:>helper functions

    /// Helper function to check if multisig is enabled or not
    public fun is_multisig_enabled(res_addr: address): bool acquires MultsigEnabled{
        borrow_global<MultsigEnabled>(res_addr).value
    }

    /// Helper function to enable and disable multisig
    public fun try_enable_disable_multisig(res_addr: address, value: bool) acquires MultsigEnabled{
        borrow_global_mut<MultsigEnabled>(res_addr).value=value;
    }

    /// Helper function to set multisig info like no. approval and no. of signers for multisig
    public fun set_multisig_info(res_addr: address, signers: vector<address>, approvs: u64) acquires MultisigInfo{
        let info=borrow_global_mut<MultisigInfo>(res_addr);
        info.signers=signers;
        info.approvs=approvs;
    }

    /// Helper function to get multisig info like no. approval and no. of signers for multisig
    public fun get_multisig_info(res_addr:address):(vector<address>,u64) acquires MultisigInfo{
        let info=borrow_global_mut<MultisigInfo>(res_addr);
        (info.signers,info.approvs)
    }

    /// Helper function to add signers
    public  fun try_add_signers(res_addr: address, addrs: vector<address>) acquires MultisigInfo{
        let info=borrow_global_mut<MultisigInfo>(res_addr);
        vector::append(&mut info.signers, addrs);
    }

    /// Helper function to remove signers
    public  fun try_remove_signers(res_addr :address, addrs: vector<address>) acquires MultisigInfo{
        let info=borrow_global_mut<MultisigInfo>(res_addr);
        vector::for_each(addrs,|element|{
            let (res,index)=vector::index_of(&info.signers,&element);
            assert!(res==true,E_NOT_A_SIGNER);
            vector::remove(&mut info.signers,index);
        });
    }

    //:!:>helper functions

    //:!:>test cases for module
    //:!:>test cases for module
}
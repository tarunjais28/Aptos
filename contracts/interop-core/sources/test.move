#[test_only]
module interop_core::tests {
    use interop_core::core::{init, send_instruction, send_batch_instructions, execute_instruction};
    use std::string;
    use std::string::utf8;
    use interop_core::maintainers::{get_admins, get_executer};
    use std::signer;
    use aptos_std::debug::print;
    use utils::payload::{get_payload, create_payload};

    #[test(
        account = @interop_core,
        executer = @0x1
    )]
    entry fun test_init(account: &signer, executer: address) {
        aptos_framework::account::create_account_for_test(@interop_core);
        init(account, executer);

        assert!(get_admins() == vector[@interop_core], 0);
        assert!(get_executer() == executer, 0);
    }

    #[test(
        account = @interop_core,
        executer = @0x1,
        token = @0xC29295f67F5d476105f19E8513da0E5027e73e39,
        investor = @0x0B70373D5BA5b0Da8672fF62704bFD117211C2C2,
    )]
    entry fun test_send_instruction(
        account: &signer,
        executer: address,
        token: address,
        investor: address,
    ) {
        aptos_framework::account::create_account_for_test(@interop_core);
        init(account, executer);

        let dest_chain = utf8(b"Holesky");
        let dest_addr = utf8(b"0xe1EE8B61deB84D424C5df1daE73E404A9C2175F7");
        let order_id = 1;
        let amount = 100;
        let action = 1;

        send_instruction(account, dest_chain, dest_addr, order_id, token, investor, amount, action);
    }

    #[test(
        account = @interop_core,
        executer = @0x1,
        token = @0xC29295f67F5d476105f19E8513da0E5027e73e39,
        investor = @0x0B70373D5BA5b0Da8672fF62704bFD117211C2C2,
    )]
    entry fun test_send_batch_instructions(
        account: &signer,
        executer: address,
        token: address,
        investor: address,
    ) {
        aptos_framework::account::create_account_for_test(@interop_core);
        init(account, executer);

        let dest_chains = vector[utf8(b"Holesky")];
        let dest_addrs = vector[utf8(b"0xe1EE8B61deB84D424C5df1daE73E404A9C2175F7")];
        let order_ids = vector[1];
        let tokens = vector[token];
        let investors = vector[investor];
        let amounts = vector[100];
        let actions = vector[1];

        send_batch_instructions(account, dest_chains, dest_addrs, order_ids, tokens, investors, amounts, actions);
    }

    #[test(
        account = @interop_core,
    )]
    entry fun test_execute_instruction(account: &signer) {
        aptos_framework::account::create_account_for_test(@interop_core);
        let executer = signer::address_of(account);
        init(account, executer);

        let source_chain = utf8(b"Holesky");
        let source_addr = utf8(b"0xe1EE8B61deB84D424C5df1daE73E404A9C2175F7");
        let payload = x"01e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa01000000000000000000000000000000000000000000000000000000000000000454657374";

        // execute_instruction(account, source_chain, source_addr, payload);
    }

    #[test(
        account = @interop_core,
        sender = @0xaf6c7bb298e4fb08c3a3f99e506fe33d69768cc5,
        investor = @0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045,
    )]
    entry fun test_create_payload(account: &signer, sender: address, investor: address) {
        let order_id = 5009;
        let amount = 70;
        let action = 3;
        let token = string::utf8(b"Test-1");

        let payload = create_payload(sender, order_id, token, investor, amount, action);
        print(&payload);
    }

    #[test(
        account = @interop_core,
        sender = @0x1D5f14250B767728DB006993834e167c6bA740Fa,
        investor = @0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045,
    )]
    entry fun test_get_payload(account: &signer, sender: address, investor: address) {
        let payload = x"03e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b460454600000000000000000000000000000000000000af6c7bb298e4fb08c3a3f99e506fe33d69768cc5911300000000000000000000000000000000000000000000000000000000000006546573742d31";

        let data = get_payload(payload);

        print(&data);
    }
}

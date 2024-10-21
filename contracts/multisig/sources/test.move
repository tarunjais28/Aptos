#[test_only]
module multisig::tests {
    use std::vector::{Self, is_empty};
    use std::unit_test;
    use std::signer;
    use multisig::multisig::{init, cast_vote, get_vote, execute_transaction};
    use std::string;
    use std::option;
    use std::string::{String, utf8};
    use utils::i128;
    use utils::error;
    use utils::i128::I128;
    use multisig::maintainers::{get_admins, add_validators, get_validators};
    use utils::interop_constants::get_mint;
    use aptos_std::debug::print;

    fun init_test(account: &signer, threshold: u8) {
        init(account, threshold);
    }

    #[test(
        account = @multisig
    )]
    entry fun test_init(account: &signer) {
        aptos_framework::account::create_account_for_test(@multisig);
        init(account, 1);
    }

    #[test(
        account = @multisig,
        validator = @0x1,
    )]
    entry fun test_add_validators(
        account: &signer,
        validator: address
    ) {
        aptos_framework::account::create_account_for_test(@multisig);
        init(account, 1);

        add_validators(account, vector[validator]);
        print(&get_validators());
    }

    #[test(
        account = @multisig,
        validator = @0x1,
    )]
    entry fun test_cast_votes(
        account: &signer,
        validator: &signer
    ) {
        aptos_framework::account::create_account_for_test(@multisig);
        init(account, 1);

        let addr = signer::address_of(validator);
        add_validators(account, vector[addr]);

        let tx_hash = string::utf8(b"1");
        cast_vote(validator, tx_hash, true);

        print(&get_vote(tx_hash));
    }


    #[test(
        account = @multisig,
        validator = @0x1,
        investor = @0xe6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b46045,
        from = @0xC29295f67F5d476105f19E8513da0E5027e73e39,
    )]
    entry fun test_execute_transaction(
        account: &signer,
        validator: &signer,
        investor: address,
        from: address,
    ) {
        aptos_framework::account::create_account_for_test(@multisig);
        init(account, 1);

        let addr = signer::address_of(validator);
        add_validators(account, vector[addr]);

        let tx_hash = string::utf8(b"0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca");
        cast_vote(validator, tx_hash, true);

        let source_chain=  string::utf8(b"Holesky");
        let source_address = string::utf8(b"0xec8fd47f7609c961d9016b72ae65e5d59a8342c54bf40fe59f12b5a4074995ca");
        let payload = x"02e6e21ddb0434468edda0ccffcb01fb501e741691241506df44ab6a13a6b4604564000000000000000000000000000000000000001d5f14250b767728db006993834e167c6ba740fa04000000000000000000000000000000000000000000000000000000000000000454657374";

        execute_transaction(
            account,
            source_chain,
            source_address,
            tx_hash,
            payload,
        );
    }

    // #[test(
    //     account = @multisig,
    //     executer = @0x1,
    //     token = @0xC29295f67F5d476105f19E8513da0E5027e73e39,
    //     investor = @0x0B70373D5BA5b0Da8672fF62704bFD117211C2C2,
    // )]
    // entry fun test_send_instruction(
    //     account: &signer,
    //     executer: address,
    //     token: address,
    //     investor: address,
    // ) {
    //     aptos_framework::account::create_account_for_test(@multisig);
    //     init(account, executer);
    //
    //     let dest_chain = utf8(b"Holesky");
    //     let dest_addr = utf8(b"0xe1EE8B61deB84D424C5df1daE73E404A9C2175F7");
    //     let order_id = 1;
    //     let amount = 100;
    //     let action = 1;
    //
    //     send_instruction(account, dest_chain, dest_addr, order_id, token, investor, amount, action);
    // }
    //
    // #[test(
    //     account = @multisig,
    //     executer = @0x1,
    // )]
    // entry fun test_execute_instruction(account: &signer, executer: address) {
    //     aptos_framework::account::create_account_for_test(@multisig);
    //     init(account, executer);
    //
    //     let source_chain = utf8(b"Holesky");
    //     let source_addr = utf8(b"0xe1EE8B61deB84D424C5df1daE73E404A9C2175F7");
    //     let payload = x"a201317c4030786237303337336435626135623064613836373266663632373034626664313137323131633263327c3130307c403078633239323935663637663564343736313035663139653835313364613065353032376537336533397c403078396135306165643063613264363165646137626336646637623563373433363532356631623231366461663932633165633533643039306137663664393265347c31";
    //
    //     execute_instruction(account, source_chain, source_addr, payload);
    // }
}

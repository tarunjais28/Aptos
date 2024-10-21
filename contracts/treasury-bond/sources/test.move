#[test_only]
module treasury_bond::test {

    use std::signer;
    use std::string::{Self};
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aptos_framework::account;
    use treasury_bond::treasury_bond::{init, create};
    use treasury_bond::maintainer::get_admins;
    use treasury_bond::agent::has_agent_rights;
    use std::vector;
    use aptos_std::debug::print;

    #[test(
        account = @treasury_bond,
        dia = @0x1,
        usdt = @0x2,
        usdc = @0x3,
    )]
    entry fun test_init(account: &signer, dia: address, usdt: address, usdc: address) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        init(account, dia, usdt, usdc);

        assert!(vector::contains(&get_admins(), &addr), 0);
    }

    #[test(
        account = @treasury_bond,
        timer = @0x1,
        dia = @0x2,
        usdt = @0x3,
        usdc = @0x4,
    )]
    entry fun test_create(
        account: &signer,
        timer: &signer,
        dia: address,
        usdt: address,
        usdc: address,
    ) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        set_time_has_started_for_testing(timer);

        init(account, dia, usdt, usdc);

        let id = string::utf8(b"unique");
        let token = string::utf8(b"budz");
        let issuer = string::utf8(b"issuer");
        let issue_size = 100;
        let face_value = 100;
        let coupon_rate = 7;
        let accrued_interest = 8;
        let maturity_date = 121322456;
        let coupon_frequency = string::utf8(b"Monthly");

        // Fails during price fetch due to absence of price feed
        create(
            account,
            id,
            token,
            issue_size,
            face_value,
            coupon_rate,
            accrued_interest,
            maturity_date,
            issuer,
            coupon_frequency,
        );

        // assert!(has_agent_rights(token, addr), 0);
        //
        // let token = string::utf8(b"budz");
        // create(
        //     account,
        //     token,
        //     issue_size,
        //     face_value,
        //     coupon_rate,
        //     accrued_interest,
        //     maturity_date,
        //     issuer,
        //     coupon_frequency,
        // );
    }
}

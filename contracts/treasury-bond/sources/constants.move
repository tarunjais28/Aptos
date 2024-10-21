module treasury_bond::constants {

    const DAI: u8 = 0;
    const USDT: u8 = 1;
    const USDC: u8 = 2;

    public fun dai(): u8 {
        DAI
    }

    public fun usdt(): u8 {
        USDT
    }

    public fun usdc(): u8 {
        USDC
    }
}
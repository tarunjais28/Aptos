module fund::constants {

    /// Different types of assets used
    const TOKEN: u8 = 0;
    const STABLE_COIN: u8 = 1;
    const FIAT: u8 = 2;

    /// Different types of stable coins used
    const DAI: u8 = 0;
    const USDT: u8 = 1;
    const USDC: u8 = 2;

    /// Function to return token identity constant
    public fun token(): u8 {
        TOKEN
    }

    /// Function to return stable_coin identity constant
    public fun stable_coin(): u8 {
        STABLE_COIN
    }

    /// Function to return fiat identity constant
    public fun fiat(): u8 {
        FIAT
    }

    /// Function to return dai identity constant
    public fun dai(): u8 {
        DAI
    }

    /// Function to return usdt identity constant
    public fun usdt(): u8 {
        USDT
    }

    /// Function to return usdc identity constant
    public fun usdc(): u8 {
        USDC
    }
}
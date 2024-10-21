# Capital Call's Fund Contract in Aptos

📚 This contracts is fully based on capital call functionalities in Aptos based on its fund contract.

---

## Introduction

This README file is use to guide the concept of capital call on Aptos Blockchain through its fund contract, and how to integrate them into project.

## Integrating Fund Contract in Capital Call Project

To integrate a fund contract following steps must be followed:

1. Understand the provided smart contracts i.e., modules on Aptos (`fund.move`, `events.move`, `agents.move`, `maintainers.move`, `resource.move`, `stable_coin.move`, `constants.move`, `test.move` ), their functions, and their interactions and for e2e testcases understand `test.move`
2. Customize the smart contracts as needed to fit the project's requirements.
3. Deploy or publish the module to Aptos network. Check this link to know how to publish and interact with modules in Aptos : https://aptos.dev/

Please note that familiarity with Rust, move and the Aptos ecosystem is required to successfully integrate Fund Contract into Capital Call project.

### Contract Flow Diagram

![Fund-Contract-Aptos](https://github.com/tarunjais28/provenance-token-contract/assets/76393080/0efc8d57-9e94-464b-981b-80fe3ccee06a)


## Functions Description and Usage

The Fund folder provide several `.move` files which have several functions and events and many more. Below is a guide on how to use these functions :

### Publishing the Modules

Head to `fund` folder and publish the underlying modules on the Aptos network with the help of `Makefile` provided. The makefile has all the necessary functions in it to reduce writing big CLI commands. Do `make publish` which will publish the module.

### Initializing

To initialize the fund contract from an account. Call the `init` function in `fund.move` :

```move
public entry fun init(
    account: &signer,
    dai: address,
    usdt: address,
    usdc: address,
)
```
##### This function takes the following parameters:
- `account`: The account of the signer that will serve as an admin. No need to pass this parameter as all the parameters with `&signer` is automatically fetched as that address is doing the particular transaction
- `dai`: Address of DAI coin, for testing purpose test DAI has been minted from `fungible-token` contract.
- `usdt`: Address of USDT coin, for testing purpose test USDT has been minted from `fungible-token` contract.
- `usdc`: Address of USDC coin, for testing purpose test USDC has been minted from `fungible-token` contract.

<a name="update-admin-"></a>
### Update Admin

#### To update admin, call the `update_admin` function in `maintainer.move`:

```move
public entry fun update_admin(account: &signer, new_admin: address)
```

##### This function takes the following parameters:

- `account`: The account of the signer
- `new_admin`: The address that are going to be new admin

<a name="create-fund-"></a>
### Creating Fund

To create Fund, call the `create` function in `fund.move` :

```move
public entry fun create(
    account: &signer,
    token_id: String,
    fund_name: String,
    asset_type: u8,
    issuer_name: String,
    target_aum: u64,
    nav_launch_price: u64,
)
```
##### This function takes the following parameters:

- `account`: The account of signer
- `token_id` - Unique id mapped to each token
- `fund_name` - Name of the fund
- `asset_type` - Asset Type, can be either Stable Coin, Token or Fiat
- `issuer_name` - Name of the issuer
- `target_aum` - Target Asset Under Management
- `nav_launch_price` - Net Asset Value during launch

This function returns nothing and will only create fund contract for particular token

<a name="share-dividend-"></a>
### Share Dividend

#### For Share Dividend call `share_dividend` in `fund.move`:

Stable coins must be transferred from `from` account to agent account before this function call. This function supports batch operation. The investors, amounts and tokens must be passed in ordered manner, such as investors[0] corresponds to amounts[0] and tokens[0]

```move
public entry fun share_dividend(
    account: &signer,
    token_id: String,
    to_addresses: vector<address>,
    dividends: vector<u64>,
    asset_types: vector<u8>,
    coin_type: u8,
)
```

##### These functions take the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `to_addresses` - Recipients addresses
- `dividends` - Amount of tokens and stable coins going to be shared
- `asset_type` - Asset Type, can be either Stable Coin, Token or Fiat
- `coin_type` - Coin Type, coin used for the transaction, can be either of DAI, USDC or USDT

###### The possible errors cases :

- If the quantity of investors, amounts and tokens are different
- Sender doesn't have agent rights

<a name="distribute-and-burn-"></a>
### Distribute and Burn / Waterfall Distribution

Here tokens are burned from investor account and stable coins are transffered.

Stable coins must be transferred from `from` account to agent account before this function call. This function supports batch operation. The investors, amounts and tokens must be passed in ordered manner, such as investors[0] corresponds to amounts[0] and tokens[0]

To distribute stable coins and burn tokens, call `distribute_and_burn` in `fund.move`:

```move
public entry fun distribute_and_burn(
        account: &signer,
        token_id: String,
        investors: vector<address>,
        amounts: vector<u64>,
        tokens: vector<u64>,
        coin_type: u8,
    )
```
##### This function takes the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `investors` - Addresses of investors
- `amounts` - Amount of tokens stable coins transferred to investor's account in exchange with the specific tokens burned
- `tokens` - Tokens to be burned
- `coin_type` - Coin Type, coin used for the transaction, can be either of DAI, USDC or USDT

###### The possible errors cases :

- If the quantity of investors, amounts and tokens are different
- Sender doesn't have agent rights

<a name="rescue-token-"></a>
### Rescue Token

The extra tokens can be claimed or rescued from the agent

Agent can call `rescue_token` in `fund.move` to return the extra tokens:

```move
public entry fun rescue_token(
        account: &signer,
        token_id: String,
        to: address,
        amount: u64,
    )
```

##### This function takes the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `to` - Address of the recipient
- `amount` - Amount of stable coins to be rescued

###### The possible errors cases :

- Sender is not the agent

### User Management Fees

<a name="add-user-management-fees"></a>
#### Add User Management Fees

Function for add user management fees. This function supports batch operation. The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]


Note:-  This function is not currently in use, may be used in future versions

To add management fees, call `add_user_management_fees` in `fund.move`:

```move
public entry fun add_user_management_fees(
        account: &signer,
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    )
```

##### This function takes the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `users` - Addresses of the users to be added
- `fees` - Fees of management to be added

###### The possible errors cases :

- Sender is not the agent

<a name="update-user-management-fees"></a>
#### Update User Management Fees

Function for update user management fees. This function supports batch operation. The users and fees must be passed in ordered manner, such as users[0] corresponds to fees[0]


Note:-  This function is not currently in use, may be used in future versions

To update management fees, call `update_user_management_fees` in `fund.move`:

```move
public entry fun update_user_management_fees(
        account: &signer,
        token_id: String,
        users: vector<address>,
        fees: vector<u64>,
    )
```

##### This function takes the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `users` - Addresses of the users to be updated
- `fees` - Fees of management to be updated

###### The possible errors cases :

- Sender is not the agent

<a name="remove-user-management-fees"></a>
#### Remove User Management Fees

Function for update user management fees. This function supports batch operation.


Note:-  This function is not currently in use, may be used in future versions

To remove management fees user, call `remove_user_management_fees` in `fund.move`:

```move
public entry fun remove_user_management_fees(
    account: &signer,
    token_id: String,
    users: vector<address>,
)
```

##### This function takes the following parameters:

- `account` - Sender / Caller of the transaction
- `token_id` - Unique id mapped to each token
- `users` - Addresses of the users to be removed

###### The possible errors cases :

- Sender is not the agent

<a name="notes"></a>
#### Notes

Some functions are not being used in the current version and subject to further changes. This might be updated in future releases.

---

# Fungible Asset in Aptos

📚 This repository presents a set of smart contracts for tokenizing an asset into Fungible Assets in Aptos.

---

## Introduction

The Token project aims to provide sets of contracts for creating Fungible Tokens. This README will guide you through the concept of tokenizing an asset into fungible asset on Aptos Blockchain, and how to integrate them into your project.

## Integrating Fungible Asset into Your Project

To integrate a fungible asset into your project, follow these steps:

1. Understand the provided smart contracts i.e., modules on Aptos (`asset_coin.move` , `events.move` , `agents.move` , `maintainers.move` , `resource.move` , `roles.move` , `whitelist.move` ), their functions, and their interactions and for e2e testcases understand `test.move`
2. Customize the smart contracts as needed to fit your project's requirements.
3. Deploy or publish the module to Aptos network. Check this link to know how to publish and interact with modules in Aptos : https://aptos.dev/

Please note that familiarity with Rust, move and the Aptos ecosystem is required to successfully integrate Fungible Assets into your project.

### Contract Flow Diagram

![Aptos Contract Flow](https://github.com/Asset-Pro-Inc/aptossto/assets/74697191/cb05c973-98bc-4f7a-b986-d01e5f9907c5)


## Functions Description and Usage

The Fungible Tokens folders provide several `.move` files which have several functions and events to tokenize assets into Fungible Assets and many more. Below is a guide on how to use these functions :

### Publishing the Modules

Head to `fungible-tokens` folder and publish the underlying modules on the Aptos network with the help of `Makefile` provided. The makefile has all the necessary functions in it to reduce writing big CLI commands. Do `make publish` which will publish the module.

### Initializing 

To initialize from an admin account, call the `init` function in `asset_coin.move` :

```move
public entry fun init(admin: &signer)
```
##### This function takes the following parameters:

- `admin`: The account of the signer that will serve as an admin. No need to pass this parameter as all the parameters with `&signer` is automatically fetched as that address is doing the particular transaction

<a name="adding-and-removing-sub-admins-"></a>
### Adding and removing Sub-admins 

#### To add sub-admins, call the `add_sub_admins` function in `maintainer.move`: 

```move
public entry fun add_sub_admins(
account: &signer, 
addrs: vector<address>
)
```

##### This function takes the following parameters:

- `account`: The account of the signer 
-  `addrs`: The vector of address which will serve as sub-admins

#### To add sub-admins, call the `remove_sub_admins` function in `maintainer.move`:

```move
 public entry fun remove_sub_admins(
account: &signer,
addrs: vector<address>
)
```
##### This function takes the following parameters:

- `account`: The account of the signer
-  `addrs`: The vector of address which will be removed as sub-admins

These functions will return nothing, but in the explorer you can see under the resource address and under that resource address all the resource initiated empty at start and sub_admin added or removed

The function will return error `ERR_NOT_ADMIN` if the signer is not admin

### Creating Token

To create token, call the `create_token` function in `asset_coin.move` :

```move
public entry fun create_token(
creator: &signer,
id: String,
name: String,
symbol: String,
icon_uri: String,
project_uri: String,
token_limit: u64,
country_codes: vector<u8>,
issuer: address,
tokenization_agent: address,
transfer_agent: address,
)
```
##### This function takes the following parameters:

- `creator`: The account of signer 
- `id`: The unique token id which will help in differentiating tokens 
- `name`: The name of the token
- `symbol`: The symbol of the token
- `icon_uri`: The icon uri
- `project_uri`: The project uri
- `token_limit`: The token limit of the asset
- `country_codes`: The country codes, which is countries which are able to do transactions
- `issuer`: Issuer Address
- `tokenization_agent` : Tokenization agent address
- `transfer_agent`: Transfer agent address

This function returns nothing and will only create token

The `issuer` , `tokenization_agent` and `transfer_agent` are the accounts who have different types of access in our contract.

###### The possible errors to come :

- `ERR_NOT_SUB_ADMIN`: The signer is not sub-admin. To resolve this error, perform [add_remove_sub_admins](#adding-and-removing-sub-admins-)
- `ERR_ID_EXIST`: The id already exists if trying to create token second time
- `ERR_NAME_EXIST`: The name already exists if trying to create token second time
- `ERR_SYMBOL_EXIST`: The symbol already exists if trying to create token second time

### Burning tokens and Minting tokens

#### To burn token and mint, call `burn_token` and `mint_token` in `asset_coin.move`:

```move
public entry fun burn_token(
        account: &signer,
        id: String,
        users: vector<address>,
        amounts: vector<u64>,
    )
```

```move
public entry fun mint_token(
        account: &signer,
        id: String,
        users: vector<address>,
        amounts: vector<u64>,
    ) 
```
##### These functions take the following parameters:

- `account`: The account of signer
- `id`: The unique id of the token created before
- `users`: The vector of address from which the amount will be burned
- `amounts`: The vector of amounts which will be burned

###### The possible errors to come :

- `ERR_MULTISIG_ENABLED`: Multi-sig functionality has been enabled for that token with id passed in function, and now it is required to go through the multi-sig process to burn and mint tokens. To disable multi-sig perform [enable_disable_multi-sig](#enable-and-disable-multi-sig-)
- `ERR_ARGUMENTS_MISMATCHED`: The length of vector of address and vector of amount is not equal
- `ERR_UNAUTHORIZED` : The signer does not have rights to perform this action. The signer should be `issuer` , `tokenization_agent` , `sub-admin` or should have `burn` or `mint` rights
- `ERR_BALANCE_FROZEN`: The amount to burn is frozen or less than the frozen amount for particular address
- `ERR_TOKEN_LIMIT_EXCEEDED`: The amount to mint exceeded the token limit set during creation of token

### Transfer Tokens
 
To transfer tokens, call `transfer_token` in `asset_coin.move`:

```move
public entry fun transfer_token(
        from: &signer,
        id: String,
        to: address,
        amount: u64
    )
```
##### This function takes the following parameters:

- `from`: The account of signer
- `id`: The unique token id
- `to`: The receiver address
- `amount`: The amount to transfer

###### The possible errors to come :

- `ERR_TOKEN_LIMIT_EXCEEDED`: The amount to mint exceeded the token limit set during creation of token
- `ERR_ACCOUNT_NOT_WHITELISTED`: The account is not white-listed .To a white-list account do [white-list](#white-list-account)
- `ERR_BALANCE_FROZEN`: The amount to transfer is frozen or less than the frozen amount for particular address
- `ESTORE_IS_FROZEN`: The account is frozen and can not do transfer 

### Force Transfer Token

To force transfer token, call `force_transfer` in `asset_coin.move`:

```move
public entry fun force_transfer(
        account: &signer,
        id: String,
        from_addresses: vector<address>,
        to_addresses: vector<address>,
        amounts: vector<u64>,
    )
```

##### This function takes the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- `from_addresses`: The vector of address from which the force transfer will happen
- `to_addresses`: The vector of receiver address 
- `amounts`: The vector of amount to force transfer

###### The possible errors to come :

- `ERR_UNAUTHORIZED` : The signer does not have rights to perform this action. The signer should be `issuer` , `tokenization_agent` , `sub-admin` or should have `burn` or `mint` rights. To make signer following perform [add_agents_and_roles](#add-agents-and-roles-) or make sub-admin using [add_remove_sub_admins](#adding-and-removing-sub-admins-)
- `ERR_ARGUMENTS_MISMATCHED`: The length of vector of address and vector of amount is not equal
- `ERR_TOKEN_LIMIT_EXCEEDED`: The amount to mint exceeded the token limit set during creation of token
- `ERR_ACCOUNT_NOT_WHITELISTED`: The account is not white-listed .To a white-list account do [white-list](#white-list-account)
- `ERR_BALANCE_FROZEN`: The amount to transfer is frozen or less than the frozen amount for particular address

### Freeze and Unfreeze Account

#### To freeze and unfreeze account call, `freeze_accounts` and `unfreeze_accounts` in `asset_coin.move`:

```move
public entry fun freeze_accounts(
        sender: &signer,
        id: String,
        addrs: vector<address>,
    ) 
```
```move
 public entry fun unfreeze_accounts(
        sender: &signer,
        id: String,
        addrs: vector<address>,
    )
```

##### These functions take the following parameters:

- `sender`: The account of signer
- `id`: The unique token id
- `addrs` : The vector of address to freeze

###### The possible errors to come :

- `ERR_UNAUTHORIZED` : The signer does not have rights to perform this action. The signer should be `issuer` , `tokenization_agent` , `sub-admin` or should have `burn` or `mint` rights. To make signer following perform [add_agents_and_roles](#add-agents-and-roles-) or make sub-admin using [add_remove_sub_admins](#adding-and-removing-sub-admins-)


## Other Functions and their usage

<a name="add-agents-and-roles-"></a>
### Add Agents and Roles 

#### To add or remove issuer, Tokenization and transfer agents, call, `add_issuer` , `remove_issuer` , `add_transfer_agent` , `remove_transfer_agent` , `add_tokenization_agent` , `remove_tokenization_agent` in `roles.move`:

```move
 public entry fun add_issuer(
        account: &signer, 
        id: String,
        new_issuer: address
    )
```

```move
  public entry fun remove_issuer(
        account: &signer, 
        id: String,
    )
```

##### These functions take the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- `new_issuer`: The address of issuer

###### The possible errors to come :

- `ERR_NOT_SUB_ADMIN`: The signer is not sub-admin. To resolve this error, perform [add_remove_sub_admins](#adding-and-removing-sub-admins-)

#### To add or remove mint,burn,transfer, force_transfer,freeze,unfreeze,deposit,delete,unspecified and withdraw access , call `assign_agent_role` or `unassign_agent_role` in `agents.move`:
 
```move
public entry fun assign_agent_role(
       id: String,
       addr: address,
       roles: vector<u64>
   )
```

```move
public entry fun unassign_agent_role(
       id: String,
       addr: address,
       roles: vector<u64>
   )
```

##### These functions take the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- `roles`: The vector of roles i.e., mint,burn etc

###### The possible errors to come :

- `ERR_ALREADY_ASSIGNED_ACCESS`: Access is already assigned
- `ERR_NO_ADMIN_ACCESS` etc : The access trying to remove is not assigned 

<a name="white-list-account"></a>
### White-list account

#### To white-list or black-list account, call `add` or remove `remove` in `whitelist.move`:

```move
public entry fun add(
        account: &signer,
        id: String,
        users: vector<address>,
        country_codes: vector<u8>,
    ) 
```

```move
public entry fun remove(
        account: &signer,
        id: String,
        users: vector<address>,
    ) 
```

##### These functions take the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- `users`: The address that will be white-listed or black-listed based on the function
- `country_codes`: The country codes for the country which will be allowed to do transactions 

###### The possible errors to come :

- `ERR_UNAUTHORIZED` : The signer does not have rights to perform this action. The signer should be `issuer` , `tokenization_agent` , `sub-admin` or should have `burn` or `mint` rights. To make signer following perform [add_agents_and_roles](#add-agents-and-roles-) or make sub-admin using [add_remove_sub_admins](#adding-and-removing-sub-admins-)
- `ERR_ARGUMENTS_MISMATCHED`: The length of vector of address and vector of country codes is not equal

### Add or remove Country codes

#### To add or remove country codes, call `add_country_code` or `remove_country_code` in `resource.move`:

```move
 public fun add_country_code(
        account: &signer,
        id: String,
        country_codes: vector<u8>
    )
```

```move
 public fun remove_country_code(
        account: &signer,
        id: String,
        country_codes: vector<u8>
    ) 
```

##### These functions take the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- `country_codes`: The country codes for the country which will be allowed to do transactions 

###### The possible errors to come : 

- `ERR_NOT_SUB_ADMIN`: The signer is not sub-admin. To resolve this error, perform [add_remove_sub_admins](#adding-and-removing-sub-admins-)
- `ERR_COUNTRY_CODE_ALREADY_PRESENT`: The country code already added that is being added
- `ERR_COUNTRY_CODE_NOT_PRESENT`: The country codes do not exist that is being removed

### Partial freeze and unfreeze balances

#### To partial freeze and unfreeze balances, call `partial_freeze` or `partial_unfreeze` in `resource.move`:

```move
public entry fun partial_freeze(
        sender: &signer,
        id: String,
        addrs: vector<address>,
        balances: vector<u64>,
    ) 
```

##### This function takes the following parameters:

- `sender`: The account of signer
- `id`: The unique token id
- `addrs` : The vector of address to have balances partially freeze
- `balances` : The vector of balances to be frozen partially

```move
 public entry fun partial_unfreeze(
        sender: &signer,
        id: String,
        addrs: vector<address>
    )
```

##### This function takes the following parameters:

- `sender`: The account of signer
- `id`: The unique token id
- `addrs` : The vector of address to have balances partially freeze

###### The possible errors to come :

- `ERR_UNAUTHORIZED` : The signer does not have rights to perform this action. The signer should be `issuer` , `tokenization_agent` , `sub-admin` or should have `burn` or `mint` rights. To make signer following perform [add_agents_and_roles](#add-agents-and-roles-) or make sub-admin using [add_remove_sub_admins](#adding-and-removing-sub-admins-)
- `ERR_ARGUMENTS_MISMATCHED`: The length of vector of address and vector of country codes is not equal

### Update Token Limit

#### To update the token limit set during the creation of token, call `update_token_limit` in `resource.move` : 

```move
public entry fun update_token_limit(
        account: &signer,
        id: String,
        limit: u64
    )
```

##### This function takes the following parameters:

- `account`: The account of signer
- `id`: The unique token id
- limit: The new token limit


###### The possible errors to come :

- `ERR_NOT_SUB_ADMIN`: The signer is not sub-admin. To resolve this error, perform [add_remove_sub_admins](#adding-and-removing-sub-admins-)

<a name="future-release"></a>
#### Future Release

Multisig is under internal testing will be available in future release. 

---

# CredentialChain

A verifiable credentials and certification system where digital credentials can be recognized by multiple verifiers.

## Overview

CredentialChain is a Clarity smart contract that enables a decentralized credential ecosystem on the Stacks blockchain. It allows authorized issuers to create verifiable credentials as NFTs, verifiers to establish trust levels for credentials, and individuals to own and present these credentials.

## Features

- **NFT Credential Management**: Issue, transfer, and track ownership of digital credentials
- **Issuer Registration**: Credential issuers can register to be part of the CredentialChain ecosystem
- **Verifier Trust System**: Verifiers can set trust levels for different credentials
- **Credential Claims**: Store and retrieve detailed claims within credentials
- **Access Controls**: Proper authorization checks for all sensitive operations

## Contract Functions

### Admin Functions

- `set-contract-owner`: Update the contract owner
- `register-issuer`: Register a new credential issuer to the platform
- `deactivate-issuer`: Deactivate a previously registered issuer

### NFT Functions

- `issue-credential`: Create a new NFT credential with metadata
- `transfer-credential`: Transfer a credential to another user
- `set-credential-trust`: Define how much a verifier trusts a specific credential
- `set-credential-claims`: Set or update a credential's claims

### Read-Only Functions

- `get-credential-details`: Get basic information about a credential
- `get-credential-claims`: Get the claims of a credential
- `get-credential-trust`: Check how much a verifier trusts a specific credential
- `get-issuer-info`: Get information about a registered issuer
- `get-credential-owner`: Get the current owner of a credential
- `is-issuer-active`: Check if an issuer is currently active

## Usage

### For Issuers

1. Register as an issuer using `register-issuer`
2. Issue credentials to recipients using `issue-credential`
3. Define detailed claims for credentials using `set-credential-claims`

### For Verifiers

1. Register as an issuer (verifiers are also issuers in this system)
2. Set trust levels for credentials using `set-credential-trust`

### For Credential Holders

1. Receive credentials from authorized issuers
2. Present credentials to verifiers who can check their validity
3. Transfer credentials when appropriate

## Development

This contract is developed using Clarity and can be tested with Clarinet.
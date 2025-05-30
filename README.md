# EcoCredit

EcoCredit is a decentralized carbon credit marketplace built on Stacks blockchain, enabling transparent verification and trading of carbon offset projects through community consensus.

## Features

- **Carbon Project Certification**: Community-driven verification of environmental impact projects
- **Credit Trading**: Peer-to-peer trading of verified carbon credits
- **Transparent Auditing**: Decentralized audit process ensures project legitimacy
- **Impact Tracking**: Immutable record of environmental impact and offset verification

## Smart Contract Functions

### Credit Management
- `mint-carbon-credits`: Issue carbon credits to ecosystem participants
- `transfer-credits`: Trade credits between participants
- `get-participant-credits`: Check participant's credit balance

### Project Certification
- `submit-project`: Submit carbon offset project for community review
- `audit-project`: Audit and verify submitted projects
- `finalize-certification`: Complete certification process
- `get-project`: Retrieve project details and certification status

## Getting Started

1. Clone this repository
2. Install [Clarinet](https://github.com/hirosystems/clarinet)
3. Run `clarinet check` to verify the contract
4. Deploy using Clarinet or Stacks CLI
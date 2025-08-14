# Raffle Contract

## Overview

This project implements a decentralized raffle (lottery) smart contract in Solidity. The raffle allows users to enter by paying a fixed entry fee in ETH. After a predefined time interval, a winner is automatically selected using Chainlink's Verifiable Random Function (VRF) for secure randomness and Chainlink Automation for triggering the winner selection process. The entire prize pool (collected entry fees) is transferred to the winner.

The contract is designed to be gas-efficient, secure, and compatible with both local development (using mocks) and live networks like Sepolia. It includes deployment scripts, helper configurations, interaction scripts for Chainlink setup, mock contracts, and comprehensive unit tests.

Key technologies:
- Solidity ^0.8.19
- Chainlink VRF v2.5 for randomness
- Chainlink Automation for time-based triggers
- Foundry for development, testing, and deployment

**Author**: Ajay Curry  
**License**: MIT (as per SPDX-License-Identifier in the contracts)

## Features

- **Entry Mechanism**: Users enter the raffle by sending ETH >= entry fee. Multiple entries are allowed, increasing the prize pool.
- **Automated Winner Selection**: After the interval (e.g., 30 seconds on testnets), Chainlink Automation checks if upkeep is needed and triggers the random winner pick via VRF.
- **Raffle States**: Supports `OPEN` (accepting entries) and `CALCULATING` (processing winner) states to prevent entries during winner calculation.
- **Events**: Emits events for entry, winner request, and winner pick for easy off-chain tracking.
- **Error Handling**: Custom errors for insufficient funds, closed raffle, failed transfers, and unnecessary upkeep.
- **View Functions**: Getters for entry fee, raffle state, players, starting timestamp, and recent winner.
- **Network Agnostic**: Configurable for local Anvil chains (with mocks) and Ethereum Sepolia testnet.
- **Testing**: Full unit tests covering initialization, entry, upkeep, VRF fulfillment, and edge cases.
- **Scripts**: Deployment, Chainlink subscription creation/funding, and consumer addition.

## How It Works

1. **Deployment**: The contract is deployed with parameters like entry fee, interval, VRF coordinator address, gas lane (key hash), subscription ID, and callback gas limit.
2. **Entering the Raffle**: Users call `enterRaffle()` with ETH >= `i_entryFee`. Players are stored in an array.
3. **Upkeep Check**: Chainlink Automation periodically calls `checkUpkeep()` to verify if:
   - Time interval has passed.
   - Raffle is open.
   - Contract has balance (entries).
   - There are players.
4. **Perform Upkeep**: If upkeep is needed, `performUpkeep()` requests random words from Chainlink VRF and sets the state to `CALCULATING`.
5. **VRF Fulfillment**: Chainlink calls `fulfillRandomWords()` with random numbers. A winner is selected modulo the number of players, the prize is transferred, and the raffle resets (new timestamp, empty players, open state).
6. **Reset**: The raffle reopens for new entries after winner selection.

## Prerequisites

- **Foundry**: Install via `curl -L https://foundry.paradigm.xyz | bash` (requires Rust and Git).
- **Dependencies**: The project uses:
  - Chainlink contracts (`chainlink-brownie-contracts`).
  - Forge-std for scripting and testing.
  - Foundry-devops for deployment tools.
  - Solmate for ERC20 (used in mocks).
  - Run `forge install` to fetch dependencies.
- **Local Development**: Anvil (Foundry's local Ethereum node) for testing.
- **Testnet (Sepolia)**: 
  - Ethereum wallet with Sepolia ETH and LINK.
  - Private key or Account keystore for deployment.
  - Chainlink subscription (created via scripts if needed).
- **Environment Variables**: For Sepolia deployment, set `PRIVATE_KEY` (or use cast wallet import and --account with forge create) and `SEPOLIA_RPC_URL` in `.env`.

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd raffle-contract
   ```

2. Install dependencies:
   ```
   forge install
   ```

3. Build the project:
   ```
   forge build
   ```

## Deployment

The deployment script (`DeployRaffle.s.sol`) handles network-specific configs via `HelperConfig.s.sol`. It deploys the `Raffle` contract and sets up Chainlink if needed.

### Local (Anvil)
```
forge script script/DeployRaffle.s.sol --broadcast --fork-url http://localhost:8545
```
- This deploys mocks for VRF Coordinator and LINK token if on chain ID 31337.
- Creates and funds a VRF subscription automatically.
- Adds the raffle contract as a consumer.

### Sepolia Testnet
```
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```
- Uses predefined Sepolia configs (VRF Coordinator: `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`, etc.).
- If no subscription ID is set, creates and funds one (requires LINK in the deployer account).
- Adds the contract as a consumer to the subscription.

**Note**: Update `HelperConfig.s.sol` with your Sepolia account if needed. Fund the subscription with at least 3 LINK for testing.

## Usage

### Interacting with the Contract

1. **Enter the Raffle**:
   - Call `enterRaffle()` with value >= entry fee (e.g., 0.01 ETH).
   - Example (via Foundry cast):  
     ```
     cast send <raffle-address> "enterRaffle()" --value 0.01ether --rpc-url <rpc-url> --private-key <private-key>
     ```

2. **Check Upkeep**:
   - View function: `checkUpkeep("")` returns if winner selection is ready.
   - In production, Chainlink Automation handles this.

3. **Perform Upkeep**:
   - Call `performUpkeep("")` when upkeep is needed (manual on local/test; automated on live).
   - Triggers VRF request.

4. **View State**:
   - `getEntryFee()`: Returns entry fee.
   - `getRaffleState()`: 0 (OPEN) or 1 (CALCULATING).
   - `getPlayer(index)`: Player address at index.
   - `getRecentWinner()`: Last winner.
   - `getStartingTimeStamp()`: Raffle start time.

### Chainlink Setup Scripts (`Interactions.s.sol`)

- **Create Subscription**:
  ```
  forge script script/Interactions.s.sol:CreateSubscription --rpc-url <rpc-url> --private-key <private-key> --broadcast
  ```
  - Logs the new subscription ID (update in `HelperConfig.s.sol` if needed).

- **Fund Subscription**:
  ```
  forge script script/Interactions.s.sol:FundSubscription --rpc-url <rpc-url> --private-key <private-key> --broadcast
  ```
  - Funds with 3 LINK (adjust `FUND_AMOUNT` if needed).

- **Add Consumer**:
  ```
  forge script script/Interactions.s.sol:AddConsumer --rpc-url <rpc-url> --private-key <private-key> --broadcast
  ```
  - Adds the most recent `Raffle` deployment as a consumer.

## Testing

The project includes unit tests in `RaffleTest.t.sol` and `Interactions.t.sol`.

Run all tests:
```
forge test
```

### Key Tests in `RaffleTest.t.sol`
- Initialization: Verifies open state.
- Entry: Reverts on low payment, records players, emits events, blocks during calculating.
- Upkeep: False if no balance/players, not open, or time not passed; true otherwise.
- Perform Upkeep: Reverts if not needed, updates state, emits request ID.
- VRF Fulfillment: Only callable after upkeep, picks winner, resets raffle, transfers prize.

### Key Tests in `Interactions.t.sol`
- Subscription Creation: Validates ID, owner, and coordinator.
- Edge Cases: Reverts on invalid coordinator.

**Coverage**: Run `forge coverage` for report.

## Contracts Overview

| File                  | Description |
|-----------------------|-------------|
| **Raffle.sol**       | Core raffle logic, VRF integration, entry/upkeep/fulfillment. |
| **DeployRaffle.s.sol** | Deploys `Raffle`, handles mocks/subscription on local/Sepolia. |
| **HelperConfig.s.sol** | Network configs (entry fee, interval, VRF params); creates mocks on local. |
| **Interactions.s.sol** | Scripts for Chainlink: create/fund subscription, add consumer. |
| **Interactions.t.sol** | Tests for subscription creation and validation. |
| **LinkToken.sol**    | Mock ERC20/677 LINK token for local testing. |
| **RaffleTest.t.sol** | Comprehensive unit tests for `Raffle`. |

## Security Considerations

- Uses Chainlink for trusted randomness (prevents miner manipulation).
- Custom errors for gas savings.
- No reentrancy risks (transfers at end).
- Audit recommended for production.

## Contributing

Fork the repo, create a branch, and submit a PR with changes/tests.

## License

MIT License. See contract headers for details.
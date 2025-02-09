# Pendle Standardized Yield (SY) Contracts

This repository contains the Standardized Yield (SY) smart contracts of Pendle Protocol, which serve as wrappers around various yield-bearing tokens to standardize their interfaces and behaviors.

## Overview

The SY contracts provide a unified interface for interacting with different yield-bearing tokens across DeFi protocols, including:

- Liquid Staking Derivatives (Lido, Renzo, Swell, etc.)
- Lending Protocols (Aave, Venus, Flux)
- AMM LP Tokens (GMX, Thena)
- Yield Aggregators (Convex)
- And many more

## Key Features

- Standardized deposit/redeem interface
- Support for native tokens and wrapped versions
- Reward handling for protocols with yield farming
- Exchange rate calculations
- Preview functions for deposits and redemptions

## Contract Structure

- Base contracts:
  - `SYBase.sol`: Core base contract for basic SY functionality
  - `SYBaseWithRewards.sol`: Extended base for SYs with reward claiming
  - `SYBaseUpg.sol`: Upgradeable version of the base contract

- Implementation contracts:
  - Protocol-specific implementations inheriting from base contracts
  - Each implementation handles the unique aspects of interacting with its underlying protocol

## License

BUSL-1.1

## Links

- Website: https://pendle.finance
- Documentation: https://docs.pendle.finance/Developers/Overview
- GitHub: https://github.com/pendle-finance/pendle-sy-public

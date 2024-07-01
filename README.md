## Staking Contract

Simplified Staking.

A Staking Project where there are 3 roles involved.

- Staker
- Owner
- Chainlink Keeper

## Live test
(coming-soon)

## Roles

#### Staker
- Stake: Stake his tokens
- Unstake: Unstake his tokens (after `LockTime`)
- Claim: Claim rewards daily after ChainLink Keeper calls `earned`.


#### Owner
- Pause/Unpause: Pause/Unpause the protocol.
- ChangeKeeper: Change the Keeper to an other address/keeper.
- SetLockTime: Set the locktime for when an user `stake`/s.
- setMaxRewards: Set the max rewards the contract will ever distribute.


#### Chainlink Keeper
The chainlink keeper will be to:
- Earned
`Earned` can only be called by the keeper, and will be only called once a day.
Thus rewards will be calculated for all `stakers` once a day by the Keeper.

### Installation

```shell
$ yarn install
```

```shell
$ forge install
```

```shell
$ forge build
```

### Test

```shell
$ forge test
```

# Disclaimer
Please note that this code is unaudited several bug/s may be present, use
at own risk.# StakingProject
# Staking-Project
# Staking-Project

# ERC1155 written in pure Yul

## Repository installation

1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

- Install solidity compiler
  <https://docs.soliditylang.org/en/latest/installing-solidity.html#installing-the-solidity-compiler>

- Build Yul contracts and check tests pass

```bash
forge test
```

## Running tests

Run tests (compiles yul then fetch resulting bytecode in test)

```bash
forge test
```

To see the console logs during tests

```bash
forge test -vvv
```

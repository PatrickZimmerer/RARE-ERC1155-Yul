# ERC1155 written in pure Yul

List of supported functions (ERC-1155 standard):

- :white_check_mark: balanceOf(address account, uint256 id)
- :white_check_mark: balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
- :white_check_mark: setApprovalForAll(address \_operator, bool \_approved)
- :white_check_mark: isApprovedForAll(address \_owner, address \_operator)
- :white_check_mark: safeTransferFrom(address \_from, address \_to, uint256 \_id, uint256 \_value, bytes calldata \_data)
- :white_check_mark: safeBatchTransferFrom(address \_from, address \_to, uint256[] calldata \_ids, uint256[] calldata \_values, bytes calldata \_data)

List of non-standard functions:

- :white_check_mark: mint(address to, uint256 id, uint256 amount)
- :white_check_mark: mint(address to, uint256 id, uint256 amount, bytes calldata data)
- :white_check_mark: batchMint(address to, uint256 id, uint256 amount)
- :white_check_mark: batchMint(address to, uint256 id, uint256 amount, bytes calldata data)

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

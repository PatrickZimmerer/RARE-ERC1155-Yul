// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC1155 {
    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function balanceOf(
        address owner,
        uint256 tokenId
    ) external returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function batchMint(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract ERC1155Helper {
    IERC1155 public target;

    constructor(IERC1155 _target) {
        target = _target;
    }

    function setApprovalForAll(address operator, bool approved) external {
        target.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return target.isApprovedForAll(account, operator);
    }

    function balanceOf(
        address owner,
        uint256 tokenId
    ) external returns (uint256) {
        return target.balanceOf(owner, tokenId);
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        return target.balanceOfBatch(accounts, ids);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        target.mint(to, tokenId, amount, data);
    }

    function batchMint(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        target.batchMint(to, tokenIds, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        target.safeTransferFrom(from, to, tokenId, amount, data);
    }
}

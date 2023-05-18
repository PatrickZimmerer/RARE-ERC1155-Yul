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

    function mint(
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
        return target.setApprovalForAll(operator, approved);
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

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        target.mint(to, tokenId, amount, data);
    }
}

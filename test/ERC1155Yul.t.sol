// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./lib/YulDeployer.sol";
import "./lib/ERC1155Helper.sol";

interface ERC1155 {}

contract ERC1155YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    ERC1155 erc1155;
    ERC1155Helper erc1155helper;

    address alice = address(0x1337);
    address bob = address(0x42069);

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    function setUp() public {
        erc1155 = ERC1155(yulDeployer.deployContract("ERC1155Yul"));
        erc1155helper = new ERC1155Helper(IERC1155(address(erc1155)));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    function test_Test() public {
        assertEq(true, true);
    }

    // ------------------------------------------------- //
    // --------------- UNIT TESTING -------------------- //
    // ------------------------------------------------- //
    function test_Mint() public {
        erc1155helper.mint(alice, 1337, 420, "");
        uint256 balance = erc1155helper.balanceOf(alice, 1337);
        assertEq(balance, 420);
        erc1155helper.mint(alice, 1337, 420, "");
        balance = erc1155helper.balanceOf(alice, 1337);
        assertEq(balance, 840);
    }

    function test_SetApprovalForAll() public {
        erc1155helper.setApprovalForAll(alice, true);
        bool isApproved = erc1155helper.isApprovedForAll(address(this), alice);
        assertEq(isApproved, true);
        erc1155helper.setApprovalForAll(alice, false);
        isApproved = erc1155helper.isApprovedForAll(address(this), alice);
        assertEq(isApproved, false);
    }

    // ------------------------------------------------- //
    // --------------- FUZZ TESTING -------------------- //
    // ------------------------------------------------- //
    function test_Fuzz_Minting(address to, uint256 id, uint256 amount) public {
        // Bound fuzzer to nonZero values to avoid false positives
        vm.assume(to != address(0) && amount != 0 && id <= type(uint160).max);
        // we need to bound to below uint160.max since the storage would overflow
        // since the hash from storageSlot 0 is already a pretty big number so there
        // is only a certain amount of "ids" we can store from that point in storage
        erc1155helper.mint(to, id, amount, "");
        uint256 balance = erc1155helper.balanceOf(to, id);
        assertEq(balance, amount);
    }

    function test_Fuzz_SetApprovalForAll(
        address operator,
        bool isApproved
    ) public {
        vm.assume(operator != address(0));
        erc1155helper.setApprovalForAll(operator, isApproved);
        bool isOperatorApproved = erc1155helper.isApprovedForAll(
            address(this),
            operator
        );
        assertEq(isOperatorApproved, isApproved);
    }

    // ------------------------------------------------- //
    // ----------- EXPECTED REVERT TESTING ------------- //
    // ------------------------------------------------- //
    function test_Revert_MintToZeroAddress() public {
        vm.expectRevert();
        erc1155helper.mint(address(0), 1337, 420, "");
        uint256 balance = erc1155helper.balanceOf(alice, 1337);
        assertEq(balance, 0);
    }

    function test_Revert_SetApprovalForAll() public {
        vm.expectRevert();
        erc1155helper.setApprovalForAll(address(0), true);
        bool isApproved = erc1155helper.isApprovedForAll(address(this), alice);
        assertEq(isApproved, false);
    }
}

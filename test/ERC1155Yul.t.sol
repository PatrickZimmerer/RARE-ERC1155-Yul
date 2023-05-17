// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./lib/YulDeployer.sol";

interface ERC1155 {}

contract ERC1155YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    ERC1155 erc1155;

    address alice = address(0x1337);
    address bob = address(0x42069);

    function setUp() public {
        erc1155 = ERC1155(yulDeployer.deployContract("ERC1155Yul"));
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
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(0xBEEF),
            1337,
            420,
            ""
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            address(0xBEEF),
            1337
        );
        (success, data) = address(erc1155).call(callData);
        uint256 balance = abi.decode(data, (uint256));
        assertEq(balance, 420);
        callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(0xBEEF),
            1337,
            420,
            ""
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            address(0xBEEF),
            1337
        );
        (success, data) = address(erc1155).call(callData);
        balance = abi.decode(data, (uint256));
        assertEq(balance, 840);
    }

    function test_SetApprovalForAll() public {
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(0xBEEF),
            true
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "isApprovedForAll(address,address)",
            address(this),
            address(0xBEEF)
        );
        (success, data) = address(erc1155).call(callData);
        bool isApproved = abi.decode(data, (bool));
        assertEq(isApproved, true);
        callData = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(0xBEEF),
            false
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "isApprovedForAll(address,address)",
            address(this),
            address(0xBEEF)
        );
        (success, data) = address(erc1155).call(callData);
        isApproved = abi.decode(data, (bool));
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
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            to,
            id,
            amount,
            ""
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            to,
            id
        );
        (success, data) = address(erc1155).call(callData);
        uint256 balance = abi.decode(data, (uint256));
        assertEq(balance, amount);
    }

    function test_Fuzz_SetApprovalForAll(
        address operator,
        bool isApproved
    ) public {
        vm.assume(operator != address(0));
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(operator),
            isApproved
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "isApprovedForAll(address,address)",
            address(this),
            address(operator)
        );
        (success, data) = address(erc1155).call(callData);
        bool operatorApproved = abi.decode(data, (bool));
        assertEq(operatorApproved, isApproved);
    }

    // ------------------------------------------------- //
    // ----------- EXPECTED REVERT TESTING ------------- //
    // ------------------------------------------------- //
    function test_Revert_MintToZeroAddress() public {
        vm.expectRevert();
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(0),
            1337,
            420,
            ""
        );
        (success, ) = address(erc1155).call(callData);
        callData = abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            address(0xBEEF),
            1337
        );
        (success, data) = address(erc1155).call(callData);
        uint256 balance = abi.decode(data, (uint256));
        assertEq(balance, 0);
    }

    function test_Revert_SetApprovalForAll() public {
        bytes memory data;
        bool success;
        bytes memory callData = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(0xBEEF),
            true
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "isApprovedForAll(address,address)",
            address(this),
            address(0xBEEF)
        );
        (success, data) = address(erc1155).call(callData);
        bool isApproved = abi.decode(data, (bool));
        assertEq(isApproved, true);
        callData = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(0xBEEF),
            false
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        callData = abi.encodeWithSignature(
            "isApprovedForAll(address,address)",
            address(this),
            address(0xBEEF)
        );
        (success, data) = address(erc1155).call(callData);
        isApproved = abi.decode(data, (bool));
        assertEq(isApproved, false);
    }
}

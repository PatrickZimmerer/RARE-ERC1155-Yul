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
        console.logAddress(alice);
        assertEq(true, true);
    }

    function testMintToEOA() public {
        bytes memory data;
        bool success;
        // mint(address,uint256,uint256,bytes)
        bytes memory callData = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(0xBEEF),
            1337,
            420,
            ""
        );
        (success, ) = address(erc1155).call(callData);
        assertTrue(success);
        // balanceOf(address,uint256)
        callData = abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            address(0xBEEF),
            1337
        );
        (success, data) = address(erc1155).call(callData);
        uint256 bal = abi.decode(data, (uint256));
        assertEq(bal, 420);
        // assertEq(erc1155.balanceOf(address(0xBEEF), 1337), 420);
    }
}

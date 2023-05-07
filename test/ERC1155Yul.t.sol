// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./lib/YulDeployer.sol";

interface YulContract {}

contract ERC1155YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    YulContract yulContract;

    address alice = address(0x1337);
    address bob = address(0x42069);

    function setUp() public {
        yulContract = YulContract(yulDeployer.deployContract("ERC1155Yul"));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    function test_Test() public {
        console.logAddress(alice);
        assertEq(true, true);
    }
}

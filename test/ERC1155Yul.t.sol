// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "../src/ERC1155Yul.sol";

contract ERC1155YulTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x1337);
    address bob = address(0x42069);

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    function test_ConstructNonZeroTokenRevert() public {
        assertEq(true, true);
    }
}

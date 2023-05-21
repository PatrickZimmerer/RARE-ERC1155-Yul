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

    address alice = address(0x0187);
    address bob = address(0x42069);

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event URI(string _value, uint256 indexed _id);

    function setUp() public {
        erc1155 = ERC1155(yulDeployer.deployContract("ERC1155Yul"));
        erc1155helper = new ERC1155Helper(IERC1155(address(erc1155)));
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    // ------------------------------------------------- //
    // --------------- UNIT TESTING -------------------- //
    // ------------------------------------------------- //
    function test_Mint() public {
        vm.expectEmit(false, true, true, true);
        emit TransferSingle(address(this), address(0), alice, 1337, 420);
        erc1155helper.mint(alice, 1337, 420, "");
        uint256 balance = erc1155helper.balanceOf(alice, 1337);
        assertEq(balance, 420);
        erc1155helper.mint(alice, 1337, 420, "");
        balance = erc1155helper.balanceOf(alice, 1337);
        assertEq(balance, 840);
    }

    // TODO ASK QUESTIONS WHY OPERATOR IS NOT EMITTED CORRECTLY EVEN THOUGH USED AS ABOVE
    // function testBatchMintToEOAAndEmit() public {
    //     uint256[] memory ids = new uint256[](2);
    //     ids[0] = 1337;
    //     ids[1] = 1338;

    //     uint256[] memory amounts = new uint256[](2);
    //     amounts[0] = 100;
    //     amounts[1] = 200;

    //     vm.expectEmit(false, true, true, true);
    //     emit TransferBatch(address(this), address(0), alice, ids, amounts);
    //     erc1155helper.batchMint(alice, ids, amounts, "");

    //     assertEq(erc1155helper.balanceOf(alice, 1337), 100);
    //     assertEq(erc1155helper.balanceOf(alice, 1338), 200);
    // }

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        erc1155helper.batchMint(alice, ids, amounts, "");

        assertEq(erc1155helper.balanceOf(alice, 1337), 100);
        assertEq(erc1155helper.balanceOf(alice, 1338), 200);
        assertEq(erc1155helper.balanceOf(alice, 1339), 300);
        assertEq(erc1155helper.balanceOf(alice, 1340), 400);
        assertEq(erc1155helper.balanceOf(alice, 1341), 500);
    }

    function testBatchBalanceOf() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        erc1155helper.mint(address(0xBEEF), 1337, 100, "");
        erc1155helper.mint(address(0xCAFE), 1338, 200, "");
        erc1155helper.mint(address(0xFACE), 1339, 300, "");
        erc1155helper.mint(address(0xDEAD), 1340, 400, "");
        erc1155helper.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = erc1155helper.balanceOfBatch(tos, ids);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function testSafeTransferFromSelf() public {
        erc1155helper.mint(address(this), 1337, 100, "");

        erc1155helper.safeTransferFrom(
            address(this),
            address(0xBEEF),
            1337,
            70,
            ""
        );

        assertEq(erc1155helper.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(erc1155helper.balanceOf(address(this), 1337), 30);
    }

    function test_SafeTransferFromToEOA() public {
        address from = address(0xABCD);

        erc1155helper.mint(from, 1337, 100, "");

        vm.prank(from);
        erc1155helper.setApprovalForAll(address(this), true);

        vm.expectEmit(false, true, true, true);
        emit TransferSingle(address(this), from, address(0xBEEF), 1337, 70);

        erc1155helper.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(erc1155helper.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(erc1155helper.balanceOf(from, 1337), 30);
    }

    function test_SetApprovalForAll() public {
        vm.expectEmit(false, true, true, true);
        emit ApprovalForAll(address(this), alice, true);
        erc1155helper.setApprovalForAll(alice, true);
        bool isApproved = erc1155helper.isApprovedForAll(address(this), alice);
        assertEq(isApproved, true);
        erc1155helper.setApprovalForAll(alice, false);
        isApproved = erc1155helper.isApprovedForAll(address(this), alice);
        assertEq(isApproved, false);
        vm.prank(alice);
        erc1155helper.setApprovalForAll(bob, true);
        isApproved = erc1155helper.isApprovedForAll(alice, bob);
        assertEq(isApproved, true);
    }

    // ------------------------------------------------- //
    // --------------- FUZZ TESTING -------------------- //
    // ------------------------------------------------- //
    function test_Fuzz_Minting(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory mintData
    ) public {
        // Bound fuzzer to nonZero values to avoid false positives
        vm.assume(amount != 0 && id <= type(uint160).max);
        if (to == address(0)) to = alice;
        // we need to bound to below uint160.max since the storage would overflow
        // since the hash from storageSlot 0 is already a pretty big number so there
        // is only a certain amount of "ids" we can store from that point in storage
        erc1155helper.mint(to, id, amount, mintData);
        assertEq(erc1155helper.balanceOf(to, id), amount);
    }

    function test_Fuzz_SafeTransferFromToEOA(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        vm.assume(transferAmount != 0 && id <= type(uint160).max);
        if (to == address(0)) to = address(0xBEEF);
        // Bound fuzzer to nonZero values to avoid false positives

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        address from = address(0xABCD);

        erc1155helper.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        erc1155helper.setApprovalForAll(address(this), true);

        erc1155helper.safeTransferFrom(
            from,
            to,
            id,
            transferAmount,
            transferData
        );

        if (to == from) {
            assertEq(erc1155helper.balanceOf(to, id), mintAmount);
        } else {
            assertEq(erc1155helper.balanceOf(to, id), transferAmount);
            assertEq(
                erc1155helper.balanceOf(from, id),
                mintAmount - transferAmount
            );
        }
    }

    function test_Fuzz_ApproveAll(address to, bool approved) public {
        vm.assume(to != address(0));
        vm.assume(to != address(1));
        vm.assume(to != address(2));
        vm.assume(to != address(3));
        vm.assume(to != address(4));
        vm.assume(to != address(5));
        vm.assume(to != address(6));
        vm.assume(to != address(7));
        vm.assume(to != address(8));
        vm.assume(to != address(9));
        erc1155helper.setApprovalForAll(to, approved);

        assertEq(erc1155helper.isApprovedForAll(address(this), to), approved);
    }

    // ------------------------------------------------- //
    // -------------- FAIL FUZZ TESTING ---------------- //
    // ------------------------------------------------- //

    function testFail_Fuzz_MintToZero(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        erc1155helper.mint(address(0), id, amount, data);
    }

    function testFail_Fuzz_BatchMintToZero() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        erc1155helper.batchMint(address(0), ids, mintAmounts, "");
    }

    function testFail_Fuzz_BatchMintWithArrayMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;

        erc1155helper.batchMint(address(0xBEEF), ids, amounts, "");
    }

    function testFail_Fuzz_SafeTransferFromInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        transferAmount = bound(
            transferAmount,
            mintAmount + 1,
            type(uint256).max
        );

        erc1155helper.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        erc1155helper.setApprovalForAll(address(this), true);

        erc1155helper.safeTransferFrom(
            from,
            to,
            id,
            transferAmount,
            transferData
        );
    }

    function testFail_Fuzz_SafeTransferFromSelfInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(
            transferAmount,
            mintAmount + 1,
            type(uint256).max
        );

        erc1155helper.mint(address(this), id, mintAmount, mintData);
        erc1155helper.safeTransferFrom(
            address(this),
            to,
            id,
            transferAmount,
            transferData
        );
    }

    function testFail_Fuzz_SafeTransferFromToZero(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 1, mintAmount);

        erc1155helper.mint(address(this), id, mintAmount, mintData);
        erc1155helper.safeTransferFrom(
            address(this),
            address(0),
            id,
            transferAmount,
            transferData
        );
    }
}

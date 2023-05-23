// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./lib/YulDeployer.sol";

interface IERC1155 {
    // ERC-1155 standard functions
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    // must be marked back to view function
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    // custom functions
    function mint(address to, uint256 id, uint256 amount) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata
    ) external;

    function batchMint(
        address to,
        uint256[] calldata id,
        uint256[] calldata amounts
    ) external;

    function batchMint(
        address to,
        uint256[] calldata id,
        uint256[] calldata amounts,
        bytes calldata
    ) external;
}

contract ERC1155YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    IERC1155 token;

    address alice = address(0x0187);
    address bob = address(0x42069);
    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256))
        public userTransferOrBurnAmounts;

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
        token = IERC1155(yulDeployer.deployContract("ERC1155Yul"));

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    function min2(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function min3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return a > b ? (b > c ? c : b) : (a > c ? c : a);
    }

    // ------------------------------------------------- //
    // --------------- UNIT TESTING -------------------- //
    // ------------------------------------------------- //
    function testMintToSelfAndEmit() public {
        vm.expectEmit(false, true, true, true);
        emit TransferSingle(address(this), address(0), alice, 1337, 420);
        token.mint(alice, 1337, 420, "");
        uint256 balance = token.balanceOf(alice, 1337);
        assertEq(balance, 420);
        token.mint(alice, 1337, 420, "");
        balance = token.balanceOf(alice, 1337);
        assertEq(balance, 840);
    }

    function testBatchMintToEOAAndEmit() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1337;
        ids[1] = 1338;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        // TODO ASK QUESTIONS WHY IS NOT EMITTED CORRECTLY EVEN THOUGH LOG VALUE IS FINE
        //data: 0x
        // 0000000000000000000000000000000000000000000000000000000000000020 0x00 /ptr 1st array
        // 0000000000000000000000000000000000000000000000000000000000000002 0x20 /len 1st array
        // 0000000000000000000000000000000000000000000000000000000000000539 0x40 /tokenId 1337
        // 000000000000000000000000000000000000000000000000000000000000053a 0x60 /tokenId 1338
        // 00000000000000000000000000000000000000000000000000000000000000a0 0x80 /ptr 2nd array
        // 0000000000000000000000000000000000000000000000000000000000000002 0xa0 /len 2nd array
        // 0000000000000000000000000000000000000000000000000000000000000064 0xc0 /amount 100
        // 00000000000000000000000000000000000000000000000000000000000000c8 0xe0 /amount 200
        // vm.expectEmit(true, true, true, false); making last param to true fails the test... why
        vm.expectEmit(true, true, true, false);
        emit TransferBatch(address(this), address(0), alice, ids, amounts);
        token.batchMint(alice, ids, amounts, "");

        assertEq(token.balanceOf(alice, 1337), 100);
        assertEq(token.balanceOf(alice, 1338), 200);
    }

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

        token.batchMint(alice, ids, amounts, "");

        assertEq(token.balanceOf(alice, 1337), 100);
        assertEq(token.balanceOf(alice, 1338), 200);
        assertEq(token.balanceOf(alice, 1339), 300);
        assertEq(token.balanceOf(alice, 1340), 400);
        assertEq(token.balanceOf(alice, 1341), 500);
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

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(tos, ids);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function testApproveAll() public {
        vm.expectEmit(false, true, true, true);
        emit ApprovalForAll(address(this), alice, true);
        token.setApprovalForAll(alice, true);
        bool isApproved = token.isApprovedForAll(address(this), alice);
        assertEq(isApproved, true);
        token.setApprovalForAll(alice, false);
        isApproved = token.isApprovedForAll(address(this), alice);
        assertEq(isApproved, false);
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        isApproved = token.isApprovedForAll(alice, bob);
        assertEq(isApproved, true);
    }

    function testSafeTransferFromSelf() public {
        token.mint(address(this), 1337, 100, "");

        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(address(this), 1337), 30);
    }

    function test_SafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit(false, true, true, true);
        emit TransferSingle(address(this), from, address(0xBEEF), 1337, 70);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    // ------------------------------------------------- //
    // --------------- FUZZ TESTING -------------------- //
    // ------------------------------------------------- //
    function test_Fuzz_MintToEOA(
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
        token.mint(to, id, amount, mintData);
        assertEq(token.balanceOf(to, id), amount);
    }

    function testBatchMintToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max -
                userMintAmounts[to][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[to][id] += mintAmount;
        }

        token.batchMint(to, normalizedIds, normalizedAmounts, mintData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(to, id), userMintAmounts[to][id]);
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
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function test_Fuzz_SafeTransferFromToEOA(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        address from = address(0xABCD);

        vm.assume(mintAmount != 0 && id <= type(uint160).max);
        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);

        if (to == from) {
            assertEq(token.balanceOf(to, id), mintAmount);
        } else {
            assertEq(token.balanceOf(to, id), transferAmount);
            assertEq(token.balanceOf(from, id), mintAmount - transferAmount);
        }
    }

    function test_Fuzz_SafeTransferFromSelf(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        vm.assume(mintAmount != 0 && id <= type(uint160).max);
        token.mint(address(this), id, mintAmount, mintData);

        token.safeTransferFrom(
            address(this),
            to,
            id,
            transferAmount,
            transferData
        );

        assertEq(token.balanceOf(to, id), transferAmount);
        assertEq(
            token.balanceOf(address(this), id),
            mintAmount - transferAmount
        );
    }

    function test_Fuzz_BatchBalanceOf(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        uint256 minLength = min3(tos.length, ids.length, amounts.length);

        address[] memory normalizedTos = new address[](minLength);
        uint256[] memory normalizedIds = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];
            address to = tos[i] == address(0) || tos[i].code.length > 0
                ? address(0xBEEF)
                : tos[i];

            uint256 remainingMintAmountForId = type(uint256).max -
                userMintAmounts[to][id];

            normalizedTos[i] = to;
            normalizedIds[i] = id;

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);
            vm.assume(mintAmount != 0 && id <= type(uint160).max);
            token.mint(to, id, mintAmount, mintData);

            userMintAmounts[to][id] += mintAmount;
        }

        uint256[] memory balances = token.balanceOfBatch(
            normalizedTos,
            normalizedIds
        );

        for (uint256 i = 0; i < normalizedTos.length; i++) {
            assertEq(
                balances[i],
                token.balanceOf(normalizedTos[i], normalizedIds[i])
            );
        }
    }

    // ------------------------------------------------- //
    // -------------- FAIL FUZZ TESTING ---------------- //
    // ------------------------------------------------- //

    function testFail_Fuzz_MintToZero(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        token.mint(address(0), id, amount, data);
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

        token.batchMint(address(0), ids, mintAmounts, "");
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

        token.batchMint(address(0xBEEF), ids, amounts, "");
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

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);
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

        token.mint(address(this), id, mintAmount, mintData);
        token.safeTransferFrom(
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

        token.mint(address(this), id, mintAmount, mintData);
        token.safeTransferFrom(
            address(this),
            address(0),
            id,
            transferAmount,
            transferData
        );
    }

    function testFailBalanceOfBatchWithArrayMismatch() public view {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        token.balanceOfBatch(tos, ids);
    }
}

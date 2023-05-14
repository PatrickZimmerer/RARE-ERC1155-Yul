/**
 * @title ERC1155 Purely in Yul.
 * @notice This implements the ERC1155 entirely in Yul.
 * @notice EIP => https://eips.ethereum.org/EIPS/eip-1155
 * @author Patrick Zimmerer
 */

object "ERC1155Yul" {   
    /**
     * @notice Constructor
     */
    code {
        // Basic constructor
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
    /**
     * @notice Deployed contracts runtime code
     */
        code {

            /* ---------------------------------------------------------- */
            /* --------------------- SETUP STORAGE ---------------------- */
            /* ---------------------------------------------------------- */
            function balancesMappingSlot() -> p { p := 0 }  // balances of         || address => address => uint256
            function operatorApprovalSlot() -> p { p := 1 } // approved operators  || address => address => bool
            function uriLengthSlot() -> p { p := 2 } // it stores length of string passed into constructor, next slots => value

            // STORAGE LAYOUT WILL LOOK LIKE THIS
            // 0x00 - 0x20 => Scratch Space
            // 0x20 - 0x40 => Scratch Space
            // 0x40 - 0x60 => Scratch Space
            // 0x60 - 0x80 => Free memory pointer
            // 0x80 - .... => Free memory
            
            /* ------------------------------------------------------- */
            /* ----------------- FUNCTION SELECTORS ------------------ */
            /* ------------------------------------------------------- */

            switch getSelector()
            // mint(address,uint256,uint256,bytes)
            case 0x731133e9 {
                let to := decodeAsAddress(0)
                // require(to != address(0), "ERC1155: mint to the zero address");
                require(to)
                let id := decodeAsAddress(1)
                let amount := decodeAsUint(2)
                // get storage slot of the address being minted to 
                mstore(0x00, balancesMappingSlot())
                mstore(0x20, to)
                mstore(0x40, id)
                let slot := keccak256(0x00, 0x60)
                // _balances[id][to] += amount;
                let oldBalance := sload(slot)
                let newBalance := safeAdd(oldBalance, amount)
                sstore(slot, newBalance)


                // _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

                // emit TransferSingle(operator, address(0), to, id, amount);

                // _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

                // _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);

            }

            // mintBatch(address,uint256[],uint256[],bytes) 
            case 0x1f7fdffa {
                // function _batchMint(
                //     address to,
                //     uint256[] memory ids,
                //     uint256[] memory amounts,
                //     bytes memory data
                // ) internal virtual {
                //     uint256 idsLength = ids.length; // Saves MLOADs.

                //     require(idsLength == amounts.length, "LENGTH_MISMATCH");

                //     for (uint256 i = 0; i < idsLength; ) {
                //     balanceOf[to][ids[i]] += amounts[i];

                //     // An array can't have a total length
                //     // larger than the max uint256 value.
                //     unchecked {
                //         ++i;
                //     }
                // let to := decodeAsAddress(0)
                // let idsLength := 1
            }
            

            // balanceOf(address,uint256)
            case 0x00fdd58e {
                let account := decodeAsAddress(0)
                // revert if zero address
                require(account)
                let id := decodeAsAddress(1)
                // get storage slot of the address being minted to 
                mstore(0x00, balancesMappingSlot())
                mstore(0x20, account)
                mstore(0x40, id)
                let slot := keccak256(0x00, 0x60)
                let res := sload(slot)
                returnUint(res)
                // function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
                //     require(account != address(0), "ERC1155: address zero is not a valid owner");
                //     return _balances[id][account];
                // }

            }

            // balanceOfBatch(address[] memory, uint256[] memory)
            case 0x4e1273f4 {

            }

            // setApprovalForAll(address,bool)
            case 0xa22cb465 {

            }

            // isApprovedForAll(address,address)
            case 0xe985e9c5 {

            }
            
            // safeTransferFrom(address,address,uint256,uint256,bytes)
            case 0xf242432a  {

            }

            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6  {

            }
            // If no function selector was found we revert (fallback not implemented)
            default {
                revert(0, 0)
            }


            /* ---------------------------------------------------------- */
            /* -------- HELPER FUNCTIONS FOR CALLDATA DECODING  --------- */
            /* ---------------------------------------------------------- */
            // @dev grabs the function selector from the calldata
            function getSelector() -> selector {
                selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // @dev masks 12 bytes to decode an address from the calldata (address is 20bytes)
            function decodeAsAddress(offset) -> value {
                value := decodeAsUint(offset)
                if iszero(iszero(and(value, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            // @dev starts at 4th byte to skip function selector and decodes theuint of the calldata
            function decodeAsUint(offset) -> value {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                value := calldataload(pos)
            }

            /* ------------------------------------------------------- */
            /* ---------- HELPER FUNCTIONS FOR RETURN DATA ----------- */
            /* ------------------------------------------------------- */
            // @dev returns memory data (from offset, size of return value)
            // @param from (starting address in memory) to return, e.g. 0x00
            // @param to (size of the return value), e.g. 0x20 for 32 bytes 0x40 for 64 bytes
            function returnMemory(offset, size) {
                return(offset, size)
            }

            // @dev stores the value in memory 0x00 and returns that part of memory
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            // @dev helper functino that returns true (uint of 1 === true)
            function returnTrue() {
                returnUint(1)
            }

            /* ------------------------------------------------------- */
            /* -------------- UTILITY HELPER FUNCTIONS --------------- */
            /* ------------------------------------------------------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }

            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            // Overflow Protection / Safe Math 
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }

            function safeSub(a, b) -> r {
                r := sub(a, b)
                if gt(r, a) { revert(0, 0) }
            }
        }
    }

}
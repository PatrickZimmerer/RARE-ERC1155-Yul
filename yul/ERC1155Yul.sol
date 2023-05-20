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
            // functions that return the storage slots for readability later on
            function balanceOfMappingSlot() -> p { p := 0 }  // balances of         || address => address => uint256
            function isApprovedForAllMappingSlot() -> p { p := 1 } // approved operators  || address => address => bool
            function uriLengthSlot() -> p { p := 2 } // it stores length of string passed into constructor, next slots => value

            // STORAGE LAYOUT WILL LOOK LIKE THIS
            // 0x00 - 0x20 => Scratch Space
            // 0x20 - 0x40 => Scratch Space
            // 0x40 - 0x60 => Scratch Space
            // 0x60 - 0x80 => Free memory pointer
            // 0x80 - .... => Free memory
            setMemoryPointer(0x80)
            
            /* ------------------------------------------------------- */
            /* ----------------- FUNCTION SELECTORS ------------------ */
            /* ------------------------------------------------------- */

            switch getSelector()
            // -------------------------------------------------------- //
            // --------- mint(address,uint256,uint256,bytes) ---------- //
            // -------------------------------------------------------- //
            case 0x731133e9 {
                let to := decodeAsAddress(0)
                require(to)                             // checks for zero address and reverts
                // could do this in the slot getter function but didn't to improve readability
                let tokenId := decodeAsAddress(1)            
                let amount := decodeAsUint(2)           
                let slot := getNestedMappingSlot(balanceOfMappingSlot(), to, tokenId)     // get storage slot of the address
                let oldBalance := sload(slot)
                let newBalance := safeAdd(oldBalance, amount)
                sstore(slot, newBalance)
                // operator is the caller when minting, from is zero addr, rest is given as input
                emitTransferSingle(caller(), 0, to, tokenId, amount)
            }

            // -------------------------------------------------------- //
            // ---- mintBatch(address,uint256[],uint256[],bytes) ------ //
            // -------------------------------------------------------- //
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

            // -------------------------------------------------------- //
            // ------------- balanceOf(address,uint256) --------------- //
            // -------------------------------------------------------- //
            case 0x00fdd58e {
                // puts in the "account" & "tokenId" to get the value in the nested mapping
                let balanceOfUser := getBalanceOfUser(decodeAsAddress(0), decodeAsUint(1))
                // saves value to mem and returns
                returnUint(balanceOfUser)                      
            }

            // -------------------------------------------------------- //
            // -- balanceOfBatch(address[] memory, uint256[] memory) -- //
            // -------------------------------------------------------- //
            case 0x4e1273f4 {

            }

            // -------------------------------------------------------- //
            // ------------ setApprovalForAll(address,bool) ----------- //
            // -------------------------------------------------------- //
            case 0xa22cb465 {
                let operator := decodeAsAddress(0)
                let isApproved := decodeAsUint(1)
                let slot := getNestedMappingSlot(isApprovedForAllMappingSlot(), caller(), operator)
                sstore(slot, isApproved)
                emitApprovalForAll(caller(), operator, isApproved)
                return(0, 0)
            }

            // -------------------------------------------------------- //
            // ---------- isApprovedForAll(address,address) ----------- //
            // -------------------------------------------------------- //
            case 0xe985e9c5 {
                let isApproved := isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1))
                mstore(0x00, isApproved)
                return(0, 0x20)
            }
            
            // -------------------------------------------------------- //
            // safeTransferFrom(address,address,uint256,uint256,bytes)  //
            // -------------------------------------------------------- //
            case 0xf242432a  {
                let from := decodeAsAddress(0)
                let to := decodeAsAddress(1)

                let tokenId := decodeAsUint(2)
                let amount := decodeAsUint(3)
                // if sender is owner or approved for the "from" address continue
                require(iszero(or(eq(caller(), from), isApprovedForAll(from, caller()))))
                let fromSlot := getNestedMappingSlot(balanceOfMappingSlot(), from, tokenId)
                let fromBalance := sload(fromSlot)
                // check for sufficient balance 
                require(gte(fromBalance, amount))
                // check for not sending to zero address
                require(to)
                // already checked for underflow => use sub instead of safeSub
                sstore(fromSlot, sub(fromBalance, amount))
                
                let toSlot := getNestedMappingSlot(balanceOfMappingSlot(), to, tokenId)
                // sload the old balance and safeAdd "amount" for overflow protection
                sstore(toSlot, safeAdd(sload(toSlot), amount))
                emitTransferSingle(caller(), from, to, tokenId, amount)
            }

            // ---------------------------------------------------------------- //
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes) //
            // ---------------------------------------------------------------- //
            case 0x2eb2c2d6  {

            }
            // If no function selector was found we revert (fallback not implemented)
            default {
                revert(0, 0)
            }

            /* ---------------------------------------------------------- */
            /* ---------------- FREQUENTLY USED FUNCTIONS --------------- */
            /* ---------------------------------------------------------- */
            function getBalanceOfUser(account, tokenId) -> balanceOfUser {
                let slot := getNestedMappingSlot(balanceOfMappingSlot(), account, tokenId)
                balanceOfUser := sload(slot)
            }
            
            function isApprovedForAll(account,operator) -> isApproved {
                let slot := getNestedMappingSlot(isApprovedForAllMappingSlot(), caller(), operator)
                isApproved := sload(slot)
            }

            /* ---------------------------------------------------------- */
            /* ---------------- STORAGE HELPER FUNCTIONS ---------------- */
            /* ---------------------------------------------------------- */
            // gets the slot where values are stored in a nested mapping
            function getNestedMappingSlot(mappingSlot, param1, param2) -> slot {
                mstore(0x00, mappingSlot)                       // store storage slot of mapping
                mstore(0x20, param1)                            // store 1st input
                mstore(0x40, param2)                            // store 2nd input

                slot := keccak256(0x00, 0x60)                   // get hash of those => storage slot
            }

            /* ---------------------------------------------------------- */
            /* ---------------- MEMORY HELPER FUNCTIONS ----------------- */
            /* ---------------------------------------------------------- */
            // just returns the memory pointer position which is 0x60
            function getMemoryPointerPosition() -> position {
                position := 0x60
            }
            // gets the value (initialized as 0x80) stored in the memory pointer position 
            function getMemoryPointer() -> value {
                value := mload(getMemoryPointerPosition())
            }
            // advances the memory pointer value by 32 bytes (initialy 0x80 + 0x20 => 0xa0)
            function incrementMemoryPointer() {
                mstore(getMemoryPointerPosition(), add(getMemoryPointer(), 0x20))
            }
            // sets memory pointer to a given memory slot, remember default value is 0x80
            function setMemoryPointer(newSlot) {
                mstore(getMemoryPointerPosition(), newSlot)
            }

            /* ---------------------------------------------------------- */
            /* -------------- EMIT EVENTS HELPER FUNCTIONS -------------- */
            /* ---------------------------------------------------------- */
            function emitTransferSingle(operator, from, to, tokenId, amount) {
                // keccak256 of "TransferSingle(address,address,address,uint256,uint256)"
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                // use scratch space to store non indexed values from 0x00 - 0x40
                mstore(0, tokenId)
                mstore(0x20, amount)
                log4(0, 0x40, signatureHash, operator, from, to)
            }

            function emitTransferBatch(operator, from, to, tokenIds, amounts) {
                // keccak256 of "TransferBatch(address,address,address,uint256[],uint256[])"
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                
                log4(0, 0x40, signatureHash, operator, from, to)
                // TODO Store values of arrays in memory and get length to log4 later
            }

            function emitApprovalForAll(owner, operator, isApproved) {
                // keccak256 of "ApprovalForAll(address,address,bool)"
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0, isApproved)
                log3(0, 0x20, signatureHash, owner, operator)
            }

            function emitURI(stringValue, id) {
                // keccak256 of "URI(string,uint256)"
                let signatureHash := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
                // TODO Store values of arrays in memory and get length to log2 later
            }

            /* ---------------------------------------------------------- */
            /* -------- HELPER FUNCTIONS FOR CALLDATA DECODING  --------- */
            /* ---------------------------------------------------------- */
            // @dev grabs the function selector from the calldata
            function getSelector() -> selector {
                selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // @dev masks 12 bytes to decode an address from the calldata (address = 20 bytes)
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
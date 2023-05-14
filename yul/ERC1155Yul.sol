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
            function balancesMappingSlot() -> p { p := 0 }  // balances of                   || address => address => uint256
            function operatorApprovalSlot() -> p { p := 1 } // approved operators for tokens || address => address => bool
            function uriLengthSlot() -> p { p := 2 } // it stores length of string passed into constructor, next slots => value


            /* ------------------------------------------------------- */
            /* ----------------- FUNCTION SELECTORS ------------------ */
            /* ------------------------------------------------------- */

            switch findSelector()
            // mint(address,uint256,uint256,bytes)
            case 0x731133e9 {

            }

            // mintBatch(address,uint256[],uint256[],bytes) 
            case 0x1f7fdffa {

            }

            // balanceOf(address,uint256)
            case 0x00fdd58e {

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
            case 0xf242432a  {

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

        }
    }

}
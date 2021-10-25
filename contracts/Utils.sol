
//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

/********************************************************************************************************
    Library
    Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
    A library is embedded into the contract if all library functions are internal.
    Otherwise the library must be deployed and then linked before the contract is deployed.
    https://solidity-by-example.org/
*********************************************************************************************************/

library Utils {

    /*  
        Addresses

        In a blockchain, addresses are unique identifiers associated with an entity, a wallet or a smart 
        contract. They are usually composed of an alphanumeric string with between 26 and 35 characters. 
        In the Bitcoin case, the address is a 160-bit hash of the public key generated from the ECDSA 
        private key.

        The address and the public key can be shared with anyone with no security restrictions. On the 
        other hand, the private key cannot be shared and should be kept secure (unless you want to lose 
        all your money).

        In most blockchains, the address derives from the public key, and there are 3 simple steps to 
        create an address:

        1-  Creating a private key (ECDSA)
        2-  Take the public key from the private key (Public Key Infrastructure always have private/public 
            key pairs)
        3-  Hash the public key to generate the address
    */


    // require  evmVersion: "petersburg" for address.codehash function
    function isContractExt(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash = account.codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        //assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    // https://docs.soliditylang.org/en/v0.5.3/assembly.html#example
    // provides library code to access the code of another contract and load it into a bytes variable.
    // This is not possible with “plain Solidity” and the idea is that assembly libraries will be used
    // to enhance the Solidity language.
    function at(address _addr) internal view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    // convert a bytes or public key representation to an address
    function BytesToAddress(bytes memory pub) internal pure returns (address addr) {
        bytes32 hash = keccak256(pub);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }

    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }
        return tempUint;
    }

    // https://2π.com/17/chinese-remainder-theorem/
    function chineseRemainder(uint256 x0, uint256 x1) public pure returns (uint256 r0, uint256 r1) {
        assembly {
            r0 := x0
            r1 := sub(sub(x1, x0), lt(x1, x0))
        }
    }

}
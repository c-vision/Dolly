// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMathQuad.sol

/********************************************************************************************************
    Library
    Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
    A library is embedded into the contract if all library functions are internal.
    Otherwise the library must be deployed and then linked before the contract is deployed.
    https://solidity-by-example.org/
*********************************************************************************************************/

library Math {

    // taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    // no changes required
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    //https://2π.com/21/muldiv/index.html
    // taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    // ported to Solidity 0.8.6
    function fullDiv(uint256 l, uint256 h, uint256 d) private pure returns (uint256) {
        uint256 pow2 = d & (~d + 1);
        uint256 negatepow2 = pow2 & (~pow2 + 1);
        d /= pow2;
        l /= pow2;
        l += h * (negatepow2 / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    /**
    * Get index of the most significant non-zero bit in binary representation of
    * x.  Reverts if x is zero.
    *
    * @return index of the most significant non-zero bit in binary representation
    *         of x
    */
    function mostSignificantBit (uint256 x) private pure returns (uint256) {
        unchecked {
            require (x > 0);

            uint256 result = 0;

            if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
            if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
            if (x >= 0x100000000) { x >>= 32; result += 32; }
            if (x >= 0x10000) { x >>= 16; result += 16; }
            if (x >= 0x100) { x >>= 8; result += 8; }
            if (x >= 0x10) { x >>= 4; result += 4; }
            if (x >= 0x4) { x >>= 2; result += 2; }
            if (x >= 0x2) result += 1; // No need to shift x anymore

            return result;
        }
    }

    /**
    * Convert signed 256-bit integer number into quadruple precision number.
    *
    * @param x signed 256-bit integer number
    * @return quadruple precision number
    */
    function fromInt (int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16 (0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint256 (x > 0 ? x : -x);

                uint256 msb = mostSignificantBit (result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16 (uint128 (result));
            }
        }
    }

    /**
    * Convert quadruple precision number into unsigned 256-bit integer number
    * rounding towards zero.  Revert on underflow.  Note, that negative floating
    * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
    * without error, because they are rounded to zero.
    *
    * @param x quadruple precision number
    * @return unsigned 256-bit integer number
    */
    function toUInt (bytes16 x) internal pure returns (uint256) {
        unchecked {
            uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

            if (exponent < 16383) return 0; // Underflow

            require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

            require (exponent <= 16638); // Overflow
            uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
                0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            return result;
        }
    }

    /**
    * Generate a predictable rundom number which is anyway hard to detect
    * https://stackoverflow.com/questions/58188832/solidity-generate-unpredictable-random-number-that-does-not-depend-on-input
    */
    function randomNumber(uint256 limit, uint256 nonce) internal view returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty + nonce +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
        //return (seed - ((seed / 1000) * limit));
        return seed % limit;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = a + m;
        uint256 d = c - 1;
        return (d/m) * m;
    }

    function onePercent(uint256 _value) public pure returns (uint256)  {
        return ceil(_value, 100) * 100 / 10000;
    }

    // https://github.com/ethereum/dapp-bin/blob/master/library/math.sol
    /// @dev Computes the modular exponential (x ** k) % m.
    function modExp(uint x, uint k, uint m) public pure returns (uint r) {
        r = 1;
        for (uint s = 1; s <= k; s *= 2) {
            if (k & s != 0)
                r = mulmod(r, x, m);
            x = mulmod(x, x, m);
        }
    }

    // Newton's method https://en.wikipedia.org/wiki/Cube_root#Numerical_methods
    function cubeRoot(uint256 y) internal pure returns (uint256 z) {
        if (y > 7) {
            z = y;
            uint256 x = y / 3 + 1;
            while (x < z) {
                z = x;
                x = (y / (x * x) + (2 * x)) / 3;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // https://github.com/aave/markets-adapters/blob/master/contracts/misc/MathUtils.sol
    /**
     * @notice Returns the square root of an uint256 x
     * - Uses the Babylonian method, but using (x + 1) / 2 as initial guess in order to have decreasing guessing iterations
     * which allow to do z < y instead of checking that z*z is within a range of precision respect to x
     * @param x The number to calculate the sqrt from
     * @return The root
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/Babylonian.sol
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrtUniswap(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    // fibonacci calculation
    function fib(uint256 N, uint256 f0, uint256 f1) external pure returns (uint256) {
        if (N == 0) return f0;
        if (N == 1) return f1;
        uint256 fN;
        for (uint256 i = 0; i < N - 1; i++) {
            fN = f0 + f1;
            require(fN >= f1);  // overflow
            f0 = f1;
            f1 = fN;
        }
        return fN;
    }
    
}

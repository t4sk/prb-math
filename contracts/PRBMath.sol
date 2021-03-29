// SPDX-License-Identifier: MIT
// solhint-disable code-complexity, func-name-mixedcase
pragma solidity >=0.8.0;

import "hardhat/console.sol";

/// @title PRBMath
/// @author Paul Razvan Berg
/// @notice Smart contract library for mathematical functions. Works with int256 numbers considered to have 18
/// decimals. We call this format decimal 59.18 fixed-point numbers, since there can be up to 59 digits in the
/// integer part and up to 18 digits in the fractional part.
library PRBMath {
    /// @dev Half the UNIT number.
    int256 internal constant HALF_UNIT = 5e17;

    /// @dev The maximum value a 59.18 decimal fixed-point number can have.
    int256 internal constant MAX_59x18 = type(int256).max;

    /// @dev The maximum whole value a 59.18 decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_59x18 = type(int256).max - (type(int256).max % UNIT);

    /// @dev The minimum value a 59.18 decimal fixed-point number can have.
    int256 internal constant MIN_59x18 = type(int256).min;

    /// @dev The minimum whole value a 59.18 decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_59x18 = type(int256).min - (type(int256).min % UNIT);

    /// @dev Twice the UNI number.
    int256 internal constant TWICE_UNIT = 2e18;

    /// @dev Constant that determines how many decimals can be represented.
    int256 internal constant UNIT = 1e18;

    /// PURE FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - `x` must be higher than min 59.18.
    ///
    /// @param x The number to calculate the absolute for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        require(x > MIN_59x18);
        return x < 0 ? -x : x;
    }

    /// @notice Yields the least integer greater than or equal to x.
    ///
    /// @dev See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions
    ///
    /// Requirements:
    /// - `x` must be less than or equal to the maximum whole value allowed by the 59.18 decimal fixed-point format.
    ///
    /// @param x The 59.18 decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x.
    function ceil(int256 x) internal pure returns (int256 result) {
        require(x <= MAX_WHOLE_59x18);
        if (x % UNIT == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a value with the same sign as x.
            result = x - (x % UNIT);
            if (x > 0) {
                result += UNIT;
            }
        }
    }

    function div(int256 x, int256 y) internal pure returns (int256 result) {
        int256 scaledNumerator = x * UNIT;
        result = scaledNumerator / y;
    }

    function exp(int256 x) internal pure returns (int256 result) {
        x;
        result = 0;
    }

    function exp2(int256 x) internal pure returns (int256 result) {
        x;
        result = 0;
    }

    /// @notice Yields the greatest integer less than or equal to x.
    ///
    /// @dev See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions
    ///
    /// Requirements:
    /// - `x` must be greater than or equal to the minimum whole value allowed by the 59.18 decimal fixed-point format.
    ///
    /// @param x The 59.18 decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x.
    function floor(int256 x) internal pure returns (int256 result) {
        require(x >= MIN_WHOLE_59x18);
        if (x % UNIT == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a value with the same sign as x.
            result = x - (x % UNIT);
            if (x < 0) {
                result -= UNIT;
            }
        }
    }

    /// @notice Yields the excess beyond x's floored value for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The 59.18 decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a 59.18 decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        result = x % UNIT;
    }

    /// @dev See https://stackoverflow.com/a/600306/3873510.
    function isPowerOfTwo(uint256 x) internal pure returns (bool result) {
        require(x > 0);
        result = (x & (x - 1)) == 0;
    }

    /// @notice Based on the insight that ln(x) = log2(x) * ln(2).
    ///
    /// Requirements:
    /// - All from `log2`.
    ///
    /// Caveats:
    /// - All from `log2`.
    /// - This doesn't return exactly 1 for 2.718281828459045235, we would need more fine-grained precision for that.
    ///
    /// @param x The 59.18 decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a 59.18 decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        require(x > 0);
        int256 ln_2 = 693147180559945309;
        result = mul(log2(x), ln_2);
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - `x` must be higher than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal digit, because of the iterative approximation.
    ///
    /// @param x The 59.18 decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a 59.18 decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        require(x > 0);

        // TODO: explain this
        int256 sign;
        if (x >= UNIT) {
            sign = 1;
        } else {
            sign = -1;
            x = div(UNIT, x);
        }

        // Calculate the integer part n, add it to the result and finally calculate y = x * 2^(-n).
        uint256 quotient = uint256(x / UNIT);
        uint256 n = mostSignificantBit(quotient);
        result = int256(n) * UNIT * sign;
        int256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == UNIT) {
            return result;
        }

        // Calculate the fractional part via the iterative approximation.
        int256 delta;
        for (delta = HALF_UNIT; delta > 0; delta >>= 1) {
            // TODO: replace this with "mul"
            y = (y * y) / UNIT;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= TWICE_UNIT) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta * sign;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
    }

    /// @notice Finds the zero-based index of the first zero in the binary representation of x.
    /// @dev See the "Find First Set" article on Wikipedia https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the most significant bit.
    /// @return msb The most significant bit.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        int256 doubleScaledProduct = x * y;

        // Before dividing, we add half the UNIT for positive numbers and subtract half the UNIT for negative numbers,
        // so that we get rounding instead of truncation. Without this, 6.6e-19 would be truncated to 0 instead of being
        // rounded to 1e-18. See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        int256 doubleScaledProductWithHalfUnit;
        if (x > 0) {
            doubleScaledProductWithHalfUnit = doubleScaledProduct + HALF_UNIT;
        } else {
            doubleScaledProductWithHalfUnit = doubleScaledProduct - HALF_UNIT;
        }

        result = doubleScaledProductWithHalfUnit / UNIT;
    }

    /// @dev See https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/FullMath.sol.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        a;
        b;
        denominator;
        result = 0;
    }

    /// @dev See https://stackoverflow.com/a/1322548/3873510.
    function nextPowerOfTwo(uint256 x) internal pure returns (uint256 npot) {
        require(x > 0);
        npot = x - 1;
        npot |= npot >> 1;
        npot |= npot >> 2;
        npot |= npot >> 4;
        npot |= npot >> 8;
        npot |= npot >> 16;
        npot |= npot >> 32;
        npot |= npot >> 64;
        npot |= npot >> 128;
        npot += 1;
    }

    function sqrt(int256 x) internal pure returns (int256 result) {
        x;
        result = 0;
    }

    /// @notice Returns Euler's number in 59.18 decimal fixed-point representation.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2718281828459045235;
    }

    /// @notice Returns PI in 59.18 decimal fixed-point representation.
    function pi() internal pure returns (int256 result) {
        result = 3141592653589793238;
    }

    /// @notice Returns 1 in 59.18 decimal fixed-point representation.
    function unit() internal pure returns (int256 result) {
        result = UNIT;
    }
}

----------------------------------------------------------------------------------
-- Author: Daniele Giardino
--
-- Date: 2024.02.20
-- Description:
--   This package, `pkg_vhdl_toolbox`, provides a collection of utility functions and
--   data types designed to simplify mathematical operations and data conversions
--   within VHDL designs. It includes functions for logarithmic calculations,
--   reciprocal approximation, fixed-point conversion from real numbers, and
--   high-precision real-to-string conversion for simulation and debugging.
--   Additionally, it defines custom complex number data types for std_logic_vector,
--   signed, and unsigned representations.
--
-- Design:
--
-- Revision:
--   2024.02.20 - File Created
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

package pkg_vhdl_toolbox is

  -- FUNCTIONS
  function log2(i : natural) return natural;
  function inv(a  : real) return real;
  function flp_to_fxp (
    x  : real; -- Input floating-point number
    Wl : integer; -- Total word length (number of bits)
    Fl : integer -- Fractional length (number of bits)
  ) return std_logic_vector;
  function real_to_string_full_precision (real_val : real; frac_chars : integer) return string;
  function get_gcd (a : positive; b : positive) return positive;
  function get_lcm (a : positive; b : positive) return positive;

  -- TYPES
  type t_complex_std_vec16 is record
    re : std_logic_vector(15 downto 0);
    im : std_logic_vector(15 downto 0);
  end record;

  type t_complex_int16 is record
    re : signed(15 downto 0);
    im : signed(15 downto 0);
  end record;

  type t_complex_uint16 is record
    re : unsigned(15 downto 0);
    im : unsigned(15 downto 0);
  end record;

end package;

package body pkg_vhdl_toolbox is

  -- FUNCTIONS
  -- Log2. Since the input is a positive integer,
  -- the return value is 'floor(log2(x))'.
  function log2(i  : natural) return natural is
    variable temp    : natural := i;
    variable ret_val : natural := 0;
  begin
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;
    end loop;
    return ret_val;
  end function;

  -- Reciprocal
  function inv(a : real) return real is
    variable x     : real := a;
    --variable Thr  : real := 5.9605e-08;  -- pow(2,-24)
    variable h : real := 0.0;
  begin
    while (a * x > 1.0) loop
      x := x * 0.5;
    end loop;

    for n in 0 to 19 loop
      h := 1.0 - a * x;
      x := x * (1.0 + h * (1.0 + h));
    end loop;
    return x;
  end function;

  ----------------------------------------------------------------------------------
  -- Function: flp_to_fxp
  --
  -- Description:
  --   This function converts a real (floating-point) number to a fixed-point
  --   representation using a specified word length (Wl) and fractional length (Fl).
  --   It handles saturation for out-of-range values, performs scaling and rounding,
  --   and converts the resulting value into a binary fixed-point representation.
  --
  -- Parameters:
  --   x  : real; -- Input floating-point number to be converted.
  --   Wl : integer; -- Total word length (number of bits) of the fixed-point output.
  --   Fl : integer; -- Fractional length (number of bits) of the fixed-point output.
  --
  -- Return Value:
  --   std_logic_vector(Wl-1 downto 0); -- The fixed-point representation of the input real number.
  --
  -- Functionality:
  --   1. Calculates the maximum (x_max) and minimum (x_min) representable
  --      values based on the provided Wl and Fl.
  --   2. Implements saturation logic:
  --      - If x is greater than or equal to x_max, the output is set to the
  --        maximum positive fixed-point value (sign bit '0', all other bits '1').
  --      - If x is less than or equal to x_min, the output is set to the
  --        minimum negative fixed-point value (sign bit '1', all other bits '0').
  --      - If x is equal to 0, the output is set to all '0's.
  --   3. Scales the input x by 2^Fl to shift the binary point.
  --   4. Rounds the scaled value:
  --      - For positive scaled values, it adds 0.5 and truncates to an integer.
  --      - For negative scaled values, it takes the absolute value of (scaled_x),
  --        adds 0.5, truncates to an integer, and negates the result.
  --   5. Performs binary conversion:
  --      - Iterates through each bit position (0 to Wl-1).
  --      - Calculates the remainder when the scaled value is divided by 2.
  --      - Sets the corresponding bit in the output to '1' if the remainder is 1, '0' otherwise.
  --      - Divides the scaled value by 2 for the next iteration.
  --   6. Returns the resulting std_logic_vector representing the fixed-point number.
  --
  -- Notes:
  --   - This function uses real data types for intermediate calculations, which
  --     will be translated to fixed-point or floating-point hardware during synthesis.
  --   - A testbench is required to verify the functionality of this function.
  --   - The precision of the conversion depends on the Wl and Fl parameters.
  --   - The std.textio library can be used for debugging by printing intermediate values.
  ----------------------------------------------------------------------------------
  function flp_to_fxp (
    x  : real; -- Input floating-point number
    Wl : integer; -- Total word length (number of bits)
    Fl : integer -- Fractional length (number of bits)
  ) return std_logic_vector is
    variable flag_report  : boolean := false; -- If it is true, 'report' function is used to debug the function
    variable x_dbg        : real; -- Variable used to debug the function
    variable x_max        : real; -- Maximum representable value (real)
    variable x_min        : real; -- Minimum representable value (real)
    variable x_scaled     : real; -- Scaled input value (real)
    variable x_rem        : real; -- Remainder during binary conversion (real)
    variable result       : std_logic_vector(Wl - 1 downto 0); -- Resulting fixed-point representation
    variable abs_x_scaled : real; -- Absolute value of scaled x

  begin

    -- Calculate max and min representable values
    x_max := + (2.0 ** (real(Wl-Fl) - 1.0)) - (1.0 / (2.0 **real(Fl)));   -- Max value: +2^(Wl-1) - 1 - 2^(-Fl)
    x_min := - (2.0 ** (real(Wl-Fl) - 1.0)) + (1.0 / (2.0 ** real(Fl)));  -- Min value: -2^(Wl-1) + 2^(-Fl)

    -- Saturation logic
    if x >= x_max then
      result(Wl - 1) := '0'; -- Set sign bit to 0 (positive)
      for i in 1 to Wl - 1 loop
        result(Wl - 1 - i) := '1'; -- Set all other bits to 1 (max positive)
      end loop;
      return result;
    elsif x <= x_min then
      result(Wl - 1) := '1'; -- Set sign bit to 1 (negative)
      for i in 1 to Wl - 1 loop
        result(Wl - 1 - i) := '0'; -- Set all other bits to 0 (min negative)
      end loop;
      return result;
    elsif x = 0.0 then
      result := (others => '0'); -- If x is 0, set all bits to 0
      return result;
    end if;

    -- Scaling
    x_scaled := x;

    if flag_report=True then
      x_dbg := 0.9;
    end if;
    for i in 0 to Fl-1 loop
      x_scaled := x_scaled * 2.0;
        if flag_report=True and x=x_dbg then
          report 
            "++++++++++++++++ " &
            "i=" & integer'image(i) & " | " &
            "x=" & real'image(x) & " | " &
            "x_scaled" & real'image(x_scaled) & " | " &
            "x_scaled=" & real_to_string_full_precision(x_scaled, 10) &
            " ++++++++++++++++"
          severity note;
        end if;
    end loop;
    if flag_report=True and x=x_dbg then
      report 
        "++++++++++++++++ " &
        "x=" & real'image(x) & " | " &
        "x_scaled=" & real_to_string_full_precision(x_scaled, 0) &
        " ++++++++++++++++"
      severity note;
    end if;

    -- Rounding
    if x_scaled > 0.0 then  -- Round positive values
      x_scaled := floor(x_scaled + 0.5) ; 
    else                    -- Round negative values
      abs_x_scaled := x_scaled * SIGN(x_scaled);
      abs_x_scaled := floor(abs_x_scaled + 0.5);
      x_scaled     := abs_x_scaled * (-1.0); 
    end if;
    
    -- Binary conversion for the integer part.
    for i in 0 to Wl - 1 loop
      
      x_rem := x_scaled/2.0 - floor(x_scaled/2.0);
      
      if abs(x_rem) = 0.5 then
        result(i) := '1'; -- Set bit to 1 if remainder is 1
      else
        result(i) := '0'; -- Set bit to 0 if remainder is 0
      end if;

      x_scaled := floor(x_scaled / 2.0); -- Divide by 2 for next bit
    end loop;

    return result;

  end function flp_to_fxp;


  ----------------------------------------------------------------------------------
  -- Function: real_to_string_full_precision
  --
  -- Description:
  --   This function converts a real (floating-point) number into a string representation,
  --   aiming to provide a detailed and precise output. It separates the real number
  --   into its integer and fractional components, then constructs a string by
  --   concatenating the sign, integer part, decimal point, and fractional part.
  --   The function allows specifying the desired number of fractional digits in the
  --   resulting string.
  --
  -- Parameters:
  --   real_val   : real;    -- The real number to be converted into a string.
  --   frac_chars : integer; -- The number of digits to include in the fractional part of the string.
  --
  -- Return Value:
  --   string; -- The string representation of the input real number.
  --
  -- Functionality:
  --   1. Determines the sign of the input 'real_val' and stores it in 'sign_str'.
  --   2. Separates the input into integer and fractional parts using 'floor'.
  --   3. Calculates the number of digits in the integer part using logarithms.
  --   4. Converts the integer part into a string by iteratively extracting digits.
  --   5. Converts the fractional part into a string by iteratively extracting digits,
  --      up to the number specified by 'frac_chars'.
  --   6. Concatenates the sign, integer part, decimal point, and fractional part to
  --      form the final string.
  --
  -- Notes:
  --   - This function is primarily intended for simulation and debugging, where a
  --     detailed string representation of real numbers is needed.
  --   - The precision of the output string is limited by the inherent precision of
  --     the 'real' data type used in VHDL.
  --   - The function handles both positive and negative real numbers, including zero.
  --   - The length of the 'int_str' and 'frc_str' variables should be sufficient to
  --     accommodate the expected number of digits.
  --   - This implementation relies on iterative digit extraction, which may not be
  --     the most efficient approach for all scenarios.
  ----------------------------------------------------------------------------------
  function real_to_string_full_precision (real_val : real; frac_chars : integer) return string is
      
      
      variable abs_val  : real;
      variable int_part : real;
      variable frc_part : real;

      variable x          : real;
      variable x_int      : integer;
      variable int_chars  : integer;

      variable sign_str : string(1 to 1);
      variable int_str  : string(1 to 100);
      variable tmp_char : string(1 to 1);
      variable frc_str  : string(1 to frac_chars);

  begin
      -- Handle sign
      if real_val < 0.0 then
          sign_str := "-";
          abs_val := -real_val;
      else
          sign_str := "+";
          abs_val := real_val;
      end if;

      -- Separate integer and fractional parts
      int_part := floor(abs_val);
      frc_part := abs_val-int_part;

      -- Find the integers chars
      if abs_val>0.0 then
        int_chars := INTEGER(CEIL(LOG10(abs_val)));
      else
        int_chars := 0;
      end if;

      x := int_part / (10.0**real(int_chars-1));

      for i in 1 to int_chars loop
        x_int       := integer(floor(x));
        tmp_char    := integer'image(x_int);
        int_str(i)  := tmp_char(1);
        x := (x-real(x_int)) * 10.0;
      end loop;

      -- Find the fractional chars
      x := frc_part * 10.0;
      for i in 1 to frac_chars loop
        x_int       := integer(floor(x));
        tmp_char    := integer'image(x_int);
        frc_str(i)  := tmp_char(1);
        x := (x-real(x_int)) * 10.0;
      end loop;

      return sign_str & int_str(1 to int_chars+1) & "." & frc_str;
  end function real_to_string_full_precision;


----------------------------------------------------------------------------
  -- Calculates the Greatest Common Divisor (GCD) using the Euclidean algorithm.
  -- This runs at compile-time to determine generic parameters.
  ----------------------------------------------------------------------------
  function get_gcd (a : positive; b : positive) return positive is
    variable temp_a    : natural := a;
    variable temp_b    : natural := b;
    variable remainder : natural;
  begin
    while temp_b /= 0 loop
      remainder := temp_a rem temp_b;
      temp_a    := temp_b;
      temp_b    := remainder;
    end loop;
    return temp_a;
  end function get_gcd;

  ----------------------------------------------------------------------------
  -- Calculates the Least Common Multiple (LCM) of two positive integers.
  -- Divides first to prevent integer overflow during compile-time evaluation.
  ----------------------------------------------------------------------------
  function get_lcm (a : positive; b : positive) return positive is
  begin
    -- Using positive types ensures inputs are always greater than 0
    return (a / get_gcd(a, b)) * b;
  end function get_lcm;


end package body;

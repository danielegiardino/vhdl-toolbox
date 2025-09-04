-- ============================================================================
-- File        : lfsr_fib.vhd
-- Author      : La Cesa Riccardo
-- Date        : 20/08/2025
-- Description : Fibonacci LFSR (Linear Feedback Shift Register) in VHDL.
--               It uses a specified width, feedback taps, and seed value.
--               The LFSR generates a pseudo-random sequence based on the defined parameters.
-- ============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_fib is
    generic (
        lfsr_width      : integer := 32;                                    -- Width of the LFSR
        data_out_width  : integer := 16;                                    -- Width of the output data  (data_out_width <= lfsr_width)
        lfsr_taps       : std_logic_vector(32-1 downto 0) := x"80200006";   -- mask for feedback taps. Example: WIDTH=32, poly:(x^32+x^22+x^2+x+1), taps: x"80200006" (binary: 1000 0000 0010 0000 0000 0000 0000 0110)
        lfsr_seed       : std_logic_vector(32-1 downto 0) := x"00000001"    -- must be =! 0
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        enb        : in  std_logic;
        lfsr_out   : out std_logic_vector(data_out_width-1 downto 0);       
        lfsr_valid : out std_logic
    );
end lfsr_fib;

architecture rtl of lfsr_fib is

    signal lfsr_reg       : std_logic_vector(lfsr_width-1 downto 0);     -- Internal LFSR register
    signal lfsr_valid_int : std_logic_vector(data_out_width-1 downto 0); -- Internal valid delay chain. lfsr has data_out_width cycles of latency
    signal feedback_bit   : std_logic;                                   -- Feedback bit for LFSR

begin

    -- delay chain process to shift the LFSR bits, when reset is active, the LFSR is set to the seed value
    del_chain_proc : process(clk) 
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr_reg <= lfsr_seed; -- Reset LFSR to seed value;
            elsif enb = '1' then
                lfsr_reg(0) <= feedback_bit; -- Update the first bit with feedback
                for i in 1 to lfsr_width-1 loop
                    lfsr_reg(i) <= lfsr_reg(i-1); -- Shift the LFSR bits
                end loop;
            end if;
        end if;
    end process;

    -- feedback process to calculate the feedback bit based on the taps
    feedback_proc : process(lfsr_reg)
    variable temp_feedback : std_logic; -- Temporary variable to hold the feedback bit
    begin
        temp_feedback := '0'; -- Initialize feedback bit to '0'
        for i in 0 to lfsr_width-1 loop
            if  lfsr_taps(i) = '1' then
                temp_feedback  := temp_feedback xor lfsr_reg(i); -- XOR feedback bits based on taps
            end if;
        end loop;
        feedback_bit <= temp_feedback; -- Assign the calculated feedback bit
    end process;

    -- Output assignments
    lfsr_out <= lfsr_reg(data_out_width-1 downto 0); -- Assign the output data from the LSB of the LFSR

    -- ===========================================================================================================================
    -- dout_valid process to manage the valid signal for the output data:
    -- 1) when the LFSR is resetted the random generation starts from seed value. 
    -- 2) when enabled the lfsr starts to generate random number.
    --    there is a latency equal to data_out_width bits because 
    --    we have to wait that the zeros are shifted out of the LFSR.
    -- 3) when desabled the output mantein its last value and enable is 0
    -- 4) when enabled again the output starts to change,
    --    in this case enable is directly 1 with no latency because there are no zeros to shift out 
    -- ===========================================================================================================================
    
    dout_valid_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr_valid_int <= (others => '0');
            elsif enb = '1' then
                lfsr_valid_int(0) <= '1';
                for i in 1 to data_out_width-1 loop
                    lfsr_valid_int(i) <= lfsr_valid_int(i-1);
                end loop;
            else
                lfsr_valid_int(data_out_width-1) <= '0';
            end if;
        end if;
    end process;
    -- Assign the last bit of the internal valid signal to the output valid signal
    lfsr_valid <= lfsr_valid_int(data_out_width-1);


end architecture;
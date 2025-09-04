-- ============================================================================
-- File        : lfsr_gal.vhd
-- Author      : La Cesa Riccardo
-- Date        : 29/08/2025
-- Description : TB for the Galois LFSR (Linear Feedback Shift Register) in VHDL.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_gal is
    generic (
        lfsr_width      : integer := 16;                                    -- Width of the LFSR
        data_out_width  : integer := 8;                                     -- Width of the output data  (data_out_width <= lfsr_width)
        lfsr_taps       : std_logic_vector(15 downto 0) := x"B400";   -- mask for feedback taps. Example: WIDTH=16, poly:(x^16+x^14+x^13+x^11+1), taps: x"B400" (binary: 1011 0100 0000 0000)
        lfsr_seed       : std_logic_vector(15 downto 0) := x"0001"    -- must be =! 0
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        enb          : in std_logic;
        lfsr_out    : out std_logic_vector(data_out_width-1 downto 0);       
        lfsr_valid  : out std_logic
    );
end lfsr_gal;

architecture rtl of lfsr_gal is

    signal lfsr_reg       : std_logic_vector(lfsr_width-1 downto 0);     -- Internal LFSR register
    signal lfsr_valid_int : std_logic_vector(data_out_width-1 downto 0); -- Internal valid delay chain. lfsr has data_out_width cycles of latency

begin

    
    -- delay chain process to shift the LFSR bits, when reset is active, the LFSR is set to the seed value
    lfsr_process : process(clk) 
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr_reg <= lfsr_seed; -- Reset LFSR to seed value;
            elsif enb = '1' then
                lfsr_reg(lfsr_width-1) <= lfsr_reg(0); -- Update the MSB bit with feedback
                for i in lfsr_width-2 downto 0 loop
                    if lfsr_taps(i) = '1' then
                        lfsr_reg(i) <= lfsr_reg(i+1) xor lfsr_reg(0); -- Shift the LFSR bits with XOR feedback
                    else
                        lfsr_reg(i) <= lfsr_reg(i+1); -- Shift the LFSR bits without feedback
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- valid process
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

    -- Output assignments
    -- if data_out_width=1 output is lfsr_valid_int(0);
    -- if data_out_width>1 output is lfsr_reg(data_out_width-1 downto 0);

    dOutWlIs0_GEN: if data_out_width=1 generate
    begin
        lfsr_valid <= lfsr_valid_int(0);
    end generate;

    dOutWlIsNot0_GEN: if data_out_width>1 generate
    begin
    lfsr_out <= lfsr_reg(data_out_width-1 downto 0); 
    end generate;

    -- valid out assignment
    lfsr_valid <= lfsr_valid_int(data_out_width-1);

end architecture;
-- ============================================================================
-- File        : lfsr_gal_tb.vhd
-- Author      : La Cesa Riccardo
-- Date        : 29/08/2025
-- Description : TB for the Galois LFSR (Linear Feedback Shift Register) in VHDL.
-- ============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity lfsr_gal_tb is
end lfsr_gal_tb;

architecture sim of lfsr_gal_tb is

    -- Clock parameters
    constant clk_hz     : integer := 100e6;
    constant clk_period : time    := 1 sec / clk_hz;

    -- LFSR parameters
    constant lfsr_width      : integer := 16;                              -- Width of the LFSR
    constant data_out_width  : integer := 8;                               -- Width of the output data  (data_out_width <= lfsr_width)
    constant lfsr_taps       : std_logic_vector(15 downto 0) := x"B400";   -- mask for feedback taps. Example: WIDTH=16, poly:(x^16+x^14+x^13+x^11+1), taps: x"B400" (binary: 1011 0100 0000 0000)
    constant lfsr_seed       : std_logic_vector(15 downto 0) := x"0001"; -- must be /= 0
   
    -- File paths for output data
    constant fileDataOut : string := "../../../../../random_generator/Galois_LFSR/testbench/data_out.txt";


    signal clk        : std_logic := '1';
    signal rst        : std_logic := '1';
    signal enb        : std_logic := '0';
    signal lfsr_out   : std_logic_vector(data_out_width-1 downto 0);
    signal lfsr_valid : std_logic;


begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.lfsr_gal
    generic map (
        lfsr_width      => lfsr_width,
        data_out_width  => data_out_width,
        lfsr_taps       => lfsr_taps,
        lfsr_seed       => lfsr_seed
    )
    port map (
        clk         => clk,
        rst         => rst,
        enb         => enb,
        lfsr_out    => lfsr_out,
        lfsr_valid  => lfsr_valid   
    );



    SEQUENCER_PROC : process
    begin


      -- Reset and enable sequence
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period * 2;
        enb <= '1'; -- Enable the LFSR
        wait for clk_period * 50;
        enb <= '0'; -- Disable the LFSR
        wait for clk_period * 10;
        enb <= '1'; -- Re-enable the LFSR

        -- Let the simulation run for a long time to check the statistic of the output
        wait for clk_period * 1*10**6;

        finish;
    end process;


---------- Write Process ----------
  process(clk)
    file out_stream : text open write_mode is fileDataOut;
    variable row    : line;
  begin
    if rising_edge(clk) then
      if lfsr_valid ='1' then
        write(row, to_bitvector(lfsr_out));
        writeline(out_stream,row);
      end if;
    end if;
  end process;


end architecture;
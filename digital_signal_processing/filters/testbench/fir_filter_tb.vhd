----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2024.03.08
-- Description: 
--   Test Bench.
-- 
-- Design:
-- 
-- Revision:
--   0.01 - File Created
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity fir_filter_tb is
end fir_filter_tb;

architecture sim_noSym of fir_filter_tb is
  
  -- 'fileDataIn' and 'fileDataOut' are used for the simulation and the relative path used
  -- in the testbench file refers to the xsim folder location, which is inside the project directory.
  -- See https://support.xilinx.com/s/article/66843?language=en_US
  constant fileDataIn  : string := "../../../../../digital_signal_processing/filters/testbench/data_in.txt";
  constant fileDataOut : string := "../../../../../digital_signal_processing/filters/testbench/data_out.txt";
  
  -- 'fileCoeffs' is passed to the DUT and the relative path file used 
  -- by the DUT file refers to the DUT file folder location.
  constant fileCoeffs  : string := "../testbench/coeffs_len64_Wl18.txt";
  
  constant clk_hz     : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  
  constant Width_in     : integer := 16;
  constant Width_coeffs : integer := 18;
  constant Width_sum    : integer := 40; -- Width_in + Width_coeffs + log2(Coeffs_len)
  constant Clip_bits    : integer :=  5;
  constant Width_out    : integer := 18;

  signal enb       : std_logic;
  signal valid_in  : std_logic;
  signal data_in   : std_logic_vector(Width_in-1 downto 0);
  signal valid_out : std_logic;
  signal data_out  : std_logic_vector(Width_out-1 downto 0);

begin

  ---------- Read Process ----------
  readData_PROC : process(clk)
    file     f     : text open read_mode is fileDataIn;
    variable fLine : line;
    variable temp  : bit_vector(Width_in - 1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        data_in <= (others=>'0');
        valid_in <= '0';
      elsif enb='1' then
        if (not endfile(f)) then
          readline(f, fLine);
          read(fLine, temp);
          data_in <= to_stdlogicvector(temp);
          valid_in <= '1';
        else
          data_in <= (others => '0');
          valid_in <= '0';
        end if;
      end if;
    end if;
  end process;


  ---------- DUT ----------

  clk <= not clk after clk_period / 2;

  DUT : entity work.fir_filter(rtl_noSym)
  generic map (
    -- Coefficients parameters
    Coeffs_file  => fileCoeffs,
    Coeffs_len   => 64,

    -- FIR filter parameters
    Width_in     => Width_in    ,
    Width_coeffs => Width_coeffs,
    Width_sum    => Width_sum   , -- Width_in + Width_coeffs + log2(Coeffs_len)
    Clip_bits    => Clip_bits   ,
    Width_out    => Width_out
  )
  port map (
    clk       => clk       ,
    rst       => rst       ,
    enb       => enb       ,
    valid_in  => valid_in  ,
    data_in   => data_in   ,
    valid_out => valid_out ,
    data_out  => data_out  
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;
    rst <= '0';
    enb <= '1';
    
    wait for clk_period * 10000;
    assert false
      report "Replace this with your test cases"
      severity failure;

    finish;
  end process;

  ---------- Write Process ----------

  -- Write Process
  process(clk)
    file out_stream : text open write_mode is fileDataOut;
    variable row    : line;
  begin
    if rising_edge(clk) then
      if valid_out='1' then
        write(row, to_bitvector(data_out));
        writeline(out_stream,row);
      end if;
    end if;
  end process;



end architecture;
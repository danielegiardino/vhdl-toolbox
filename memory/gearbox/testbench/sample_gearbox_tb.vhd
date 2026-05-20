----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2026.05.26
-- Description: 
--   Test Bench.
-- 
-- Design:
-- 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

library work;
use work.pkg_vhdl_toolbox.lcm;

entity sample_gearbox_tb is
end entity;

architecture sim of sample_gearbox_tb is

  -- 'fileDataOut' is used for the simulation and the relative path used
  -- in the testbench file refers to the xsim folder location, which is inside the project directory.
  constant fileDataOut : string := "../../../../../memory/gearbox/testbench/data_out.txt";

  constant clk_hz     : integer := 1e9;
  constant clk_period : time    := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  signal enb : std_logic := '0';

  -- Generic parameters
  constant SAMPLE_WIDTH   : natural := 16; -- Bit size of one sample
  constant INPUT_SAMPLES  : natural := 8; -- Number of input samples
  constant OUTPUT_SAMPLES : natural := 6; -- Number of output samples

  -- Counter to generate input data
  signal cnt_rate_in : unsigned(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
  signal cnt_data    : unsigned(SAMPLE_WIDTH - 1 downto 0) := (others => '0');

  -- Counter to track the number of output samples read, 
  -- used to control the read process and ensure correct sequencing of output data
  function est_max_rate_cnt (spc_in : natural; spc_out : natural) return natural is
    variable a      : real := real(spc_in);
    variable b      : real := real(spc_out);
    variable result : real;
  begin
    result := real(spc_in) / real(spc_out);
    result := ceil(result);
    return natural(result);

  end function;
  constant MAX_RATE_CNT : natural := est_max_rate_cnt(INPUT_SAMPLES, OUTPUT_SAMPLES);

  -- Write side
  signal i_tvalid : std_logic;
  signal i_tdata  : std_logic_vector((SAMPLE_WIDTH * INPUT_SAMPLES) - 1 downto 0);
  signal i_tready : std_logic;

  -- Read side
  signal o_tvalid : std_logic;
  signal o_tdata  : std_logic_vector((SAMPLE_WIDTH * OUTPUT_SAMPLES) - 1 downto 0);
  signal o_tready : std_logic;

  -- std_logic_vector to array of samples conversion
  type sample_array is array (natural range <>) of std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
  signal i_tdata_arr : sample_array(0 to INPUT_SAMPLES - 1);
  signal o_tdata_arr : sample_array(0 to OUTPUT_SAMPLES - 1);

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.sample_gearbox(rtl)
    generic map(
      SAMPLE_WIDTH   => SAMPLE_WIDTH,
      INPUT_SAMPLES  => INPUT_SAMPLES,
      OUTPUT_SAMPLES => OUTPUT_SAMPLES
    )
    port map
    (
      clk      => clk,
      rst      => rst,
      i_tvalid => i_tvalid,
      i_tdata  => i_tdata,
      i_tready => i_tready,
      o_tvalid => o_tvalid,
      o_tdata  => o_tdata,
      o_tready => o_tready
    );


  -- Counter to generate the input data rate, creating a valid signal at the input of the gearbox 
  -- at a specific rate defined by MAX_RATE_CNT, which is calculated based on the ratio of input
  -- and output samples to ensure proper timing and sequencing of data through the gearbox
  p_data_rate : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt_rate_in <= (others => '0');
      elsif enb = '1' then
        if cnt_rate_in = MAX_RATE_CNT - 1 then
          cnt_rate_in <= (others => '0');
        else
          cnt_rate_in <= cnt_rate_in + 1;
        end if;
      end if;
    end if;
  end process;


  -- Generate input valid signal and data based on the counter, creating a sequence of samples
  -- that increments with each new set of input samples. The valid signal is asserted at a specific
  -- rate defined by MAX_RATE_CNT to ensure proper timing and sequencing of data through the gearbox,
  -- allowing the testbench to simulate realistic data flow conditions and verify the correct 
  -- operation of the gearbox under
  p_input_data : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        i_tvalid <= '0';
        cnt_data <= (others => '1');
      elsif cnt_rate_in = MAX_RATE_CNT - 1 then
        i_tvalid <= '1';
        cnt_data <= cnt_data + 1;
      else
        i_tvalid <= '0';
      end if;
    end if;
  end process;

  -- Generate input data based on the counter, creating a sequence of samples that increments with each new set of input samples
  G_counter_to_data : for i in 0 to INPUT_SAMPLES - 1 generate
    signal sample_value    : real := 0.0;
    signal sample_value_un : unsigned(SAMPLE_WIDTH - 1 downto 0);
  begin
    sample_value    <= real(to_integer(cnt_data)) * real(INPUT_SAMPLES) + real(i);
    sample_value_un <= to_unsigned(integer(sample_value), SAMPLE_WIDTH);

    i_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH) <= std_logic_vector(sample_value_un);
  end generate;

  SEQUENCER_PROC : process
  begin

    rst      <= '1';
    enb      <= '0';
    o_tready <= '0';
    wait for clk_period * 2;

    rst      <= '0';
    enb      <= '1';
    o_tready <= '1';
    wait;

    -- assert false
    --   report "Replace this with your test cases"
    --   severity failure;
    -- finish;
  end process;

  
  -- Convert std_logic_vector to array of samples for easier access in the testbench
  g_input_array : for i in 0 to INPUT_SAMPLES - 1 generate
  begin
    i_tdata_arr(i) <= i_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH);
  end generate;
  g_output_array : for i in 0 to OUTPUT_SAMPLES - 1 generate
  begin
    o_tdata_arr(i) <= o_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH);
  end generate;
    
  ---------- Write Process ----------
  -- Write Process
  process (clk)
    file out_stream       : text open write_mode is fileDataOut;
    variable row          : line;
    variable sample_value : integer;
  begin
    if rising_edge(clk) then
      if o_tvalid = '1' then
        for i in 0 to OUTPUT_SAMPLES - 1 loop
          sample_value := to_integer(unsigned(o_tdata_arr(i)));
          write(row, sample_value);
          writeline(out_stream, row);
        end loop;
      end if;
    end if;
  end process;

end architecture;

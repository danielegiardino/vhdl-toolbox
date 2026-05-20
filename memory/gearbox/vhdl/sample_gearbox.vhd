----------------------------------------------------------------------------------
-- Author: Daniele Giardino
-- 
-- Date: 2026.05.18
-- Description: 
--  High-speed synchronous fractional gearbox designed to scale 
--  the number of parallel samples per clock cycle from N to M 
--  while maintaining a constant overall throughput.
--
-- Features:
--   1. Configurable sample width and number of input/output samples.
--   2. Efficient buffering mechanism using a register array sized to the LCM of input and output samples.
--   3. FSM-based control logic to manage the write and read processes, ensuring correct timing and data integrity.
--   4. Seamless handling of backpressure from the downstream module, allowing for smooth data flow without loss or corruption.
--   5. Optimized for high-speed operation, minimizing latency and maximizing throughput in demanding applications.
--
-- Note:
--  The gearbox is designed to maintain the same throughput. The developer must ensure that 
--  the input and output sample rates are compatible, meaning that the number of input samples
--  per cycle and the number of output samples per cycle must be chosen such that the overall 
--  data rate remains constant. This is typically achieved by ensuring that the 
--  product of the number of samples and the clock frequency is the same on both sides of the gearbox.
--
-- Examples of compatible sample rates:
--   Considering that the gearbox uses a single clock domain, the input and output sample rates 
--   must be compatible to maintain the same overall throughput. This means that the product of the 
--   number of samples per cycle and the clock frequency should be the same for both input and output. 
--   Here are some examples of compatible sample rates:
--     Example 1:
--       - Input: 4 samples per cycle at 250 MHz (1 GS/s of capable input data rate)
--       - Output: 8 samples per cycle at 250 MHz (1 GS/s of capable output data rate).
--       - The valid input data is provided every cycle, resulting in a total input data rate of 1 GS/s.
--       - The valid output data is generated every 2 cycles, effectively maintaining the same throughput.
--
--         Good waveform at 250 MHz:
--            clk            ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  
--            @250MHz:      ─┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──
--
--            i_tvalid:      ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  
--                          ─┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──
--            i_data[3]:      X3    X7    X13   X17   X21   X25   X29                                                   
--            i_data[2]:      X2    X6    X12   X16   X20   X24   X28                                                   
--            i_data[1]:      X1    X5    X11   X15   X19   X23   X27                                                   
--            i_data[0]:      X0    X4    X10   X14   X18   X22   X26

--            i_tready:      ┌─────────────────────────────────────────
--                          ─┘
--            
--            o_tvalid:                  ┌──┐        ┌──┐        ┌──┐  
--                          ─────────────┘  └────────┘  └────────┘  └──
--            o_data[7]:      --    --    X7    --    X17   --    X25                                               
--            o_data[6]:      --    --    X6    --    X16   --    X24                                               
--            o_data[5]:      --    --    X5    --    X15   --    X23                                               
--            o_data[4]:      --    --    X4    --    X14   --    X22                                               
--            o_data[3]:      --    --    X3    --    X13   --    X21                                               
--            o_data[2]:      --    --    X2    --    X12   --    X20                                               
--            o_data[1]:      --    --    X1    --    X11   --    X19                                               
--            o_data[0]:      --    --    X0    --    X10   --    X18
--            
--            o_tready:      ┌─────────────────────────────────────────
--                          ─┘
--
--     Example 2:
--       - Input: 3 samples per cycle at 200 MHz (600 MSps of capable input data rate)
--       - Output: 2 samples per cycle at 200 MHz (400 MSps of capable output data rate)
--       - The valid input data is provided every cycle, resulting in a total input data rate of 600 MSps.
--       - With a clock frequency of 200 MHz, the throughput input is not maintained. To maintain the 
--         same throughput of 600 MSps, the clock frequency would need to be adjusted to 300 MHz.
--         At 300 MHz, the capable output data rate will be 600 MSps, effectively maintaining the 
--         same throughput, and the valid input will not be provided every cycle. 
--         
--         A possible waveform at 300 MHz to maintain the same throughput:
  
--            clk            ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐ 
--            @300MHz:      ─┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └─
--
--            i_tvalid:      ┌──┐  ┌──┐        ┌──┐  ┌──┐        ┌──┐  ┌──┐   
--                          ─┘  └──┘  └────────┘  └──┘  └────────┘  └──┘  └───────
--            i_data[2]:      X2    X5    --    X8    X11   --    X14   X17                                                     
--            i_data[1]:      X1    X4    --    X7    X10   --    X13   X16                                                     
--            i_data[0]:      X0    X3    --    X6    X9    --    X12   X15  

--            i_tready:      ┌────────────────────────────────────────────────────
--                          ─┘
--            
--            o_tvalid:                        ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  
--                          ───────────────────┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──
--            o_data[1]:      --    --    --    X1    X3    X5    X7    X9    X11                                                 
--            o_data[0]:      --    --    --    X0    X2    X4    X6    X8    X10  
--            
--            o_tready:      ┌────────────────────────────────────────────────────
--                          ─┘
--
--
-- Block Diagram:
--
--   ┌───────────────────────────────────────────────────────────────────────────────────────┐
--   │                                     SAMPLE_GEARBOX                                    │
--   │                                                                                       │
--   │  i_tvalid ──────────┐                                                                 │
--   │                     │                                                                 │
--   │  i_tdata            ▼                                                                 │
--   │  (N samples) ┌─────────────┐                                                          │
--   │              │ i_tdata_arr │  Input vector unpacked into INPUT_SAMPLES lanes          │
--   │              └──────┬──────┘                                                          │
--   │                     │                                                                 │
--   │                     ▼                                                                 │
--   │              ┌───────────────┐                ┌───────────────────┐                   │
--   │              │ sample_buffer │                │ sample_buffer_out │                   │
--   │              │               │  fsm_wr=SEND   │ Snapshot register │                   │
--   │              │               ├───────────────>│                   │                   │
--   │              │ ┌──────────┐  │  Block copy    │    ┌──────────┐   │                   │
--   │              │ │ Reg [0]  │  │                │    │ Reg [0]  │   │                   │
--   │              │ ├──────────┤  │                │    ├──────────┤   │                   │
--   │              │ │ Reg [1]  │  │                │    │ Reg [1]  │   │                   │
--   │              │ ├──────────┤  │                │    ├──────────┤   │                   │
--   │              │ │   ...    │  │                │    │   ...    │   │                   │
--   │              │ ├──────────┤  │                │    ├──────────┤   │                   │
--   │              │ │Reg[LCM-1]│  │                │    │Reg[LCM-1]│   │                   │
--   │              │ └──────────┘  │                │    └──────────┘   │                   │
--   │              └──────▲────────┘                └─────────┬─────────┘                   │
--   │                     │                                   │                             │
--   │                     │  Write mux /                      │ Read mux /                  │
--   │                     │  indexed write                    │ indexed read                │
--   │                     │  (cnt_wr selects chunk)           │ (cnt_rd selects chunk)      │
--   │                     │                                   │                             │
--   │              ┌──────┴──────┐                            ▼                             │
--   │              │ WR_COUNTER  │                     ┌─────────────┐                      │
--   │              └──────▲──────┘                     │ Output mux  │                      │
--   │                     │                            └──────┬──────┘                      │
--   │                     │ enb                               │                             │
--   │                     │                                   ▼                             │
--   │              ┌──────┴───────────────────────────────────────────────┐                 │
--   │              │ Control / handshake / FSMs                           │                 │
--   │              │ - enb      <= i_tvalid and o_tready                  │                 │
--   │              │ - i_tready <= (not reg_o_tvalid) or o_tready         │                 │
--   │              │ - fsm_wr, fsm_rd drive counters and buffer transfers │                 │
--   │              └──────┬───────────────────────────────────────┬───────┘                 │
--   │                     │                                       │                         │
--   │  i_tready <─────────┘                                       ▼                         │
--   │                                                      ┌─────────────┐                  │
--   │                                                      │ reg_o_tdata │                  │
--   │                                                      │ reg_o_tvalid│                  │
--   │                                                      └──────┬──────┘                  │
--   │                                                             │                         │
--   │                                                             ├─> o_tvalid              │
--   │                                                             │                         │
--   │                                                             └─> o_tdata (M samples)   │
--   │  o_tready ────────────────────────────────────────────────────>                       │
--   │                                                                                       │
--   └───────────────────────────────────────────────────────────────────────────────────────┘
--
--   Functional notes:
--   * LCM_SAMPLES = lcm(INPUT_SAMPLES, OUTPUT_SAMPLES)
--   * WR_CYCLES   = LCM_SAMPLES / INPUT_SAMPLES
--   * RD_CYCLES   = LCM_SAMPLES / OUTPUT_SAMPLES
--   * The current implementation accepts input data only when the downstream
--     interface is ready, because enb is gated by both i_tvalid and o_tready.
--   * One complete LCM-sized frame is first buffered, then emitted in
--     RD_CYCLES output beats.
-- Revision:
--   2026.05.18 - File Created
--
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.pkg_vhdl_toolbox.all;

entity sample_gearbox is
  generic (
    SAMPLE_WIDTH   : natural := 16; -- Bit size of one sample
    INPUT_SAMPLES  : natural := 2; -- Number of input samples
    OUTPUT_SAMPLES : natural := 3 -- Number of output samples
  );
  port (

    -- Clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- Write side
    i_tvalid : in std_logic;
    i_tdata  : in std_logic_vector((SAMPLE_WIDTH * INPUT_SAMPLES) - 1 downto 0);
    i_tready : out std_logic;

    -- Read side
    o_tvalid : out std_logic;
    o_tdata  : out std_logic_vector((SAMPLE_WIDTH * OUTPUT_SAMPLES) - 1 downto 0);
    o_tready : in std_logic
  );
end entity;

architecture rtl of sample_gearbox is

  -- Enable signal to control when the gearbox should process data
  signal enb : std_logic;

  -- Size of registers needed to hold the samples during processing
  constant LCM_SAMPLES : positive := lcm(INPUT_SAMPLES, OUTPUT_SAMPLES);

  -- Buffer to hold the samples during processing, sized to the LCM of input and output samples
  type buffer_t is array (natural range <>) of std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
  signal sample_buffer     : buffer_t(0 to LCM_SAMPLES - 1) := (others => (others => '0'));
  signal sample_buffer_out : buffer_t(0 to LCM_SAMPLES - 1) := (others => (others => '0'));

  -- Input sample converted to an array of individual samples for easier processing
  type samples_array_t is array (natural range <>) of std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
  signal i_tdata_arr : samples_array_t(0 to INPUT_SAMPLES - 1);

  -- FSM states for the write process
  type fsm_wr_t is (FILL, SEND);
  signal fsm_wr : fsm_wr_t := FILL;

  -- Counters to track the number of samples currently in the buffer for both writing and reading.
  signal cnt_wr : std_logic_vector(log2(LCM_SAMPLES) - 1 downto 0) := (others => '0'); -- Number of valid samples currently in the buffer
  signal cnt_rd : std_logic_vector(log2(LCM_SAMPLES) - 1 downto 0) := (others => '0');

  -- Number of writing and reading cycles needed to fill the buffer with the LCM of samples
  constant WR_CYCLES : positive := LCM_SAMPLES / INPUT_SAMPLES;
  constant RD_CYCLES : positive := LCM_SAMPLES / OUTPUT_SAMPLES;

  -- FSM states for the read process
  type Tstate is (IDLE, READ);
  signal fsm_rd     : Tstate := IDLE;
  signal cnt_rd_enb : std_logic;

  -- Output register to hold the final output samples before sending them out
  signal reg_o_tdata  : std_logic_vector((SAMPLE_WIDTH * OUTPUT_SAMPLES) - 1 downto 0) := (others => '0');
  signal reg_o_tvalid : std_logic                                                      := '0';
begin

  -- The gearbox is enabled to process data when there is valid input data and the downstream is ready to accept output data.
  enb <= i_tvalid and o_tready;

  ----------------------------------------------------------------------------
  -- Write side logic:
  -- 1. A counter tracks how many samples have been written into the buffer.
  -- 2. When the counter matches the expected number of samples for the current write cycle, the incoming samples are written into the correct positions in the buffer.
  -- 3. Once the buffer is full (after WR_CYCLES), the samples are copied to an output register to prepare for the read process.
  ----------------------------------------------------------------------------
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        fsm_wr <= FILL;
      else
        case fsm_wr is
          when FILL =>
            if enb = '1' and unsigned(cnt_wr) = WR_CYCLES - 1 then
              fsm_wr <= SEND;
            else
              fsm_wr <= FILL;
            end if;

          when SEND =>
            fsm_wr <= FILL;

        end case;
      end if;
    end if;
  end process;

  -- Counter to track the number of samples currently in the buffer.
  -- It increments with each write and resets when it reaches the LCM of samples.
  WR_COUNTER : entity work.counter_with_hit(rtl_unsigned)
    generic map(
      bitLength => cnt_wr'length,
      valToRst  => WR_CYCLES - 1,
      valToHit  => WR_CYCLES - 1
    )
    port map
    (
      clk => clk,
      rst => rst,
      enb => enb,
      inc => std_logic_vector(to_unsigned(1, cnt_wr'length)),
      hit => open,
      cnt => cnt_wr
    );

  -- Convert the input data into an array of individual samples for easier processing
  g_input_array : for i in 0 to INPUT_SAMPLES - 1 generate
  begin
    i_tdata_arr(i) <= i_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH);
  end generate;

  -- Generate block to write incoming samples into the buffer.
  -- Each input sample is written to the correct position in the buffer 
  -- based on the current write count.
  g_write_buffer : for i in 0 to WR_CYCLES - 1 generate
  begin
    g_write_to_reg : for j in 0 to INPUT_SAMPLES - 1 generate
    begin

      process (clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            sample_buffer(i * INPUT_SAMPLES + j) <= (others => '0');
          elsif enb = '1' and cnt_wr = std_logic_vector(to_unsigned(i, cnt_wr'length)) then
            sample_buffer(i * INPUT_SAMPLES + j) <= i_tdata_arr(j);
          else
            sample_buffer(i * INPUT_SAMPLES + j) <= sample_buffer(i * INPUT_SAMPLES + j);
          end if;
        end if;
      end process;

    end generate;
  end generate;

  -- Copy the buffer to the output register when the buffer is full,
  -- creating the output samples in the correct order
  p_copy_buffer : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sample_buffer_out <= (others => (others => '0'));
      elsif fsm_wr = SEND then
        sample_buffer_out <= sample_buffer;
      else
        sample_buffer_out <= sample_buffer_out;
      end if;
    end if;
  end process;

  
  ----------------------------------------------------------------------------
  -- Read side logic:
  -- 1. When the gearbox is enabled and the downstream is ready, an FSM starts the read process, which is controlled by a counter that tracks how many samples have been read from the buffer.
  -- 2. The output samples are generated in the correct order based on the LCM of samples, ensuring that the output data stream is correctly formed according to the specified number of output samples.
  ----------------------------------------------------------------------------

  -- Output counter to create the output samples in the correct order based on the LCM of samples
  RD_COUNTER : entity work.counter_with_hit(rtl_unsigned)
    generic map(
      bitLength => cnt_rd'length,
      valToRst  => RD_CYCLES - 1,
      valToHit  => RD_CYCLES - 1
    )
    port map
    (
      clk => clk,
      rst => rst,
      enb => cnt_rd_enb,
      inc => std_logic_vector(to_unsigned(1, cnt_rd'length)),
      hit => open,
      cnt => cnt_rd
    );

  cnt_rd_enb <= '1' when (o_tready = '1' and fsm_rd = READ) else
    '0';

  -- FSM to control the read process, generating the output samples in the correct order based on the LCM of samples
  p_read_logic : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        fsm_rd <= IDLE;

      elsif o_tready = '1' then

        case fsm_rd is
          when IDLE =>
            if fsm_wr = SEND then
              fsm_rd <= READ;
            else
              fsm_rd <= IDLE;
            end if;
          when READ =>
            if unsigned(cnt_rd) = RD_CYCLES - 1 then
              fsm_rd <= IDLE;
            else
              fsm_rd <= READ;
            end if;
        end case;

      end if;
    end if;
  end process;

  g_output_data : for i in 0 to OUTPUT_SAMPLES - 1 generate
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          reg_o_tvalid                                                    <= '0';
          reg_o_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH) <= (others => '0');
        elsif o_tready = '1' and fsm_rd = READ then
          reg_o_tvalid                                                    <= '1';
          reg_o_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH) <= sample_buffer_out((to_integer(unsigned(cnt_rd)) * OUTPUT_SAMPLES + i));
        else
          reg_o_tvalid                                                    <= '0';
          reg_o_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH) <= reg_o_tdata((i + 1) * SAMPLE_WIDTH - 1 downto i * SAMPLE_WIDTH);
        end if;
      end if;
    end process;
  end generate;

  -- Assign the output signals
  i_tready <= (not reg_o_tvalid) or o_tready; -- Ready to accept new data when not currently outputting valid data or when the downstream is ready
  o_tvalid <= reg_o_tvalid;
  o_tdata  <= reg_o_tdata;

end architecture;
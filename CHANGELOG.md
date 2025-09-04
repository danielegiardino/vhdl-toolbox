# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next release...]

### TODO

- [math/reciprocal_square_root] folder
- [math/waves] folder. Upgrade the DDS design.

## [2025.08.29]

### Added

**Random_generator**

- Random_generator/
  - Galois_LFSR
    - matlab
      - histo_out.m
    - testbench
      - data_out.txt
        - lfsr_gal_tb.vhd
      - vhdl
        - lfsr_gal.vhd

### Changed

Some Readme files and comments in .vhd files that had typos have been corrected.


## [2025.08.28]

### Added

**Random_generator**

- Random_generator/
  - Fibonacci_LFSR
    - matlab
      - histo_out.m
    - testbench
      - data_out.txt
        - lfsr_fib_tb.vhd
      - vhdl
        - lfsr_fib.vhd

## [2025.03.14]

### Added

**math**

- waves/
  - testbench
    - dds_c_wave_tb.vhd
  - vhdl
    - dds_c_wave.vhd
    - dds_cos.vhd
    - dds_sin.vhd

## [2025.03.19]

### Added

**math**

- natural_log/
  - cordic
    - c
      - lib_cordic_ln.c
      - main.c
      - print_atanh_values.c
      - lib_cordic_ln.h
      - bash_cmd.sh
      - error_values.txt
    - testbench
      - cordic_ln_tb.vhd
    - vhdl
      - cordic_ln.vhd

### Changed

- In `digital_signal_processing/sample_rate_converter/vhdl/fir_decimator.vhd`, regB_len of numtAdd_inst has been changed from 2 to 1.
- In `memory/fifo/vhdl/axi_fifo_2clk.vhd`, the reading logic has been patched.
- In `math/square_root/cordic/vhdl/cordic_sqrt.vhd`, the dynamic of the bits and valid propagation have been fixed. Cordic block did not work correctly for large input values.
- In `clock_domain_crossing/vhdl/cdc_sync_slv.vhd`, vhdl attribute has been patchted.

## [2024.04.08]

### Added

**basic**  

- encoder
  - testbench
    - priorityEncoder_tb.vhd
  - vhdl
    - priorityEncoder.vhd
- shifters
  - testbench
    - barrelShifter_tb.vhd
  - vhdl
    - barrelShifter.vhd

**math**  

- square_root
  - cordic
    - c
      - bash_cmd.sh
      - lib_cordicSqrt.c
      - lib_cordicSqrt.h
      - main.c
    - testbench
      - cordic_sqrt_tb.vhd
    - vhdl
      - cordic_sqrt.vhd

### Changed

- In `basic/delay/vhdl/delay_ram_slv.vhd`, the reset address counting has been modified.
- In `clock_domain_crossing/vhdl/cdc_sync_slv.vhd`, the name of the architecture was wrong.
- In `digital_signal_processing/sample_rate_converter/vhdl/fir_decimator.vhd`, the *delayLength* parameter of the block *delay_chain_slv* was equal to 2. It has been fixed.
- In `math/arithmetic_operations/vhdl/c_mult.vhd`, `math/arithmetic_operations/vhdl/c_sub.vhd` and `math/arithmetic_operations/vhdl/c_sum.vhd`, the name of the architecture was wrong.
- In `math/rounding/vhdl/clip_slv.vhd` and `math/rounding/vhdl/round_slv.vhd`, valid_out signal has been fixed.

---

## [2024.03.09]

### Changed

- clock_domain_crossing/vhdl/cdc_sync_slv.vhd. It was cdc_sync.vhd
- memory/fifo/vhdl/axi_fifo_2clk.vhd has been improved. It didn't work properly. Testbench can be modified to test clock domain crossing and change the input sample rate.

## [2024.03.08]

### Added

**digital signal processing folder**  

- filters
  - python
    - genFIRCoeffs.py
    - genSignal.py
    - readSignal.py
  - testbench
    - coeffs_len64_Wl18.txt
    - data_in.txt
    - data_out.txt
    - fir_filter_tb.vhd
  - vhdl
    - fir_filter.vhd
- sample_rate_converter
  - python
    - genFIRCoeffsDecimator.py
    - genFIRCoeffsInterpolator.py
    - genSignal.py
    - readSignal.py
  - testbench
    - coeffs_len128_Wl18_L8.txt
    - coeffs_len128_Wl18_M8.txt
    - data_in.txt
    - data_out.txt
    - fir_decimator_tb.vhd
    - fir_interpolator_tb.vhd
  - vhdl
    - fir_decimator.vhd
    - fir_interpolator.vhd

**math folder**  

- arithmetic_operations
  - testbench
    - acc_N_sps_tb.vhd
    - multAdd_tb.vhd
  - vhdl
    - acc_N_sps.vhd
    - c_sum.vhd
    - c_sub.vhd
    - c_mult.vhd
    - mult.vhd
    - multAdd.vhd

**memory folder**  

- fifo/testbench
    - axi_fifo_2clk_tb.vhd

### Changed

- Architecture names have been changed from `bhv` to `rtl`.
- Titles and subtitles of README files have been rearranged.


## [2024.03.05]

### Added

**memory folder**

- README.md: rom section has been added.
- rom
  - python
    - genCounter.vhd
  - testbench
    - data_signed.txt
    - data_unsigned.txt
    - rom_slv_tb.vhd
  - vhdl
    - rom_slv.vhd

**TCL script for testbench**
- sim_tb.tcl was created to automatically generate a Vivado project and test the code.

### Changed

- VHDL file comments have been changed.
- pkg_vhdl_toolbox.vhd has been moved from `packages` to `packages/vhdl`.

## [2024.02.20]

### Added

**basic folder**

- README.md
- counter
  - testbench
    - counter_with_hit_tb.vhd
  - vhdl
    - counter_with_hit.vhd
- delay
  - testbench
    - delay_chain_sl_tb.vhd
    - delay_chain_slv_tb.vhd
    - delay_ram_slv_tb.vhd
    - delay_sl_tb.vhd
    - delay_slv_tb.vhd
  - vhdl
    - delay_chain_sl.vhd
    - delay_chain_slv.vhd
    - delay_ram_slv.vhd
    - delay_sl.vhd
    - delay_slv.vhd

**clock_domain_crossing folder**
- README.md
- vhdl
  - cdc_sync.vhd


**math folder**

- README.md
- rounding
  - testbench
    - axi_round_and_clip_slv_tb.vhd
    - round_and_clip_slv_tb.vhd
  - vhdl
    - axi_clip_slv.vhd
    - axi_round_and_clip_slv.vhd
    - axi_round_slv.vhd
    - clip_slv.vhd
    - round_and_clip_slv.vhd
    - round_and_clip.vhd.toTest
    - round_slv.vhd


**memory folder**

- README.md
- fifo
  - vhdl
    - axi_fifo_2clk.vhd
- ram
  - vhdl
    - ram_2clk.vhd


**packages folder**

- pkg_dg.vhdl

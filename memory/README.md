Memory
===

- [Memory](#memory)
  - [Fifo](#fifo)
  - [Gearbox](#gearbox)
  - [Ram](#ram)
  - [Rom](#rom)

## Fifo

**Filename** - `axi_fifo_2clk.vhd`  
The purpose of this dual clock FIFO is to enable two circuits that operate at different clock frequencies to communicate with each other.  
A simplified diagram is shown as follows:

```
       WRITE SIDE (i_clk)    ┊    READ SIDE (o_clk)
  ───────────────────────────┼──────────────────────
   i_clk ──────┐             ┊             ┌── o_clk
   i_tdata ──┐ │    ┌─────┐  ┊             │
             │ └───>│     │<───────────────┘
             └─────>│  R  │  ┊
   ┌─────┐  wr_addr │  A  ├─────────────────────> y
 ┏>│ cnt ├─────────>│  M  │  ┊
 ┃ └─────┘          │     │<────────────────────┐
 ┃                  └──┬──┘  ┊                  │
 ┃    ┌───────┐        │     ┊  ┌─────┐ rd_addr │
 ┃    │ write │<───────┼───────>│ FSM ├─────────┘
 ┗━━━━┥ logic │        │     ┊  └─────┘
      └───────┘      ┌─▼─┐   ┊   ┌───┐
                     │cdc├──────>│cdc│
                     └───┘   ┊   └───┘
```

<br>

## Gearbox

**Filename** - `sample_gearbox.vhd`  
A high-speed synchronous fractional gearbox designed to convert the number of parallel samples per clock cycle from N to M while maintaining constant overall throughput. Its behavior is shown below:

```
clk            ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  
@250MHz:      ─┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──
i_tvalid:      ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  
              ─┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──
i_data[3]:      X3    X7    X13   X17   X21   X25   X29                                                   
i_data[2]:      X2    X6    X12   X16   X20   X24   X28                                                   
i_data[1]:      X1    X5    X11   X15   X19   X23   X27                                                   
i_data[0]:      X0    X4    X10   X14   X18   X22   X26
i_tready:      ┌─────────────────────────────────────────
              ─┘

o_tvalid:                  ┌──┐        ┌──┐        ┌──┐  
              ─────────────┘  └────────┘  └────────┘  └──
o_data[7]:      --    --    X7    --    X17   --    X25                                               
o_data[6]:      --    --    X6    --    X16   --    X24                                               
o_data[5]:      --    --    X5    --    X15   --    X23                                               
o_data[4]:      --    --    X4    --    X14   --    X22                                               
o_data[3]:      --    --    X3    --    X13   --    X21                                               
o_data[2]:      --    --    X2    --    X12   --    X20                                               
o_data[1]:      --    --    X1    --    X11   --    X19                                               
o_data[0]:      --    --    X0    --    X10   --    X18

o_tready:      ┌─────────────────────────────────────────
              ─┘
```

The VHDL file also includes a block diagram and another usage example.

<br>

## Ram

**Filename** - `ram_2clk.vhd`  
It is a dual clock synchronous RAM.
The design is:

```
     WRITE SIDE       ┊     READ SIDE        
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                      ┊        
  clk_a               ┊               clk_b
  ────────────┐       ┊       ┌────────────
  ena         │    ┌─────┐    │         enb
  ─────────┐  └───>│     │<───┘  ┌─────────
           └──────>│     │<──────┘
  data_in          │  R  │         data_out
  ────────────────>│  A  ├────────────────>
                   │  M  │
  wea      ┌──────>│     │<──────┐      wea
  ─────────┘  ┌───>│     │<───┐  └─────────
  addra       │    └─────┘    │       addra
  ────────────┘               └────────────
```

<br>

## Rom

**Filename** - `rom_slv.vhd`  
Input port 'addr_rd' is used to read the rom values.
The design is:

```
  clk                      
  ────────────┐            
  enb         │    ┌─────┐ 
  ─────────┐  └───>│     │
           └──────>│     │      valid_out
  data_in          │  R  ├──────────────>
  ────────────────>│  O  │
                   │  M  │       data_out
  addr_rd  ┌──────>│     ├──────────────>
  ─────────┘       │     │
                   └─────┘
```

<br>

**Filename** - `rom_slv.vhd`  
Input port 'addr_rd' is not used. The rom values are read sequentially using an address generated internally. The address signal is incremented when enable is high.
The design is:

```
  clk                      
  ────────────┐            
  enb         │    ┌─────┐ 
  ─────────┐  └───>│     │
           └──────>│     │      valid_out
  data_in          │  R  ├──────────────>
  ────────────────>│  O  │
                   │  M  │       data_out
                   │     ├──────────────>
                   │     │
                   └─────┘
```
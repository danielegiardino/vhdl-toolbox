Memory
===

- [Memory](#memory)
  - [Fifo](#fifo)
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
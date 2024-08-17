## Datasheet

### Overview
The `vgalcd` IP is a fully parameterised soft IP recording the SoC architecture and ASIC backend informations. The IP features an APB4 slave register interface, fully compliant with the AMBA APB Protocol Specification v2.0 and. In addition, the IP features an AXI4 master interface, support memory-map read operation.

### Feature
* VGA and LCD mode support
* RGB332, RGB444, RGB555 and RGB565 color modes
* Programmable video timing
* Programmable burst length
* Programmable two frame buffer switch
* Static synchronous design
* Full synthesizable

### Interface
| port name | type        | description          |
|:--------- |:------------|:---------------------|
| apb4      | interface   | apb4 slave interface |
| axi4      | interface   | axi4 master interface |
| vgalcd ->| interface | vgalcd interface |
| `vgalcd.vgalcd_r_o[4:0]` | output | vgalcd red data output |
| `vgalcd.vgalcd_g_o[5:0]` | output | vgalcd green data output |
| `vgalcd.vgalcd_b_o[4:0]` | output | vgalcd blue data output |
| `vgalcd.vgalcd_hsync_o` | output | vgalcd horizon sync output |
| `vgalcd.vgalcd_vsync_o` | output | vgalcd vertical sync output |
| `vgalcd.vgalcd_de_o` | output | vgalcd data enable output |
| `vgalcd.vgalcd_pclk_o` | output | vgalcd pixel clock output |
| `vgalcd.irq_o` | output | vgalcd interrupt output |


### Register

| name | offset  | length | description |
|:----:|:-------:|:-----: | :---------: |
| [CTRL](#control-register) | 0x0 | 4 | control register |
| [HVVL](#horizon-vertical-visble-length-reigster) | 0x4 | 4 | horizon vertical visble length reigster |
| [HTIM](#horizon-timing-reigster) | 0x8 | 4 | horizon timing register |
| [VTIM](#vertical-timing-reigster) | 0x0C | 4 | vertical timing register |
| [FBBA1](#frame-buffer-base-address-1-reigster) | 0x10 | 4 | frame buffer base address 1 register |
| [FBBA2](#frame-buffer-base-address-2-reigster) | 0x14 | 4 | frame buffer base address 2 register |
| [THOLD](#threshold-register) | 0x18 | 4 | threshold register |
| [STAT](#state-reigster) | 0x1C | 4 | state register |

#### Control Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:27]` | none | reserved |
| `[26:19]` | RW | BURLEN |
| `[18:17]` | RW | MODE |
| `[16:16]` | RW | TEST |
| `[15:8]` | RW | DIV |
| `[7:7]` | RW | VSPOL |
| `[6:6]` | RW | HSPOL |
| `[5:5]` | RW | BLPOL |
| `[4:4]` | RW | VBSE |
| `[3:3]` | RW | VBSIE |
| `[2:2]` | RW | VIE |
| `[1:1]` | RW | HIE |
| `[0:0]` | RW | EN |

reset value: `0x0000_0000`

* BURLEN: burst length(0~255)

* MODE: color mode
    * `MODE = 2'b00`: rgb332
    * `MODE = 2'b01`: rgb444
    * `MODE = 2'b10`: rgb555
    * `MODE = 2'b11`: rgb565

* TEST: build-in test mode
    * `TEST = 1'b0`: read pixel data from frame buffer
    * `TEST = 1'b1`: direct output color bar

* DIV: pixel clock division value

* VSPOL: vertical sync active polarity
    * `VSPOL = 1'b0`: active high
    * `VSPOL = 1'b1`: active low

* HSPOL: horizon sync active polarity
    * `HSPOL = 1'b0`: active high
    * `HSPOL = 1'b1`: active low

* BLPOL: blank active polarity
    * `BLPOL = 1'b0`: active high
    * `BLPOL = 1'b1`: active low

* VBSE: video bank switch enable
    * `VBSE = 1'b0`: disable two frame switch function
    * `VBSE = 1'b1`: otherwise

* VBSIE: video bank switch interrupt enable
    * `VBSIE = 1'b0`: disable two frame switch interrupt
    * `VBSIE = 1'b1`: otherwise

* VIE: vertical sync interrupt enable
    * `VBSIE = 1'b0`: disable vertical sync interrupt
    * `VBSIE = 1'b1`: otherwise

* HIE: horizon sync interrupt enable
    * `HIE = 1'b0`: disable horizon sync interrupt
    * `HIE = 1'b1`: otherwise

#### Horizon Vertical Visble Lengh Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:16]` | RW | VVLEN |
| `[15:0]` | RW | HVLEN |

reset value: `0x0000_0000`

* VVLEN: vertical visible length

* HVLEN: horizon visible length

#### Horizon Timing Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:30]` | none | reserved |
| `[29:20]` | RW | HBPSIZE |
| `[19:10]` | RW | HSNSIZE |
| `[9:0]` | RW | HFPSIZE |

reset value: `0x0000_0000`

* HBPSIZE: horizon back porch size

* HSNSIZE: horizon sync size

* HFPSIZE: horizon front porch size

#### Vertical Timing Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:30]` | none | reserved |
| `[29:20]` | RW | VBPSIZE |
| `[19:10]` | RW | VSNSIZE |
| `[9:0]` | RW | VFPSIZE |

reset value: `0x0000_0000`

* VBPSIZE: vertical back porch size

* VSNSIZE: vertical sync size

* VFPSIZE: vertical front porch size

#### Frame Buffer Base Address 1 Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | RW | FBBA1 |

reset value: `0x0000_0000`

* FBBA1: frame buffer base address 1

#### Frame Buffer Base Address 2 Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | RW | FBBA2 |

reset value: `0x0000_0000`

* FBBA2: frame buffer base address 2

#### Threshold Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:10]` | none | reserved |
| `[9:0]` | RW | THOLD |

reset value: `0x0000_0000`

* THOLD: tx fifo threshold, if the number of data in fifo is large than `THOLD`, the axi4 master interface stop sending request

#### State Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:4]` | none | reserved |
| `[3:3]` | RW | CFB |
| `[2:2]` | RW | VBSIF |
| `[1:1]` | RW | VIF |
| `[0:0]` | RW | HIF |

reset value: `0x0000_0000`

* CFB: current frame buffer id(1/2)

* VBSIF: video buffer switch interrupt flag

* VIF: vertical sync interrupt flag

* HIF: horizon sync interrupt flag

### Program Guide
Config registers can be accessed by 4-byte aligned read and write. C-like pseudocode init operation:
```c
vgalcd.CTRL         = (uint32_t)0
vgalcd.HVVL.HVLEN   = HOR_VIS_16_bit - 1 // set horizon visible length
vgalcd.HVVL.VVLEN   = VER_VIS_16_bit - 1 // set vertical visible length
vgalcd.HTIM.HBPSIZE = HBP_16_bit - 1     // set hori timing params
vgalcd.HTIM.HSNSIZE = HSN_16_bit - 1     // set hori timing params
vgalcd.HTIM.HFPSIZE = HFP_16_bit - 1     // set hori timing params
vgalcd.VTIM.HBPSIZE = VBP_16_bit - 1     // set vert timing params
vgalcd.VTIM.HSNSIZE = VSN_16_bit - 1     // set vert timing params
vgalcd.VTIM.HFPSIZE = VFP_16_bit - 1     // set vert timing params
vgalcd.FBBA1        = FB1_ADDRESS_32_bit
vgalcd.FBBA2        = FB2_ADDRESS_32_bit
vgalcd.CTRL.DIV     = (uint32_t)3        // div 4
vgalcd.CTRL.MODE    = (uint32_t)1        // rgb444 mode
vgalcd.CTRL.BURLEN  = (uint32_t)63       // 64 burst len
```

normal operation:
```c
void fill_fb(uint32_t block) {
    if(~block) {
        for(int i = 0; i < 0x96000; ++i)
            mem[FB1_ADDRESS_32_bit+i] = FRAME_BUFFER_DATA
    } else {
       for(int i = 0; i < 0x96000; ++i)
            mem[FB2_ADDRESS_32_bit+i] = FRAME_BUFFER_DATA
    }
}

fill_fb(0)
fill_fb(1)
vgalcd.CTRL.[VBSE, VBSIE, EN] = 1         // irq, core en
while(1) {
    if(vgalcd.STAT.VBSIF) {
        vgalcd.STAT.VBSIF = (uint32_t) 0; // clear irq flag
        fill_fb(~vgalcd.STAT.CFB)
    }
}

```
complete driver and test codes in [driver](../driver/) dir.

### Resoureces
### References
### Revision History
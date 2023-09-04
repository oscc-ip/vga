> coding时遇到的问题

**缩写对照表**

| 缩写 | 全写               |
| ---- | ------------------ |
| SC   | SoC Core           |
| PPR  | Ping Pong Register |
| VC   | Vga Control        |
| CU   | Config Unit        |

# PPR相关的问题

1. 时钟问题：PPR需要跟AXI以及VC交互，目前打算:

   - VC从PPR读数据的时候，采用VC的时钟`clk_v`
   - PPR通过AXI总线从SDRAM读取数据时，采用AXI的时钟`clk_a`
     问题如下：

   - [ ] Q1: 该设计方案是否可行?
   - [ ] Q2: 我们是否需要其他的一些时钟同步的手段?

2. 计算SDRAM访存地址
   - [ ] Q1: SoC Core将需要显示的数据存储在SDRAM哪段位置？
   - [ ] Q2: PPR光依靠`base_addr`无法完成地址的计算，还需要`top_addr`
   - [ ] Q3: PPR从base_addr读到top_addr后，又会从base_addr开始读数据，
         此时PPR如何保证SoC Core已经将新的数据写入到了SDRAM的base_addr？
         还是默认该地址的数据是有效的？

# VC相关的问题

# CU相关的问题

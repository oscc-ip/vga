---
title: VGA设计第二版
date: 2023-08-02 11:51:39
tags:
  - RISC-V
  - IP
password: opensource
---

VGA设计文档第二版

<!--more-->

[TOC]

# VGA 设计与实现第二版

## 规格设计

> VGA模块的规格设计

- VGA输出帧率为60Hz，支持的输出分辨率有*640x480*, _480x272_, _320x240_
- Frame Buffer的深度$depth=640\cdot480=307200$，宽度为12 bits
- Frame Buffer, VC, SoC Core之间通过AXI总线连接

**缩写对照表**

| 缩写 | 全写         |
| ---- | ------------ |
| SC   | SoC Core     |
| FB   | Frame Buffer |
| VC   | Vga Control  |

## 功能描述

> 描述VGA现实画面的过程

1. SC将每一帧需要现实的数据，通过AXI总线存储到SDRAM对应的位置`VGA_BASE`
2. FB采用ping pong memory结构，FB通过AXI总线从SDRAM读取一帧的画面到<u>空闲的Memory</u>(没有被VC占用的Memory)
3. VC在需要显示像素的时候，会给出读取的像素的地址到FB，并且在下一个cycle得到对应的12bit数据

## 总体设计

![data flow](https://s2.loli.net/2023/07/27/edc2HSwg5iNuXsI.png)
如上图所示，从SoC产生数据到数据通过VGA现实在屏幕上，数据需要首先被写入到SDRAM中，VGA再从SDRAM中读取数据。
由于需要处理好**SDRAM的竞争问题**，经过调研发现如下几种常见的解决方法：

1. 使用双端口SDRAM
   - 优点：能够直接支持Core跟VGA同时访问SDRAM
   - 缺点：
     1. 双端口SDRAM的成本跟面积比单端口SDRAM大
     2. 当有其他访问SDRAM的设备加入时，不适用
2. 将SDRAM的频率提升至Core频率的两倍，此时SDRAM一半的时间可以由Core访问、另一半的时间可以由VGA访问
   - 优点：能够满足Core跟VGA交替访问SDRAM
   - 缺点：
     1. SDRAM频率很难做到Core的两倍
     2. 当有其他访问SDRAM的设备加入时，不适用
3. 总线+时分复用：由于VGA输出存在blank时间，此时不需要现实数据，因此blank时间可以让Core访问SDRAM
   - 优点：对SDRAM没有额外要求
   - 缺点：
     1. 需要额外控制链路控制Core跟VGA访问SDRAM
     2. 在VGA处于visible时间时，Core无法访问SDRAM，因此可能导致Core Stall

![system](https://s2.loli.net/2023/07/26/BxZr9HknAaltCUd.png)
通过上述分析，以及开源SDRAM设计，本版VGA跟SDRAM和Core通过AXI总线链接，如上图所示，其设计特点如下：

1. 采用双端口SDRAM以尽可能保证VGA访问SDRAM时，SDRAM不会被其他设备占用
2. Core写入SDRAM的优先级高于VGA访问优先级，从而保证Core的执行
3. VGA模块内部有ping pong memory作为frame buffer，SDRAM通过Burst传输的方式将帧画面写入到frame buffer

<!-- ![vga](https://s2.loli.net/2023/07/27/2Mqdg78YAphLjQI.png) -->

![vga](https://s2.loli.net/2023/07/31/6LrcjlnaOQKi7T9.png)
VGA模块内部设计如上图所示，主要分为3大模块，各模块功能如下：

1. FB：是一块Ping Pong Memory，其主要作用是缓存一帧的画面，从而避免VGA访问SDRAM失败时，输出画面撕裂
2. Config Module：通过AXI总线接受Core对VGA的配置信息，从而更改VGA的输出分辨率以及帧率
3. VGA Ctrl：运行VGA计算，输出444的RGB数据以及同步信号

## 顶层接口

> input and output design

- VGA的输入数据主要来自于Core的寄存器配置信息，以及从SDRAM里读出的帧画面信息；
- VGA输出数据主要包括RGB信号以及同步信号。

### 从SDRAM读取数据的信号

> VGA 的frame buffer作为AXI的master

| Signal  | Direction | Width | Description                                |
| ------- | --------- | ----- | ------------------------------------------ |
| arburst | Output    | 2     | burst传输类型                              |
| araddr  | Output    | 32    | 读地址                                     |
| arlen   | Output    | 8     | bursy长度；表示一次burst传输包含的传输次数 |
| arsize  | Output    | 3     | 表示一次burst传输内每次传输的size          |
| arready | Input     | 1     | 准备好接收读地址                           |
| arvalid | Output    | 1     | 读地址有效信号                             |
| rdata   | Input     | 32    | 读数据                                     |
| rresp   | Input     | 2     | 读操作状态                                 |
| rlast   | Input     | 1     | burst传输内的最后一个                      |
| rready  | Output    | 1     | 准备好了接收读数据                         |
| rvalid  | Input     | 1     | 读有效信号                                 |

TODO: add clock signals

### Core写入到VGA 寄存器的信号

> VGA config单元作为AXI的Slave

| Signal  | Direction | Width | Description                                                      |
| ------- | --------- | ----- | ---------------------------------------------------------------- |
| awid    | Input     |       | 写地址ID，用来标识写操作，相同ID内响应不能乱序；不同ID间可以乱序 |
| awburst | Input     | 2     | burst类型                                                        |
| awlen   | Input     | 8     | burst长度                                                        |
| awsize  | Input     | 3     | burst传输size                                                    |
| awready | Output    | 1     | slave准备好接收写地址                                            |
| awvalid | Input     | 1     | 写地址有效信号                                                   |
| awaddr  | Input     | 32    | 写地址                                                           |
| wdata   | Input     | 32    | 写数据                                                           |
| wstrb   | Input     | 4     | bit为1表示对应byte数据有效                                       |
| wready  | Output    | 1     | 准备好接收写数据                                                 |
| wvalid  | Input     | 1     | 写有效                                                           |
| bresp   | Output    | 2     | 写操作状态                                                       |
| bvalid  | Output    | 1     | 写响应有效信号                                                   |
| bready  | Input     | 1     | MASTER准备好接收写响应                                           |

### 输出到屏幕的信号

| Signal  | Direction | Width | Description           |
| ------- | --------- | ----- | --------------------- |
| clk_p   | Input     | 1     | 像素时钟，默认是25mhz |
| reset_n | Input     | 1     | 复位信号              |
| r       | Output    | 4     | 蓝色                  |
| g       | Output    | 4     | 绿色                  |
| b       | Output    | 4     | 蓝色                  |
| vsync   | Output    | 1     | 垂直同步              |
| hsycn   | Output    | 1     | 水平同步              |
| blank   | Output    | 1     | 黑屏信号              |

## 关键时序

1. VC内部时序
   ![vga_ctrl_output](https://s2.loli.net/2023/07/31/5iSQEIPg7yOm8kd.png)
2. VC从FB读取数据时序
   ![vc_fb_read](https://s2.loli.net/2023/08/02/7epzoyGVhN21tRc.png)

## 详细设计

> 描述该模块具体怎么实现功能描述的，包含哪些子模块，各个子模块的功能描述、顶层接口、模块框图和电路图等。
> 要具体详细，他人看到该部分后能完成该模块的 RTL 代码实现。

### FB(Frame Buffer)

1. 功能定义：采用ping pong memory的结构，每块memory存储一帧的画面；  
   某一块memory被VGA模块读取时，另一块memory会从SDRAM中读取下一帧的数据，此过程交替进行

2. 接口定义

   - 跟VC相关的接口

     | Signal   | Direction | Width | Description           |
     | -------- | --------- | ----- | --------------------- |
     | clk_p    | Input     | 1     | 帧时钟                |
     | data_reg | Input     | 1     | 颜色数据请求          |
     | swap     | Input     | 1     | 换一个memory 读取数据 |
     | x_index  | Input     | 10    | 行坐标                |
     | y_index  | Input     | 9     | 纵坐标                |
     | data     | Outpu     | 12    | 颜色数据              |

   - 跟SDRAM相关的接口：同过AXI接口同SDRAM进行数据交互，FB当作AXI的Master从SDRAM读取数据

3. 功能实现

   - FB有一个内部寄存器`flag`用来表明当前被VC模块读取的memory；  
     一帧显示完全之后，该`flag`会被更改。
   - 从两块memory中读取的数据，会根据`flag`信号，通过二选一选择器来输出到VC
   - 从SDRAM中读取的数据，会以`flag`作为写使能信号写入到其中一块memory中

   ![](https://s2.loli.net/2023/07/31/y8ij5MnsKXHl2BW.png)

4. **🌟讨论点🌟**：
   1. SC能否直接将帧数据通过AXI写入到VGA的FB中？
   2. FB可以放到SDRAM中，这样做有如下的优缺点：
      - 优点：VGA内部不用放存储了；节约了总线带宽
      - 缺点：VC需要判断直接从SDRAM读取像素信息是否完成（因为SDRAM不想FB一样是VC独占设备);  
        VC设计需要考虑AXI设计，因此当总线换了之后，VC也需要更改，不具有独立性。

### VC(VGA Control)

1. 功能定义：VC模块主要负责根据配置信息，从FB中读取数据，输出需要显示到屏幕上的**颜色信号**、**同步信号**
2. 接口定义

   | Signal     | Direction | Width | Description           |
   | ---------- | --------- | ----- | --------------------- |
   | clk_p      | Input     | 1     | 帧时钟                |
   | resetn     | Input     | 1     | 复位                  |
   | data       | Input     | 12    | 12bit的数据           |
   | config     | Input     | 1     | 更新输出分辨率        |
   | reso_index | Input     | 2     | 分辨率选择            |
   | r          | Output    | 4     | 红色                  |
   | g          | Output    | 4     | 绿色                  |
   | b          | Output    | 4     | 蓝色                  |
   | vsync      | Output    | 1     | 垂直同步              |
   | hsync      | Output    | 1     | 水平同步              |
   | blank      | Output    | 1     | 空白信号              |
   | data_req   | Output    | 1     | 颜色数据请求          |
   | swap       | Input     | 1     | 换一个memory 读取数据 |
   | x_index    | Output    | 10    | 行坐标                |
   | y_index    | Output    | 9     | 纵坐标                |

3. 功能实现

   - 配置信号：VGA内部会存储各种分辨率所需要的配置信息到寄存器组中，配置信号可以有Core来选择
     拟支持的分辨率有**320x240x60hz**, **480x272x60Hz**, **640x480x60hz**，其配置信息会被存储在VC模块内部的寄存器中

     - 当`config`信号拉高时，会根据`reso_index`来选择对应的寄存器配置信息
       ![](https://s2.loli.net/2023/07/31/lcnmGfuHD5Or4bP.png)
     - 针对每种分辨率，分别存储其：Hsync_End, Hpulse_End, Hdata_begin, Hdata_end; Vsync_End, Vpulse_End, Vdata_begin, Vdata_end信息到寄存器中  
       例如针对**640x480x60hz**分辨率，其

       | Name        | Value | Width |
       | ----------- | ----- | ----- |
       | Hsync_End   | 800   | 10    |
       | Hpulse_End  | 96    | 7     |
       | Hdata_Begin | 144   | 8     |
       | Hdata_End   | 784   | 10    |
       | Vsync_End   | 525   | 9     |
       | Vpulse_End  | 2     | 2     |
       | Vdata_Begin | 35    | 6     |
       | Vdata_End   | 515   | 9     |

     - 用2个32bits的寄存器来存储一个分辨率的配置信息，三种分辨率一共需要6个32bits的寄存器，寄存器各字段对应信息如下：
       ![](https://s2.loli.net/2023/07/31/Lbtp4T2FHAgXNuB.png)

   - 颜色信号：`r=data[3:0]; g=data[7:4]; b=data[11:8];`
   - 同步信号、位置信号：同步信号根据该时序图输出
     - sync: $counter\le pulse\_End$
     - rgb: $data\_Begin \le counter \le data\_End$
     - `index=counter-data_Begin`
       ![](https://s2.loli.net/2023/07/31/QrdlXhuax9nvpcP.png)

## 测试点方案

> 详细列出该模块的功能点，目的是为该模块的单元测试（UT）做准备。
> 功能点分解是为了**针对该模块的功能点设计相应的测试用例**，完成该模块单元测试功能覆盖率覆盖。

VGA 输出到显示器时，需要实现的功能：

1. 在640x480 60Hz的输出分辨率下：
   1. 输出到显示器，在整个显示器上显示同一块颜色
   2. 输出到显示器，在整个显示器上显示彩条，如下图所示
      ![output color strop](https://s2.loli.net/2023/07/25/hbEuYgeNWm8aJfy.png)
   3. 输出到显示器，在整个显示器上静态图片
   4. 输出到显示器，在整个显示器上文字
2. 跟SDRAM读取数据时需要考虑的情况
3. 更改输出分辨率时需要考虑的情况

### 模块测试

1. VC模块

   - [ ] VGA根据配置信息，正确的输出rgb信号跟同步信号的时序
   - [ ] 在testbench里输入不同的data，VC能够正确输出其RGB信号

2. FB模块
   - [ ] FB能够根据`x_index`, `y_index`和`data_reg`信号输出正确的`data`
   - [ ] FB能够正确写入一帧的数据到某一个memory中
   - [ ] Frame 输出、输入能够根据`flag`切换memory

### 联合测试

> 将VC跟FB联合进行测试

- [ ] VC 可以根据`data_reg`, `x_index`和`y_index`从FB中读取一帧的数据，并且输出正确的rgb跟同步信号
- [ ] VC 可以在输出完一帧画面的信号之后，从FB中读取另一帧的信号

### 集成测试

> 将VC跟FB结合AXI总线，集成到系统内部测试

- [ ] 输出到显示器，在整个显示器上显示同一块颜色
- [ ] 输出到显示器，在整个显示器上显示彩条，如下图所示
      ![output color strop](https://s2.loli.net/2023/07/25/hbEuYgeNWm8aJfy.png)
- [ ] 输出到显示器，在整个显示器上静态图片
- [ ] 输出到显示器，在整个显示器上文字
- [ ] 输出到显示器，在整个显示器上动态视频

## 测试点分解

TBD

## 临时疑问

> 学习过程中的临时疑问，供<u>记录</u>和<u>讨论</u>

- [x] SoC 速度 vs VGA 读取速度：可以通过 SDRAM 将 SoC 跟 VGA 解耦，从而 VGA 在读取数据的时候，不用直接跟 SoC 交互。  
       但是 SoC 往 VGA 配置寄存器里写入配置信息的时候，还是需要考虑时钟问题。
- [ ] SoC配置分辨率的时候，是通过APB跟VGA通信吗？
- [ ] Core写数据到SDRAM时，如何知道哪些数据是被VGA显示过的（可以被覆盖）；VGA从SDRAM读数据时，如何知道哪些地址的数据是Core写入的（有效数据）？

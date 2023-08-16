---
title: VGA设计第四版
date: 2023-08-10 08:47:23
tags:
  - RISC-V
  - IP
password: opensource
---

VGA设计文档第四版

<!--more-->

[TOC]

# VGA 设计与实现第四版

## 更改内容

> 本次主要的更改内容如下

1. APB总线只支持32bits的位宽
2. VGA作为主设备访问SDRAM的时候，需要支持burst传输
3. VGA内部ping pong register从<u>2个</u>增加为<u>2组每组32个</u>，以支持burst传输
4. 增加了项目计划的时间节点：说明大致的工作进度安排

## 工作进度安排计划

![](https://s2.loli.net/2023/08/14/5HjDOoNI3WTJ82A.png)

- [x] VGA调研 & 方案设计
- [ ] 代码编写 & 模块测试：3周(8.14~9.3)
  - [ ] VC模块：1周
  - [ ] PPR模块：1周
  - [ ] CU模块：1周
- [ ] 集成测试：2周(9.4~9.17)
- [ ] FPGA测试：2周(9.18~10.8)

## 规格设计

> VGA模块的规格设计

- VGA输出帧率为60Hz，支持的输出分辨率有*800x600*, _640x480_, _480x272_, _320x240_
- VGA作为AXI总线的master向SDRAM发送数据读取请求，一次成功的访问可以读取64bits的数据到VGA内部寄存器中
- SoC Core可以通过APB总线读写VGA内部的控制寄存器，改变VGA的输出分辨率、读取数据的起始地址

**缩写对照表**

| 缩写 | 全写               |
| ---- | ------------------ |
| SC   | SoC Core           |
| PPR  | Ping Pong Register |
| VC   | Vga Control        |
| CU   | Config Unit        |

## 功能描述

> 描述VGA现实画面的过程

1. SC将每一帧需要现实的数据，通过AXI总线存储到SDRAM对应的位置`VGA_BASE`
2. PPR通过AXI总线从SDRAM读取数据到<u>空闲的regisger</u>(没有被VC占用的register)，忙的register被VC读取
3. VC在需要显示像素的时候，会给出读取的像素的地址到FB，并且在下一个cycle得到对应的12bit数据

## 总体设计

![data flow](https://s2.loli.net/2023/07/27/edc2HSwg5iNuXsI.png)
如上图所示，从SoC产生数据到数据通过VGA现实在屏幕上，数据需要首先被写入到SDRAM中，VGA再从SDRAM中读取数据；常见的解决SDRAM读取竞争问题的方法，可以参考[这篇博客](https://timemeansalot.github.io/2023/08/02/vga-v2/).

在当前VGA的设计中，SC将需要展示的数据写入到SDRAM中，VC作为AXI master从SDRAM中读取数据；

- SDRAM的访问冲突由SDRAM来解决，VGA作为master只需要根据数据显示需求发出访问需求即可
- VGA内部用两块64bits的寄存器来存储数据，当作ping pong memory
  - 一个像素点的数据只占用12bits的数据，因此64bits的寄存器至少可以存储4个像素点信息
  - 一个寄存器被VC读取时，另一块寄存器可以写入AXI返回的数据
  - VC需要注意控制每次AXI读取请求时SDRAM地址的计算

<!-- ![vga-v1](https://s2.loli.net/2023/07/27/2Mqdg78YAphLjQI.png) -->
<!-- ![vga-v2](https://s2.loli.net/2023/07/31/6LrcjlnaOQKi7T9.png) -->

VGA模块内部设计如上图所示，主要分为3大模块，各模块功能如下：

1. VGA Ctrl(VC)：主要负责计算需要输出到屏幕的rgb信号跟同步信号
2. ping pong register：每个寄存器64bits，主要负责暂存AXI总线的读取数据，该数据会被VC使用；
   PPR一共分为两组，两组交替使用，**每一组包含32个64bits的寄存器**，通过AXI burst传输从SDRAM里读取数据
3. CU(Config Unit)：主要是一堆可以供SC读写的控制寄存器，用于更改VGA的分辨率、base address

### 顶层接口

![vga-v4](https://s2.loli.net/2023/08/14/WrhqiA15wkbzSLp.png)

> input and output design

- VGA的输入数据主要来自于Core的寄存器配置信息，以及从SDRAM里读出的色彩信息
- VGA输出数据主要包括RGB信号以及同步信号。

#### 从SDRAM读取数据的信号

> VGA 的PPR 作为AXI的master

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

#### 输出到屏幕的信号

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

<!-- ### 关键时序 -->

## 详细设计(分模块设计)

> 该模块主要详细描述VGA以下三个部分的设计：

1. VC设计
2. PPR设计
3. CU设计

### VC(VGA Control)

1. 整体框架
   ![VC](https://s2.loli.net/2023/08/08/CgD4hEaAr7PjSFB.png)
2. 功能
   - VC模块主要读入的分辨率配置信息，产生读取颜色的信号`data_reg`，从PPR里读取颜色数据
   - 输出到屏幕的颜色信号、同步信号
3. 时序图

   - VC内部时序
     ![vga_ctrl_output](https://s2.loli.net/2023/08/08/qTdRfrGJKXoiFu1.png)
   - VC从PPR读取数据时序
     ![vc_fb_read](https://s2.loli.net/2023/08/08/tghQyz2DTWZ8OjB.png)

4. 接口列表

   VC相关的信号可以划分为如下2个大类:

   - 数据相关信号

     | Signal   | Direction | Width | Description  |
     | -------- | --------- | ----- | ------------ |
     | clk_p    | Input     | 1     | 帧时钟       |
     | resetn   | Input     | 1     | 复位         |
     | data_req | Output    | 1     | 颜色数据请求 |
     | data     | Input     | 12    | 12bit的数据  |
     | r        | Output    | 4     | 红色         |
     | g        | Output    | 4     | 绿色         |
     | b        | Output    | 4     | 蓝色         |
     | vsync    | Output    | 1     | 垂直同步     |
     | hsync    | Output    | 1     | 水平同步     |
     | blank    | Output    | 1     | 空白信号     |

   - 配置相关信号

     | Signal      | Direction | Width | Description  |
     | ----------- | --------- | ----- | ------------ |
     | Hsync_End   | Input     | 11    | 水平同步结束 |
     | Hpulse_End  | Input     | 8     | 水平脉冲结束 |
     | Hdata_Begin | Input     | 8     | 水平数据开始 |
     | Hdata_End   | Input     | 10    | 水平数据结束 |
     | Vsync_End   | Input     | 9     | 垂直同步结束 |
     | Vpulse_End  | Input     | 3     | 垂直脉冲结束 |
     | Vdata_Begin | Input     | 5     | 垂直数据开始 |
     | Vdata_End   | Input     | 9     | 垂直数据结束 |

     分辨率配置相关信号的含义，如下图所示

   ![](https://s2.loli.net/2023/08/07/WHsNZRLE1dISjnc.png)

### 乒乓寄存器PPR(ping pong register)

> ping pong register主要负责通过AXI总线向SDRAM发送数据读取请求，并且根据VC请求输出对应的数据到VC

1. 整体框架
   ![PPR](https://s2.loli.net/2023/08/14/xRBIZypbSaDzF8k.png)
2. 功能
   - 根据VC数据读取需求，返回色彩数据
     - 令ping pong register每2B存储一组色彩信息，一个64bits的寄存器可以存储4个像素点信息
     - Control Unit在接收到VC的数据请求信号`data_reg`之后，会根据`write_enable`信号选择
       读寄存器，会根据`byte_select`信号从读寄存器里选择2B的数据，**但是发送给VC的数据是
       12bits，以避免无效数据传输**
   - 发送AXI读取请求到SDRAM
     - Control Unit主要负责连接AXI的地址通道跟反馈通道，其主要功能有:
       **计算SDRAM访存地址、判断AXI返回数据有效、控制ping pong register的交替访存**
     - ping pong register跟AXI的数据通道连接，主要负责写入AXI返回的读数据
     - PPR在读取SDRAM时，不采用burst传输的方式，因为一次只有一个寄存器可以被写入
   - PPR内部的Control Unit必须控制PPR的交替写入跟读取
3. 时序图
   ![](https://s2.loli.net/2023/08/10/q529nohGQZp4Taz.png)
4. 接口列表

   - VC相关的接口

     | 信号名   | 方向   | 位宽 | 描述               |
     | -------- | ------ | ---- | ------------------ |
     | data_req | Input  | 1    | VC申请颜色数据     |
     | data     | Output | 12   | 返回给VC的颜色数据 |

   - AXI相关的接口

     | Signal  | Direction | Width | Description                                |
     | ------- | --------- | ----- | ------------------------------------------ |
     | arburst | Output    | 2     | burst传输类型                              |
     | araddr  | Output    | 64    | 读地址                                     |
     | arlen   | Output    | 8     | bursy长度；表示一次burst传输包含的传输次数 |
     | arsize  | Output    | 3     | 表示一次burst传输内每次传输的size          |
     | arready | Input     | 1     | 准备好接收读地址                           |
     | arvalid | Output    | 1     | 读地址有效信号                             |
     | rdata   | Input     | 64    | 读数据                                     |
     | rresp   | Input     | 2     | 读操作状态                                 |
     | rlast   | Input     | 1     | burst传输内的最后一个                      |
     | rready  | Output    | 1     | 准备好了接收读数据                         |
     | rvalid  | Input     | 1     | 读有效信号                                 |

### 控制模块(CU)

> 控制模块主要是一堆可以供SC读写的寄存器，用于存储分辨率信息、SDRAM数据起始地址

1. 整体框架
   ![CU structure](https://s2.loli.net/2023/08/14/3wNTFlvu4rpisVK.png)
2. 功能

   - 选择分辨率，VGA支持的分辨率有**320x240x60hz**, **480x272x60Hz**, **640x480x60hz**, **800x600x60hz**，
     SC通过往`resolution`寄存器里写入分辨率数据，选择对应的分辨率，其对应关系如下：

     | resolution寄存器 | 分辨率选择 |
     | ---------------- | ---------- |
     | 0001             | 320x240    |
     | 0010             | 480x272    |
     | 0100             | 640x480    |
     | 1000             | 800x600    |

     - 针对每种分辨率，有一个内部寄存器分别存储其：
       Hsync_End, Hpulse_End, Hdata_begin, Hdata_end;
       Vsync_End, Vpulse_End, Vdata_begin, Vdata_end等信息，例如在800x600的分辨率下

       | Name        | Value | Width |
       | ----------- | ----- | ----- |
       | Hsync_End   | 800   | 1056  |
       | Hpulse_End  | 96    | 128   |
       | Hdata_Begin | 144   | 216   |
       | Hdata_End   | 784   | 1016  |
       | Vsync_End   | 525   | 628   |
       | Vpulse_End  | 2     | 4     |
       | Vdata_Begin | 35    | 27    |
       | Vdata_End   | 515   | 627   |

     - 由于VGA一共需要支持4种分辨率，所以我们使用4个64bits的寄存器来存储对应的信息，
       如整体架构里红色部分的4个寄存器所示；**这四个寄存器会在config模块初始化的时候被写入固定值**
       ![](https://s2.loli.net/2023/08/08/YlbV85qsidRmeUS.png)
     - 这四个配置寄存器的值，会根据`resolution`寄存器的值作为选择信号，选择一种分辨率信号，
       输出到VC模块

   - 配置SDRAM读取的起始地址`BaseAddr`，SC会通过APB写入到整体框架中的`BaseAddr`寄存器中

3. 时序图
   ![FSM](https://s2.loli.net/2023/08/07/GJZQDAOzUhEfNTc.png)
   读传输情况时序如下图所示，PREADY信号可以无限延后，直到数据准备好后再拉高：
   ![read](https://s2.loli.net/2023/08/08/hVdAInZE1ijeSYb.png)
   写传输的情况也与读传输类似的
   ![write](https://s2.loli.net/2023/08/08/hzU7N1sc3dfKHgi.png)
4. 接口列表
   该模块主要采用APB总线接受SC的写入数据，其详细接口信号如下:

   - APB总线相关信号

     | 信号名  | 方向   | 位宽 | 描述       |
     | ------- | ------ | ---- | ---------- |
     | pclk    | Input  | 1    | 时钟       |
     | presetn | Input  | 1    | 复位       |
     | paddr   | Input  | 64   | 地址       |
     | psel    | Input  | 1    | 片选       |
     | penable | Input  | 1    | 使能       |
     | pwrite  | Input  | 1    | 写/读      |
     | pdata   | Input  | 64   | 写数据     |
     | pready  | Output | 1    | 从设备就绪 |
     | prdata  | Output | 64   | 读数据     |
     | pslverr | Output | 1    | 从设备错误 |

   [APB总线参考资料1](https://www.lzrnote.cn/2021/09/17/apb%E6%80%BB%E7%BA%BF%E6%80%BB%E7%BB%93/),
   [APB总线参考资料2](https://blog.csdn.net/weixin_46022434/article/details/105051587)

   - 发送给PPR和VC的相关信号

     > 下述信号皆为wire类型

     | 信号名      | 方向   | 位宽 | 描述                   |
     | ----------- | ------ | ---- | ---------------------- |
     | BaseAddr    | Output | 64   | 发送给PPR的起始地址    |
     | Hsync_End   | Output | 11   | 发送给VC的水平同步结束 |
     | Hpulse_End  | Output | 8    | 发送给VC的水平脉冲结束 |
     | Hdata_Begin | Output | 8    | 发送给VC的水平数据开始 |
     | Hdata_End   | Output | 10   | 发送给VC的水平数据结束 |
     | Vsync_End   | Output | 9    | 发送给VC的垂直同步结束 |
     | Vpulse_End  | Output | 3    | 发送给VC的垂直脉冲结束 |
     | Vdata_Begin | Output | 5    | 发送给VC的垂直数据开始 |
     | Vdata_End   | Output | 9    | 发送给VC的垂直数据结束 |

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

2. PPR模块
   - [ ] PPR能够根据`x_index`, `y_index`和`data_reg`信号输出正确的`data`
   - [ ] PPR能够正确写入一帧的数据到某一个memory中
   - [ ] Frame 输出、输入能够根据`flag`切换memory
3. CU模块
   - [ ] resolution_config_register在CU初始化之后被正确赋初值
   - [ ] resulution个BaseAddr寄存器被APB总线写入

### 联合测试

> 将VC, PPR跟CU联合进行测试

- [ ] VC 可以根据`data_reg`, `x_index`和`y_index`从PPR中读取一帧的数据，并且输出正确的rgb跟同步信号
- [ ] VC 可以在输出完一帧画面的信号之后，从PPR中读取另一帧的信号
- [ ] 写入resulution寄存器，更改输出分辨率之后，VC输出的同步信号是否改变

### 集成测试

> 将VC跟PPR结合AXI总线，集成到系统内部测试

- [ ] 输出到显示器，在整个显示器上显示同一块颜色
- [ ] 输出到显示器，在整个显示器上显示彩条，如下图所示
      ![output color strop](https://s2.loli.net/2023/07/25/hbEuYgeNWm8aJfy.png)
- [ ] 输出到显示器，在整个显示器上静态图片
- [ ] 输出到显示器，在整个显示器上文字
- [ ] 输出到显示器，在整个显示器上动态视频

## 测试点分解

TODO

## 临时疑问

> 学习过程中的临时疑问，供<u>记录</u>和<u>讨论</u>

- [x] SoC 速度 vs VGA 读取速度：可以通过 SDRAM 将 SoC 跟 VGA 解耦，从而 VGA 在读取数据的时候，不用直接跟 SoC 交互。  
       但是 SoC 往 VGA 配置寄存器里写入配置信息的时候，还是需要考虑时钟问题。
- [ ] Core写数据到SDRAM时，如何知道哪些数据是被VGA显示过的（可以被覆盖）；VGA从SDRAM读数据时，如何知道哪些地址的数据是Core写入的（有效数据）？

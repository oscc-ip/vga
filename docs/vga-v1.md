---
title: VGA笔记
date: 2023-07-10 11:16:32
tags:
  - RISC-V
  - IP
password: opensource
---

VGA 相关笔记

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWcyMDE4LmNuYmxvZ3MuY29tL2Jsb2cvMTQyNjI0MC8yMDE4MDkvMTQyNjI0MC0yMDE4MDkyMjE2MzI1MTM0My0yMjkzOTAwNjkuanBn?x-oss-process=image/format,png)

<!--more-->

[TOC]

# VGA（Video Graphics Array）基础原理

> 实际上，操作 VGA 的过程就是给你一块有横纵坐标范围的区域，区域上的每一个坐标点就是一个像素点，你可以做的事情是**给这个像素点特定的 rgb 色彩**.

## 历史背景

1.  IBM 于 1987 年随 PS/2 机一起推出的一种使用模拟信号的视频传输标准

2.  不支持热插拔，不支持音频传输

3.  信号：三原色（红绿蓝）、hsync、vsyn

4.  时序

    ![VGA时序](https://s2.loli.net/2023/07/13/bLzAfZvM8YgURuo.png)

    Hor Scan Time 是一个扫描周期，它会先扫描到 Hor Sync、再扫描 Hor Back Porch，然后才进入有效显示区 Hor Active Video，最后是一段 Hor Front Porch；可以看出来，四段区间只有 Hor Active Video 这一段是能够正常显示图像信息的，也就是屏幕上显示的那一块区间

    VGA 的时序参数跟**分辨率**以及**刷新频率**有关

    - 分辨率

      ![image-20230711113651677](https://s2.loli.net/2023/07/13/F8OE2iUr74nHxuK.png)

    - 刷新频率：行扫描周期 _ 场扫描周期 _ 刷新频率 = 时钟频率

           640x480@60：
           行扫描周期：800(像素)，场扫描周期：525(行扫描周期) 刷新频率：60Hz
           800 _ 525 _ 60 = 25,200,000 ≈ 25.175MHz （误差忽略不计）
           640x480@75：
           行扫描周期：840(像素) 场扫描周期：500(行扫描周期) 刷新频率：75Hz
           840 _ 500 _ 75 = 31,500,000 = 31.5MHz

           ![VESA and Industry Standards and Guidelines

      for Computer Display Monitor Timing (DMT)](https://s2.loli.net/2023/07/13/c5HDeym6pquUBYT.png)

5.  VGA 基础知识

    1. 一件很重要的事情是，虽然你看到的屏幕大小是 640x480 的，但是它的实际大小并不只有那么点，形象一点就是说，VGA 扫描的范围是包含了你能够看到的 640x480 这一块区域的更大区域
    2. VGA 显示器扫描方式从屏幕左上角一点开始，从左向右逐点扫描，每扫描完一行，电子束回到屏幕的左边下一行的起始位置，在这期间，**CRT（阴极射线管） 对电子束进行消隐**（当电子枪扫描过了右侧没有荧光粉的区域后，还没有收到回到最左侧的命令（行同步信号脉冲）之前，电子枪需要关闭以实现**消隐**），每行结束时，用行同步信号进行同步
    3. 当扫描完所有的行，**形成一帧**，用场同步信号进行场同步，并使扫描回到屏幕左上方
    4. 完成一行扫描的时间称为水平扫描时间，其倒数称为行频率；完成一帧（整屏）扫描的时间称为垂直扫描时间，其倒数称为场频率，即屏幕的刷新频率

    ![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWcyMDE4LmNuYmxvZ3MuY29tL2Jsb2cvMTQyNjI0MC8yMDE4MDkvMTQyNjI0MC0yMDE4MDkyMjE2MzM0NTgxOC0xNzA0NjU5OTQucG5n?x-oss-process=image/format,png)

# VGA 开源项目

## [vga-clock](https://github.com/mattvenn/vga-clock)

> 在 640x480 VGA 显示器上显示时间的简单项目

![image-20230712192126069](https://s2.loli.net/2023/07/13/lJLxqWwBAD49j2F.png)

只实现了**640x480**分辨率的 VGA Controller，然后基于该 VGA Controller 实现了*时钟显示的应用*

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 4   |
| 可配置性   | 2   |
| 功能正确性 | 5   |
| 易用性     | 2   |

## [Miz702_VGA](https://gitee.com/fengshuaigit/Miz702_VGA)

> 支持 640\*480 分辨率，能够显示静态彩色图片

其 VGA 控制器端口如下，控制器端口列表里不包括待显示的数据信号，一共可以显示 640x480 个像素点，像素点位置由 pixel_x, pixel_y 确定

```verilog
module vga_sync(
        input   wire            clk,
        input   wire            rst_n,
        output	wire		video_en,                  //数据有效
        output  reg             hsync,                 //场同步信号
        output  reg             vsync,                 //行同步信号
        output  wire    [9:0]   pixel_x,               //待显示待像素的x坐标
        output  wire    [9:0]   pixel_y                //待显示待像素的y坐标
);

endmodule
```

测试文件的端口如下所示，测试文件端口里不包含像素点的坐标信息，因为连接到显示器之后，VGA 信号会自动从左到右、从上到下在显示器上输出显示，在确定了显示的分辨率跟频率之后，信号输出的位置由`hsync`跟`vsync`信号确定

```verilog
module vga_test(
            input   wire            sys_clk,
            input   wire            sys_rst_n,
            output  wire            hsync,  // <-- VGA port 13
            output  wire            vsync,  // <-- VGA port 14
    		output  wire   [11:0]   rgb,    // <-- VGA port 1,2,3
		    output  reg	            led
);
endmodule
```

在显示器上输出静态图片的原理：

- 将 640x480 的静态图片制作成 ceo 文件
- 在 vivado 里将该 ceo 文件创建为一个 ROM IP
- 在 testbench 里面调用该 ROM IP，实现数据读取。将数据读取到寄存器里
- testbench 输出 rbg 信号的时候，存寄存器里输出信号到 rgb

项目分析（满分 5 分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 5   |
| 可配置性   | 2   |
| 功能正确性 | 5   |
| 易用性     | 4   |

## [VGA 原理与 FPGA 实现](https://blog.csdn.net/yifantan/article/details/126835530?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-5-126835530-blog-81840978.235^v38^pc_relevant_sort_base2&spm=1001.2101.3001.4242.4&utm_relevant_index=8)

> 支持多种分辨率

其 VGA Controller 端口定义如下，Controller 端口里包含了数据信号的输入、输出`Data`, `VGA_RGB`

```verilog
module VGA_CTRL(
    input Clk,
    input Reset_n,
    input [23:0]Data,
    output reg Data_Req,    //根据波形调试得到
    output reg [9:0]hcount, //当前扫描点的有效图片H坐标, 用于test模块
    output reg [9:0]vcount, //当前扫描点的有效图片V坐标, 用于test模块
    output reg VGA_HS,
    output reg VGA_VS,
    output reg VGA_BLK,     //BLK表示的就是 输出有效图片 信号  高电平有效
    output reg [23:0]VGA_RGB//  RGB888
    );
endmodule
```

所有支持的分辨率在一个文件里定义，通过宏的方式选择某一个分辨率

```verilog
// `define Resolution_480x272 1	//刷新率为60Hz时像素时钟为9MHz
`define Resolution_640x480 1	//刷新率为60Hz时像素时钟为25.175MHz
// `define Resolution_800x480 1	//刷新率为60Hz时像素时钟为33MHz
//`define Resolution_800x600 1	//刷新率为60Hz时像素时钟为40MHz
//`define Resolution_1024x768 1	//刷新率为60Hz时像素时钟为65MHz
//`define Resolution_1280x720 1	//刷新率为60Hz时像素时钟为74.25MHz
//`define Resolution_1920x1080 1	//刷新率为60Hz时像素时钟为148.5MHz

`ifdef Resolution_480x272
    `define H_Right_Border 0
    `define H_Front_Porch 2
    `define H_Sync_Time 41
    `define H_Back_Porch 2
    `define H_Left_Border 0
    `define H_Data_Time 480
    `define H_Total_Time 525
    `define V_Bottom_Border 0
    `define V_Front_Porch 2
    `define V_Sync_Time 10
    `define V_Back_Porch 2
    `define V_Top_Border 0
    `define V_Data_Time 272
    `define V_Total_Time 286

`elsif Resolution_640x480
	`define H_Total_Time  12'd800
	`define H_Right_Border  12'd8
	`define H_Front_Porch  12'd8
	`define H_Sync_Time  12'd96
	`define H_Data_Time 12'd640
	`define H_Back_Porch  12'd40
	`define H_Left_Border  12'd8
	`define V_Total_Time  12'd525
	`define V_Bottom_Border  12'd8
	`define V_Front_Porch  12'd2
	`define V_Sync_Time  12'd2
	`define V_Data_Time 12'd480
	`define V_Back_Porch  12'd25
	`define V_Top_Border  12'd8

//......
```

在 VGA_CTRL 模块里，调用了各种分辨率对应的宏，从而支持各种分辨率的 VGA

```verilog
    localparam Hsync_End = `H_Total_Time;
    localparam HS_End = `H_Sync_Time;
    localparam Hdata_Begin = `H_Sync_Time + `H_Back_Porch + `H_Left_Border;
    localparam Hdata_End = `H_Sync_Time + `H_Left_Border + `H_Back_Porch + `H_Data_Time;
    localparam Vsync_End = `V_Total_Time;
    localparam VS_End = `V_Sync_Time;
    localparam Vdata_Begin =  `V_Sync_Time + `V_Back_Porch + `V_Top_Border;
    localparam Vdata_End = `V_Sync_Time + `V_Back_Porch + `V_Top_Border + `V_Data_Time;
```

项目分析（满分 5 分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 5   |
| 可配置性   | 4   |
| 功能正确性 | 5   |
| 易用性     | 4   |

![image-20230713110232004](https://s2.loli.net/2023/07/13/tYG5xCX3ypM6F8L.png)

![image-20230713110138494](https://s2.loli.net/2023/07/13/rHQUsAGiDJP6ujf.png)

## [vga_lcd](https://github.com/freecores/vga_lcd)

<img src="https://s2.loli.net/2023/07/13/NFyegRCiTvaLcnl.png" alt="image-20230713113742671" style="zoom: 25%;" />

该项目有以下特点：

1. 支持多种分辨率、自定义分辨率
2. 支持多种颜色深度 bpp
3. 定义了跟 Host 进行数据读取的模块
4. 支持鼠标模块

上述架构图中，各个模块的功能如下：

1. Cursor 相关部分

   - Cursor Base Register：存储 Cursor 像素信息的起始地址
   - Cursor Buffer：从存储里读取出来的 Cursor 的信息，可以存储在该 Buffer 中，从而避免每次需要访问存储才能得到 Cursor 的像素信息。该 Buffer 的容量是 512x32bit
   - Cursor Processor：负责计算跟 Cursor 相关的像素点的位置、颜色信息，需要跟 VGA 背景颜色进行选择，从而在屏幕上展示 Cursor

2. 图像相关部分

   - Line FiFo：输入 RBG 信号，是一个 ping pong memory 的结构，保证了输出到 VGA 屏幕的颜色信号源源不断、同时起到时钟域切换的作用
   - Color Processor：将不同深度的颜色转化为 VGA 屏幕展示的 RGB 信息，当输入的颜色信息是 32bit, 24 bit 时，直接 pass through 即可；当输入颜色信息是 16bit 时，其中 5bit 展示红色、6bit 展示绿色、5bit 展示蓝色；当输入的颜色是 8bit 时，通过内部的 Color Lookup Table 找到 RGB 颜色
   - Video Timing Generator：产生 VGA 同步信号，如`VSYNC, HSYNC`

3. 数据访问相关

   - Video Memory Base Register：存储外部 Video 数据的起始地址
   - Wishbone Master Interface：Color Processor 跟 Cursor Processor 访问外部存储器时，通过该接口
   - Wishbone Slave Interface：控制用户可以访问的寄存器的访问

项目分析（满分 5 分）：

| 考核标准   |     |
| ---------- | --- |
| 可读性     | 3   |
| 可配置性   | 5   |
| 功能正确性 | 5   |
| 易用性     | 3   |

# VGA 项目比较

如上所述，[vga-clock](https://github.com/mattvenn/vga-clock)、 [Miz702_VGA](https://gitee.com/fengshuaigit/Miz702_VGA)两个项目都只支持固定 640x480 分辨率的 VGA 接口，其优点在于代码规范、比较容易上手；

[VGA 原理与 FPGA 实现](https://blog.csdn.net/yifantan/article/details/126835530?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-5-126835530-blog-81840978.235^v38^pc_relevant_sort_base2&spm=1001.2101.3001.4242.4&utm_relevant_index=8)则支持多种分辨率模式的 VGA 接口，其原理在于通过预先定义的宏来支持各种分辨率的 VGA，并且其 VGA Controller 模块中的信号包含`hsync, vsync, RGB[23:0]` 等信号，因此其 VGA Controller 的输出可以直接驱动显示器显示画面；

[vga_lcd](https://github.com/freecores/vga_lcd)支持多种分辨率模式、多种色深模式，其不止是一个 VGA 控制器，还支持鼠标显示；此外该项目还包含了 VGA 模块跟存储模块的交互设置，保证了 VGA 颜色可以源源不断地输出，但是该项目也是最复杂的。

# VGA 细节设计和设计难点

![](https://s2.loli.net/2023/07/19/EAGOHLg6V2qbNTS.png)

VGA 支持如下特性：

1. 其分辨率最高为 640x480，颜色深度为 4 以节约输出带宽
2. 其分辨率最高为 640x480，颜色深度为 4 以节约数据存储空间

## VGA Ctrl 模块的输入输出信号

| Port    | Width | Rirection | Description      |
| ------- | ----- | --------- | ---------------- |
| clk_p_i | 1     | Input     | Pixel Clock      |
| reset   | 1     | Input     | Reset Singal     |
| data_i  | 12    | Input     | Color Data Input |
| hsync_o | 1     | Output    | Horizontal Sync  |
| vsync_o | 1     | Output    | Vertical Sync    |
| blank_o | 1     | Output    | Blank Sync       |
| r_o     | 4     | Output    | Red Color Data   |
| g_o     | 4     | Output    | Green Color Data |
| b_o     | 4     | Output    | Blue Color Data  |
| v_addr  | 10    | Output    | Vertical index   |
| h_addr  | 9     | Output    | Horizontal index |

信号说明：

1. clk_p_i, reset: 时钟信号，跟像素输出所需要的频率有关；复位信号
2. data_i：从内存里读取的颜色信号，一共 12bit，每个颜色占 4bit
3. r_o, g_o, b_o：颜色信号，每个颜色信号占 4 bit，输出的颜色信号会被数模转换模块(DAC)转化为对应的模拟信号
4. hsync_o, vsync_o：同步信号、低有效，分别是“水平同步”、“垂直同步”，各同步信号对于图像输出的作用如下图所示

   ![](https://s2.loli.net/2023/07/19/5FxhmHw4ZItsuKG.png)

5. blank_o：空白信号、低有效，该信号为高的时候，表明显示器上没有图像显示，blank 信号有效时，DAC 输出的模拟信号会被强制拉低
6. v_addr, h_addr：像素点的坐标，该坐标主要用于从 Data Memory 里面去读取对应的像素信息，每次从 Data Memory 里读取 12 bits 数据，输入到 VGA 中

## 内存计算相关

640x480 的屏幕，一帧画面需要的存储为 MEM，则

$$
MEM = 640 * 480 * 12 = 3.51 MB
$$

> 为了保证 VGA 能够输出连续的画面，VGA 需要输出的一帧的色彩数据，需要提前写入到 Memory 中，然后供 VGA 读取

1. 针对 640x480 的屏幕，令其存储为 RAM 一共有 640*480=307200 行，每一行占 12 bit，在数据读取的时候，
   根据`index=h_addr*480+v_addr`，再由该 index 作为索引取出 12bits 的数据
   **Question:**既然 VGA 输出信号是从左到右、从上到下顺序输出的，我们是否需要能够在一帧画面输出开始之后，顺序从 Data Memory 里取出数据给到 VGA，从而不用使用地址进行索引？

2. 为了保证 Core 写入数据到 Data Memory 跟 VGA 从 Data Memory 数据被 VGA 读出时互不干扰，Data Memory 采用 Ping Pong Memory 的结构，保证一读一写； Data Memory 内部需要维护读写操作

## Optional：调节输出的分辨率

<u>只需要把刷新的上界的值存储在**寄存器**里，就可以支持不同的刷新率跟分辨率了</u>，
如果只需要固定的 640x480 分辨率，则可以将相关参数在 RTL 代码里写死.

```verilog
  //640x480分辨率下的VGA参数设置
  parameter    h_frontporch = 96;
  parameter    h_active = 144;
  parameter    h_backporch = 784;
  parameter    h_total = 800;

  parameter    v_frontporch = 2;
  parameter    v_active = 35;
  parameter    v_backporch = 515;
  parameter    v_total = 525;
```

如上所示，VGA 输出的信号都是有上述信号来计算产生的，例如同步信号的计算如下：

```verilog
  //生成同步信号
  assign hsync = (x_cnt > h_frontporch);
  assign vsync = (y_cnt > v_frontporch);
```

在不同的分辨率下上述参数有不同的数值，如下表所示；若上述参数不是在 RTL 代码里固定写死的，而是通过寄存器里读出，那么 VGA 模块在实际运行的时候，就可以支持输出不同的分辨率以及频率了。

![](https://s2.loli.net/2023/07/19/4kWq2lSJR7pvgao.png)

## 难点分析

1. Q: Core 的时钟跟 VGA 的时钟不同，需要数据时钟域的切换；此外，能否保证 Ping Pong Memory 跟 VGA 是一个时钟域？  
   A：由设计者决定以及实现
2. Q：如何正确地选择 VGA Data Memory 的容量，才可以保证其能够容纳 VGA 一帧的画面、并且不会占据太多存储空间？  
   A：VGA memory 设计需要跟 SDRAM 设计协同
3. Q：Core 如何写入数据到 Data Memory？是通过 load/store 指令还是通过 DMA？  
   A：目前 Core 不支持 DMA，所以是通过 load/store 来实现将数据写入到 SDRAM。
4. Q： 如果我们采用寄存器的方式来更改 VGA 输出的分辨率以及频率，则我们应该如何往这些配置寄存器里写入数据？是通过处理器往 VGA 配置寄存器里写入吗？  
   A：由 Core 负责写入配置信息到寄存器中

# 🌟🌟🌟VGA 设计与实现 🌟🌟🌟

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

### SoC 速度 vs VGA 读取速度

1. SoC 会将每帧的画面存储到 SDRAM 中(如果 rgb 颜色占 4bits，则 640x480 的输出，每帧画面占大概 3.51Mb)
2. 在 SDRAM 中划分 2 块存储区域，作为 ping pong memory
3. VGA 只需要从 SDRAM 中读取数据即可，不受 SoC 时钟的影响; VGA 只需要处理跟 SDRAM 的交互即可

### VGA 跟 SDRAM 联合设计

### VGA 设计的具体东西：软件启动、VGA 初始化等

### 设计、验证的具体流程

# 周会记录

## 2023.07.20 会议纪要

- [ ] SoC 速度 vs VGA 读取速度
- [ ] VGA 跟 SDRAM 联合设计
- [ ] VGA 设计的具体东西：软件启动、VGA 初始化等
- [ ] 设计、验证的具体流程

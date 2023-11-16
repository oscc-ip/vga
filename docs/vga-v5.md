# VGA 交接文档

## 使用本仓库

1. 测试vga_top功能: `make`
   > PS: 更改Makefile里的module，可以单独对模块进行测试
2. 查看波形: `make wave`
3. 在SDL里展示彩条画面: `make sdl`
   > PS: 需要保证按照了SDL2

## 设计

![vga-v4](https://s2.loli.net/2023/08/14/WrhqiA15wkbzSLp.png)

VGA模块分为3个模块，各个模块功能如下所示：

1. VC(Vga Control)：负责实现VGA输出rgb信号跟同步sync信号到屏幕的功能，支持自测试模式
2. PPR(Ping Pong Register)：负责从SDRAM读取需要显示的颜色数据，作为AXI总线的主设备从SDRAM读取数据，每次读取32\*64bits的数据
3. CU(Config Unit)：负责接受Core的配置信号，可以配置的有
   - SDRAM地址读取范围
   - VGA分辨率
   - 自测试模式开启

### VC

> VGA输出帧率为60Hz，支持的输出分辨率有*800x600*, _640x480_, _480x272_, _320x240_，默认支持*640x480*

1. 整体框架
   ![image-20231116161539623](https://s2.loli.net/2023/11/16/Ad8HsOSRv7owb1F.png)
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

     | Signal      | Direction | Width | Description    |
     | ----------- | --------- | ----- | -------------- |
     | Hsync_End   | Input     | 11    | 水平同步结束   |
     | Hpulse_End  | Input     | 8     | 水平脉冲结束   |
     | Hdata_Begin | Input     | 8     | 水平数据开始   |
     | Hdata_End   | Input     | 10    | 水平数据结束   |
     | Vsync_End   | Input     | 9     | 垂直同步结束   |
     | Vpulse_End  | Input     | 3     | 垂直脉冲结束   |
     | Vdata_Begin | Input     | 5     | 垂直数据开始   |
     | Vdata_End   | Input     | 9     | 垂直数据结束   |
     | self_test   | Input     | 1     | 启动自测试模式 |

### 乒乓寄存器PPR(ping pong register)

> ping pong register主要负责通过AXI总线向SDRAM发送数据读取请求，并且根据VC请求输出对应的数据到VC

1. 整体框架
   ![PPR](https://s2.loli.net/2023/08/14/xRBIZypbSaDzF8k.png)
2. 功能
   - 根据VC数据读取需求，返回色彩数据
     - 令ping pong register每2B存储一组色彩信息，一个64bits的寄存器可以存储4个像素点信息
       ![SDRAM line](https://s2.loli.net/2023/10/07/V7iXfPR3qhZw5aO.png)
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

   ![image-20231116161155829](https://s2.loli.net/2023/11/16/mNBXkhlJqwxHRPK.png)

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
       | Hsync_End   | 800   | 11    |
       | Hpulse_End  | 96    | 8     |
       | Hdata_Begin | 144   | 8     |
       | Hdata_End   | 784   | 10    |
       | Vsync_End   | 525   | 10    |
       | Vpulse_End  | 2     | 4     |
       | Vdata_Begin | 35    | 6     |
       | Vdata_End   | 515   | 10    |

     - 由于VGA一共需要支持4种分辨率，所以我们使用4个67bits的寄存器来存储对应的信息，
       如整体架构里红色部分的4个寄存器所示；**这四个寄存器会在config模块初始化的时候被写入固定值**
     - 这四个配置寄存器的值，会根据`resolution`寄存器的值作为选择信号，选择一种分辨率信号，输出到VC模块。默认选择的分辨率为*640x480*

   - 配置SDRAM读取的起始地址`BaseAddr`，SC会通过APB写入到整体框架中的`BaseAddr`寄存器中
   - 配置自测试模式，采用寄存器self_test表示自测试模式，默认会打开自测试模式

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
     | self_test   | Output | 1    | 是否打开自测试模式     |

## 测试

### 测试的流程

1. 分3个模块进行测试，模块内部测试采用了UVM测试框架:

   - 通过Verilator将Verilog编译成C++ Class
   - 通过C++搭建UVM的测试框架，对单个模块进行测试，包括ScoreBoard、Driver、OutMoniter等组建
   - 通过C++编写RM(reference model)，每个模块都包含一个对应的C++编写的类作为RM，还包含两个IO类分别作为该RM的Input跟Output

     ![image-20231116162049909](https://s2.loli.net/2023/11/16/XDKdQh3MYxymbpO.png)

2. RM编写:

   - 每个模块分别对应用C++编写的RM，RM里主要包含了内部控制变量、IO、跟eval方法，eval方法里实现了模块的功能

   ```c++
       class vga_ctrl {

       private:
         // resolotion configs
         int vcount, hcount;
         int test_cnt;
         int test_color[8];

       public:
         vc_in_io *in;
         vc_out_io *out;

         void resetn(); // resetn c_model
         void eval();   // step one cycle
         vga_ctrl() {
           in = new vc_in_io;
           out = new vc_out_io;
           vcount = 0;
           hcount = 0;
         }
       };

   ```

   - RM的IO分别用一个Input跟Output类编写，Input类里的成员变量跟模块的所有input信号一致、Output类的成员变量跟模块所有的output信号一致
   - Input类实现了Random方法，用于生成随机的输入testcase

3. ScoreBoard里会将测试模块的output信号同该模块的Output类向对比，从而判断是否出错

### 测试结果

- [x] 3个模块单独跟RM对比测试，通过
- [x] vga_top跟RM对比测试，测试通过
- [x] vga_top接入SDL框架，显示自测试彩条
![hdl](https://s2.loli.net/2023/11/16/U14wkBxt6pvSdRi.png)

## TODO

- [x] VGA调研 & 方案设计
- [x] 代码编写 & 模块测试
  - [x] VC模块
  - [x] PPR模块
  - [x] CU模块
- [x] vga_top测试
- [x] SDL测试
- [ ] SDRAM集成测试
- [ ] FPGA测试

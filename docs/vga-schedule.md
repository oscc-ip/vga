# 任务描述

1. 任务1:
   - 描述：测试VGA_CTRL模块, 编写VC的reference model，在testbench里对VC模块进行测试
   - 风险：开发者编写的reference model可能存在一些先入为主的错误，需要别的同学帮忙review代码
   - 已完成
2. 任务2: 测试PPR模块
   - 描述：补充RTL代码里TODO部分、采用verilator对PPR进行测试，需要搭建testbench，**编写PPR的reference model**，构造测试用例对PPR进行测试
   - 时间：4天
   - 资源：需要再次确认AXI相关接口是否完整; 跟SDRAM设计确认交互的逻辑（信号约定、时序等）
   - 风险
3. 任务3: 联合测试VC跟PPR模块
   - 描述：将VC跟PPR的RTL代码连接起来、同时将二者的reference model连接起来，构造测试用例进行测试
   - 时间: 4天
   - 资源
   - 风险: 4天时间有点紧张
4. 任务4: 测试CU(Config Unit)模块
   - 描述: 补充RTL代码里的TODO部分，编写CU的reference model，在testbench里对CU进行测试
   - 时间: 3天
   - 资源
   - 风险: 需要再次确认APB信号是否完整、确保自己对APB总线信号理解正确
5. 任务5: 联合测试VC、PPR、CU模块
   - 描述: 在RTL上将三者代码连接起来得到vga_top、同时连接三者的reference model，对整个VGA模块进行测试
   - 时间: 4天
   - 资源
   - 风险: 连接reference model可能需要花点时间，因为reference model不想RTL那样连接信号线即可，而是由3个class来表示的

![vga-v4](https://s2.loli.net/2023/08/14/WrhqiA15wkbzSLp.png)

# 时间规划

![](https://s2.loli.net/2023/09/28/Lb1ANWjHtgYnkRF.png)

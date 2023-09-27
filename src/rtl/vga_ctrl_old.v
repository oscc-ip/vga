module vga_ctrl_comb(
    input clock,
    input resetn,
    input         io_master_awready,
    output        io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [3:0]  io_master_awid,
    output [7:0]  io_master_awlen,
    output [2:0]  io_master_awsize,
    output [1:0]  io_master_awburst,
    input         io_master_wready,
    output        io_master_wvalid,
    output [63:0] io_master_wdata,
    output [7:0]  io_master_wstrb,
    output        io_master_wlast,
    output        io_master_bready,
    input         io_master_bvalid,
    input  [1:0]  io_master_bresp,
    input  [3:0]  io_master_bid,
    input         io_master_arready,
    output        io_master_arvalid,
    output [31:0] io_master_araddr,
    output [3:0]  io_master_arid,
    output [7:0]  io_master_arlen,
    output [2:0]  io_master_arsize,
    output [1:0]  io_master_arburst,
    output        io_master_rready,
    input         io_master_rvalid,
    input  [1:0]  io_master_rresp,
    input  [63:0] io_master_rdata,
    input         io_master_rlast,
    input  [3:0]  io_master_rid,

    output        io_slave_awready,
    input         io_slave_awvalid,
    input  [31:0] io_slave_awaddr,
    input  [3:0]  io_slave_awid,
    input  [7:0]  io_slave_awlen,
    input  [2:0]  io_slave_awsize,
    input  [1:0]  io_slave_awburst,
    output        io_slave_wready,
    input         io_slave_wvalid,
    input  [63:0] io_slave_wdata,
    input  [7:0]  io_slave_wstrb,
    input         io_slave_wlast,
    input         io_slave_bready,
    output        io_slave_bvalid,
    output [1:0]  io_slave_bresp,
    output [3:0]  io_slave_bid,
    output        io_slave_arready,
    input         io_slave_arvalid,
    input  [31:0] io_slave_araddr,
    input  [3:0]  io_slave_arid,
    input  [7:0]  io_slave_arlen,
    input  [2:0]  io_slave_arsize,
    input  [1:0]  io_slave_arburst,
    input         io_slave_rready,
    output        io_slave_rvalid,
    output [1:0]  io_slave_rresp,
    output [63:0] io_slave_rdata,
    output        io_slave_rlast,
    output [3:0]  io_slave_rid,

    output [31:0] io_offset,

    output hsync,
    output vsync,
    output [3:0]vga_r,
    output [3:0]vga_g,
    output [3:0]vga_b
);

    wire vga_clk_din, vga_clk_dout;
    preg #(1,0) vga_clk_gen(clock, ~resetn, ~vga_clk_dout, vga_clk_dout, 1'b1);
    wire vga_clk_en = vga_clk_dout;

	parameter h_frontporch = 120;
	parameter h_active = 184;
	parameter h_backporch = 984;
	parameter h_total = 1040;

	parameter v_frontporch = 6;
	parameter v_active = 29;
	parameter v_backporch = 629;
	parameter v_total = 666;

    parameter MODE800x600 = 0;
    parameter MODE400x300 = 1;

    parameter trans_num = 25;
    parameter trans1_800 = 16;
    parameter trans2_800 = trans_num - trans1_800;

    parameter bufnum_800 = 469;
    parameter bufnum_400 = 118;

    wire [7:0] buf11_addr, buf12_addr, buf21_addr, buf22_addr;
    wire [23:0] buf11_din, buf12_din, buf21_din, buf22_din;
    wire [31:0] buf11_dout, buf12_dout, buf21_dout, buf22_dout;
    wire buf11_wen, buf12_wen, buf21_wen, buf22_wen;

    S011HD1P_X64Y4D32_BW buffer11(.Q(buf11_dout), .CLK(clock), .CEN(1'b0), .WEN(~buf11_wen), .BWEN(32'h0), .A(buf11_addr), .D({8'b0, buf11_din}));
    S011HD1P_X64Y4D32_BW buffer12(.Q(buf12_dout), .CLK(clock), .CEN(1'b0), .WEN(~buf12_wen), .BWEN(32'h0), .A(buf12_addr), .D({8'b0, buf12_din}));
    S011HD1P_X64Y4D32_BW buffer21(.Q(buf21_dout), .CLK(clock), .CEN(1'b0), .WEN(~buf21_wen), .BWEN(32'h0), .A(buf21_addr), .D({8'b0, buf21_din}));
    S011HD1P_X64Y4D32_BW buffer22(.Q(buf22_dout), .CLK(clock), .CEN(1'b0), .WEN(~buf22_wen), .BWEN(32'h0), .A(buf22_addr), .D({8'b0, buf22_din}));

    wire [31:0] status_din, status_dout, base_din, base_dout, offset_din, offset_dout;
    wire status_wen, base_wen, offset_wen;
    preg #(32, 0) status_r(clock, ~resetn, status_din, status_dout, status_wen);
    preg #(32, 0) base_r(clock, ~resetn, base_din, base_dout, base_wen);
    preg #(32, 0) offset_r(clock, ~resetn, offset_din, offset_dout, offset_wen);

    wire isMode800 = status_dout[0] == MODE800x600;

	// 像素计数值
    wire [10:0] x_next_din, x_next_dout;
    wire [9:0] y_next_din, y_next_dout;
    wire x_next_wen, y_next_wen;
    preg #(11, 1) x_next_cnt (clock, ~resetn, x_next_din, x_next_dout, x_next_wen);
    assign x_next_din = base_dout == 0 ? 0 : (x_next_dout == h_total ? 1 : x_next_dout + 11'd1);
    assign x_next_wen = vga_clk_en;

    preg #(10, 1) y_next_cnt (clock, ~resetn, y_next_din, y_next_dout, y_next_wen);
    assign y_next_din = base_dout == 0 ? 0 : ((y_next_dout == v_total & x_next_dout == h_total) ? 1 : y_next_dout + 10'd1);
    assign y_next_wen = (x_next_dout == h_total) & vga_clk_en;

    wire [10:0] x_din, x_dout;
    wire [9:0] y_din, y_dout;
    wire x_wen, y_wen;
    preg #(11, 1) x_cnt (clock, ~resetn, x_din, x_dout, x_wen);
    preg #(10, 1) y_cnt (clock, ~resetn, y_din, y_dout, y_wen);
    assign x_din = x_next_dout;
    assign x_wen = 1;
    assign y_din = y_next_dout;
    assign y_wen = 1;

	wire h_valid;
	wire v_valid;

	// 生成同步信号
	assign hsync = (x_dout > h_frontporch);
	assign vsync = (y_dout > v_frontporch);
	// 生成消隐信号
	assign h_valid = (x_dout > h_active) & (x_dout <= h_backporch);
	assign v_valid = (y_dout > v_active) & (y_dout <= v_backporch);
	wire valid = h_valid & v_valid;
	// 计算当前有效像素坐标
	wire [10:0] h_addr = x_next_dout - (h_active + 1);
	wire [9:0] v_addr = y_next_dout - (v_active + 1);
	// 设置输出的颜色值
    wire vga_idx_v = isMode800? v_addr[0] : v_addr[1];
    wire [9:0] vga_idx_h = isMode800 ? (h_addr >= 512 ? h_addr - 512 : h_addr) : h_addr[10:1];
    wire [10:0] pixel_h = x_dout - (h_active + 1);
    wire [9:0] pixel_v = y_dout - (v_active + 1);

    wire [9:0] pixel_idx_din, pixel_idx_dout;
    wire pixel_idx_wen;
    preg #(10, 0) pixel_idx(clock, ~resetn, pixel_idx_din, pixel_idx_dout, pixel_idx_wen);
    wire [9:0] axiw_idx_din, axiw_idx_dout;
    wire axiw_idx_wen;
    preg #(10, 0) axiw_idx(clock, ~resetn, axiw_idx_din, axiw_idx_dout, axiw_idx_wen);
    wire [8:0] buf_count_din, buf_count_dout;
    wire buf_count_wen;
    preg #(9, 0) buf_count(clock, ~resetn, buf_count_din, buf_count_dout, buf_count_wen);
    wire [1:0] valid_num_din, valid_num_dout;
    wire valid_num_wen;
    preg #(2, 0) buf_valid(clock, ~resetn, valid_num_din, valid_num_dout, valid_num_wen);
    wire axiw_newline = axiw_idx_wen & (axiw_idx_din[9] != axiw_idx_dout[9]);
    wire pixel_newline = pixel_idx_wen & (pixel_idx_din[9] != pixel_idx_dout[9]) & (isMode800 | pixel_v[0]);
    assign valid_num_din = valid_num_dout - {9'b0, pixel_newline} + {9'b0, axiw_newline};
    assign valid_num_wen = axiw_newline | pixel_newline;

    wire secondHalf = isMode800? pixel_h[0]: pixel_h[1];

    wire [9:0] pre_pixel_din, pre_pixel_dout;
    wire pre_pixel_wen;
    preg #(10, 0) pre_pixel(clock, ~resetn, pre_pixel_din, pre_pixel_dout, pre_pixel_wen);
    assign pre_pixel_din = pixel_idx_dout;
    assign pre_pixel_wen = 1'b1;

    wire isBuf2x = pre_pixel_dout[9];
    wire isBufx2 = pre_pixel_dout[8];

    wire [11:0] pixel = ({12{!isBuf2x & !isBufx2 & !secondHalf}} & buf11_dout[11:0]) | ({12{!isBuf2x & !isBufx2 & secondHalf}} & buf11_dout[23:12]) |
                        ({12{!isBuf2x & isBufx2  & !secondHalf}} & buf12_dout[11:0]) | ({12{!isBuf2x & isBufx2  & secondHalf}} & buf12_dout[23:12]) |
                        ({12{isBuf2x  & !isBufx2 & !secondHalf}} & buf21_dout[11:0]) | ({12{isBuf2x  & !isBufx2 & secondHalf}} & buf21_dout[23:12]) |
                        ({12{isBuf2x  & isBufx2  & !secondHalf}} & buf22_dout[11:0]) | ({12{isBuf2x  & isBufx2  & secondHalf}} & buf22_dout[23:12]);

	assign vga_r = valid ? pixel[11:8] : 0;
	assign vga_g = valid ? pixel[7:4] : 0;
	assign vga_b = valid ? pixel[3:0] : 0;


    wire [10:0] vidx_din, vidx_dout, pre_vidx_din, pre_vidx_dout;
    wire vidx_wen, pre_vidx_wen, vaddr_wen;
    wire [31:0] vaddr_din, vaddr_dout;
    preg #(11, 0) axi_vidx(clock, ~resetn, vidx_din, vidx_dout, vidx_wen);
    preg #(11, 0) pre_axi_vidx(clock, ~resetn, pre_vidx_din, pre_vidx_dout, pre_vidx_wen);
    preg #(32, 0) axi_vaddr(clock, ~resetn, vaddr_din, vaddr_dout, vaddr_wen);
    assign vidx_din = y_dout == v_backporch ? 0 : vidx_dout + 1;
    assign vidx_wen = v_valid && (x_dout == 1) && vga_clk_en;
    assign vaddr_din = y_dout == v_backporch ? 0 : vaddr_dout + (isMode800 ? 20'd800 : 20'd400);
    assign vaddr_wen = v_valid && (x_dout == 1) && vga_clk_en;
    // wire [19:0] axi_vaddr = vidx_dout * (isMode800 ? 20'd800 : 20'd400);
    assign pre_vidx_din = vidx_dout;
    assign pre_vidx_wen = 1;

    // 更新buffer
    parameter[1:0] mIdle = 0, mRaddr = 1, mRdata = 2;
    wire [1:0] mstate_din, mstate_dout;
    wire mstate_wen;
    preg #(2, mIdle) mstate (clock, ~resetn, mstate_din, mstate_dout, mstate_wen);

    wire axi_idx_din, axi_idx_dout, axi_idx_wen;
    preg #(1,0) axi_idx(clock, ~resetn, axi_idx_din, axi_idx_dout, axi_idx_wen);
    wire mraddrEn_din, mraddrEn_dout, mraddrEn_wen, mrdataEn_din, mrdataEn_dout, mrdataEn_wen;
    preg #(1,0) mraddrEn(clock, ~resetn, mraddrEn_din, mraddrEn_dout, mraddrEn_wen);
    preg #(1,0) mrdataEn(clock, ~resetn, mrdataEn_din, mrdataEn_dout, mrdataEn_wen);
    wire [4:0] axicount_din, axicount_dout;
    wire axicount_wen;
    preg #(5, 0) axicount(clock, ~resetn, axicount_din, axicount_dout, axicount_wen);

    assign pixel_idx_wen = valid & vga_clk_en & (isMode800? pixel_h[0] : (pixel_h[1:0] == 2'b11));
    assign pixel_idx_din = (x_dout == h_backporch && y_dout == v_backporch) ? {~pixel_idx_dout[9], 9'b0} :  isMode800 ? (pixel_idx_dout + 10'b1) : 
                            (pixel_h == 11'd799 && !pixel_v[0])? pixel_idx_dout - 10'd199 : pixel_idx_dout + 10'b1;//pixel_idx_dout + (isMode800? 10'b1 : pixel_v[0]);

    // preg #(1, 0) second (clock, ~resetn, second_din, second_dout, second_wen);
    wire [31:0] mraddr_din, mraddr_dout;
    wire mraddr_wen;
    preg #(32,0) mraddr(clock, ~resetn, mraddr_din, mraddr_dout, mraddr_wen);
    wire [8:0] axiOffset_din, axiOffset_dout;
    wire axiOffset_wen;
    preg #(9,0) axiOffset(clock, ~resetn, axiOffset_din, axiOffset_dout, axiOffset_wen);

    wire mIdle_s = (base_dout != 0) & (mstate_dout == mIdle & valid_num_dout != 2'd2);
    wire mRaddr_s = mstate_dout == mRaddr & mraddrEn_dout & io_master_arready;
    wire mRdata_data = mstate_dout == mRdata & mrdataEn_dout & io_master_rvalid;
    wire mRdata_last = mRdata_data & io_master_rlast;
    wire mRdata_nlast = mRdata_data & !io_master_rlast;
    wire mhs_ar = mraddrEn_dout & io_master_arready;

    assign mstate_din = mIdle_s ? mRaddr : mRaddr_s ? mRdata : mRdata_last ? mIdle : mstate_dout;
    assign mstate_wen = mIdle_s | mRaddr_s | mRdata_last;
    assign axi_idx_din = isMode800? vidx_dout[0] : vidx_dout[1];
    assign axi_idx_wen = mIdle_s;
    assign mraddrEn_din = mIdle_s;
    assign mraddrEn_wen = mIdle_s | (mRaddr_s & mhs_ar);
    assign mraddr_din = base_dout + buf_count_dout * 32'h1000 + axiw_idx_dout[8] * 32'h800;
    assign mraddr_wen = mIdle_s;

    assign mrdataEn_din = mRaddr_s;
    assign mrdataEn_wen = mRaddr_s | mRdata_last;
    assign axiOffset_din = mRdata_last ? 0 : axiOffset_dout + 1;
    assign axiOffset_wen = mRdata_data;
    assign axicount_din = pre_vidx_dout != vidx_dout ? 0 : (axicount_dout + 1);
    // assign second_din = ~second_dout;
    assign axicount_wen = mRdata_last || (pre_vidx_dout != vidx_dout);
    // assign second_wen = mRdata_last;

    wire frame_finish = buf_count_dout == ((isMode800? bufnum_800 : bufnum_400) - 1);

    // assign axiw_idx_din = (frame_finish && axiw_idx_dout[8:0] == 9'h1ff) ? 10'b0 : axiw_idx_dout + 10'b1;
    assign axiw_idx_din = axiw_idx_dout + 10'b1;
    assign axiw_idx_wen = mRdata_data;
    assign buf_count_din = frame_finish ? 0 : buf_count_dout + 9'b1;
    assign buf_count_wen = axiw_idx_wen & (axiw_idx_din[8:0] == 9'h0 && axiw_idx_dout[8:0] == 9'h1ff);

    assign buf11_wen = !axiw_idx_dout[9] & !axiw_idx_dout[8] & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    assign buf12_wen = !axiw_idx_dout[9] & axiw_idx_dout[8]  & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    assign buf21_wen = axiw_idx_dout[9]  & !axiw_idx_dout[8] & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    assign buf22_wen = axiw_idx_dout[9]  & axiw_idx_dout[8]  & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);

    // assign buf11_wen = axi_idx_dout == 0 & (!isMode800 || !second_dout) & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    // assign buf12_wen = axi_idx_dout == 0 & (isMode800 && second_dout) & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    // assign buf21_wen = axi_idx_dout == 1 & (!isMode800 || !second_dout) & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    // assign buf22_wen = axi_idx_dout == 1 & (isMode800 && second_dout) & mRdata_data & (io_master_rresp == 0 | io_master_rresp == 1);
    assign buf11_addr = (!axiw_idx_dout[9] && valid_num_dout != 2'd2) ? axiw_idx_dout[7:0] : pixel_idx_dout[7:0];
    assign buf12_addr = buf11_addr;
    assign buf21_addr = (axiw_idx_dout[9] && valid_num_dout != 2'd2) ? axiw_idx_dout[7:0] : pixel_idx_dout[7:0];
    assign buf22_addr = buf21_addr;
    assign buf11_din = {io_master_rdata[55:52], io_master_rdata[47:44], io_master_rdata[39:36], io_master_rdata[23:20], io_master_rdata[15:12], io_master_rdata[7:4]};
    assign buf12_din = buf11_din;
    assign buf21_din = buf11_din;
    assign buf22_din = buf11_din;

    parameter [1:0] sIdle = 0, sWdata = 1, sWresp = 2, sRaddr = 1, sRdata = 2;
    wire [1:0] swstate_din, swstate_dout, srstate_din, srstate_dout;
    wire swstate_wen, srstate_wen;
    preg #(2, sIdle) swstate(clock, ~resetn, swstate_din, swstate_dout, swstate_wen);
    preg #(2, sIdle) srstate(clock, ~resetn, srstate_din, srstate_dout, srstate_wen);

    wire [1:0]waddr_din, waddr_dout;
    wire waddr_wen;
    preg #(2, 0) waddr_r(clock, ~resetn, waddr_din, waddr_dout, waddr_wen);

    wire swaddrEn_din, swaddrEn_dout, swaddrEn_wen, swdataEn_din, swdataEn_dout, swdataEn_wen, sbEn_din, sbEn_dout, sbEn_wen;
    preg #(1,1) swaddrEn(clock, ~resetn, swaddrEn_din, swaddrEn_dout, swaddrEn_wen);
    preg #(1,0) swdataEn(clock, ~resetn, swdataEn_din, swdataEn_dout, swdataEn_wen);
    preg #(1,0) sbEn(clock, ~resetn, sbEn_din, sbEn_dout, sbEn_wen);
    wire [3:0] sbid_din, sbid_dout;
    wire sbid_wen;
    preg #(4,0) sbid(clock, ~resetn, sbid_din, sbid_dout, sbid_wen);

    wire sIdle_sw = swstate_dout == sIdle & swaddrEn_dout & io_slave_awvalid;
    wire sWdata_data = swstate_dout == sWdata & swdataEn_dout & io_slave_wvalid;
    wire sWdata_last = sWdata_data & io_slave_wlast;
    wire sWresp_sw = swstate_dout == sWresp & sbEn_dout & io_slave_bready;

    assign swstate_din = sIdle_sw ? sWdata : sWdata_last ? sWresp : sWresp_sw ? sIdle : swstate_dout;
    assign swstate_wen = sIdle_sw | sWdata_last | sWresp_sw;
    assign waddr_din = io_slave_awaddr[3:2];
    assign waddr_wen = sIdle_sw;
    assign swaddrEn_din = sWresp_sw;
    assign swaddrEn_wen = sIdle_sw | sWresp_sw;
    assign swdataEn_din = sIdle_sw;
    assign swdataEn_wen = sIdle_sw | sWdata_last;
    assign sbEn_din = sWdata_last;
    assign sbEn_wen = sWdata_last | sWresp_sw;
    assign sbid_din = io_slave_awid;
    assign sbid_wen = sIdle_sw;
    assign status_din = io_slave_wdata[31:0];
    assign status_wen = sWdata_data & (waddr_dout == 0);
    assign base_din = io_slave_wdata[63:32];
    assign base_wen = sWdata_data & (waddr_dout == 1);
    assign offset_din = io_slave_wdata[31:0];
    assign offset_wen = sWdata_data & (waddr_dout == 2);

    wire sraddrEn_din, sraddrEn_dout, sraddrEn_wen, srdataEn_din, srdataEn_dout, srdataEn_wen, srlast_din, srlast_dout, srlast_wen;
    preg #(1,1) sraddrEn(clock, ~resetn, sraddrEn_din, sraddrEn_dout, sraddrEn_wen);
    preg #(1,0) srdataEn(clock, ~resetn, srdataEn_din, srdataEn_dout, srdataEn_wen);
    preg #(1,0) srlast(clock, ~resetn, srlast_din, srlast_dout, srlast_wen);
    wire [3:0] srid_din, srid_dout;
    wire srid_wen;
    preg #(4,0) srid(clock, ~resetn, srid_din, srid_dout, srid_wen);
    wire [63:0] srdata_din, srdata_dout;
    wire srdata_wen;
    preg #(64,0) srdata(clock, ~resetn, srdata_din, srdata_dout, srdata_wen);

    wire sIdle_sr = srstate_dout == sIdle & sraddrEn_dout & io_slave_arvalid;
    wire sRdata_data = srstate_dout == sRdata & srdataEn_dout & io_slave_rready;

    assign srstate_din = sIdle_sr ? sRdata : sIdle;
    assign srstate_wen = sIdle_sr | sRdata_data;
    assign sraddrEn_din = sRdata_data;
    assign sraddrEn_wen = sIdle_sr | sRdata_data;
    assign srdataEn_din = sIdle_sr;
    assign srdataEn_wen = sIdle_sr | sRdata_data;
    assign srid_din = io_slave_rid;
    assign srid_wen = sIdle_sr;
    assign srlast_din = sIdle_sr;
    assign srlast_wen = sIdle_sr | sRdata_data;
    assign srdata_din = io_slave_araddr[3:0] == 0? {32'h0, status_dout}: io_slave_araddr[3:0] == 4? {base_dout, 32'h0} : {32'h0, offset_dout};
    assign srdata_wen = sIdle_sr;

    assign io_master_awvalid    = 0;
    assign io_master_awaddr     = 0;
    assign io_master_awid       = 0;
    assign io_master_awlen      = 0;
    assign io_master_awsize     = 0;
    assign io_master_awburst    = 0;
    assign io_master_wvalid     = 0;
    assign io_master_wdata      = 0;
    assign io_master_wstrb      = 0;
    assign io_master_wlast      = 0;
    assign io_master_bready     = 0;
    assign io_master_arvalid    = mraddrEn_dout;
    assign io_master_araddr     = mraddr_dout;
    assign io_master_arid       = 0;
    assign io_master_arlen      = 8'hff;//isMode800 ? 8'd16 : 8'd8; //8'd199;
    assign io_master_arsize     = 3;
    assign io_master_arburst    = 1;
    assign io_master_rready     = mrdataEn_dout;

    assign io_slave_awready = swaddrEn_dout;
    assign io_slave_wready  = swdataEn_dout;
    assign io_slave_bvalid  = sbEn_dout;
    assign io_slave_bresp   = 0;
    assign io_slave_bid     = sbid_dout;
    assign io_slave_arready = sraddrEn_dout;
    assign io_slave_rvalid  = srdataEn_dout;
    assign io_slave_rresp   = 1;
    assign io_slave_rdata   = srdata_dout;
    assign io_slave_rlast   = srlast_dout;
    assign io_slave_rid     = srid_dout;

    assign io_offset        = offset_dout;

endmodule
// combine mapping and vga_ctrl_axi

module vga_ctrl(
    input clock,
	input resetn,
    input         io_master_awready,
    output        io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [3:0]  io_master_awid,
    output [7:0]  io_master_awlen,
    output [2:0]  io_master_awsize,
    output [1:0]  io_master_awburst,
    input         io_master_wready,
    output        io_master_wvalid,
    output [63:0] io_master_wdata,
    output [7:0]  io_master_wstrb,
    output        io_master_wlast,
    output        io_master_bready,
    input         io_master_bvalid,
    input  [1:0]  io_master_bresp,
    input  [3:0]  io_master_bid,
    input         io_master_arready,
    output        io_master_arvalid,
    output [31:0] io_master_araddr,
    output [3:0]  io_master_arid,
    output [7:0]  io_master_arlen,
    output [2:0]  io_master_arsize,
    output [1:0]  io_master_arburst,
    output        io_master_rready,
    input         io_master_rvalid,
    input  [1:0]  io_master_rresp,
    input  [63:0] io_master_rdata,
    input         io_master_rlast,
    input  [3:0]  io_master_rid,

    output        io_slave_awready,
    input         io_slave_awvalid,
    input  [31:0] io_slave_awaddr,
    input  [3:0]  io_slave_awid,
    input  [7:0]  io_slave_awlen,
    input  [2:0]  io_slave_awsize,
    input  [1:0]  io_slave_awburst,
    output        io_slave_wready,
    input         io_slave_wvalid,
    input  [63:0] io_slave_wdata,
    input  [7:0]  io_slave_wstrb,
    input         io_slave_wlast,
    input         io_slave_bready,
    output        io_slave_bvalid,
    output [1:0]  io_slave_bresp,
    output [3:0]  io_slave_bid,
    output        io_slave_arready,
    input         io_slave_arvalid,
    input  [31:0] io_slave_araddr,
    input  [3:0]  io_slave_arid,
    input  [7:0]  io_slave_arlen,
    input  [2:0]  io_slave_arsize,
    input  [1:0]  io_slave_arburst,
    input         io_slave_rready,
    output        io_slave_rvalid,
    output [1:0]  io_slave_rresp,
    output [63:0] io_slave_rdata,
    output        io_slave_rlast,
    output [3:0]  io_slave_rid,

    output hsync,
	output vsync,
	output [3:0]vga_r,
	output [3:0]vga_g,
	output [3:0]vga_b

);
    wire        vga_slave_awready;
    wire        vga_slave_awvalid;
    wire [31:0] vga_slave_awaddr;
    wire [3:0]  vga_slave_awid;
    wire [7:0]  vga_slave_awlen;
    wire [2:0]  vga_slave_awsize;
    wire [1:0]  vga_slave_awburst;
    wire        vga_slave_wready;
    wire        vga_slave_wvalid;
    wire [63:0] vga_slave_wdata;
    wire [7:0]  vga_slave_wstrb;
    wire        vga_slave_wlast;
    wire        vga_slave_bready;
    wire        vga_slave_bvalid;
    wire [1:0]  vga_slave_bresp;
    wire [3:0]  vga_slave_bid;
    wire        vga_slave_arready;
    wire        vga_slave_arvalid;
    wire [31:0] vga_slave_araddr;
    wire [3:0]  vga_slave_arid;
    wire [7:0]  vga_slave_arlen;
    wire [2:0]  vga_slave_arsize;
    wire [1:0]  vga_slave_arburst;
    wire        vga_slave_rready;
    wire        vga_slave_rvalid;
    wire [1:0]  vga_slave_rresp;
    wire [63:0] vga_slave_rdata;
    wire        vga_slave_rlast;
    wire [3:0]  vga_slave_rid;
    wire        map_slave_awready;
    wire        map_slave_awvalid;
    wire [31:0] map_slave_awaddr;
    wire [3:0]  map_slave_awid;
    wire [7:0]  map_slave_awlen;
    wire [2:0]  map_slave_awsize;
    wire [1:0]  map_slave_awburst;
    wire        map_slave_wready;
    wire        map_slave_wvalid;
    wire [63:0] map_slave_wdata;
    wire [7:0]  map_slave_wstrb;
    wire        map_slave_wlast;
    wire        map_slave_bready;
    wire        map_slave_bvalid;
    wire [1:0]  map_slave_bresp;
    wire [3:0]  map_slave_bid;
    wire        map_slave_arready;
    wire        map_slave_arvalid;
    wire [31:0] map_slave_araddr;
    wire [3:0]  map_slave_arid;
    wire [7:0]  map_slave_arlen;
    wire [2:0]  map_slave_arsize;
    wire [1:0]  map_slave_arburst;
    wire        map_slave_rready;
    wire        map_slave_rvalid;
    wire [1:0]  map_slave_rresp;
    wire [63:0] map_slave_rdata;
    wire        map_slave_rlast;
    wire [3:0]  map_slave_rid;


    wire [31:0] offset;

    VgaCrossbar vgacrossbar(
        .clock(clock),
        .reset(~resetn),
        .io_master_awready(io_slave_awready),
        .io_master_awvalid(io_slave_awvalid),
        .io_master_awaddr(io_slave_awaddr),
        .io_master_awid(io_slave_awid),
        .io_master_awlen(io_slave_awlen),
        .io_master_awsize(io_slave_awsize),
        .io_master_awburst(io_slave_awburst),
        .io_master_wready(io_slave_wready),
        .io_master_wvalid(io_slave_wvalid),
        .io_master_wdata(io_slave_wdata),
        .io_master_wstrb(io_slave_wstrb),
        .io_master_wlast(io_slave_wlast),
        .io_master_bready(io_slave_bready),
        .io_master_bvalid(io_slave_bvalid),
        .io_master_bresp(io_slave_bresp),
        .io_master_bid(io_slave_bid),
        .io_master_arready(io_slave_arready),
        .io_master_arvalid(io_slave_arvalid),
        .io_master_araddr(io_slave_araddr),
        .io_master_arid(io_slave_arid),
        .io_master_arlen(io_slave_arlen),
        .io_master_arsize(io_slave_arsize),
        .io_master_arburst(io_slave_arburst),
        .io_master_rready(io_slave_rready),
        .io_master_rvalid(io_slave_rvalid),
        .io_master_rresp(io_slave_rresp),
        .io_master_rdata(io_slave_rdata),
        .io_master_rlast(io_slave_rlast),
        .io_master_rid(io_slave_rid),
        .io_vga_slave_awready(vga_slave_awready),
        .io_vga_slave_awvalid(vga_slave_awvalid),
        .io_vga_slave_awaddr(vga_slave_awaddr),
        .io_vga_slave_awid(vga_slave_awid),
        .io_vga_slave_awlen(vga_slave_awlen),
        .io_vga_slave_awsize(vga_slave_awsize),
        .io_vga_slave_awburst(vga_slave_awburst),
        .io_vga_slave_wready(vga_slave_wready),
        .io_vga_slave_wvalid(vga_slave_wvalid),
        .io_vga_slave_wdata(vga_slave_wdata),
        .io_vga_slave_wstrb(vga_slave_wstrb),
        .io_vga_slave_wlast(vga_slave_wlast),
        .io_vga_slave_bready(vga_slave_bready),
        .io_vga_slave_bvalid(vga_slave_bvalid),
        .io_vga_slave_bresp(vga_slave_bresp),
        .io_vga_slave_bid(vga_slave_bid),
        .io_vga_slave_arready(vga_slave_arready),
        .io_vga_slave_arvalid(vga_slave_arvalid),
        .io_vga_slave_araddr(vga_slave_araddr),
        .io_vga_slave_arid(vga_slave_arid),
        .io_vga_slave_arlen(vga_slave_arlen),
        .io_vga_slave_arsize(vga_slave_arsize),
        .io_vga_slave_arburst(vga_slave_arburst),
        .io_vga_slave_rready(vga_slave_rready),
        .io_vga_slave_rvalid(vga_slave_rvalid),
        .io_vga_slave_rresp(vga_slave_rresp),
        .io_vga_slave_rdata(vga_slave_rdata),
        .io_vga_slave_rlast(vga_slave_rlast),
        .io_vga_slave_rid(vga_slave_rid),
        .io_map_slave_awready(map_slave_awready),
        .io_map_slave_awvalid(map_slave_awvalid),
        .io_map_slave_awaddr(map_slave_awaddr),
        .io_map_slave_awid(map_slave_awid),
        .io_map_slave_awlen(map_slave_awlen),
        .io_map_slave_awsize(map_slave_awsize),
        .io_map_slave_awburst(map_slave_awburst),
        .io_map_slave_wready(map_slave_wready),
        .io_map_slave_wvalid(map_slave_wvalid),
        .io_map_slave_wdata(map_slave_wdata),
        .io_map_slave_wstrb(map_slave_wstrb),
        .io_map_slave_wlast(map_slave_wlast),
        .io_map_slave_bready(map_slave_bready),
        .io_map_slave_bvalid(map_slave_bvalid),
        .io_map_slave_bresp(map_slave_bresp),
        .io_map_slave_bid(map_slave_bid),
        .io_map_slave_arready(map_slave_arready),
        .io_map_slave_arvalid(map_slave_arvalid),
        .io_map_slave_araddr(map_slave_araddr),
        .io_map_slave_arid(map_slave_arid),
        .io_map_slave_arlen(map_slave_arlen),
        .io_map_slave_arsize(map_slave_arsize),
        .io_map_slave_arburst(map_slave_arburst),
        .io_map_slave_rready(map_slave_rready),
        .io_map_slave_rvalid(map_slave_rvalid),
        .io_map_slave_rresp(map_slave_rresp),
        .io_map_slave_rdata(map_slave_rdata),
        .io_map_slave_rlast(map_slave_rlast),
        .io_map_slave_rid(map_slave_rid)
    );

    vga_ctrl_comb vga(
        .clock(clock),
        .resetn(resetn),
        .io_master_awready(1'b0),
        // .io_master_awvalid,
        // .io_master_awaddr,
        // .io_master_awid,
        // .io_master_awlen,
        // .io_master_awsize,
        // .io_master_awburst,
        .io_master_wready(1'b0),
        // .io_master_wvalid,
        // .io_master_wdata,
        // .io_master_wstrb,
        // .io_master_wlast,
        //.io_master_bready(1'b0),
        .io_master_bvalid(1'b0),
        // .io_master_bresp,
        // .io_master_bid,
        .io_master_arready(io_master_arready),
        .io_master_arvalid(io_master_arvalid),
        .io_master_araddr(io_master_araddr),
        .io_master_arid(io_master_arid),
        .io_master_arlen(io_master_arlen),
        .io_master_arsize(io_master_arsize),
        .io_master_arburst(io_master_arburst),
        .io_master_rready(io_master_rready),
        .io_master_rvalid(io_master_rvalid),
        .io_master_rresp(io_master_rresp),
        .io_master_rdata(io_master_rdata),
        .io_master_rlast(io_master_rlast),
        .io_master_rid(io_master_rid),

        .io_slave_awready(vga_slave_awready),
        .io_slave_awvalid(vga_slave_awvalid),
        .io_slave_awaddr(vga_slave_awaddr),
        .io_slave_awid(vga_slave_awid),
        .io_slave_awlen(vga_slave_awlen),
        .io_slave_awsize(vga_slave_awsize),
        .io_slave_awburst(vga_slave_awburst),
        .io_slave_wready(vga_slave_wready),
        .io_slave_wvalid(vga_slave_wvalid),
        .io_slave_wdata(vga_slave_wdata),
        .io_slave_wstrb(vga_slave_wstrb),
        .io_slave_wlast(vga_slave_wlast),
        .io_slave_bready(vga_slave_bready),
        .io_slave_bvalid(vga_slave_bvalid),
        .io_slave_bresp(vga_slave_bresp),
        .io_slave_bid(vga_slave_bid),
        .io_slave_arready(vga_slave_arready),
        .io_slave_arvalid(vga_slave_arvalid),
        .io_slave_araddr(vga_slave_araddr),
        .io_slave_arid(vga_slave_arid),
        .io_slave_arlen(vga_slave_arlen),
        .io_slave_arsize(vga_slave_arsize),
        .io_slave_arburst(vga_slave_arburst),
        .io_slave_rready(vga_slave_rready),
        .io_slave_rvalid(vga_slave_rvalid),
        .io_slave_rresp(vga_slave_rresp),
        .io_slave_rdata(vga_slave_rdata),
        .io_slave_rlast(vga_slave_rlast),
        .io_slave_rid(vga_slave_rid),

        .io_offset(offset),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    Mapping map(
        .clock(clock),
        .reset(~resetn),
        .io_map_in_awready(map_slave_awready),
        .io_map_in_awvalid(map_slave_awvalid),
        .io_map_in_awaddr(map_slave_awaddr),
        .io_map_in_awid(map_slave_awid),
        .io_map_in_awlen(map_slave_awlen),
        .io_map_in_awsize(map_slave_awsize),
        .io_map_in_awburst(map_slave_awburst),
        .io_map_in_wready(map_slave_wready),
        .io_map_in_wvalid(map_slave_wvalid),
        .io_map_in_wdata(map_slave_wdata),
        .io_map_in_wstrb(map_slave_wstrb),
        .io_map_in_wlast(map_slave_wlast),
        .io_map_in_bready(map_slave_bready),
        .io_map_in_bvalid(map_slave_bvalid),
        .io_map_in_bresp(map_slave_bresp),
        .io_map_in_bid(map_slave_bid),
        .io_map_in_arready(map_slave_arready),
        .io_map_in_arvalid(map_slave_arvalid),
        .io_map_in_araddr(map_slave_araddr),
        .io_map_in_arid(map_slave_arid),
        .io_map_in_arlen(map_slave_arlen),
        .io_map_in_arsize(map_slave_arsize),
        .io_map_in_arburst(map_slave_arburst),
        .io_map_in_rready(map_slave_rready),
        .io_map_in_rvalid(map_slave_rvalid),
        .io_map_in_rresp(map_slave_rresp),
        .io_map_in_rdata(map_slave_rdata),
        .io_map_in_rlast(map_slave_rlast),
        .io_map_in_rid(map_slave_rid),
        .io_offset(offset),
        .io_map_out_awready(io_master_awready),
        .io_map_out_awvalid(io_master_awvalid),
        .io_map_out_awaddr(io_master_awaddr),
        .io_map_out_awid(io_master_awid),
        .io_map_out_awlen(io_master_awlen),
        .io_map_out_awsize(io_master_awsize),
        .io_map_out_awburst(io_master_awburst),
        .io_map_out_wready(io_master_wready),
        .io_map_out_wvalid(io_master_wvalid),
        .io_map_out_wdata(io_master_wdata),
        .io_map_out_wstrb(io_master_wstrb),
        .io_map_out_wlast(io_master_wlast),
        .io_map_out_bready(io_master_bready),
        .io_map_out_bvalid(io_master_bvalid),
        .io_map_out_bresp(io_master_bresp),
        .io_map_out_bid(io_master_bid),
        .io_map_out_arready(1'b0),
        // .io_map_out_arvalid,
        // .io_map_out_araddr,
        // .io_map_out_arid,
        // .io_map_out_arlen,
        // .io_map_out_arsize,
        // .io_map_out_arburst,
        // .io_map_out_rready,
        .io_map_out_rvalid(1'b0),
        .io_map_out_rresp(2'b0),
        .io_map_out_rdata(64'b0),
        .io_map_out_rlast(1'b0),
        .io_map_out_rid(4'b0)
    );

endmodule

module VgaCrossbar(
  input         clock,
  input         reset,
  output        io_master_awready,
  input         io_master_awvalid,
  input  [31:0] io_master_awaddr,
  input  [3:0]  io_master_awid,
  input  [7:0]  io_master_awlen,
  input  [2:0]  io_master_awsize,
  input  [1:0]  io_master_awburst,
  output        io_master_wready,
  input         io_master_wvalid,
  input  [63:0] io_master_wdata,
  input  [7:0]  io_master_wstrb,
  input         io_master_wlast,
  input         io_master_bready,
  output        io_master_bvalid,
  output [1:0]  io_master_bresp,
  output [3:0]  io_master_bid,
  output        io_master_arready,
  input         io_master_arvalid,
  input  [31:0] io_master_araddr,
  input  [3:0]  io_master_arid,
  input  [7:0]  io_master_arlen,
  input  [2:0]  io_master_arsize,
  input  [1:0]  io_master_arburst,
  input         io_master_rready,
  output        io_master_rvalid,
  output [1:0]  io_master_rresp,
  output [63:0] io_master_rdata,
  output        io_master_rlast,
  output [3:0]  io_master_rid,
  input         io_vga_slave_awready,
  output        io_vga_slave_awvalid,
  output [31:0] io_vga_slave_awaddr,
  output [3:0]  io_vga_slave_awid,
  output [7:0]  io_vga_slave_awlen,
  output [2:0]  io_vga_slave_awsize,
  output [1:0]  io_vga_slave_awburst,
  input         io_vga_slave_wready,
  output        io_vga_slave_wvalid,
  output [63:0] io_vga_slave_wdata,
  output [7:0]  io_vga_slave_wstrb,
  output        io_vga_slave_wlast,
  output        io_vga_slave_bready,
  input         io_vga_slave_bvalid,
  input  [1:0]  io_vga_slave_bresp,
  input  [3:0]  io_vga_slave_bid,
  input         io_vga_slave_arready,
  output        io_vga_slave_arvalid,
  output [31:0] io_vga_slave_araddr,
  output [3:0]  io_vga_slave_arid,
  output [7:0]  io_vga_slave_arlen,
  output [2:0]  io_vga_slave_arsize,
  output [1:0]  io_vga_slave_arburst,
  output        io_vga_slave_rready,
  input         io_vga_slave_rvalid,
  input  [1:0]  io_vga_slave_rresp,
  input  [63:0] io_vga_slave_rdata,
  input         io_vga_slave_rlast,
  input  [3:0]  io_vga_slave_rid,
  input         io_map_slave_awready,
  output        io_map_slave_awvalid,
  output [31:0] io_map_slave_awaddr,
  output [3:0]  io_map_slave_awid,
  output [7:0]  io_map_slave_awlen,
  output [2:0]  io_map_slave_awsize,
  output [1:0]  io_map_slave_awburst,
  input         io_map_slave_wready,
  output        io_map_slave_wvalid,
  output [63:0] io_map_slave_wdata,
  output [7:0]  io_map_slave_wstrb,
  output        io_map_slave_wlast,
  output        io_map_slave_bready,
  input         io_map_slave_bvalid,
  input  [1:0]  io_map_slave_bresp,
  input  [3:0]  io_map_slave_bid,
  input         io_map_slave_arready,
  output        io_map_slave_arvalid,
  output [31:0] io_map_slave_araddr,
  output [3:0]  io_map_slave_arid,
  output [7:0]  io_map_slave_arlen,
  output [2:0]  io_map_slave_arsize,
  output [1:0]  io_map_slave_arburst,
  output        io_map_slave_rready,
  input         io_map_slave_rvalid,
  input  [1:0]  io_map_slave_rresp,
  input  [63:0] io_map_slave_rdata,
  input         io_map_slave_rlast,
  input  [3:0]  io_map_slave_rid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [1:0] state; // @[vga_crossbar.scala 21:24]
  wire  _T = 2'h0 == state; // @[Conditional.scala 37:30]
  wire [3:0] _GEN_1 = io_master_arvalid | io_master_awvalid ? io_map_slave_rid : 4'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 62:17]
  wire  _GEN_2 = (io_master_arvalid | io_master_awvalid) & io_map_slave_rlast; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 61:17]
  wire [63:0] _GEN_3 = io_master_arvalid | io_master_awvalid ? io_map_slave_rdata : 64'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 60:17]
  wire [1:0] _GEN_4 = io_master_arvalid | io_master_awvalid ? io_map_slave_rresp : 2'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 59:17]
  wire  _GEN_5 = (io_master_arvalid | io_master_awvalid) & io_map_slave_rvalid; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 58:17]
  wire  _GEN_6 = (io_master_arvalid | io_master_awvalid) & io_master_rready; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 82:17]
  wire [1:0] _GEN_7 = io_master_arvalid | io_master_awvalid ? io_master_arburst : 2'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 81:17]
  wire [2:0] _GEN_8 = io_master_arvalid | io_master_awvalid ? io_master_arsize : 3'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 80:17]
  wire [7:0] _GEN_9 = io_master_arvalid | io_master_awvalid ? io_master_arlen : 8'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 79:17]
  wire [3:0] _GEN_10 = io_master_arvalid | io_master_awvalid ? io_master_arid : 4'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 78:17]
  wire [31:0] _GEN_11 = io_master_arvalid | io_master_awvalid ? io_master_araddr : 32'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 77:17]
  wire  _GEN_12 = (io_master_arvalid | io_master_awvalid) & io_master_arvalid; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 76:17]
  wire  _GEN_13 = (io_master_arvalid | io_master_awvalid) & io_map_slave_arready; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 57:17]
  wire [3:0] _GEN_14 = io_master_arvalid | io_master_awvalid ? io_map_slave_bid : 4'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 56:17]
  wire [1:0] _GEN_15 = io_master_arvalid | io_master_awvalid ? io_map_slave_bresp : 2'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 55:17]
  wire  _GEN_16 = (io_master_arvalid | io_master_awvalid) & io_map_slave_bvalid; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 54:17]
  wire  _GEN_17 = (io_master_arvalid | io_master_awvalid) & io_master_bready; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 75:17]
  wire  _GEN_18 = (io_master_arvalid | io_master_awvalid) & io_master_wlast; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 74:17]
  wire [7:0] _GEN_19 = io_master_arvalid | io_master_awvalid ? io_master_wstrb : 8'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 73:17]
  wire [63:0] _GEN_20 = io_master_arvalid | io_master_awvalid ? io_master_wdata : 64'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 72:17]
  wire  _GEN_21 = (io_master_arvalid | io_master_awvalid) & io_master_wvalid; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 71:17]
  wire  _GEN_22 = (io_master_arvalid | io_master_awvalid) & io_map_slave_wready; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 53:17]
  wire [1:0] _GEN_23 = io_master_arvalid | io_master_awvalid ? io_master_awburst : 2'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 70:17]
  wire [2:0] _GEN_24 = io_master_arvalid | io_master_awvalid ? io_master_awsize : 3'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 69:17]
  wire [7:0] _GEN_25 = io_master_arvalid | io_master_awvalid ? io_master_awlen : 8'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 68:17]
  wire [3:0] _GEN_26 = io_master_arvalid | io_master_awvalid ? io_master_awid : 4'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 67:17]
  wire [31:0] _GEN_27 = io_master_arvalid | io_master_awvalid ? io_master_awaddr : 32'h0; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 66:17]
  wire  _GEN_28 = (io_master_arvalid | io_master_awvalid) & io_master_awvalid; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 65:17]
  wire  _GEN_29 = (io_master_arvalid | io_master_awvalid) & io_map_slave_awready; // @[vga_crossbar.scala 30:63 vga_crossbar.scala 32:27 cpu.scala 52:17]
  wire [3:0] _GEN_31 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_rid : _GEN_1; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_32 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_rlast :
    _GEN_2; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire [63:0] _GEN_33 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_rdata :
    _GEN_3; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire [1:0] _GEN_34 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_rresp :
    _GEN_4; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_35 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_rvalid :
    _GEN_5; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_36 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_rready; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 82:17]
  wire [1:0] _GEN_37 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_arburst : 2'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 81:17]
  wire [2:0] _GEN_38 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_arsize : 3'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 80:17]
  wire [7:0] _GEN_39 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_arlen : 8'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 79:17]
  wire [3:0] _GEN_40 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_arid : 4'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 78:17]
  wire [31:0] _GEN_41 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_araddr : 32'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 77:17]
  wire  _GEN_42 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_arvalid; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 76:17]
  wire  _GEN_43 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_arready :
    _GEN_13; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire [3:0] _GEN_44 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_bid : _GEN_14
    ; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire [1:0] _GEN_45 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_bresp :
    _GEN_15; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_46 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_bvalid :
    _GEN_16; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_47 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_bready; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 75:17]
  wire  _GEN_48 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_wlast; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 74:17]
  wire [7:0] _GEN_49 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_wstrb : 8'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 73:17]
  wire [63:0] _GEN_50 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_wdata : 64'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 72:17]
  wire  _GEN_51 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_wvalid; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 71:17]
  wire  _GEN_52 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_wready :
    _GEN_22; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire [1:0] _GEN_53 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_awburst : 2'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 70:17]
  wire [2:0] _GEN_54 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_awsize : 3'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 69:17]
  wire [7:0] _GEN_55 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_awlen : 8'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 68:17]
  wire [3:0] _GEN_56 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_awid : 4'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 67:17]
  wire [31:0] _GEN_57 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_master_awaddr : 32'h0; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 66:17]
  wire  _GEN_58 = (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) & io_master_awvalid; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27 cpu.scala 65:17]
  wire  _GEN_59 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? io_vga_slave_awready :
    _GEN_29; // @[vga_crossbar.scala 27:269 vga_crossbar.scala 29:27]
  wire  _GEN_60 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_6; // @[vga_crossbar.scala 27:269 cpu.scala 82:17]
  wire [1:0] _GEN_61 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 2'h0 : _GEN_7; // @[vga_crossbar.scala 27:269 cpu.scala 81:17]
  wire [2:0] _GEN_62 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 3'h0 : _GEN_8; // @[vga_crossbar.scala 27:269 cpu.scala 80:17]
  wire [7:0] _GEN_63 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 8'h0 : _GEN_9; // @[vga_crossbar.scala 27:269 cpu.scala 79:17]
  wire [3:0] _GEN_64 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 4'h0 : _GEN_10; // @[vga_crossbar.scala 27:269 cpu.scala 78:17]
  wire [31:0] _GEN_65 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 32'h0 : _GEN_11; // @[vga_crossbar.scala 27:269 cpu.scala 77:17]
  wire  _GEN_66 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_12; // @[vga_crossbar.scala 27:269 cpu.scala 76:17]
  wire  _GEN_67 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_17; // @[vga_crossbar.scala 27:269 cpu.scala 75:17]
  wire  _GEN_68 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_18; // @[vga_crossbar.scala 27:269 cpu.scala 74:17]
  wire [7:0] _GEN_69 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 8'h0 : _GEN_19; // @[vga_crossbar.scala 27:269 cpu.scala 73:17]
  wire [63:0] _GEN_70 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 64'h0 : _GEN_20; // @[vga_crossbar.scala 27:269 cpu.scala 72:17]
  wire  _GEN_71 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_21; // @[vga_crossbar.scala 27:269 cpu.scala 71:17]
  wire [1:0] _GEN_72 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 2'h0 : _GEN_23; // @[vga_crossbar.scala 27:269 cpu.scala 70:17]
  wire [2:0] _GEN_73 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 3'h0 : _GEN_24; // @[vga_crossbar.scala 27:269 cpu.scala 69:17]
  wire [7:0] _GEN_74 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 8'h0 : _GEN_25; // @[vga_crossbar.scala 27:269 cpu.scala 68:17]
  wire [3:0] _GEN_75 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 4'h0 : _GEN_26; // @[vga_crossbar.scala 27:269 cpu.scala 67:17]
  wire [31:0] _GEN_76 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 32'h0 : _GEN_27; // @[vga_crossbar.scala 27:269 cpu.scala 66:17]
  wire  _GEN_77 = io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) |
    io_master_awvalid & (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000) ? 1'h0 : _GEN_28; // @[vga_crossbar.scala 27:269 cpu.scala 65:17]
  wire  _T_11 = 2'h1 == state; // @[Conditional.scala 37:30]
  wire  _T_15 = 2'h2 == state; // @[Conditional.scala 37:30]
  wire [1:0] _GEN_79 = io_map_slave_rvalid & io_map_slave_rlast | io_map_slave_bready & io_map_slave_bvalid ? 2'h0 :
    state; // @[vga_crossbar.scala 43:110 vga_crossbar.scala 44:23 vga_crossbar.scala 21:24]
  wire [3:0] _GEN_80 = _T_15 ? io_map_slave_rid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 62:17]
  wire  _GEN_81 = _T_15 & io_map_slave_rlast; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 61:17]
  wire [63:0] _GEN_82 = _T_15 ? io_map_slave_rdata : 64'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 60:17]
  wire [1:0] _GEN_83 = _T_15 ? io_map_slave_rresp : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 59:17]
  wire  _GEN_84 = _T_15 & io_map_slave_rvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 58:17]
  wire  _GEN_85 = _T_15 & io_master_rready; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 82:17]
  wire [1:0] _GEN_86 = _T_15 ? io_master_arburst : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 81:17]
  wire [2:0] _GEN_87 = _T_15 ? io_master_arsize : 3'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 80:17]
  wire [7:0] _GEN_88 = _T_15 ? io_master_arlen : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 79:17]
  wire [3:0] _GEN_89 = _T_15 ? io_master_arid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 78:17]
  wire [31:0] _GEN_90 = _T_15 ? io_master_araddr : 32'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 77:17]
  wire  _GEN_91 = _T_15 & io_master_arvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 76:17]
  wire  _GEN_92 = _T_15 & io_map_slave_arready; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 57:17]
  wire [3:0] _GEN_93 = _T_15 ? io_map_slave_bid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 56:17]
  wire [1:0] _GEN_94 = _T_15 ? io_map_slave_bresp : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 55:17]
  wire  _GEN_95 = _T_15 & io_map_slave_bvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 54:17]
  wire  _GEN_96 = _T_15 & io_master_bready; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 75:17]
  wire  _GEN_97 = _T_15 & io_master_wlast; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 74:17]
  wire [7:0] _GEN_98 = _T_15 ? io_master_wstrb : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 73:17]
  wire [63:0] _GEN_99 = _T_15 ? io_master_wdata : 64'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 72:17]
  wire  _GEN_100 = _T_15 & io_master_wvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 71:17]
  wire  _GEN_101 = _T_15 & io_map_slave_wready; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 53:17]
  wire [1:0] _GEN_102 = _T_15 ? io_master_awburst : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 70:17]
  wire [2:0] _GEN_103 = _T_15 ? io_master_awsize : 3'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 69:17]
  wire [7:0] _GEN_104 = _T_15 ? io_master_awlen : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 68:17]
  wire [3:0] _GEN_105 = _T_15 ? io_master_awid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 67:17]
  wire [31:0] _GEN_106 = _T_15 ? io_master_awaddr : 32'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 66:17]
  wire  _GEN_107 = _T_15 & io_master_awvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 65:17]
  wire  _GEN_108 = _T_15 & io_map_slave_awready; // @[Conditional.scala 39:67 vga_crossbar.scala 42:23 cpu.scala 52:17]
  wire [3:0] _GEN_110 = _T_11 ? io_vga_slave_rid : _GEN_80; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_111 = _T_11 ? io_vga_slave_rlast : _GEN_81; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire [63:0] _GEN_112 = _T_11 ? io_vga_slave_rdata : _GEN_82; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire [1:0] _GEN_113 = _T_11 ? io_vga_slave_rresp : _GEN_83; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_114 = _T_11 ? io_vga_slave_rvalid : _GEN_84; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_115 = _T_11 & io_master_rready; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 82:17]
  wire [1:0] _GEN_116 = _T_11 ? io_master_arburst : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 81:17]
  wire [2:0] _GEN_117 = _T_11 ? io_master_arsize : 3'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 80:17]
  wire [7:0] _GEN_118 = _T_11 ? io_master_arlen : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 79:17]
  wire [3:0] _GEN_119 = _T_11 ? io_master_arid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 78:17]
  wire [31:0] _GEN_120 = _T_11 ? io_master_araddr : 32'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 77:17]
  wire  _GEN_121 = _T_11 & io_master_arvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 76:17]
  wire  _GEN_122 = _T_11 ? io_vga_slave_arready : _GEN_92; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire [3:0] _GEN_123 = _T_11 ? io_vga_slave_bid : _GEN_93; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire [1:0] _GEN_124 = _T_11 ? io_vga_slave_bresp : _GEN_94; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_125 = _T_11 ? io_vga_slave_bvalid : _GEN_95; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_126 = _T_11 & io_master_bready; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 75:17]
  wire  _GEN_127 = _T_11 & io_master_wlast; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 74:17]
  wire [7:0] _GEN_128 = _T_11 ? io_master_wstrb : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 73:17]
  wire [63:0] _GEN_129 = _T_11 ? io_master_wdata : 64'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 72:17]
  wire  _GEN_130 = _T_11 & io_master_wvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 71:17]
  wire  _GEN_131 = _T_11 ? io_vga_slave_wready : _GEN_101; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire [1:0] _GEN_132 = _T_11 ? io_master_awburst : 2'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 70:17]
  wire [2:0] _GEN_133 = _T_11 ? io_master_awsize : 3'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 69:17]
  wire [7:0] _GEN_134 = _T_11 ? io_master_awlen : 8'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 68:17]
  wire [3:0] _GEN_135 = _T_11 ? io_master_awid : 4'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 67:17]
  wire [31:0] _GEN_136 = _T_11 ? io_master_awaddr : 32'h0; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 66:17]
  wire  _GEN_137 = _T_11 & io_master_awvalid; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23 cpu.scala 65:17]
  wire  _GEN_138 = _T_11 ? io_vga_slave_awready : _GEN_108; // @[Conditional.scala 39:67 vga_crossbar.scala 36:23]
  wire  _GEN_140 = _T_11 ? 1'h0 : _GEN_85; // @[Conditional.scala 39:67 cpu.scala 82:17]
  wire [1:0] _GEN_141 = _T_11 ? 2'h0 : _GEN_86; // @[Conditional.scala 39:67 cpu.scala 81:17]
  wire [2:0] _GEN_142 = _T_11 ? 3'h0 : _GEN_87; // @[Conditional.scala 39:67 cpu.scala 80:17]
  wire [7:0] _GEN_143 = _T_11 ? 8'h0 : _GEN_88; // @[Conditional.scala 39:67 cpu.scala 79:17]
  wire [3:0] _GEN_144 = _T_11 ? 4'h0 : _GEN_89; // @[Conditional.scala 39:67 cpu.scala 78:17]
  wire [31:0] _GEN_145 = _T_11 ? 32'h0 : _GEN_90; // @[Conditional.scala 39:67 cpu.scala 77:17]
  wire  _GEN_146 = _T_11 ? 1'h0 : _GEN_91; // @[Conditional.scala 39:67 cpu.scala 76:17]
  wire  _GEN_147 = _T_11 ? 1'h0 : _GEN_96; // @[Conditional.scala 39:67 cpu.scala 75:17]
  wire  _GEN_148 = _T_11 ? 1'h0 : _GEN_97; // @[Conditional.scala 39:67 cpu.scala 74:17]
  wire [7:0] _GEN_149 = _T_11 ? 8'h0 : _GEN_98; // @[Conditional.scala 39:67 cpu.scala 73:17]
  wire [63:0] _GEN_150 = _T_11 ? 64'h0 : _GEN_99; // @[Conditional.scala 39:67 cpu.scala 72:17]
  wire  _GEN_151 = _T_11 ? 1'h0 : _GEN_100; // @[Conditional.scala 39:67 cpu.scala 71:17]
  wire [1:0] _GEN_152 = _T_11 ? 2'h0 : _GEN_102; // @[Conditional.scala 39:67 cpu.scala 70:17]
  wire [2:0] _GEN_153 = _T_11 ? 3'h0 : _GEN_103; // @[Conditional.scala 39:67 cpu.scala 69:17]
  wire [7:0] _GEN_154 = _T_11 ? 8'h0 : _GEN_104; // @[Conditional.scala 39:67 cpu.scala 68:17]
  wire [3:0] _GEN_155 = _T_11 ? 4'h0 : _GEN_105; // @[Conditional.scala 39:67 cpu.scala 67:17]
  wire [31:0] _GEN_156 = _T_11 ? 32'h0 : _GEN_106; // @[Conditional.scala 39:67 cpu.scala 66:17]
  wire  _GEN_157 = _T_11 ? 1'h0 : _GEN_107; // @[Conditional.scala 39:67 cpu.scala 65:17]
  assign io_master_awready = _T ? _GEN_59 : _GEN_138; // @[Conditional.scala 40:58]
  assign io_master_wready = _T ? _GEN_52 : _GEN_131; // @[Conditional.scala 40:58]
  assign io_master_bvalid = _T ? _GEN_46 : _GEN_125; // @[Conditional.scala 40:58]
  assign io_master_bresp = _T ? _GEN_45 : _GEN_124; // @[Conditional.scala 40:58]
  assign io_master_bid = _T ? _GEN_44 : _GEN_123; // @[Conditional.scala 40:58]
  assign io_master_arready = _T ? _GEN_43 : _GEN_122; // @[Conditional.scala 40:58]
  assign io_master_rvalid = _T ? _GEN_35 : _GEN_114; // @[Conditional.scala 40:58]
  assign io_master_rresp = _T ? _GEN_34 : _GEN_113; // @[Conditional.scala 40:58]
  assign io_master_rdata = _T ? _GEN_33 : _GEN_112; // @[Conditional.scala 40:58]
  assign io_master_rlast = _T ? _GEN_32 : _GEN_111; // @[Conditional.scala 40:58]
  assign io_master_rid = _T ? _GEN_31 : _GEN_110; // @[Conditional.scala 40:58]
  assign io_vga_slave_awvalid = _T ? _GEN_58 : _GEN_137; // @[Conditional.scala 40:58]
  assign io_vga_slave_awaddr = _T ? _GEN_57 : _GEN_136; // @[Conditional.scala 40:58]
  assign io_vga_slave_awid = _T ? _GEN_56 : _GEN_135; // @[Conditional.scala 40:58]
  assign io_vga_slave_awlen = _T ? _GEN_55 : _GEN_134; // @[Conditional.scala 40:58]
  assign io_vga_slave_awsize = _T ? _GEN_54 : _GEN_133; // @[Conditional.scala 40:58]
  assign io_vga_slave_awburst = _T ? _GEN_53 : _GEN_132; // @[Conditional.scala 40:58]
  assign io_vga_slave_wvalid = _T ? _GEN_51 : _GEN_130; // @[Conditional.scala 40:58]
  assign io_vga_slave_wdata = _T ? _GEN_50 : _GEN_129; // @[Conditional.scala 40:58]
  assign io_vga_slave_wstrb = _T ? _GEN_49 : _GEN_128; // @[Conditional.scala 40:58]
  assign io_vga_slave_wlast = _T ? _GEN_48 : _GEN_127; // @[Conditional.scala 40:58]
  assign io_vga_slave_bready = _T ? _GEN_47 : _GEN_126; // @[Conditional.scala 40:58]
  assign io_vga_slave_arvalid = _T ? _GEN_42 : _GEN_121; // @[Conditional.scala 40:58]
  assign io_vga_slave_araddr = _T ? _GEN_41 : _GEN_120; // @[Conditional.scala 40:58]
  assign io_vga_slave_arid = _T ? _GEN_40 : _GEN_119; // @[Conditional.scala 40:58]
  assign io_vga_slave_arlen = _T ? _GEN_39 : _GEN_118; // @[Conditional.scala 40:58]
  assign io_vga_slave_arsize = _T ? _GEN_38 : _GEN_117; // @[Conditional.scala 40:58]
  assign io_vga_slave_arburst = _T ? _GEN_37 : _GEN_116; // @[Conditional.scala 40:58]
  assign io_vga_slave_rready = _T ? _GEN_36 : _GEN_115; // @[Conditional.scala 40:58]
  assign io_map_slave_awvalid = _T ? _GEN_77 : _GEN_157; // @[Conditional.scala 40:58]
  assign io_map_slave_awaddr = _T ? _GEN_76 : _GEN_156; // @[Conditional.scala 40:58]
  assign io_map_slave_awid = _T ? _GEN_75 : _GEN_155; // @[Conditional.scala 40:58]
  assign io_map_slave_awlen = _T ? _GEN_74 : _GEN_154; // @[Conditional.scala 40:58]
  assign io_map_slave_awsize = _T ? _GEN_73 : _GEN_153; // @[Conditional.scala 40:58]
  assign io_map_slave_awburst = _T ? _GEN_72 : _GEN_152; // @[Conditional.scala 40:58]
  assign io_map_slave_wvalid = _T ? _GEN_71 : _GEN_151; // @[Conditional.scala 40:58]
  assign io_map_slave_wdata = _T ? _GEN_70 : _GEN_150; // @[Conditional.scala 40:58]
  assign io_map_slave_wstrb = _T ? _GEN_69 : _GEN_149; // @[Conditional.scala 40:58]
  assign io_map_slave_wlast = _T ? _GEN_68 : _GEN_148; // @[Conditional.scala 40:58]
  assign io_map_slave_bready = _T ? _GEN_67 : _GEN_147; // @[Conditional.scala 40:58]
  assign io_map_slave_arvalid = _T ? _GEN_66 : _GEN_146; // @[Conditional.scala 40:58]
  assign io_map_slave_araddr = _T ? _GEN_65 : _GEN_145; // @[Conditional.scala 40:58]
  assign io_map_slave_arid = _T ? _GEN_64 : _GEN_144; // @[Conditional.scala 40:58]
  assign io_map_slave_arlen = _T ? _GEN_63 : _GEN_143; // @[Conditional.scala 40:58]
  assign io_map_slave_arsize = _T ? _GEN_62 : _GEN_142; // @[Conditional.scala 40:58]
  assign io_map_slave_arburst = _T ? _GEN_61 : _GEN_141; // @[Conditional.scala 40:58]
  assign io_map_slave_rready = _T ? _GEN_60 : _GEN_140; // @[Conditional.scala 40:58]
  always @(posedge clock) begin
    if (reset) begin // @[vga_crossbar.scala 21:24]
      state <= 2'h0; // @[vga_crossbar.scala 21:24]
    end else if (_T) begin // @[Conditional.scala 40:58]
      if (io_master_arvalid & (io_master_araddr > 32'h10000000 & io_master_araddr < 32'h11000000) | io_master_awvalid &
        (io_master_awaddr > 32'h10000000 & io_master_awaddr < 32'h11000000)) begin // @[vga_crossbar.scala 27:269]
        state <= 2'h1; // @[vga_crossbar.scala 28:23]
      end else if (io_master_arvalid | io_master_awvalid) begin // @[vga_crossbar.scala 30:63]
        state <= 2'h2; // @[vga_crossbar.scala 31:23]
      end
    end else if (_T_11) begin // @[Conditional.scala 39:67]
      if (io_vga_slave_rvalid & io_vga_slave_rlast | io_vga_slave_bready & io_vga_slave_bvalid) begin // @[vga_crossbar.scala 37:110]
        state <= 2'h0; // @[vga_crossbar.scala 38:23]
      end
    end else if (_T_15) begin // @[Conditional.scala 39:67]
      state <= _GEN_79;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  state = _RAND_0[1:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Mapping(
  input         clock,
  input         reset,
  output        io_map_in_awready,
  input         io_map_in_awvalid,
  input  [31:0] io_map_in_awaddr,
  input  [3:0]  io_map_in_awid,
  input  [7:0]  io_map_in_awlen,
  input  [2:0]  io_map_in_awsize,
  input  [1:0]  io_map_in_awburst,
  output        io_map_in_wready,
  input         io_map_in_wvalid,
  input  [63:0] io_map_in_wdata,
  input  [7:0]  io_map_in_wstrb,
  input         io_map_in_wlast,
  input         io_map_in_bready,
  output        io_map_in_bvalid,
  output [1:0]  io_map_in_bresp,
  output [3:0]  io_map_in_bid,
  output        io_map_in_arready,
  input         io_map_in_arvalid,
  input  [31:0] io_map_in_araddr,
  input  [3:0]  io_map_in_arid,
  input  [7:0]  io_map_in_arlen,
  input  [2:0]  io_map_in_arsize,
  input  [1:0]  io_map_in_arburst,
  input         io_map_in_rready,
  output        io_map_in_rvalid,
  output [1:0]  io_map_in_rresp,
  output [63:0] io_map_in_rdata,
  output        io_map_in_rlast,
  output [3:0]  io_map_in_rid,
  input  [31:0] io_offset,
  input         io_map_out_awready,
  output        io_map_out_awvalid,
  output [31:0] io_map_out_awaddr,
  output [3:0]  io_map_out_awid,
  output [7:0]  io_map_out_awlen,
  output [2:0]  io_map_out_awsize,
  output [1:0]  io_map_out_awburst,
  input         io_map_out_wready,
  output        io_map_out_wvalid,
  output [63:0] io_map_out_wdata,
  output [7:0]  io_map_out_wstrb,
  output        io_map_out_wlast,
  output        io_map_out_bready,
  input         io_map_out_bvalid,
  input  [1:0]  io_map_out_bresp,
  input  [3:0]  io_map_out_bid,
  input         io_map_out_arready,
  output        io_map_out_arvalid,
  output [31:0] io_map_out_araddr,
  output [3:0]  io_map_out_arid,
  output [7:0]  io_map_out_arlen,
  output [2:0]  io_map_out_arsize,
  output [1:0]  io_map_out_arburst,
  output        io_map_out_rready,
  input         io_map_out_rvalid,
  input  [1:0]  io_map_out_rresp,
  input  [63:0] io_map_out_rdata,
  input         io_map_out_rlast,
  input  [3:0]  io_map_out_rid
);
  assign io_map_in_awready = io_map_out_awready; // @[mapping.scala 80:16]
  assign io_map_in_wready = io_map_out_wready; // @[mapping.scala 80:16]
  assign io_map_in_bvalid = io_map_out_bvalid; // @[mapping.scala 80:16]
  assign io_map_in_bresp = io_map_out_bresp; // @[mapping.scala 80:16]
  assign io_map_in_bid = io_map_out_bid; // @[mapping.scala 80:16]
  assign io_map_in_arready = io_map_out_arready; // @[mapping.scala 80:16]
  assign io_map_in_rvalid = io_map_out_rvalid; // @[mapping.scala 80:16]
  assign io_map_in_rresp = io_map_out_rresp; // @[mapping.scala 80:16]
  assign io_map_in_rdata = io_map_out_rdata; // @[mapping.scala 80:16]
  assign io_map_in_rlast = io_map_out_rlast; // @[mapping.scala 80:16]
  assign io_map_in_rid = io_map_out_rid; // @[mapping.scala 80:16]
  assign io_map_out_awvalid = io_map_in_awvalid; // @[mapping.scala 80:16]
  assign io_map_out_awaddr = io_map_in_awaddr + io_offset; // @[mapping.scala 81:43]
  assign io_map_out_awid = io_map_in_awid; // @[mapping.scala 80:16]
  assign io_map_out_awlen = io_map_in_awlen; // @[mapping.scala 80:16]
  assign io_map_out_awsize = io_map_in_awsize; // @[mapping.scala 80:16]
  assign io_map_out_awburst = io_map_in_awburst; // @[mapping.scala 80:16]
  assign io_map_out_wvalid = io_map_in_wvalid; // @[mapping.scala 80:16]
  assign io_map_out_wdata = io_map_in_wdata; // @[mapping.scala 80:16]
  assign io_map_out_wstrb = io_map_in_wstrb; // @[mapping.scala 80:16]
  assign io_map_out_wlast = io_map_in_wlast; // @[mapping.scala 80:16]
  assign io_map_out_bready = io_map_in_bready; // @[mapping.scala 80:16]
  assign io_map_out_arvalid = io_map_in_arvalid; // @[mapping.scala 80:16]
  assign io_map_out_araddr = io_map_in_araddr + io_offset; // @[mapping.scala 82:43]
  assign io_map_out_arid = io_map_in_arid; // @[mapping.scala 80:16]
  assign io_map_out_arlen = io_map_in_arlen; // @[mapping.scala 80:16]
  assign io_map_out_arsize = io_map_in_arsize; // @[mapping.scala 80:16]
  assign io_map_out_arburst = io_map_in_arburst; // @[mapping.scala 80:16]
  assign io_map_out_rready = io_map_in_rready; // @[mapping.scala 80:16]
endmodule
module preg #(parameter w = 1, parameter reset_val = 0)(
    input clock,
    input reset,
    input [w-1:0] din,
    output [w-1:0] dout,
    input wen
);

reg [w-1:0] data;
assign dout = data;

always @(posedge clock) begin
    if(reset)
        data <= reset_val;
    else if(wen)
        data <= din; 
end

endmodule

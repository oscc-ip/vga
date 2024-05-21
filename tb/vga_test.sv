// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vga is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_VGA_TEST_SV
`define INC_VGA_TEST_SV

`include "apb4_master.sv"
`include "vga_define.sv"

class VGATest extends APB4Master;
  string                 name;
  int                    wr_val;
  virtual apb4_if.master apb4;
  virtual vga_if.tb      vga;

  extern function new(string name = "vga_test", virtual apb4_if.master apb4, virtual vga_if.tb vga);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_clk_div(input bit [31:0] run_times = 10);
  extern task automatic test_tm_mode(input bit [31:0] run_times = 10);
  extern task automatic test_rd_fb(input bit [31:0] run_times = 10);
  extern task automatic test_irq(input bit [31:0] run_times = 10);
endclass

function VGATest::new(string name, virtual apb4_if.master apb4, virtual vga_if.tb vga);
  super.new("apb4_master", apb4);
  this.name   = name;
  this.wr_val = 0;
  this.apb4   = apb4;
  this.vga    = vga;
endfunction

task automatic VGATest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`VGA_CTRL_ADDR,  "CTRL  REG", 32'b0 & {`VGA_CTRL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_HVVL_ADDR,  "HVVL  REG", 32'b0 & {`VGA_HVVL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_HTIM_ADDR,  "HTIM  REG", 32'b0 & {`VGA_HTIM_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_VTIM_ADDR,  "VTIM  REG", 32'b0 & {`VGA_VTIM_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_FBBA1_ADDR, "FBBA1 REG", 32'b0 & {`VGA_FBBA1_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_FBBA2_ADDR, "FBBA2 REG", 32'b0 & {`VGA_FBBA2_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_THOLD_ADDR, "THOLD REG", 32'b0 & {`VGA_THOLD_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGA_STAT_ADDR,  "STAT  REG", 32'b0 & {`VGA_STAT_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic VGATest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    // this.wr_rd_check(`VGA_CTRL_ADDR   , "CTRL    REG", $random & {`VGA_CTRL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_HVVL_ADDR,  "HVVL  REG", $random & {`VGA_HVVL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_HTIM_ADDR,  "HTIM  REG", $random & {`VGA_HTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_VTIM_ADDR,  "VTIM  REG", $random & {`VGA_VTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_FBBA1_ADDR, "FBBA1 REG", $random & {`VGA_FBBA1_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_FBBA2_ADDR, "FBBA2 REG", $random & {`VGA_FBBA2_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_THOLD_ADDR, "THOLD REG", $random & {`VGA_THOLD_WIDTH{1'b1}}, Helper::EQUL);
  end
    this.wr_rd_check(`VGA_HVVL_ADDR,  "HVVL  REG", 32'b0 & {`VGA_HVVL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_HTIM_ADDR,  "HTIM  REG", 32'b0 & {`VGA_HTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_VTIM_ADDR,  "VTIM  REG", 32'b0 & {`VGA_VTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_FBBA1_ADDR, "FBBA1 REG", 32'b0 & {`VGA_FBBA1_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_FBBA2_ADDR, "FBBA2 REG", 32'b0 & {`VGA_FBBA2_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGA_THOLD_ADDR, "THOLD REG", 32'b0 & {`VGA_THOLD_WIDTH{1'b1}}, Helper::EQUL);
  // verilog_format: on
endtask

task automatic VGATest::test_clk_div(input bit [31:0] run_times = 10);
  $display("=== [test vga clk div] ===");
  // div 2
  this.write(`VGA_CTRL_ADDR, '0 & {`VGA_CTRL_WIDTH{1'b1}});
  repeat (50) @(posedge this.apb4.pclk);
  // div 4
  this.write(`VGA_CTRL_ADDR, 32'h02_00 & {`VGA_CTRL_WIDTH{1'b1}});
  repeat (50) @(posedge this.apb4.pclk);
endtask

task automatic VGATest::test_tm_mode(input bit [31:0] run_times = 10);
  $display("=== [test vga test mode] ===");
  this.write(`VGA_CTRL_ADDR, 32'b0 & {`VGA_CTRL_WIDTH{1'b1}});
  // ((480-1) << 16) | (640-1)
  this.write(`VGA_HVVL_ADDR, 32'h1DF_027F & {`VGA_CTRL_WIDTH{1'b1}});
  // ((48-1) << 20) | ((96-1) << 10) | (16-1)
  this.write(`VGA_HTIM_ADDR, 32'h2F1_7C0F & {`VGA_HTIM_WIDTH{1'b1}});
  // ((33-1) << 20) | ((2-1) << 10) | (10-1)
  this.write(`VGA_VTIM_ADDR, 32'h200_0409 & {`VGA_VTIM_WIDTH{1'b1}});
  // div 4, test, en, rgb444
  this.write(`VGA_CTRL_ADDR, 32'h11_02_01 & {`VGA_CTRL_WIDTH{1'b1}});
  repeat (800 * 525 * 4) @(posedge this.apb4.pclk);
endtask

task automatic VGATest::test_rd_fb(input bit [31:0] run_times = 10);
  bit [31:0] ctrl_val = '0;
  bit [3:0] switch_cnt = '0;
  $display("=== [test vga rd fb] ===");
  repeat (800 * 525 * 4) @(posedge this.apb4.pclk);
  this.write(`VGA_CTRL_ADDR, 32'b0 & {`VGA_CTRL_WIDTH{1'b1}});
  this.write(`VGA_STAT_ADDR, 4'b0000);
  // ((480-1) << 16) | (640-1)
  this.write(`VGA_HVVL_ADDR, 32'h1DF_027F & {`VGA_CTRL_WIDTH{1'b1}});
  // ((48-1) << 20) | ((96-1) << 10) | (16-1)
  this.write(`VGA_HTIM_ADDR, 32'h2F1_7C0F & {`VGA_HTIM_WIDTH{1'b1}});
  // ((33-1) << 20) | ((2-1) << 10) | (10-1)
  this.write(`VGA_VTIM_ADDR, 32'h200_0409 & {`VGA_VTIM_WIDTH{1'b1}});
  this.write(`VGA_FBBA1_ADDR, 32'h8000_0000);  // 0x9_6000
  this.write(`VGA_FBBA2_ADDR, 32'h8010_0000);
  this.write(`VGA_THOLD_ADDR, 32'd256);
  // div 4, test, en, rgb444
  ctrl_val[0]     = 1'd1;
  ctrl_val[3]     = 1'd1;
  ctrl_val[4]     = 1'd1;
  ctrl_val[15:8]  = 8'd2;
  ctrl_val[18:17] = 2'd1;
  ctrl_val[26:19] = 8'd63;
  this.write(`VGA_CTRL_ADDR, ctrl_val & {`VGA_CTRL_WIDTH{1'b1}});
  // for (int i = 0; i < 100; i++) begin
  //   repeat (800 * 525 * 100) @(posedge this.apb4.pclk);
  // end
  while (switch_cnt < 4'd4) begin
    this.read(`VGA_STAT_ADDR);
    if (super.rd_data[2] == 1'b1) begin
      if (super.rd_data[3] == 0) begin
        $display("switch to fb2");
      end else begin
        $display("switch to fb1");
      end
      ++switch_cnt;
      this.write(`VGA_STAT_ADDR, 4'b0000);
    end
  end
endtask

task automatic VGATest::test_irq(input bit [31:0] run_times = 10);
  super.test_irq();
endtask
`endif

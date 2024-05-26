// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vgalcd is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_VGALCD_TEST_SV
`define INC_VGALCD_TEST_SV

`include "apb4_master.sv"
`include "vgalcd_define.sv"

class VGALCDTest extends APB4Master;
  string                 name;
  int                    wr_val;
  virtual apb4_if.master apb4;
  virtual vgalcd_if.tb      vgalcd;

  extern function new(string name = "vgalcd_test", virtual apb4_if.master apb4, virtual vgalcd_if.tb vgalcd);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_clk_div(input bit [31:0] run_times = 10);
  extern task automatic test_tm_mode(input bit [31:0] run_times = 10);
  extern task automatic test_rd_fb(input bit [31:0] run_times = 10);
  extern task automatic test_irq(input bit [31:0] run_times = 10);
endclass

function VGALCDTest::new(string name, virtual apb4_if.master apb4, virtual vgalcd_if.tb vgalcd);
  super.new("apb4_master", apb4);
  this.name   = name;
  this.wr_val = 0;
  this.apb4   = apb4;
  this.vgalcd    = vgalcd;
endfunction

task automatic VGALCDTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`VGALCD_CTRL_ADDR,  "CTRL  REG", 32'b0 & {`VGALCD_CTRL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_HVVL_ADDR,  "HVVL  REG", 32'b0 & {`VGALCD_HVVL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_HTIM_ADDR,  "HTIM  REG", 32'b0 & {`VGALCD_HTIM_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_VTIM_ADDR,  "VTIM  REG", 32'b0 & {`VGALCD_VTIM_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_FBBA1_ADDR, "FBBA1 REG", 32'b0 & {`VGALCD_FBBA1_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_FBBA2_ADDR, "FBBA2 REG", 32'b0 & {`VGALCD_FBBA2_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_THOLD_ADDR, "THOLD REG", 32'b0 & {`VGALCD_THOLD_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`VGALCD_STAT_ADDR,  "STAT  REG", 32'b0 & {`VGALCD_STAT_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic VGALCDTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    // this.wr_rd_check(`VGALCD_CTRL_ADDR   , "CTRL    REG", $random & {`VGALCD_CTRL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_HVVL_ADDR,  "HVVL  REG", $random & {`VGALCD_HVVL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_HTIM_ADDR,  "HTIM  REG", $random & {`VGALCD_HTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_VTIM_ADDR,  "VTIM  REG", $random & {`VGALCD_VTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_FBBA1_ADDR, "FBBA1 REG", $random & {`VGALCD_FBBA1_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_FBBA2_ADDR, "FBBA2 REG", $random & {`VGALCD_FBBA2_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_THOLD_ADDR, "THOLD REG", $random & {`VGALCD_THOLD_WIDTH{1'b1}}, Helper::EQUL);
  end
    this.wr_rd_check(`VGALCD_HVVL_ADDR,  "HVVL  REG", 32'b0 & {`VGALCD_HVVL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_HTIM_ADDR,  "HTIM  REG", 32'b0 & {`VGALCD_HTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_VTIM_ADDR,  "VTIM  REG", 32'b0 & {`VGALCD_VTIM_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_FBBA1_ADDR, "FBBA1 REG", 32'b0 & {`VGALCD_FBBA1_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_FBBA2_ADDR, "FBBA2 REG", 32'b0 & {`VGALCD_FBBA2_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`VGALCD_THOLD_ADDR, "THOLD REG", 32'b0 & {`VGALCD_THOLD_WIDTH{1'b1}}, Helper::EQUL);
  // verilog_format: on
endtask

task automatic VGALCDTest::test_clk_div(input bit [31:0] run_times = 10);
  $display("=== [test vgalcd clk div] ===");
  // div 2
  this.write(`VGALCD_CTRL_ADDR, '0 & {`VGALCD_CTRL_WIDTH{1'b1}});
  repeat (50) @(posedge this.apb4.pclk);
  // div 4
  this.write(`VGALCD_CTRL_ADDR, 32'h02_00 & {`VGALCD_CTRL_WIDTH{1'b1}});
  repeat (50) @(posedge this.apb4.pclk);
endtask

task automatic VGALCDTest::test_tm_mode(input bit [31:0] run_times = 10);
  $display("=== [test vgalcd test mode] ===");
  this.write(`VGALCD_CTRL_ADDR, 32'b0 & {`VGALCD_CTRL_WIDTH{1'b1}});
  // ((480-1) << 16) | (640-1)
  this.write(`VGALCD_HVVL_ADDR, 32'h1DF_027F & {`VGALCD_CTRL_WIDTH{1'b1}});
  // ((48-1) << 20) | ((96-1) << 10) | (16-1)
  this.write(`VGALCD_HTIM_ADDR, 32'h2F1_7C0F & {`VGALCD_HTIM_WIDTH{1'b1}});
  // ((33-1) << 20) | ((2-1) << 10) | (10-1)
  this.write(`VGALCD_VTIM_ADDR, 32'h200_0409 & {`VGALCD_VTIM_WIDTH{1'b1}});
  // div 4, test, en, rgb444
  this.write(`VGALCD_CTRL_ADDR, 32'h11_02_01 & {`VGALCD_CTRL_WIDTH{1'b1}});
  repeat (800 * 525 * 4) @(posedge this.apb4.pclk);
endtask

task automatic VGALCDTest::test_rd_fb(input bit [31:0] run_times = 10);
  bit [31:0] ctrl_val = '0;
  bit [3:0] switch_cnt = '0;
  $display("=== [test vgalcd rd fb] ===");
  repeat (800 * 525 * 4) @(posedge this.apb4.pclk);
  this.write(`VGALCD_CTRL_ADDR, 32'b0 & {`VGALCD_CTRL_WIDTH{1'b1}});
  this.write(`VGALCD_STAT_ADDR, 4'b0000);
  // ((480-1) << 16) | (640-1)
  this.write(`VGALCD_HVVL_ADDR, 32'h1DF_027F & {`VGALCD_CTRL_WIDTH{1'b1}});
  // ((48-1) << 20) | ((96-1) << 10) | (16-1)
  this.write(`VGALCD_HTIM_ADDR, 32'h2F1_7C0F & {`VGALCD_HTIM_WIDTH{1'b1}});
  // ((33-1) << 20) | ((2-1) << 10) | (10-1)
  this.write(`VGALCD_VTIM_ADDR, 32'h200_0409 & {`VGALCD_VTIM_WIDTH{1'b1}});
  this.write(`VGALCD_FBBA1_ADDR, 32'h8000_0000);  // 0x9_6000
  this.write(`VGALCD_FBBA2_ADDR, 32'h8010_0000);
  this.write(`VGALCD_THOLD_ADDR, 32'd256);
  // div 4, test, en, rgb444
  ctrl_val[0]     = 1'd1;
  ctrl_val[3]     = 1'd1;
  ctrl_val[4]     = 1'd1;
  ctrl_val[15:8]  = 8'd2;
  ctrl_val[18:17] = 2'd1;
  ctrl_val[26:19] = 8'd63;
  this.write(`VGALCD_CTRL_ADDR, ctrl_val & {`VGALCD_CTRL_WIDTH{1'b1}});
  // for (int i = 0; i < 100; i++) begin
  //   repeat (800 * 525 * 100) @(posedge this.apb4.pclk);
  // end
  while (switch_cnt < 4'd4) begin
    this.read(`VGALCD_STAT_ADDR);
    if (super.rd_data[2] == 1'b1) begin
      if (super.rd_data[3] == 0) begin
        $display("switch to fb2");
      end else begin
        $display("switch to fb1");
      end
      ++switch_cnt;
      this.write(`VGALCD_STAT_ADDR, 4'b0000);
    end
  end
endtask

task automatic VGALCDTest::test_irq(input bit [31:0] run_times = 10);
  super.test_irq();
endtask
`endif

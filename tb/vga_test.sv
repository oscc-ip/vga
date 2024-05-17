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
  end
  // verilog_format: on
endtask

task automatic VGATest::test_clk_div(input bit [31:0] run_times = 10);
  $display("=== [test vga clk div] ===");
  // this.write(`PWM_CR0_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR1_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR2_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR3_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});

  // repeat (200) @(posedge this.apb4.pclk);
  // this.write(`PWM_CTRL_ADDR, 32'b0 & {`PWM_CTRL_WIDTH{1'b1}});
  // repeat (200) @(posedge this.apb4.pclk);
  // this.write(`PWM_PSCR_ADDR, 32'd10 & {`PWM_PSCR_WIDTH{1'b1}});
  // repeat (200) @(posedge this.apb4.pclk);
  // this.write(`PWM_PSCR_ADDR, 32'd4 & {`PWM_PSCR_WIDTH{1'b1}});
  // repeat (200) @(posedge this.apb4.pclk);
  // for (int i = 0; i < run_times; i++) begin
  //   this.wr_val = ($random % 20) & {`PWM_PSCR_WIDTH{1'b1}};
  //   if (this.wr_val < 2) this.wr_val = 2;
  //   if (this.wr_val % 2) this.wr_val -= 1;
  //   this.wr_rd_check(`PWM_PSCR_ADDR, "PSCR REG", this.wr_val, Helper::EQUL);
  //   repeat (200) @(posedge this.apb4.pclk);
  // end
endtask

task automatic VGATest::test_irq(input bit [31:0] run_times = 10);
  super.test_irq();
  // this.read(`PWM_STAT_ADDR);
  // this.write(`PWM_CR0_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR1_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR2_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CR3_ADDR, 32'b0 & {`PWM_CRX_WIDTH{1'b1}});
  // this.write(`PWM_CTRL_ADDR, 32'b0 & {`PWM_CTRL_WIDTH{1'b1}});
  // this.write(`PWM_PSCR_ADDR, 32'd4 & {`PWM_PSCR_WIDTH{1'b1}});
  // this.write(`PWM_CMP_ADDR, 32'hE & {`PWM_CMP_WIDTH{1'b1}});
  // 
  // for (int i = 0; i < run_times; i++) begin
  // this.write(`PWM_CTRL_ADDR, 32'b0 & {`PWM_CTRL_WIDTH{1'b1}});
  // this.read(`PWM_STAT_ADDR);
  // $display("%t rd_data: %h", $time, super.rd_data);
  // this.write(`PWM_CTRL_ADDR, 32'b11 & {`PWM_CTRL_WIDTH{1'b1}});
  // repeat (200) @(posedge this.apb4.pclk);
  // end

endtask
`endif

// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vga is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "register.sv"
`include "vga_define.sv"

module vga_timgen (
    input  logic                     clk_i,
    input  logic                     rst_n_i,
    input  logic                     en_i,
    input  logic [`VGA_TB_WIDTH-1:0] bpsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] snsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] fpsize_i,
    input  logic [`VGA_VB_WIDTH-1:0] vlen_i,
    output logic                     end_o,
    output logic                     vis_o,
    output logic                     sync_o
);



endmodule

#include "ping_pong_register.h"
#include <cstdio>

void ping_pong_register::resetn() {

  for (int i = 0; i < 32; i++) {
    // init register
    ping[i] = 0;
    pong[i] = 0;
  }
  color = 0xf00; // self test color is red
  next_addr = in->base_addr_i;
  read_ping = PING; // read ping register when reset
  reg_count = 0;
  byte_count = 0;
  write_count = 0;
}

void ping_pong_register::eval() {

  if (in->clk_v == 1) { // eval at posedge
    // declare variables
    // VC color data
    if (in->resetn_v == 0) {
      out->data_o = 0;
    } else if (in->self_test_i) {
      out->data_o = color;
    } else {
      if (read_ping) {
        out->data_o = ((ping[reg_count]) >> byte_count) & 0xfff;
      } else {
        out->data_o = ((pong[reg_count]) >> byte_count) & 0xfff;
      }
    }
  }

  if (in->clk_a == 1) {
    // 1. ppr read logic: read data from ppr and send data to vc
    if (in->resetn_v == 0)
      byte_count = 0;
    else if (in->data_req_i)
      byte_count = byte_count + 1;
    if (in->resetn_v == 0)
      reg_count = 0;
    else if (in->data_req_i && byte_count == 3)
      reg_count = reg_count + 1;
    // calculate vga data
    if (in->resetn_v == 0) {
      out->data_o = 0;
    } else if (in->data_req_i) {
      if (in->self_test_i) {
        out->data_o = color;
      } else {
        if (read_ping) {
          // read from ping
          switch (byte_count) {
          case 0:
            out->data_o = ping[reg_count] & 0xfff;
          case 1:
            out->data_o = (ping[reg_count] >> 16) & 0xfff;
          case 2:
            out->data_o = (ping[reg_count] >> 32) & 0xfff;
          default:
            out->data_o = (ping[reg_count] >> 48) & 0xfff;
          }
        } else {
          // read from pong
          switch (byte_count) {
          case 0:
            out->data_o = pong[reg_count] & 0xfff;
          case 1:
            out->data_o = (pong[reg_count] >> 16) & 0xfff;
          case 2:
            out->data_o = (pong[reg_count] >> 32) & 0xfff;
          default:
            out->data_o = (pong[reg_count] >> 48) & 0xfff;
          }
        }
      }
    }

    // 2. ppr write logic: read data from sdram, and store into ppr
    if (in->resetn_v == 0) {
      out->araddr_o = in->base_addr_i;
      next_addr = in->base_addr_i;
      out->arburst_o = 0;
      out->arlen_o = 0;
      out->arsize_o = 0;
      out->arvalid_o = 0;
      out->rready_o = 0;
    } else if (in->arready_i) {
      out->araddr_o = next_addr;
      // calculate next AXI read address
      if (next_addr + 0x100 < in->top_addr_i) {
        next_addr = next_addr + 0x100;
      } else {
        next_addr = in->base_addr_i;
      }
      // calculate AXI read types
      out->arburst_o = 1;
      out->arlen_o = 0x1f;
      out->arsize_o = 3;
      out->arvalid_o = 1;
      out->rready_o = 1;
    }
    // write AXI read_data into PPR
    if (in->resetn_a == 0) {
      write_count = 0;
    } else if (in->rvalid_i && (in->rresp_i == 0)) {
      if (read_ping)
        pong[write_count] = in->rdata_i; // write AXI read data into pong
      else
        ping[write_count] = in->rdata_i; // write AXI read data into ping
      write_count += 1;
    }
  }
};

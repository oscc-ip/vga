#include "ping_pong_register.h"
#include <cstdint>
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
  read_count = 0;
  byte_count = 0;
  write_count = 0;
  ppr_write_finish = 0;
  vga_read_finish = 0;
}

void ping_pong_register::eval() {

  /*================== control logic calculation ==================*/
  /*================== ppr read logic  ==================*/
  if (in->clk_v == 1) { // eval at posedge
    /*================== ppr read logic  ==================*/
    if (in->resetn_v == 0) {
      out->data_o = 0;
    } else if (in->data_req_i) {
      if (in->self_test_i) {
        out->data_o = color;
      } else {
        if (read_ping) {
          // read from ping
          out->data_o = (ping[read_count] >> (16 * byte_count)) & 0xfff;
        } else {
          // read from pong
          out->data_o = (pong[read_count] >> (16 * byte_count)) & 0xfff;
        }
        printf("read_ping=%d, read_count=%d, byte_count=%d, write_count=%d\n",
               read_ping, read_count, byte_count, write_count);
      }
    }
  }

  /*================== ppr write logic  ==================*/
  if (in->clk_a == 1) {
    // AXI output data
    if (in->resetn_a == 0) {
      out->araddr_o = in->base_addr_i;
      next_addr = in->base_addr_i;
      out->arburst_o = 0;
      out->arlen_o = 0;
      out->arsize_o = 0;
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
    }
    if (in->resetn_a == 0) {
      out->arvalid_o = 0;
      out->rready_o = 0;
    } else if (ppr_write_finish == 0) {
      out->arvalid_o = 1;
      out->rready_o = 1;
    }

    // write AXI read_data into PPR
    printf("ppr_write_finish=%d, write_data=0x%lx, write_count=%d\n", ppr_write_finish,
           in->rdata_i, write_count);
    if (in->resetn_a == 0) {
    } else if (in->rvalid_i && (in->rresp_i == 0) && (ppr_write_finish == 0)) {
      if (read_ping == 1)
        pong[write_count] = in->rdata_i; // write AXI read data into pong
      else
        ping[write_count] = in->rdata_i; // write AXI read data into ping
    }
  }
  if (in->clk_v) {
    printf("display pong\n");
    for (int i = 0; i < 32; i++)
      printf("pong[%d]=0x%lx\n", i, pong[i]);
    printf("display pong\n");
    printf("display ping\n");
    for (int i = 0; i < 32; i++)
      printf("ping[%d]=0x%lx\n", i, ping[i]);
    printf("display ping\n");
  }
  // 3. calculate read_ping flag
  if (in->clk_v) {
    if (in->resetn_a == 0) {
      read_ping = 0;
    } else if (vga_read_finish && ppr_write_finish) {
      read_ping = ~read_ping;
    }
  }
  vga_read_finish = (read_count == 31 && byte_count == 3);
  // 1. calculate read controls
  if (in->clk_v == 1) { // read logic use VGA clock
    if (in->resetn_v == 0)
      read_count = 0;
    else if (in->data_req_i && byte_count == 3)
      read_count = (read_count + 1) & 0x1f;
    if (in->resetn_v == 0)
      byte_count = 0;
    else if (in->data_req_i) {
      byte_count = (byte_count + 1) & 0x3;
    }
  }
  // 2. calculate write controls
  if (in->clk_a == 1) { // write logic use AXI clock
    if (in->resetn_a == 0) {
      ppr_write_finish = 0;
    } else if (write_count == 31) {
      if (vga_read_finish == 0) {
        ppr_write_finish = 1;
      } else {
        ppr_write_finish = 0;
      }
    }
  }
  // calculate write_count
  if (in->clk_a) {
    if (in->resetn_a == 0) {
      write_count = 0;
    } else if (ppr_write_finish==false) {
      write_count = (write_count + 1) & 0x1f;
    }
  }
};

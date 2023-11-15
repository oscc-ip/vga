#include "ping_pong_register.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>

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

  /*
  =======================================================
  ======================= ppr read=== ===================
  =======================================================
  */
  if (in->clk_v == 1) { // eval at posedge
    Log("vga_read_finish=%d, ppr_write_finish=%d\n", vga_read_finish,
        ppr_write_finish);
    /*================== reset logic  ==================*/
    if (in->resetn_v == 0) {
      resetn();
    }
    /*================== ppr read logic  ==================*/
    if (in->resetn_v == 0) {
      out->data_o = 0;
    } else if (in->data_req_i) {
      // if (in->self_test_i) {
      //   out->data_o = color;}
      if (read_ping) {
        // read from ping
        out->data_o = (ping[read_count] >> (16 * byte_count)) & 0xfff;
      } else {
        // read from pong
        out->data_o = (pong[read_count] >> (16 * byte_count)) & 0xfff;
      }
    }
    // Log("data_req_i=%d, self_test_i=%d\n", in->data_req_i,
    // in->self_test_i);
    Log("read from %s=> ", read_ping ? "ping" : "pong");
    Log("read_count=%d, byte_count=%d, read_data=0x%x\n", read_count,
           byte_count, out->data_o);
  }

  /*
  =======================================================
  ======================= ppr write =====================
  =======================================================
  */
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
    if (in->resetn_a == 0) {
    } else if (in->rvalid_i && (in->rresp_i == 0) && (ppr_write_finish == 0)) {
      if (read_ping == 1)
        pong[write_count] = in->rdata_i; // write AXI read data into pong
      else
        ping[write_count] = in->rdata_i; // write AXI read data into ping
    }
    Log("write to %s => ", read_ping ? "pong" : "ping");
    Log("write_data=%ld, write_count=%d, write_enable=%s\n", in->rdata_i,
        write_count, ppr_write_finish ? "false" : "true");
  }
  // if (in->clk_a && (~ppr_write_finish)) {
  //   Log("display pong\n");
  //   for (int i = 0; i < 32; i++)
  //     Log("pong[%d]=0x%lx\n", i, pong[i]);
  //   Log("display ping\n");
  //   for (int i = 0; i < 32; i++)
  //     Log("ping[%d]=0x%lx\n", i, ping[i]);
  // }

  /*
  =======================================================
  =================== control signals ===================
  =======================================================
  */
  // calculate read controls
  if (in->clk_v == 1) { // read logic use VGA clock
    if (in->resetn_v == 0)
      read_count = 0;
    else if (in->data_req_i && byte_count == 3) {
      read_count++;
    }

    if (in->resetn_v == 0)
      byte_count = 0;
    else if (in->data_req_i) {
      byte_count = (byte_count + 1) & 0x3;
    }
  }
  Log("\n\n===== test in ppr =============\n");
  vga_read_finish = read_count == 32;
  read_count = vga_read_finish ? 0 : read_count;

  // int ppr_write_finish_delay = 0;
  // ppr_write_finish = ppr_write_finish_delay;
  // if (in->clk_a == 1) { // write logic use AXI clock
  //   if (in->resetn_a == 0) {
  //     ppr_write_finish_delay = 0;
  //   } else if (write_count == 31) {
  //     if (vga_read_finish == 0) {
  //       ppr_write_finish_delay = 1;
  //     } else {
  //       ppr_write_finish_delay = 0;
  //     }
  //   }
  //   Log("-->vga_read_finish=%d, ppr_write_finish=%d, write_count=%d\n",
  //          vga_read_finish, ppr_write_finish, write_count);
  // }
  // calculate write controls
  if (in->clk_a == 1) { // write logic use AXI clock
    Log("-->vga_read_finish=%d, ppr_write_finish=%d, write_count=%d\n",
        vga_read_finish, ppr_write_finish, write_count);
    if (in->resetn_a == 0) {
      ppr_write_finish = 0;
    } else if (write_count == 31) {
      if (vga_read_finish == 0) {
        ppr_write_finish = 1;
      } else {
        ppr_write_finish = 0;
      }
    }
    Log("-->vga_read_finish=%d, ppr_write_finish=%d, write_count=%d\n",
           vga_read_finish, ppr_write_finish, write_count);
  }
  // calculate write_count
  if (in->clk_a) {
    if (in->resetn_a == 0) {
      write_count = 0;
    } else if (in->rvalid_i) {
      if (write_count < 32 && ppr_write_finish == 0) {
        write_count = (write_count + 1) & 0x1f;
      }
    }
  }
  // calculate read_ping flag
  if (in->clk_v) {
    if (in->resetn_a == 0) {
      read_ping = 0;
    } else if (vga_read_finish && (~ppr_write_finish)) {
      Log("------- change read_ping ---------\n\n\n");
      read_ping ^= 1;
      Log("display pong\n");
      for (int i = 0; i < 32; i++)
        Log("pong[%d]=0x%lx\n", i, pong[i]);
      Log("display ping\n");
      for (int i = 0; i < 32; i++)
        Log("ping[%d]=0x%lx\n", i, ping[i]);
      // exit(-1);
      Log("====> change ppr <====\n");
    }
  }
};

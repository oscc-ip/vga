#include "ping_pong_register.h"
#include <cstdio>

void ping_pong_register::resetn() {

  for (int i = 0; i < 32; i++) {
    // init register
    ping[i] = 0;
    pong[i] = 0;
  }
  color = 0xf00;    // self test color is red
  read_ping = PING; // read ping register when reset
  // set read counter
  reg_count = 0;
  byte_count = 0;

  // TODO: should set addr to base_addr
  next_addr = 0;
  write_cnt = 0;
}

void ping_pong_register::eval() {

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

  // TODO: calculate AXI signals
};

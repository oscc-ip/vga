#ifndef __PING_PONG_REGISTER__
#define __PING_PONG_REGISTER__
#include <stdlib.h>
#include <cstdio>
#define PING false
#define PONG false

// IO input
class InIO {
public:
  bool clk_a, clk_v;
  bool data_req_i;  // request color data
  bool self_test_i; // seft test enable
  bool resetn_v;
  // signals with AXI bus
  bool arready_i, rvalid_i;
  int rresp_i;
  long rdata_i;
  bool resetn_a;
  long base_addr_i, top_addr_i; // AXI data and address width is 64 bits
  InIO() {
    clk_a = 0;
    clk_v = 0;
    data_req_i = 0;
    self_test_i = 0;
    resetn_v = 1;
    resetn_a = 1;
    arready_i = 0;
    rvalid_i = 0;
    rresp_i = 0;
    base_addr_i = 0;
    top_addr_i = 0;
  }
  void display() {
    printf("InIO data:\n");
    printf("clk_v=%d, clk_a=%d\n", clk_v, clk_a);
    printf("arready_i=%d\n", arready_i);
  }

  // get randome InIO
  void randInIO(unsigned long int sim_time) {
    if (sim_time >= 0 && sim_time < 4) {
      data_req_i = 0;
      self_test_i = 0;
      base_addr_i = 0;
      top_addr_i = 0;
      arready_i = 0;
      rvalid_i = 0;
      rresp_i = 0;
      rdata_i = 0;
      resetn_a = 0;
      resetn_v = 0;
      clk_a = 0;
      clk_v = 0;
    } else {
      clk_a ^= 1;
      clk_v ^= 1;
      resetn_a = 1;
      resetn_v = 1;
      arready_i = rand() & 1; // sdram ready for read
    }
  }
};

// initial clock_a
// int InIO::clock_a = 0;

class OutIO {
public:
  // VC color data
  int data_o;
  long araddr_o;
  int arburst_o, arlen_o, arsize_o;
  bool arvalid_o, rready_o;
  // compare if OutIO is equal
};
class ping_pong_register {
private:
  // ping pong registers
  long ping[32];
  long pong[32];
  int color; // self test color

  int next_addr;
  bool read_ping;
  int byte_count, reg_count, write_count;

public:
  // IO
  InIO *in;
  OutIO *out;
  // functions
  void resetn(); // reset ppr c_model
  void eval();   // step one cycle
  ping_pong_register(InIO *i, OutIO *o) {
    in = i;
    out = o;
  }
};
#endif

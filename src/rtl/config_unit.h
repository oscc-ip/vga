#ifndef __CONFIG_UNIT__
#define __CONFIG_UNIT__

#include <cstdio>

class cu_in_io {
public:
  // variables
  bool clk;
  bool resetn;
  // apb related signals
  int paddr_i;
  int pwdata_i;
  bool psel_i;
  bool penable_i;
  bool pwrite_i;
  // get random input testcase
  void randInIO(unsigned long int sim_time);
};
class cu_out_io {
public:
  bool pready_o;
  int prdata_o;
  bool pslverr_o;
  // resolution signals; used by Vga Control Unit
  int hsync_end_o;
  int hpulse_end_o;
  int hdata_begin_o;
  int hdata_end_o;
  int vsync_end_o;
  int vpulse_end_o;
  int vdata_begin_o;
  int vdata_end_o;
  // address signals; used by Ping Pong Register
  int base_addr_o;
  int top_addr_o;
  bool self_test_o;
};
class config_unit {

public:
  // ============== variables ===================
  cu_in_io *in;
  cu_out_io *out;
  unsigned long self_test_resolution;
  unsigned long resolution[4];
  unsigned int resolution_sel;
  unsigned int base_addr, offset;
  bool self_test;

  // ============== functions ===================
  config_unit() {
    in = new cu_in_io;
    out = new cu_out_io;
  }
  // reset c_model
  void resetn() { printf("resetn in config_unit\n"); }
  // step one cycle
  void eval();
};
#endif

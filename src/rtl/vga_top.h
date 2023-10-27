#ifndef __VGA_TOP__
#define __VGA_TOP__

#include "config_unit.h"
#include "ping_pong_register.h"
#include "vga_ctrl.h"
#include <cstdio>

class top_in_io {
public:
  // ppr input
  ppr_in_io *ppr;
  // vc input
  vc_in_io *vc;
  // cu input
  cu_in_io *cu;
  // get random input testcase
  void randInIO(unsigned long int sim_time);
};
class top_out_io {
public:
  // vc output
  vc_out_io *vc;
  // ppr output
  ppr_out_io *ppr;
  // cu output
  cu_out_io *cu;
};
class vga_top {

public:
  // ============== variables ===================
  vga_ctrl *vc;
  ping_pong_register *ppr;
  config_unit *cu;
  top_in_io *in;
  top_out_io *out;

  // ============== functions ===================
  vga_top() {
    vc = new vga_ctrl;
    ppr = new ping_pong_register;
    cu = new config_unit;
    in = new top_in_io;
    out = new top_out_io;

    // connect top with vc
    in->vc = vc->in;
    out->vc = vc->out;

    // connect top with ppr
    in->ppr = ppr->in;
    out->ppr = ppr->out;

    // connect top with cu
    in->cu = cu->in;
    out->cu = cu->out;
  }
  // reset c_model
  void resetn() { printf("resetn in vga_top\n"); }
  // step one cycle
  void eval();
};
#endif

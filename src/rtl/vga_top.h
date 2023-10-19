#ifndef __VGA_TOP__
#define __VGA_TOP__

#include "ping_pong_register.h"
#include "vga_ctrl.h"
#include <cstdio>

class top_in_io {
public:
  // ppr input
  ppr_in_io *ppr;
  // vc input
  vc_in_io *vc;
  // get random input testcase
  void randInIO(unsigned long int sim_time);
};
class top_out_io {
public:
  // vc output
  vc_out_io *vc;
  // ppr output
  ppr_out_io *ppr;
};
class vga_top {

public:
  // ============== variables ===================
  vga_ctrl *vc;
  ping_pong_register *ppr;
  top_in_io *in;
  top_out_io *out;

  // ============== functions ===================
  vga_top() {
    vc = new vga_ctrl;
    ppr = new ping_pong_register;
    in = new top_in_io;
    out = new top_out_io;

    // connect top with vc
    in->vc = vc->in;
    out->vc = vc->out;

    // connect top with ppr
    in->ppr = ppr->in;
    out->ppr = ppr->out;

    // connect vc with ppr
    in->vc->data_i = out->ppr->data_o;
    in->ppr->data_req_i = out->vc->data_req_o;
  }
  // reset c_model
  void resetn() { printf("resetn in vga_top\n"); }
  // step one cycle
  void eval();
};
#endif

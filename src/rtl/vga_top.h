#ifndef __VGA_TOP__
#define __VGA_TOP__

#include "ping_pong_register.h"
#include "vga_ctrl.h"

class vga_top_out {
public:
  // vc output
  int red_o, green_o, blue_o;
  bool hsync_o, vsync_o, blank_o;
  // TODO: ppr output
};
class vga_top {

public:
  vga_ctrl *vc;
  ping_pong_register *ppr;
  vga_top_out *out;
  vga_top(vga_ctrl *v, ping_pong_register *p) {
    vc = v;
    ppr = p;
    // connect ppr with vc
    vc->data_i = ppr->out->data_o;
    ppr->in->data_req_i = vc->data_req_o;
    // connect output
    out->red_o = vc->red_o;
    out->green_o = vc->green_o;
    out->blue_o = vc->blue_o;
    out->hsync_o = vc->hsync_o;
    out->vsync_o = vc->vsync_o;
    out->blank_o = vc->blank_o;
    // TODO: connect input
  }
  void resetn();
  void eval();
};
#endif

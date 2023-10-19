#include "vga_ctrl.h"
#include "config.h"
#include <cstdio>

void vga_ctrl::eval() {

  // calculate sync signal
  if (in->clk) { // only eval at posedge
    // calculate output color
    out->red_o = in->data_i & 0xf;
    out->green_o = (in->data_i >> 4) & 0xf;
    out->blue_o = (in->data_i >> 8) & 0xf;

    // calculate sync data
    out->hsync_o = hcount <= in->hpulse_end_i ? 0 : 1;
    out->vsync_o = vcount <= in->vpulse_end_i ? 0 : 1;
    out->blank_o =
        ((hcount >= in->hdata_begin_i - 1) &&
         (hcount <= in->hdata_end_i - 1)) &&
        ((vcount >= in->vdata_begin_i - 1) && (vcount <= in->hdata_end_i - 1));
    out->data_req_o = out->blank_o; // TODO: make sure data_req_o and blank_o is
                                    // correct in cycle
    if (in->resetn == 0) {
      vcount = 0;
      hcount = 0;
    } else {
      if (hcount >= in->hsync_end_i - 1)
        hcount = 0;
      else
        hcount += 1;
      if (hcount == in->hsync_end_i - 1) {
        vcount++;
        if (vcount >= in->vsync_end_i - 1)
          vcount -= in->vsync_end_i;
      }
    }
  }
  printf("hcount=%d, vcount=%d\n\n", hcount, vcount);
}

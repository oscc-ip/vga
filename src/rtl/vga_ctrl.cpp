#include "vga_ctrl.h"
#include "config.h"
#include <cstdio>
#include <cstdlib>

void vga_ctrl::eval() {

  printf("\n==================\n");
  printf("hdata_begin_i=%d, hdata_end_i=%d\n", in->hdata_begin_i,
         in->hdata_end_i);
  printf("vdata_begin_i=%d, vdata_end_i=%d\n", in->vdata_begin_i,
         in->vdata_end_i);
  // calculate sync signal
  if (in->clk) { // only eval at posedge

    out->red_o = in->data_i & 0xf;
    out->green_o = (in->data_i >> 4) & 0xf;
    out->blue_o = (in->data_i >> 8) & 0xf;

    // calculate sync data
    out->hsync_o = hcount <= in->hpulse_end_i ? 0 : 1;
    out->vsync_o = vcount <= in->vpulse_end_i ? 0 : 1;

    if (in->resetn == 0) {
      out->blank_o = 0;
    } else {
      out->blank_o = out->data_req_o;
    }
    out->data_req_o =
        ((hcount >= in->hdata_begin_i - 1) &&
         (hcount <= in->hdata_end_i - 1)) &&
        ((vcount >= in->vdata_begin_i - 1) && (vcount <= in->hdata_end_i - 1));

    // calculate vcount
    if (in->resetn == 0) {
      vcount = 0;
    } else {
      if (hcount == in->hsync_end_i - 1) {
        vcount++;
        if (vcount >= in->vsync_end_i - 1)
          vcount -= in->vsync_end_i;
      }
    }
    // calculate hcount: must put behind vcount calculation
    if (in->resetn == 0) {
      hcount = 0;
    } else {
      if (hcount >= in->hsync_end_i - 1) {
        hcount = 0;
      } else {
        hcount++;
      }
    }
  }
  printf("hcount=%d, vcount=%d\n", hcount, vcount);
  printf("data_req_o=%d\n", out->data_req_o);
  // if (out->data_req_o == 1)
  //   exit(-1);
  printf("==================");
}

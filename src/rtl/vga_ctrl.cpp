#include "vga_ctrl.h"
#include "config.h"
#include <cstdio>
#include <cstdlib>

void vga_ctrl::eval() {

  Log("\n==================\n");
  Log("hdata_begin_i=%d, hdata_end_i=%d\n", in->hdata_begin_i,
         in->hdata_end_i);
  Log("vdata_begin_i=%d, vdata_end_i=%d\n", in->vdata_begin_i,
         in->vdata_end_i);
  // calculate sync signal
  if (in->clk) { // only eval at posedge

    if (in->resetn == 0) {
      test_color[0] = 0xf00; // red
      test_color[1] = 0x0f0; // green
      test_color[2] = 0x00f; // blue
      test_color[3] = 0xff0; // yellow
      test_color[4] = 0x0ff; // cyan
      test_color[5] = 0xf0f; // magenta
      test_color[6] = 0x000; // black
      test_color[7] = 0xfff; // white
    }

    if (in->resetn == 0) {
      test_cnt = 0;
    } else if (((vcount & 0x1f) == 0x0) && (hcount == in->hdata_begin_i) &&
               (out->data_req_o)) {
      test_cnt = (test_cnt + 1) % 8;
    }

    out->red_o =   in->self_test_i?       test_color[test_cnt] & 0xf :in->data_i & 0xf;
    out->green_o = in->self_test_i?(test_color[test_cnt] >> 4) & 0xf :(in->data_i >> 4) & 0xf;
    out->blue_o =  in->self_test_i?(test_color[test_cnt] >> 8) & 0xf :(in->data_i >> 8) & 0xf;
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
  Log("hcount=%d, vcount=%d\n", hcount, vcount);
  Log("data_req_o=%d\n", out->data_req_o);
  // if (out->data_req_o == 1)
  //   exit(-1);
  Log("==================");
}

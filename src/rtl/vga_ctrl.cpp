#include "vga_ctrl.h"
#include "config.h"
#include <cstdio>

void vga_ctrl::set_resolution(int hsync_end_i, int hpulse_end_i,
                              int hdata_begin_i, int hdata_end_i,
                              int vsync_end_i, int vpulse_end_i,
                              int vdata_begin_i, int vdata_end_i) {
  this->hsync_end_i = hsync_end_i;
  this->hpulse_end_i = hpulse_end_i;
  this->hdata_begin_i = hdata_begin_i;
  this->hdata_end_i = hdata_end_i;
  this->vsync_end_i = vsync_end_i;
  this->vpulse_end_i = vpulse_end_i;
  this->vdata_begin_i = vdata_begin_i;
  this->vdata_end_i = vdata_end_i;
}

void vga_ctrl::eval(int data_i, int resetn) {

  // calculate output color
  this->data_i = data_i;
  red_o = data_i & 0xf;
  green_o = (data_i >> 4) & 0xf;
  blue_o = (data_i >> 8) & 0xf;

  // calculate sync signal
  if (resetn == 0) {
    vcount = 0;
    hcount = 0;
  } else {
    vcount += 1;
    hcount += 1;
  }
  hsync_o = hcount <= hpulse_end_i ? 0 : 1;
  vsync_o = vcount <= vpulse_end_i ? 0 : 1;
  blank_o = ((hcount >= hdata_begin_i - 1) && (hcount <= hdata_end_i - 1)) &&
            ((vcount >= vdata_begin_i - 1) && (vcount <= hdata_end_i - 1));
  data_req_o = blank_o; //TODO: make sure data_req_o and blank_o is correct in cycle

  Log("hcount=%d, vcount=%d\n", hcount, vcount);
  Log("hsync_end_i=%d\n", hsync_end_i);
}

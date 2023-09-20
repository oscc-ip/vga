#include "vga_ctrl.h"

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

void vga_ctrl::eval(int data_i) {

  // calculate output color
  this->data_i = data_i;
  red_o = data_i & 0xf;
  green_o = (data_i >> 4) & 0xf;
  blue_o = (data_i >> 8) & 0xf;

  // TODO: calculate sync data
}

#include "config_unit.h"
#include <cstdint>
#include <cstdio>

void cu_in_io::randInIO(unsigned long int sim_time) {
  // calculate clock
  if (sim_time == 0) {
    clk = 0;
  } else {
    clk ^= 1;
  }
  if (sim_time >= 0 && sim_time < 4) {
    resetn = 0;
    // apb related signals
    paddr_i = 0;
    pwdata_i = 0;
    psel_i = 0;
    penable_i = 0;
    pwrite_i = 0;
  } else {
    resetn = 1;
    // apb related signals
    paddr_i = 2;
    pwdata_i = 1;
    psel_i = 1;
    penable_i = 1;
    pwrite_i = 1;
  }
}

void config_unit::eval() {

  unsigned long msb, lsb;
  msb = 0;
  lsb = 0;

  if (in->clk) { // only eval at posedge

    // reset module
    if (in->resetn == 0) {
      out->pready_o = 0;
      out->pslverr_o = 0;
      out->prdata_o = 0;
      base_addr = 0;
      offset = 0;
      resolution_sel = 1; // choose 640*480 by default
      self_test = 1;      // enable self_test in default
      for (int i = 0; i < 4; i++) {
        // sync, pulse, data_begin, data_end
        resolution[i][0] = htotal[i];
        resolution[i][1] = hsync_pulse[i];
        resolution[i][2] = hsync_pulse[i] + hback[i] + hleft[i];
        resolution[i][3] = resolution[i][2] + hdata[i];
        resolution[i][4] = vtotal[i];
        resolution[i][5] = vsync_pulse[i];
        resolution[i][6] = vsync_pulse[i] + vback[i] + vtop[i];
        resolution[i][7] = resolution[i][6] + vdata[i];
      }
      self_test_resolution[0] = htotal[1];
      self_test_resolution[1] = hsync_pulse[1];
      self_test_resolution[2] = hsync_pulse[1] + hback[1] + hleft[1];
      self_test_resolution[3] = resolution[1][2] + hdata[1];
      self_test_resolution[4] = vtotal[1];
      self_test_resolution[5] = vsync_pulse[1];
      self_test_resolution[6] = vsync_pulse[1] + vback[1] + vtop[1];
      self_test_resolution[7] = resolution[1][6] + vdata[1];
    } else if (in->psel_i && in->penable_i) {
      out->pready_o = 1;
      if (in->pwrite_i) {
        switch (in->paddr_i) {
        case 0:
          base_addr = in->pwdata_i;
          break;
        case 1:
          offset = in->pwdata_i;
          break;
        case 2:
          self_test = in->pwdata_i;
          break;
        case 3:
          resolution_sel = in->pwdata_i & 0x11;
          break;
        }
      }
    } else {
      out->pready_o = 0;
    }

    out->hsync_end_o =
        self_test ? self_test_resolution[0] : resolution[resolution_sel][0];
    out->hpulse_end_o =
        self_test ? self_test_resolution[1] : resolution[resolution_sel][1];
    out->hdata_begin_o =
        self_test ? self_test_resolution[2] : resolution[resolution_sel][2];
    out->hdata_end_o =
        self_test ? self_test_resolution[3] : resolution[resolution_sel][3];
    out->vsync_end_o =
        self_test ? self_test_resolution[4] : resolution[resolution_sel][4];
    out->vpulse_end_o =
        self_test ? self_test_resolution[5] : resolution[resolution_sel][5];
    out->vdata_begin_o =
        self_test ? self_test_resolution[6] : resolution[resolution_sel][6];
    out->vdata_end_o =
        self_test ? self_test_resolution[7] : resolution[resolution_sel][7];
    // output address
    out->base_addr_o = base_addr;
    out->top_addr_o = base_addr + offset;
    out->self_test_o = self_test;
  }
}

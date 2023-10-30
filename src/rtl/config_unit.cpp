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
      resolution_sel = 0;
      self_test = 1; // enable self_test in default
      for (int i = 0; i < 3; i++)
        resolution[i] = 0;
      self_test_resolution = 0x8106c1b884830320;
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
        case 4: // write into low 32 bits
          msb = resolution[0] & 0xffffffff00000000;
          lsb = in->pwdata_i;
          resolution[0] = msb + lsb;
          break;
        case 5: // write into high 32 bits
          msb = in->pwdata_i;
          msb = msb << 32;
          lsb = resolution[0] & 0xffffffff;
          resolution[0] = msb + lsb;
          break;
        case 6: // write into low 32 bits
          msb = resolution[1] & 0xffffffff00000000;
          lsb = in->pwdata_i;
          resolution[1] = msb + lsb;
          break;
        case 7: // write into high 32 bits
          msb = in->pwdata_i;
          msb = msb << 32;
          lsb = resolution[1] & 0xffffffff;
          resolution[1] = msb + lsb;
          break;
        case 8: // write into low 32 bits
          msb = resolution[2] & 0xffffffff00000000;
          lsb = in->pwdata_i;
          resolution[2] = msb + lsb;
          break;
        case 9: // write into high 32 bits
          msb = in->pwdata_i;
          msb = msb << 32;
          lsb = resolution[2] & 0xffffffff;
          resolution[2] = msb + lsb;
          break;
        case 10: // write into low 32 bits
          msb = resolution[3] & 0xffffffff00000000;
          lsb = in->pwdata_i;
          resolution[3] = msb + lsb;
          break;
        case 11: // write into high 32 bits
          msb = in->pwdata_i;
          msb = msb << 32;
          lsb = resolution[3] & 0xffffffff;
          resolution[3] = msb + lsb;
          break;
        }
      }
    } else {
      out->pready_o = 0;
    }

    // output resolution
        printf("self_test_resolution=0x%016lx\n",self_test_resolution );
        out->hsync_end_o  = self_test?((self_test_resolution & 0x00000000000007ff)>>  0): ((resolution[resolution_sel] & 0x00000000000007ff) >>  0);
        out->hpulse_end_o = self_test?((self_test_resolution & 0x000000000007f800)>> 11): ((resolution[resolution_sel] & 0x000000000007f800) >> 11);
        out->hdata_begin_o= self_test?((self_test_resolution & 0x0000000007f80000)>> 19): ((resolution[resolution_sel] & 0x0000000007f80000) >> 19);
        out->hdata_end_o  = self_test?((self_test_resolution & 0x0000001ff8000000)>> 27): ((resolution[resolution_sel] & 0x0000001ff8000000) >> 27);
        out->vsync_end_o  = self_test?((self_test_resolution & 0x00003fe000000000)>> 37): ((resolution[resolution_sel] & 0x00003fe000000000) >> 37);
        out->vpulse_end_o = self_test?((self_test_resolution & 0x0001c00000000000)>> 46): ((resolution[resolution_sel] & 0x0001c00000000000) >> 46);
        out->vdata_begin_o= self_test?((self_test_resolution & 0x003e000000000000)>> 49): ((resolution[resolution_sel] & 0x003e000000000000) >> 49);
        out->vdata_end_o  = self_test?((self_test_resolution & 0x7fc0000000000000)>> 54): ((resolution[resolution_sel] & 0x7fc0000000000000) >> 54);

        printf("cu>>>>> hsync_end_o=0x%d\n", out->hsync_end_o);
    // output address
    out->base_addr_o = base_addr;
    out->top_addr_o = base_addr + offset;
    out->self_test_o = self_test;
  }
}

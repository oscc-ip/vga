#include "vga_top.h"

void top_in_io::randInIO(unsigned long int sim_time) {
  // calculate clock
  if (sim_time == 0) {
    ppr->clk_a = 0;
    ppr->clk_v = 0;
  } else {
    ppr->clk_a ^= 1;
    ppr->clk_v ^= 1;
  }
  if (sim_time >= 0 && sim_time < 4) {
    // ppr->data_req_i = 0;
    ppr->self_test_i = 1; // enable self_test_i
    ppr->base_addr_i = 0;
    ppr->top_addr_i = 0;
    ppr->arready_i = 0;
    ppr->rvalid_i = 0;
    ppr->rresp_i = 0;
    ppr->rdata_i = 0;
    ppr->resetn_a = 0;
    ppr->resetn_v = 0;
    vc->hsync_end_i = 800;
    vc->hpulse_end_i = 96;
    vc->hdata_begin_i = 144;
    vc->hdata_end_i = 784;
    vc->vsync_end_i = 525;
    vc->vpulse_end_i = 2;
    vc->vdata_begin_i = 35;
    vc->vdata_end_i = 515;
  } else {
    ppr->resetn_a = 1;
    ppr->resetn_v = 1;
  }
  vc->clk = ppr->clk_v;
  vc->resetn = ppr->resetn_v;
}

void vga_top::eval() {
  printf("eval in vga_top\n");
  ppr->eval();
  vc->eval();
}

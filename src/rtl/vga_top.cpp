#include "vga_top.h"
#include <cstdio>

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
    ppr->arready_i = 0;
    ppr->rvalid_i = 0;
    ppr->rresp_i = 0;
    ppr->rdata_i = 0;
    ppr->resetn_a = 0;
    ppr->resetn_v = 0;
    // vc->hsync_end_i = 800;
    // vc->hpulse_end_i = 96;
    // vc->hdata_begin_i = 144;
    // vc->hdata_end_i = 784;
    // vc->vsync_end_i = 525;
    // vc->vpulse_end_i = 2;
    // vc->vdata_begin_i = 35;
    // vc->vdata_end_i = 515;
  } else {
    ppr->resetn_a = 1;
    ppr->resetn_v = 1;
  }
  vc->clk = ppr->clk_v;
  vc->resetn = ppr->resetn_v;
  cu->clk = ppr->clk_a;
  cu->resetn = ppr->resetn_a;
  printf("resetn_v=%d\n", ppr->resetn_v);
  printf("resetn_a=%d\n", ppr->resetn_a);
}

void vga_top::eval() {
  printf("eval in vga_top\n");
  cu->eval();
  vc->in->hsync_end_i = cu->out->hsync_end_o;
  vc->in->hdata_begin_i = cu->out->hdata_begin_o;
  vc->in->hdata_end_i = cu->out->hdata_end_o;
  vc->in->hpulse_end_i = cu->out->hpulse_end_o;
  vc->in->vsync_end_i = cu->out->vsync_end_o;
  vc->in->vdata_begin_i = cu->out->vdata_begin_o;
  vc->in->vdata_end_i = cu->out->vdata_end_o;
  vc->in->vpulse_end_i = cu->out->vpulse_end_o;
  vc->eval();
  in->ppr->data_req_i = vc->out->data_req_o;
  in->ppr->base_addr_i = cu->out->base_addr_o;
  in->ppr->top_addr_i = cu->out->top_addr_o;
  in->ppr->self_test_i = cu->out->self_test_o;
  ppr->eval();
  in->vc->data_i = out->ppr->data_o;
}

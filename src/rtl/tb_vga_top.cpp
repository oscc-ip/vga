#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vvga_top.h"
#include <unistd.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "vga_top.h"
// set dut and c_model macros
#define DUT Vvga_top
#define REF vga_top
#define InIO top_in_io
#define OutIO top_out_io

// #define MAX_SIM_TIME 8
// #define MAX_SIM_TIME 71
// #define MAX_SIM_TIME 202 
// #define MAX_SIM_TIME 500
#define MAX_SIM_TIME 20000
// #define MAX_SIM_TIME 200000
// #define MAX_SIM_TIME 20000000
uint64_t sim_time;
uint64_t posedge_cnt;

/*
1. get random input for dut and ref
2. connect to dut and ref
*/
class InDriver {
private:
  DUT *dut;
  REF *ref;

public:
  // get random input signal for dut and ref
  void drive(InIO *in) {
    // copy input signal to ref
    dut->resetn_a = in->ppr->resetn_a;
    dut->resetn_v = in->ppr->resetn_v;
    // dut->data_req_i = in->ppr->data_req_i;
    // dut->self_test_i = in->ppr->self_test_i;
    dut->arready_i = in->ppr->arready_i;
    dut->rvalid_i = in->ppr->rvalid_i;
    dut->rresp_i = in->ppr->rresp_i;
    dut->rdata_i = in->ppr->rdata_i;
    dut->clk_a = in->ppr->clk_a;
    dut->clk_v = in->ppr->clk_v;
    // copy input signal to ref
    // ref->in = in;
  }
  // constructor: connect to dut and ref
  InDriver(DUT *d, REF *r) {
    dut = d;
    ref = r;
  }
};
/*
Score Board
1. trace InIO and OutIO
2. Compare dut and c_model
*/
class SCB {

private:
  DUT *dut;
  REF *ref;

public:
  void display() {
    printf("display dut and ref OutIO at time=%ld\n", sim_time);
    printf("red_o    -> dut: %d, ref: %d\n", dut->red_o, ref->out->vc->red_o);
    printf("green_o  -> dut: %d, ref: %d\n", dut->green_o, ref->out->vc->green_o);
    printf("blue_o   -> dut: %d, ref: %d\n", dut->blue_o, ref->out->vc->blue_o);
    printf("hsync_o  -> dut: %d, ref: %d\n", dut->hsync_o, ref->out->vc->hsync_o);
    printf("vsync_o  -> dut: %d, ref: %d\n", dut->vsync_o, ref->out->vc->vsync_o);
    printf("blank_o  -> dut: %d, ref: %d\n", dut->blank_o, ref->out->vc->blank_o);
    printf("araddr_o -> dut: %ld, ref: %ld\n", dut->araddr_o, ref->out->ppr->araddr_o);
    printf("arburst_o-> dut: %d, ref: %d\n", dut->arburst_o, ref->out->ppr->arburst_o);
    printf("arlen_o  -> dut: %d, ref: %d\n", dut->arlen_o, ref->out->ppr->arlen_o);
    printf("arsize_o -> dut: %d, ref: %d\n", dut->arsize_o, ref->out->ppr->arsize_o);
    printf("arvalid_o-> dut: %d, ref: %d\n", dut->arvalid_o, ref->out->ppr->arvalid_o);
    printf("rready_o -> dut: %d, ref: %d\n", dut->rready_o, ref->out->ppr->rready_o);
  }
  bool compare() {
    // ref->in->display();
    display();
    // both ppr and vc output content should match
    bool match = dut->araddr_o == ref->out->ppr->araddr_o &&
                 dut->arburst_o == ref->out->ppr->arburst_o &&
                 dut->arlen_o == ref->out->ppr->arlen_o &&
                 dut->arsize_o == ref->out->ppr->arsize_o &&
                 dut->arvalid_o == ref->out->ppr->arvalid_o &&
                 dut->rready_o == ref->out->ppr->rready_o &&
                 dut->red_o == ref->out->vc->red_o &&
                 dut->green_o == ref->out->vc->green_o &&
                 dut->blue_o == ref->out->vc->blue_o &&
                 dut->hsync_o == ref->out->vc->hsync_o &&
                 dut->vsync_o == ref->out->vc->vsync_o &&
                 dut->blank_o == ref->out->vc->blank_o;

    if (match) {
      printf("match\n");
    } else {
      printf("mismatch\n");
    }
    return match;
  }
  // constructor: connect to dut and ref
  SCB(DUT *d, REF *r) {
    dut = d;
    ref = r;
  }
};

/*
1. store InIO into SCB
*/
class InMonitor {};

/*
1. store OutIO to SCB, so SCB can compare dut with ref when necessary
*/
class OutMonitor {

private:
  SCB *scb;
  DUT *dut;
  REF *ref;

public:
  bool monitor_equal() {
    bool equal = scb->compare();
    return equal;
  }

  OutMonitor(SCB *s, DUT *d, REF *r) {
    scb = s;
    dut = d;
    ref = r;
  }
};

// implementations
// declare variables
VerilatedVcdC *m_trace = new VerilatedVcdC;
// Here we create the driver, scoreboard, input and output monitor blocks
DUT *dut = new DUT;
REF *ref = new REF();
InDriver *drv = new InDriver(dut, ref);
SCB *scb = new SCB(dut, ref);
OutMonitor *outMon = new OutMonitor(scb, dut, ref);

// init dut, ref and verilator
void init() {
  Log("init\n");
  // init verilator
  Verilated::traceEverOn(true);
  srand(time(NULL));
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");
  sim_time = 0;
  posedge_cnt = 0;
  // init dut
  // init ref
  ref->resetn();
  // init UVM test class
}

// destroy all pointers to free memory
void destroy() {
  Log("destroy\n");
  m_trace->close();
  Log("save waveform\n");
  delete dut;
  delete m_trace;
  delete outMon;
  delete scb;
  delete drv;
}

// step 1 cycle and compare
void step() {
  Log("step\n");
  while (sim_time < MAX_SIM_TIME) {
    Log("\nsim_time=%ld\n", sim_time);
    printf("\n\nsim_time=%ld\n", sim_time);
    // dut->clk_v ^= 1;
    // dut->clk_a ^= 1;
    // in = randInIO();
    ref->in->randInIO(sim_time);
    drv->drive(ref->in);
    dut->eval(); // dut evaluate
    ref->eval();
    // scb->display();
    // compare dut with ref
    if (outMon->monitor_equal() == 0) {
      m_trace->dump(sim_time);
      destroy();
      _exit(-1);
    };
    m_trace->dump(sim_time);
    sim_time++;
  }
}

int main(int argc, char **argv) {
  // init dut, ref and verilator
  init();
  // step and compare
  step();
  // destroy pointers
  destroy();
}


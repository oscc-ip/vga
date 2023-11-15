#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vconfig_unit.h"
#include <unistd.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "config_unit.h"
// set dut and c_model macros
#define DUT Vconfig_unit
#define REF config_unit
#define InIO cu_in_io
#define OutIO cu_out_io

// #define MAX_SIM_TIME 8
// #define MAX_SIM_TIME 71
#define MAX_SIM_TIME 202
// #define MAX_SIM_TIME 500
// #define MAX_SIM_TIME 2000000
// #define MAX_SIM_TIME 4807
// #define MAX_SIM_TIME 54696
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
    dut->clk = in->clk;
    dut->resetn = in->resetn;
    dut->paddr_i = in->paddr_i;
    dut->pwdata_i = in->pwdata_i;
    dut->psel_i = in->psel_i;
    dut->penable_i = in->penable_i;
    dut->pwrite_i = in->pwrite_i;
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
    Log("display dut and ref OutIO at time=%ld\n", sim_time);
    Log("prdata_o -> dut: %d, ref: %d\n", dut->prdata_o, ref->out->prdata_o);
    Log("pslverr_o    -> dut: %d, ref: %d\n", dut->pslverr_o,
           ref->out->pslverr_o);
    Log("hsync_end_o  -> dut: %d, ref: %d\n", dut->hsync_end_o,
           ref->out->hsync_end_o);
    Log("hpulse_end_o -> dut: %d, ref: %d\n", dut->hpulse_end_o,
           ref->out->hpulse_end_o);
    Log("hdata_begin_o-> dut: %d, ref: %d\n", dut->hdata_begin_o,
           ref->out->hdata_begin_o);
    Log("vdata_end_o  -> dut: %d, ref: %d\n", dut->vdata_end_o,
           ref->out->vdata_end_o);
    Log("vsync_end_o  -> dut: %d, ref: %d\n", dut->vsync_end_o,
           ref->out->vsync_end_o);
    Log("vpulse_end_o -> dut: %d, ref: %d\n", dut->vpulse_end_o,
           ref->out->vpulse_end_o);
    Log("vdata_begin_o-> dut: %d, ref: %d\n", dut->vdata_begin_o,
           ref->out->vdata_begin_o);
    Log("vdata_end_o  -> dut: %d, ref: %d\n", dut->hdata_end_o,
           ref->out->hdata_end_o);
    Log("base_addr_o  -> dut: %d, ref: %d\n", dut->base_addr_o,
           ref->out->base_addr_o);
    Log("top_addr_o   -> dut: %d, ref: %d\n", dut->top_addr_o,
           ref->out->top_addr_o);
    Log("self_test_o  -> dut: %d, ref: %d\n", dut->self_test_o,
           ref->out->self_test_o);
  }
  bool compare() {
    // ref->in->display();
    display();
    bool match = dut->prdata_o == ref->out->prdata_o &&
                 dut->pslverr_o == ref->out->pslverr_o &&
                 dut->hsync_end_o == ref->out->hsync_end_o &&
                 dut->hpulse_end_o == ref->out->hpulse_end_o &&
                 dut->hdata_begin_o == ref->out->hdata_begin_o &&
                 dut->vdata_end_o == ref->out->vdata_end_o &&
                 dut->vsync_end_o == ref->out->vsync_end_o &&
                 dut->vpulse_end_o == ref->out->vpulse_end_o &&
                 dut->vdata_begin_o == ref->out->vdata_begin_o &&
                 dut->hdata_end_o == ref->out->hdata_end_o &&
                 dut->base_addr_o == ref->out->base_addr_o &&
                 dut->top_addr_o == ref->out->top_addr_o &&
                 dut->self_test_o == ref->out->self_test_o;
    if (match) {
      Log("match\n");
    } else {
      Log("mismatch\n");
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
    Log("\n\nsim_time=%ld\n", sim_time);
    // dut->clk_v ^= 1;
    // dut->clk_a ^= 1;
    // in = randInIO();
    ref->in->randInIO(sim_time);
    drv->drive(ref->in);
    dut->eval(); // dut evaluate
    ref->eval();
    // scb->display();
    // compare dut with ref
    m_trace->dump(sim_time);
    sim_time++;
    if (outMon->monitor_equal() == 0) {
      m_trace->dump(++sim_time);
      destroy();
      _exit(-1);
    };
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

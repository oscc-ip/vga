#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vping_pong_register.h"
#include <unistd.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "ping_pong_register.h"
// set dut and c_model macros
#define DUT Vping_pong_register
#define REF ping_pong_register

// #define MAX_SIM_TIME 8
// #define MAX_SIM_TIME 102
// #define MAX_SIM_TIME 200
// #define MAX_SIM_TIME 270
#define MAX_SIM_TIME 2000
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
    dut->resetn_a = in->resetn_a;
    dut->resetn_v = in->resetn_v;
    dut->data_req_i = in->data_req_i;
    dut->self_test_i = in->self_test_i;
    dut->arready_i = in->arready_i;
    dut->rvalid_i = in->rvalid_i;
    dut->rresp_i = in->rresp_i;
    dut->rdata_i = in->rdata_i;
    dut->clk_a = in->clk_a;
    dut->clk_v = in->clk_v;
    // copy input signal to ref
    ref->in = in;
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
    printf("data_o   -> dut: 0x%x, ref: 0x%x\n", dut->data_o, ref->out->data_o);
    printf("araddr_o -> dut: 0x%lx, ref: 0x%lx\n", dut->araddr_o,
           ref->out->araddr_o);
    printf("arburst_o-> dut: %d, ref: %d\n", dut->arburst_o,
           ref->out->arburst_o);
    printf("arlen_o  -> dut: %d, ref: %d\n", dut->arlen_o, ref->out->arlen_o);
    printf("arsize_o -> dut: %d, ref: %d\n", dut->arsize_o, ref->out->arsize_o);
    printf("arvalid_o-> dut: %d, ref: %d\n", dut->arvalid_o,
           ref->out->arvalid_o);
    printf("rready_o -> dut: %d, ref: %d\n", dut->rready_o, ref->out->rready_o);
  }
  bool compare() {
    // ref->in->display();
    display();
    bool match = dut->data_o == ref->out->data_o &&
                 dut->araddr_o == ref->out->araddr_o &&
                 dut->arburst_o == ref->out->arburst_o &&
                 dut->arlen_o == ref->out->arlen_o &&
                 dut->arsize_o == ref->out->arsize_o &&
                 dut->arvalid_o == ref->out->arvalid_o &&
                 dut->rready_o == ref->out->rready_o;

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
InIO *in = new InIO;
OutIO *out = new OutIO;
DUT *dut = new DUT;
REF *ref = new REF(in, out);
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
  sim_time = 0; // TODO: why sim_time=0 not working?
  posedge_cnt = 0;
  // TODO: add init logic
  // init dut
  // dut->clk_a = 0;
  // dut->clk_v = 0;
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
    in->randInIO(sim_time);
    drv->drive(in);
    dut->eval(); // dut evaluate
    ref->eval();
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

#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vping_pong_register.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "ping_pong_register.h"
// set dut and c_model macros
#define DUT Vping_pong_register
#define REF ping_pong_register

// #define MAX_SIM_TIME 20
// #define MAX_SIM_TIME 102
// #define MAX_SIM_TIME 200
#define MAX_SIM_TIME 2000
// #define MAX_SIM_TIME 20000000
uint64_t sim_time;
uint64_t posedge_cnt;

// class InDrv {
// private:
//   DUT *dut;

// public:
//   InDrv(DUT *dut) { this->dut = dut; }
//   void drive(InIO *tx) {
//     // dut->data_i = tx->data_i;
//     Log("In driver: data_i = 0x%x\n", tx->data_i);
//   }
// };
// class VgaCtrlSCB {

// private:
//   std::deque<InIO *> queue;

// public:
//   REF *c_model;

//   void display(OutIO *dut, REF *c_model) {
//     Log("output format: dut : ref\n");
//     Log("red  : %2x : %2x\n", dut->red_o, c_model->red_o);
//     Log("green: %2x : %2x\n", dut->green_o, c_model->green_o);
//     Log("blue : %2x : %2x\n", dut->blue_o, c_model->blue_o);
//     Log("hsync: %2x : %2x\n", dut->hsync_o, c_model->hsync_o);
//     Log("vsync: %2x : %2x\n", dut->vsync_o, c_model->vsync_o);
//     Log("blank: %2x : %2x\n", dut->blank_o, c_model->blank_o);
//   }
//   void write_in(InIO *tx) { queue.push_back(tx); }
//   void write_out(OutIO *tx) {

//     // declare variables
//     bool color_mismatch, sync_mismatch;

//     // implementations
//     if (queue.empty()) {
//       Log("Error, queue is empty\n");
//       _exit(1);
//     }
//     InIO *in = queue.front();
//     queue.pop_front();

//     Log("dut     value: red=0x%x, green=0x%x, blue=0x%x\n", tx->red_o,
//         tx->green_o, tx->blue_o);
//     Log("c_model value: red=0x%x, green=0x%x, blue=0x%x\n", c_model->red_o,
//         c_model->green_o, c_model->blue_o);
//     Log("dut hsync_o = %d <=> c_model hsync_o =%d\n", tx->hsync_o,
//         c_model->hsync_o);

//     color_mismatch = tx->red_o != c_model->red_o ||
//                      tx->green_o != c_model->green_o ||
//                      tx->blue_o != c_model->blue_o;
//     sync_mismatch = tx->hsync_o != c_model->hsync_o ||
//                     tx->vsync_o != c_model->vsync_o ||
//                     tx->blank_o != c_model->blank_o;

//     if (color_mismatch || sync_mismatch) {
//       display(tx, c_model);
//       _exit(1);
//     } else {
//       printf("match\n");
//     }
//   };
// };
// class VgaCtrlInMonitor {
// private:
//   DUT *dut;
//   VgaCtrlSCB *scb;

// public:
//   VgaCtrlInMonitor(DUT *dut, VgaCtrlSCB *scb) {
//     this->dut = dut;
//     this->scb = scb;
//   }
//   void monitor() {
//     InIO *tx = new InIO;
//     tx->data_i = dut->data_i;
//     tx->resetn = dut->resetn;
//     scb->write_in(tx);
//   }
// };
// class VgaCtrlOutMonitor {

// private:
//   DUT *dut;
//   VgaCtrlSCB *scb;

// public:
//   VgaCtrlOutMonitor(DUT *dut, VgaCtrlSCB *scb) {
//     this->dut = dut;
//     this->scb = scb;
//   }
//   void monitor() {
//     OutIO *tx = new OutIO;
//     // color data
//     tx->red_o = dut->red_o;
//     tx->green_o = dut->green_o;
//     tx->blue_o = dut->blue_o;
//     // sync data
//     tx->hsync_o = dut->hsync_o;
//     tx->vsync_o = dut->vsync_o;
//     tx->blank_o = dut->blank_o;
//     if (dut->clk == 1) // only write_out in posedge
//       scb->write_out(tx);
//   }
// };

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
    dut->resetn_v = in->resetn_v;
    dut->data_reg_i = in->data_reg_i;
    dut->self_test_i = in->self_test_i;
    dut->arready_i = in->arready_i;
    dut->rvalid_i = in->rvalid_i;
    dut->rresp_i = in->rresp_i;
    dut->rdata_i = in->rdata_i;
    // copy input signal to ref
    ref->in = *in;
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
  void compare() { Log("compare dut with ref\n"); }
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
  monitor() { s->compare; }
  OutMonitor(SCB *s, DUT *d, REF *r) {
    scb = s;
    dut = d;
    ref = r;
  }
};

// get random input data
InIO *tx=randInIO(){
    InIO *tx=new InIO;
    return tx;
}

// implementations
// declare variables
VerilatedVcdC *m_trace = new VerilatedVcdC;
DUT *dut = new DUT;
REF *ref = new REF;
// Here we create the driver, scoreboard, input and output monitor blocks
InIO *tx;
InDriver *drv = new InDriver(dut, ref);
SCB *scb = new SCB(dut, ref);
OutMonitor *outMon = new OutMonitor(scb, dut, ref);

// init dut, ref and verilator
void init() {
  // init verilator
  Verilated::traceEverOn(true);
  srand(time(NULL));
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");
  sim_time = 0;
  posedge_cnt = 0;
  // TODO: add init logic
  // init dut
  // init ref
  // init UVM test class
}

// step 1 cycle and compare
void step() {
  while (sim_time < MAX_SIM_TIME) {
    dut->clk ^= 1;

    tx = randInIO();
    drv->drive(tx);
    dut->eval();         // dut evaluate
    ref->eval();
    outMon->monitor(); // dut output
    m_trace->dump(sim_time);
    sim_time++;
  }
}

// destroy all pointers to free memory
void destroy() {
  m_trace->close();
  delete dut;
  delete m_trace;
  delete outMon;
  delete inMon;
  delete scb;
  delete drv;
}

int main(int argc, char **argv) {
  // init dut, ref and verilator
  init();
  // step and compare
  step();
  // destroy pointers
  destroy();

  printf("hello world\n");
}

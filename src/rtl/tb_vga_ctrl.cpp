#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vvga_ctrl.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "vga_ctrl.h"
// set dut and c_model macros
#define DUT Vvga_ctrl 
#define REF vga_ctrl

// #define MAX_SIM_TIME 20
// #define MAX_SIM_TIME 102
// #define MAX_SIM_TIME 200
// #define MAX_SIM_TIME 2000
#define MAX_SIM_TIME 20000000
uint64_t sim_time;
uint64_t posedge_cnt;

class VgaCtrlInTx {
public:
  int data_i;
  int resetn;
};
class VgaCtrlOutTx {
public:
  int red_o;
  int green_o;
  int blue_o;
  int vsync_o;
  int hsync_o;
  int blank_o;
};
class VgaCtrlInDrv {
private:
  DUT *dut;

public:
  VgaCtrlInDrv(DUT *dut) { this->dut = dut; }
  void drive(VgaCtrlInTx *tx) {
    dut->data_i = tx->data_i;
    Log("In driver: data_i = 0x%x\n", tx->data_i);
  }
};
class VgaCtrlSCB {

private:
  std::deque<VgaCtrlInTx *> queue;

public:
  REF *c_model;

  void display(VgaCtrlOutTx *dut, REF *c_model) {
    printf("output format: dut : ref\n");
    printf("red  : %2x : %2x\n", dut->red_o, c_model->red_o);
    printf("green: %2x : %2x\n", dut->green_o, c_model->green_o);
    printf("blue : %2x : %2x\n", dut->blue_o, c_model->blue_o);
    printf("hsync: %2x : %2x\n", dut->hsync_o, c_model->hsync_o);
    printf("vsync: %2x : %2x\n", dut->vsync_o, c_model->vsync_o);
    printf("blank: %2x : %2x\n", dut->blank_o, c_model->blank_o);
  }
  void write_in(VgaCtrlInTx *tx) { queue.push_back(tx); }
  void write_out(VgaCtrlOutTx *tx) {

    // declare variables
    bool color_mismatch, sync_mismatch;

    // implementations
    if (queue.empty()) {
      Log("Error, queue is empty\n");
      _exit(1);
    }
    VgaCtrlInTx *in = queue.front();
    queue.pop_front();

    Log("dut     value: red=0x%x, green=0x%x, blue=0x%x\n", tx->red_o,
        tx->green_o, tx->blue_o);
    Log("c_model value: red=0x%x, green=0x%x, blue=0x%x\n", c_model->red_o,
        c_model->green_o, c_model->blue_o);
    Log("dut hsync_o = %d <=> c_model hsync_o =%d\n", tx->hsync_o,
        c_model->hsync_o);

    color_mismatch = tx->red_o != c_model->red_o ||
                     tx->green_o != c_model->green_o ||
                     tx->blue_o != c_model->blue_o;
    sync_mismatch = tx->hsync_o != c_model->hsync_o ||
                    tx->vsync_o != c_model->vsync_o ||
                    tx->blank_o != c_model->blank_o;

    if (color_mismatch || sync_mismatch) {
      display(tx, c_model);
      _exit(1);
    } else {
      printf("match\n");
    }
  };
};
class VgaCtrlInMonitor {
private:
  DUT *dut;
  VgaCtrlSCB *scb;

public:
  VgaCtrlInMonitor(DUT *dut, VgaCtrlSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    VgaCtrlInTx *tx = new VgaCtrlInTx;
    tx->data_i = dut->data_i;
    tx->resetn = dut->resetn;
    scb->write_in(tx);
  }
};
class VgaCtrlOutMonitor {

private:
  DUT *dut;
  VgaCtrlSCB *scb;

public:
  VgaCtrlOutMonitor(DUT *dut, VgaCtrlSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    VgaCtrlOutTx *tx = new VgaCtrlOutTx;
    // color data
    tx->red_o = dut->red_o;
    tx->green_o = dut->green_o;
    tx->blue_o = dut->blue_o;
    // sync data
    tx->hsync_o = dut->hsync_o;
    tx->vsync_o = dut->vsync_o;
    tx->blank_o = dut->blank_o;
    if (dut->clk == 1) // only write_out in posedge
      scb->write_out(tx);
  }
};

void dut_reset(DUT *dut, vluint64_t sim_time) {
  dut->resetn = 1;
  if (sim_time >= 0 && sim_time <= 1) {
    dut->resetn = 0;
  }
  // set vga config for resolution
  dut->hsync_end_i = 800;
  dut->hpulse_end_i = 96;
  dut->hdata_begin_i = 144;
  dut->hdata_end_i = 784;
  dut->vsync_end_i = 525;
  dut->vpulse_end_i = 2;
  dut->vdata_begin_i = 35;
  dut->vdata_end_i = 515;
};
VgaCtrlInTx *randVgaInTx() {
  VgaCtrlInTx *tx = new VgaCtrlInTx;
  tx->data_i = rand() & 0xfff;
  return tx;
};

// implementations
// declare variables
DUT *dut = new DUT;
VerilatedVcdC *m_trace = new VerilatedVcdC;
// get C referrence model, init c_model
REF *c_model = new REF;
// Here we create the driver, scoreboard, input and output monitor blocks
VgaCtrlInTx *tx;
VgaCtrlInDrv *drv = new VgaCtrlInDrv(dut);
VgaCtrlSCB *scb = new VgaCtrlSCB();
VgaCtrlInMonitor *inMon = new VgaCtrlInMonitor(dut, scb);
VgaCtrlOutMonitor *outMon = new VgaCtrlOutMonitor(dut, scb);

// init dut, c_model and verilator
void init() {
  // init dut
  dut_reset(dut, sim_time);
  // init c_model
  c_model->set_resolution(800, 96, 144, 784, 525, 2, 35, 515);
  scb->c_model = c_model;
  // init verilator
  Verilated::traceEverOn(true);
  srand(time(NULL));
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");
  sim_time = 0;
  posedge_cnt = 0;
}

// step 1 cycle and compare
void step() {
  while (sim_time < MAX_SIM_TIME) {
    dut->clk ^= 1;

    tx = randVgaInTx();
    drv->drive(tx);
    Log("dut->data_i=0x%x\n", dut->data_i);
    inMon->monitor();    // input to dut
    dut->eval();         // dut evaluate
    if (dut->clk == 1) { // c_model eval at posedge
      c_model->eval(tx->data_i, tx->resetn);
    }
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
  // init dut, c_model and verilator
  init();
  // step and compare
  step();
  // destroy pointers
  destroy();
}

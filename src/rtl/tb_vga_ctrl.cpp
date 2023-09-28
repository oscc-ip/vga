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

// #define MAX_SIM_TIME 20
// #define MAX_SIM_TIME 102
// #define MAX_SIM_TIME 200
#define MAX_SIM_TIME 2000
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
  Vvga_ctrl *dut;

public:
  VgaCtrlInDrv(Vvga_ctrl *dut) { this->dut = dut; }
  void drive(VgaCtrlInTx *tx) {
    dut->data_i = tx->data_i;
    Log("In driver: data_i = 0x%x\n", tx->data_i);
  }
};
class VgaCtrlSCB {

private:
  std::deque<VgaCtrlInTx *> queue;

public:
  vga_ctrl *c_model;

  void display(VgaCtrlOutTx *dut, vga_ctrl *c_model) {
    printf("output format: dut : ref\n");
    printf("red  : %2d : %2d\n", dut->red_o, c_model->red_o);
    printf("green: %2d : %2d\n", dut->green_o, c_model->green_o);
    printf("blue : %2d : %2d\n", dut->blue_o, c_model->blue_o);
    printf("hsync: %2d : %2d\n", dut->hsync_o, c_model->hsync_o);
    printf("vsync: %2d : %2d\n", dut->vsync_o, c_model->vsync_o);
    printf("blank: %2d : %2d\n", dut->blank_o, c_model->blank_o);
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
    c_model->eval(in->data_i, in->resetn);
    queue.pop_front();

    // TODO: add compare logic
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
    // printf("ref-> hsync_o = %d, dut->hsync_o = %d\n", c_model->hsync_o,
    // tx->hsync_o);

    if (color_mismatch) {
    // if (color_mismatch || sync_mismatch) {
      // printf("mismatch at sim_time=%lld\n", sim_time);
      display(tx, c_model);
      _exit(1);
    } else {
      printf("match\n");
    }
  };
};
class VgaCtrlInMonitor {
private:
  Vvga_ctrl *dut;
  VgaCtrlSCB *scb;

public:
  VgaCtrlInMonitor(Vvga_ctrl *dut, VgaCtrlSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    // TODO: add condition control for in_moniter
    VgaCtrlInTx *tx = new VgaCtrlInTx;
    tx->data_i = dut->data_i;
    tx->resetn = dut->resetn;
    scb->write_in(tx);
    // dut->eval();
  }
};
class VgaCtrlOutMonitor {

private:
  Vvga_ctrl *dut;
  VgaCtrlSCB *scb;

public:
  VgaCtrlOutMonitor(Vvga_ctrl *dut, VgaCtrlSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    VgaCtrlOutTx *tx = new VgaCtrlOutTx;
    // TODO: add out value
    // color data
    tx->red_o = dut->red_o;
    tx->green_o = dut->green_o;
    tx->blue_o = dut->blue_o;
    // sync data
    tx->hsync_o = dut->hsync_o;
    tx->vsync_o = dut->vsync_o;
    tx->blank_o = dut->blank_o;
    scb->write_out(tx);
  }
};

void dut_reset(Vvga_ctrl *dut, vluint64_t sim_time) {
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

int main(int argc, char **argv) {

  // declare variables
  Vvga_ctrl *dut = new Vvga_ctrl;
  VerilatedVcdC *m_trace = new VerilatedVcdC;

  VgaCtrlInTx *tx;

  // Here we create the driver, scoreboard, input and output monitor blocks
  VgaCtrlInDrv *drv = new VgaCtrlInDrv(dut);
  VgaCtrlSCB *scb = new VgaCtrlSCB();
  VgaCtrlInMonitor *inMon = new VgaCtrlInMonitor(dut, scb);
  VgaCtrlOutMonitor *outMon = new VgaCtrlOutMonitor(dut, scb);

  // get C referrence model
  vga_ctrl *c_model = new vga_ctrl;
  c_model->set_resolution(800, 96, 144, 784, 525, 2, 35, 515);
  scb->c_model = c_model;

  // implementations
  Verilated::traceEverOn(true);
  srand(time(NULL));
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");

  sim_time = 0;
  posedge_cnt = 0;
  while (sim_time < MAX_SIM_TIME) {
    dut_reset(dut, sim_time);
    dut->clk ^= 1;

    // if (dut->clk == 1) {
    posedge_cnt++;
    tx = randVgaInTx();
    drv->drive(tx);
    Log("dut->data_i=0x%x\n", dut->data_i);
    inMon->monitor(); // input to dut
    dut->eval();      // dut evaluate
    // if (dut->clk == 1) {
    //   c_model->eval(tx->data_i, tx->resetn);
    // }
    outMon->monitor(); // dut output
    // }

    m_trace->dump(sim_time);
    sim_time++;
  }
  m_trace->close();

  delete dut;
  delete m_trace;
  delete outMon;
  delete inMon;
  delete scb;
  delete drv;
}

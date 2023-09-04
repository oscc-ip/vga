#include <cstdio>
#include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Vvga_ctrl.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 20
uint64_t sim_time;
uint64_t posedge_cnt;

class VgaCtrlInTx {
public:
  int data_i;
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
  void drive(VgaCtrlInTx *tx) { dut->data_i = tx->data_i; }
};
class VgaCtrlSCB {

private:
  std::deque<VgaCtrlInTx *> queue;

public:
  void write_in(VgaCtrlInTx *tx) { queue.push_back(tx); }
  void write_out(VgaCtrlOutTx *tx) {
    if (queue.empty()) {
      printf("Error, queue is empty\n");
      exit(1);
    }
    VgaCtrlInTx *in = queue.front();
    queue.pop_front();
    // TODO: add compare logic
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
    scb->write_in(tx);
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
    tx->red_o = dut->red_o;
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
  tx->data_i = rand() & 0xff;
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

  // implementations
  Verilated::traceEverOn(true);
  srand(time(NULL));
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");

  sim_time = 0;
  posedge_cnt = 0;
  while (sim_time < MAX_SIM_TIME) {
    // printf("time=%ld\n", sim_time);
    dut_reset(dut, sim_time);
    dut->clk ^= 1;
    dut->eval();

    if (dut->clk == 1) {
      posedge_cnt++;
      // printf("cnt=%ld\n", posedge_cnt);
      tx = randVgaInTx();
      drv->drive(tx);
      inMon->monitor();
      outMon->monitor();
    }

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

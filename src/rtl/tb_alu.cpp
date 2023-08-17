#include <cstdio>
#include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/Valu.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 20
uint64_t sim_time;
uint64_t posedge_cnt;

enum Operation { add = 0, sub = 1, nop = 2 };

void dut_reset(Valu *dut, vluint64_t sim_time) {
  dut->resetn = 1;
  if (sim_time >= 0 && sim_time <= 1) {
    dut->resetn = 0;
  }
}

class AluInTx {
public:
  int a;
  int b;
  int op;
};

class AluOutTx {
public:
  int result;
};

AluInTx *randAluInTx() {
  if ((rand() & 5) == 0) {
    AluInTx *tx = new AluInTx;
    tx->a = rand() & 0xff;
    tx->b = rand() & 0xff;
    tx->op = rand() & 1;
    return tx;
  }
  return NULL;
}

class AluInDrv {
private:
  Valu *dut;

public:
  AluInDrv(Valu *dut) { this->dut = dut; }
  void drive(AluInTx *tx) {
    dut->valid_in = 0;
    if (tx != NULL) {
      dut->valid_in = 1;
      dut->a_in = tx->a;
      dut->b_in = tx->b;
      dut->op_in = tx->op;
    }
    delete tx;
  }
};
class AluSCB {
private:
  std::deque<AluInTx *> queue;

public:
  void write_in(AluInTx *tx) { queue.push_back(tx); }
  void write_out(AluOutTx *tx) {
    if (queue.empty()) {
      printf("Error, queue is empty\n");
      exit(1);
    }
    AluInTx *in = queue.front();
    queue.pop_front();

    // printf("a=%d, b= %d, op=%d\n", in->a, in->b, in->op);
    // printf("result_out = %d\n\n", tx->result);
    if (in->op == 0) {
      if (in->a != tx->result) {
        printf("Wrong !!! Get: %d, Expected: %d\n", tx->result, in->a);
      } else {
        printf("Match\n");
      }
    } else if (in->op == 1) {
      if (in->b != tx->result) {
        printf("Wrong !!! Get: %d, Expected: %d\n", tx->result, in->b);
      } else {
        printf("Match\n");
      }
    }
  }
};

class AluInMonitor {
private:
  Valu *dut;
  AluSCB *scb;

public:
  AluInMonitor(Valu *dut, AluSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    if (dut->valid_in) {
      AluInTx *tx = new AluInTx;
      tx->a = dut->a_in;
      tx->b = dut->b_in;
      tx->op = dut->op_in;
      scb->write_in(tx);
    }
  }
};

class AluOutMonitor {
private:
  Valu *dut;
  AluSCB *scb;

public:
  AluOutMonitor(Valu *dut, AluSCB *scb) {
    this->dut = dut;
    this->scb = scb;
  }
  void monitor() {
    if (dut->valid_out) {
      AluOutTx *tx = new AluOutTx;
      tx->result = dut->result_out;
      scb->write_out(tx);
    }
  }
};

int main(int argc, char **argv) {

  // declare variables
  Valu *dut = new Valu;
  VerilatedVcdC *m_trace = new VerilatedVcdC;

  AluInTx *tx;

  // Here we create the driver, scoreboard, input and output monitor blocks
  AluInDrv *drv = new AluInDrv(dut);
  AluSCB *scb = new AluSCB();
  AluInMonitor *inMon = new AluInMonitor(dut, scb);
  AluOutMonitor *outMon = new AluOutMonitor(dut, scb);

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
      tx = randAluInTx();
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

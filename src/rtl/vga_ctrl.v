#include "obj_dir/Vvga_ctrl.h"
#include <cstdlib>
#include <iostream>
#include <stdlib.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {

  Vvga_ctrl *dut = new Vvga_ctrl;
  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");
  while (sim_time < MAX_SIM_TIME) {
    dut->clk ^= 1;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
  }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}

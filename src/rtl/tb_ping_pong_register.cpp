#include <cstdio>
// #include <cstdlib>
#include <deque>
#include <iostream>
#include <stdlib.h>

#include "./obj_dir/"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "config.h"
#include "ping_pong_register.h"

// #define MAX_SIM_TIME 20
// #define MAX_SIM_TIME 102
// #define MAX_SIM_TIME 200
#define MAX_SIM_TIME 2000
uint64_t sim_time;
uint64_t posedge_cnt;

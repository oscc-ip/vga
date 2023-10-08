#ifndef __PING_PONG_REGISTER__
#define __PING_PONG_REGISTER__
#define PING false
#define PONG false

// IO input
class InIO{
public:
  bool data_reg_i;  // request color data
  bool self_test_i; // seft test enable
  bool resetn_v;
  // signals with AXI bus
  bool arready_i, rvalid_i;
  int rresp_i, rdata_i;
  bool resetn_a;
};
// IO output
class OutIO {
public:
  // VC color data
  int data_o;
  int araddr_o;
  int arburst_o, arlen_o, arsize_o;
  bool arvalid_o, rready_o;
};
class ping_pong_register {
private:
  // ping pong registers
  int ping[32];
  int pong[32];
  int color; // self test color
  bool read_ping;
  int reg_count, byte_count; // read control signals
  int next_addr, write_cnt;  // write control signals

public:
  // IO
  InIO* in;
  OutIO* out;
  // functions
  void resetn();      // reset ppr c_model
  void eval(); // step one cycle
};
#endif

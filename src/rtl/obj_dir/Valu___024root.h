// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Valu.h for the primary calling header

#ifndef VERILATED_VALU___024ROOT_H_
#define VERILATED_VALU___024ROOT_H_  // guard

#include "verilated.h"

class Valu__Syms;
VL_MODULE(Valu___024root) {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(resetn,0,0);
    VL_IN8(op_in,0,0);
    VL_IN8(valid_in,0,0);
    VL_OUT8(valid_out,0,0);
    CData/*0:0*/ alu__DOT__valid_out_reg;
    CData/*0:0*/ __Vclklast__TOP__clk;
    VL_IN(a_in,31,0);
    VL_IN(b_in,31,0);
    VL_OUT(result_out,31,0);
    IData/*31:0*/ alu__DOT__calculation_reg;

    // INTERNAL VARIABLES
    Valu__Syms* vlSymsp;  // Symbol table

    // CONSTRUCTORS
    Valu___024root(const char* name);
    ~Valu___024root();
    VL_UNCOPYABLE(Valu___024root);

    // INTERNAL METHODS
    void __Vconfigure(Valu__Syms* symsp, bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

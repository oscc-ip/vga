// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Valu.h for the primary calling header

#include "verilated.h"

#include "Valu___024root.h"

VL_ATTR_COLD void Valu___024root___settle__TOP__2(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___settle__TOP__2\n"); );
    // Body
    vlSelf->result_out = vlSelf->alu__DOT__calculation_reg;
    vlSelf->valid_out = vlSelf->alu__DOT__valid_out_reg;
}

VL_ATTR_COLD void Valu___024root___eval_initial(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vclklast__TOP__clk = vlSelf->clk;
}

VL_ATTR_COLD void Valu___024root___eval_settle(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___eval_settle\n"); );
    // Body
    Valu___024root___settle__TOP__2(vlSelf);
}

VL_ATTR_COLD void Valu___024root___final(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___final\n"); );
}

VL_ATTR_COLD void Valu___024root___ctor_var_reset(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->resetn = VL_RAND_RESET_I(1);
    vlSelf->a_in = VL_RAND_RESET_I(32);
    vlSelf->b_in = VL_RAND_RESET_I(32);
    vlSelf->op_in = VL_RAND_RESET_I(1);
    vlSelf->valid_in = VL_RAND_RESET_I(1);
    vlSelf->result_out = VL_RAND_RESET_I(32);
    vlSelf->valid_out = VL_RAND_RESET_I(1);
    vlSelf->alu__DOT__calculation_reg = VL_RAND_RESET_I(32);
    vlSelf->alu__DOT__valid_out_reg = VL_RAND_RESET_I(1);
}

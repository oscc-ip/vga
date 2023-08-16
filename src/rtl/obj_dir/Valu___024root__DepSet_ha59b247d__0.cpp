// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Valu.h for the primary calling header

#include "verilated.h"

#include "Valu___024root.h"

VL_INLINE_OPT void Valu___024root___sequent__TOP__1(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___sequent__TOP__1\n"); );
    // Body
    if (vlSelf->resetn) {
        if (vlSelf->valid_in) {
            vlSelf->alu__DOT__valid_out_reg = 1U;
            if (vlSelf->op_in) {
                if (vlSelf->op_in) {
                    vlSelf->alu__DOT__calculation_reg 
                        = (vlSelf->a_in - vlSelf->b_in);
                }
            } else {
                vlSelf->alu__DOT__calculation_reg = 
                    (vlSelf->a_in + vlSelf->b_in);
            }
        } else {
            vlSelf->alu__DOT__valid_out_reg = 0U;
        }
    } else {
        vlSelf->alu__DOT__valid_out_reg = 0U;
        vlSelf->alu__DOT__calculation_reg = 0U;
    }
    vlSelf->valid_out = vlSelf->alu__DOT__valid_out_reg;
    vlSelf->result_out = vlSelf->alu__DOT__calculation_reg;
}

void Valu___024root___eval(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___eval\n"); );
    // Body
    if (((IData)(vlSelf->clk) & (~ (IData)(vlSelf->__Vclklast__TOP__clk)))) {
        Valu___024root___sequent__TOP__1(vlSelf);
    }
    // Final
    vlSelf->__Vclklast__TOP__clk = vlSelf->clk;
}

#ifdef VL_DEBUG
void Valu___024root___eval_debug_assertions(Valu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->resetn & 0xfeU))) {
        Verilated::overWidthError("resetn");}
    if (VL_UNLIKELY((vlSelf->op_in & 0xfeU))) {
        Verilated::overWidthError("op_in");}
    if (VL_UNLIKELY((vlSelf->valid_in & 0xfeU))) {
        Verilated::overWidthError("valid_in");}
}
#endif  // VL_DEBUG

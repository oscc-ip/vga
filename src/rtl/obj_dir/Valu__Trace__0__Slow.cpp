// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Valu__Syms.h"


VL_ATTR_COLD void Valu___024root__trace_init_sub__TOP__0(Valu___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root__trace_init_sub__TOP__0\n"); );
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->declBit(c+1,"clk", false,-1);
    tracep->declBit(c+2,"resetn", false,-1);
    tracep->declBus(c+3,"a_in", false,-1, 31,0);
    tracep->declBus(c+4,"b_in", false,-1, 31,0);
    tracep->declBit(c+5,"op_in", false,-1);
    tracep->declBit(c+6,"valid_in", false,-1);
    tracep->declBus(c+7,"result_out", false,-1, 31,0);
    tracep->declBit(c+8,"valid_out", false,-1);
    tracep->pushNamePrefix("alu ");
    tracep->declBus(c+11,"WIDTH", false,-1, 31,0);
    tracep->declBit(c+1,"clk", false,-1);
    tracep->declBit(c+2,"resetn", false,-1);
    tracep->declBus(c+3,"a_in", false,-1, 31,0);
    tracep->declBus(c+4,"b_in", false,-1, 31,0);
    tracep->declBit(c+5,"op_in", false,-1);
    tracep->declBit(c+6,"valid_in", false,-1);
    tracep->declBus(c+7,"result_out", false,-1, 31,0);
    tracep->declBit(c+8,"valid_out", false,-1);
    tracep->declBus(c+9,"calculation_reg", false,-1, 31,0);
    tracep->declBit(c+10,"valid_out_reg", false,-1);
    tracep->popNamePrefix(1);
}

VL_ATTR_COLD void Valu___024root__trace_init_top(Valu___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root__trace_init_top\n"); );
    // Body
    Valu___024root__trace_init_sub__TOP__0(vlSelf, tracep);
}

VL_ATTR_COLD void Valu___024root__trace_full_top_0(void* voidSelf, VerilatedVcd* tracep);
void Valu___024root__trace_chg_top_0(void* voidSelf, VerilatedVcd* tracep);
void Valu___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/);

VL_ATTR_COLD void Valu___024root__trace_register(Valu___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root__trace_register\n"); );
    // Body
    tracep->addFullCb(&Valu___024root__trace_full_top_0, vlSelf);
    tracep->addChgCb(&Valu___024root__trace_chg_top_0, vlSelf);
    tracep->addCleanupCb(&Valu___024root__trace_cleanup, vlSelf);
}

VL_ATTR_COLD void Valu___024root__trace_full_sub_0(Valu___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Valu___024root__trace_full_top_0(void* voidSelf, VerilatedVcd* tracep) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root__trace_full_top_0\n"); );
    // Init
    Valu___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Valu___024root*>(voidSelf);
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    Valu___024root__trace_full_sub_0((&vlSymsp->TOP), tracep);
}

VL_ATTR_COLD void Valu___024root__trace_full_sub_0(Valu___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Valu___024root__trace_full_sub_0\n"); );
    // Init
    vluint32_t* const oldp VL_ATTR_UNUSED = tracep->oldp(vlSymsp->__Vm_baseCode);
    // Body
    tracep->fullBit(oldp+1,(vlSelf->clk));
    tracep->fullBit(oldp+2,(vlSelf->resetn));
    tracep->fullIData(oldp+3,(vlSelf->a_in),32);
    tracep->fullIData(oldp+4,(vlSelf->b_in),32);
    tracep->fullBit(oldp+5,(vlSelf->op_in));
    tracep->fullBit(oldp+6,(vlSelf->valid_in));
    tracep->fullIData(oldp+7,(vlSelf->result_out),32);
    tracep->fullBit(oldp+8,(vlSelf->valid_out));
    tracep->fullIData(oldp+9,(vlSelf->alu__DOT__calculation_reg),32);
    tracep->fullBit(oldp+10,(vlSelf->alu__DOT__valid_out_reg));
    tracep->fullIData(oldp+11,(0x20U),32);
}

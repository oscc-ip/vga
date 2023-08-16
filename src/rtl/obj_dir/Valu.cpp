// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Valu.h"
#include "Valu__Syms.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Valu::Valu(VerilatedContext* _vcontextp__, const char* _vcname__)
    : vlSymsp{new Valu__Syms(_vcontextp__, _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , resetn{vlSymsp->TOP.resetn}
    , op_in{vlSymsp->TOP.op_in}
    , valid_in{vlSymsp->TOP.valid_in}
    , valid_out{vlSymsp->TOP.valid_out}
    , a_in{vlSymsp->TOP.a_in}
    , b_in{vlSymsp->TOP.b_in}
    , result_out{vlSymsp->TOP.result_out}
    , rootp{&(vlSymsp->TOP)}
{
}

Valu::Valu(const char* _vcname__)
    : Valu(nullptr, _vcname__)
{
}

//============================================================
// Destructor

Valu::~Valu() {
    delete vlSymsp;
}

//============================================================
// Evaluation loop

void Valu___024root___eval_initial(Valu___024root* vlSelf);
void Valu___024root___eval_settle(Valu___024root* vlSelf);
void Valu___024root___eval(Valu___024root* vlSelf);
#ifdef VL_DEBUG
void Valu___024root___eval_debug_assertions(Valu___024root* vlSelf);
#endif  // VL_DEBUG
void Valu___024root___final(Valu___024root* vlSelf);

static void _eval_initial_loop(Valu__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    Valu___024root___eval_initial(&(vlSymsp->TOP));
    // Evaluate till stable
    vlSymsp->__Vm_activity = true;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial loop\n"););
        Valu___024root___eval_settle(&(vlSymsp->TOP));
        Valu___024root___eval(&(vlSymsp->TOP));
    } while (0);
}

void Valu::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Valu::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Valu___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    vlSymsp->__Vm_activity = true;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        Valu___024root___eval(&(vlSymsp->TOP));
    } while (0);
    // Evaluate cleanup
}

//============================================================
// Utilities

VerilatedContext* Valu::contextp() const {
    return vlSymsp->_vm_contextp__;
}

const char* Valu::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

VL_ATTR_COLD void Valu::final() {
    Valu___024root___final(&(vlSymsp->TOP));
}

//============================================================
// Trace configuration

void Valu___024root__trace_init_top(Valu___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Valu___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Valu___024root*>(voidSelf);
    Valu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->scopeEscape(' ');
    tracep->pushNamePrefix(std::string{vlSymsp->name()} + ' ');
    Valu___024root__trace_init_top(vlSelf, tracep);
    tracep->popNamePrefix();
    tracep->scopeEscape('.');
}

VL_ATTR_COLD void Valu___024root__trace_register(Valu___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Valu::trace(VerilatedVcdC* tfp, int levels, int options) {
    if (false && levels && options) {}  // Prevent unused
    tfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Valu___024root__trace_register(&(vlSymsp->TOP), tfp->spTrace());
}

#include "Vtb_power.h"
#include "verilated.h"
#include "verilated_saif_c.h"

int main(int argc, char** argv) {
    auto* context = new VerilatedContext;
    context->commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    auto* top = new Vtb_power(context);
    VerilatedSaifC saif;
    saif.set_time_unit("ns");
    saif.set_time_resolution("ps");
    top->trace(&saif, 99);
    saif.open("activity_rtl.saif");

    // Verilator's context time is expressed in the generated design precision
    // (1 ps here), while the testbench clock period is 10 ns.  Keep the
    // capture window long enough for the complete 23,648-cycle job.
    constexpr uint64_t max_time_ps = 250000000;
    while (!context->gotFinish() && context->time() < max_time_ps) {
        top->eval();
        saif.dump(context->time());
        if (context->gotFinish() || !top->eventsPending()) break;
        context->time(top->nextTimeSlot());
    }

    top->final();
    saif.close();
    delete top;
    delete context;
    return 0;
}

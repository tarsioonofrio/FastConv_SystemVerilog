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

    constexpr uint64_t max_time_ns = 250000;
    while (!context->gotFinish() && context->time() < max_time_ns) {
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

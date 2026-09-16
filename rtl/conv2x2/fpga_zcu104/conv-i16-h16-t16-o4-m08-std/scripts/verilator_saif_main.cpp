#include "Vtb_power.h"
#include "Vtb_power___024root.h"
#include "verilated.h"
#include "verilated_saif_c.h"

#include <cstdint>
#include <iostream>

int main(int argc, char** argv) {
    auto* context = new VerilatedContext;
    context->commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    auto* top = new Vtb_power(context);
    VerilatedSaifC saif;
    saif.set_time_unit("ns");
    saif.set_time_resolution("ps");
    top->trace(&saif, 99);

    // The SAIF window is protocol-directed rather than a fixed-duration
    // capture. The testbench starts the job at p_start and increments
    // jobs_completed when p_end is observed. The timeout is only a safety net.
    constexpr double nominal_clock_period_ps = 3154.574;
    // The testbench has 1 ps timeprecision, so 1.577287 ns half-periods are
    // represented as 1577 ps and the effective simulated period is 3154 ps.
    constexpr double simulated_clock_period_ps = 3154.0;
    constexpr uint64_t max_timeout_ps = 200000000;
    bool capture_started = false;
    bool capture_finished = false;
    uint64_t capture_start_ps = 0;
    uint64_t capture_end_ps = 0;
    while (!context->gotFinish() && context->time() < max_timeout_ps) {
        top->eval();
        const bool start_event = top->rootp->tb_power__DOT__p_start;
        const bool end_event = top->rootp->tb_power__DOT__jobs_completed > 0;

        if (!capture_started && start_event) {
            capture_started = true;
            capture_start_ps = context->time();
            saif.open("activity_rtl.saif");
        }
        if (capture_started && !capture_finished) {
            // SAIF timestamps are relative to the directed capture window,
            // not to the absolute simulation time before p_start.
            saif.dump(context->time() - capture_start_ps);
            if (end_event) {
                capture_end_ps = context->time();
                capture_finished = true;
                saif.close();
            }
        }
        if (context->gotFinish() || !top->eventsPending()) break;
        context->time(top->nextTimeSlot());
    }

    if (!capture_started || !capture_finished) {
        std::cerr << "SAIF_CAPTURE_ERROR start=" << capture_started
                  << " finished=" << capture_finished
                  << " time_ps=" << context->time() << "\n";
        top->final();
        saif.close();
        delete top;
        delete context;
        return 2;
    }

    const uint64_t capture_duration_ps = capture_end_ps - capture_start_ps;
    const double captured_cycles =
        static_cast<double>(capture_duration_ps) / simulated_clock_period_ps;
    const double simulated_frequency_mhz = 1.0e6 / simulated_clock_period_ps;
    std::cout << "SAIF_CAPTURE clock_period_ps=" << simulated_clock_period_ps
              << " nominal_clock_period_ps=" << nominal_clock_period_ps
              << " clock_frequency_mhz=317"
              << " simulated_clock_frequency_mhz=" << simulated_frequency_mhz
              << " capture_start_ps=" << capture_start_ps
              << " capture_end_ps=" << capture_end_ps
              << " capture_duration_ps=" << capture_duration_ps
              << " captured_cycles=" << captured_cycles << "\n";

    top->final();
    saif.close();
    delete top;
    delete context;
    return 0;
}

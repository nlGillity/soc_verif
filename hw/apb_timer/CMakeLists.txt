cmake_minimum_required(VERSION 3.8)

# Name of the project
project(apb_timer)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE src/sim.sv)
set(SIM_FILES src/apb_timer.sv src/timer.sv)

# Verilator variables
set(VERILATOR_CSOURCES sim/sim_main.cpp)
set(VERILATOR_ARGS -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-UNSIGNED --timing --trace --coverage-line)

# CMake file doing the hard job
include(cmake/build-cosimulation.cmake)

#------------------------------------------------------------------------------
# Makefile for SCR1
#------------------------------------------------------------------------------

# PARAMETERS

# CFG = <MAX, BASE, MIN, CUSTOM>
# BUS = <AHB, AXI>

export CFG      ?= MAX
export BUS      ?= $(MODULE)


ifeq ($(CFG), MAX)
# Predefined configuration SCR1_CFG_RV32IMC_MAX
    override ARCH         := IMC
    override VECT_IRQ     := 1
    override IPIC         := 1
    override TCM          := 1
    override SIM_CFG_DEF  := SCR1_CFG_RV32IMC_MAX
else
    ifeq ($(CFG), BASE)
    # Predefined configuration SCR1_CFG_RV32IC_BASE
        override ARCH         := IC
        override VECT_IRQ     := 1
        override IPIC         := 1
        override TCM          := 1
        override SIM_CFG_DEF  := SCR1_CFG_RV32IC_BASE
    else
        ifeq ($(CFG), MIN)
        # Predefined configuration SCR1_CFG_RV32EC_MIN
            override ARCH         := EC
            override VECT_IRQ     := 0
            override IPIC         := 0
            override TCM          := 1
            override SIM_CFG_DEF  := SCR1_CFG_RV32EC_MIN
        else
        # CUSTOM configuration. Parameters can be overwritten
            # These options are for compiling tests only. Set the corresponding RTL parameters manually in the file scr1_arch_description.svh.
            # ARCH = <IMC, IC, IM, I, EMC, EM, EC, E>
            # VECT_IRQ = <0, 1>
            # IPIC = <0, 1>
            # TCM = <0, 1>
            ARCH      ?= IMC
            VECT_IRQ  ?= 0
            IPIC      ?= 0
            TCM       ?= 0
            SIM_CFG_DEF  = SCR1_CFG_$(CFG)
        endif
    endif
endif

# export all overrided variables
export ARCH
export VECT_IRQ
export IPIC
export TCM
export SIM_CFG_DEF

ARCH_lowercase = $(shell echo $(ARCH) | tr A-Z a-z)
BUS_lowercase  = $(shell echo $(BUS)  | tr A-Z a-z)

ifeq ($(ARCH_lowercase),)
    ARCH_tmp = imc
else
    ifneq (,$(findstring e,$(ARCH_lowercase)))
        ARCH_tmp   += e
        EXT_CFLAGS += -D__RVE_EXT
    else
        ARCH_tmp   += i
    endif
    ifneq (,$(findstring m,$(ARCH_lowercase)))
        ARCH_tmp   := $(ARCH_tmp)m
    endif
    ifneq (,$(findstring c,$(ARCH_lowercase)))
        ARCH_tmp   := $(ARCH_tmp)c
        EXT_CFLAGS += -D__RVC_EXT
    endif
    ifneq (,$(findstring b,$(ARCH_lowercase)))
        ARCH_tmp   := $(ARCH_tmp)b
    endif
endif

override ARCH=$(ARCH_tmp)

# Use this parameter to enable tracelog
TRACE ?= 0

ifeq ($(TRACE), 1)
    export SIM_TRACE_DEF = SCR1_TRACE_LOG_EN
else
    export SIM_TRACE_DEF = SCR1_TRACE_LOG_DIS
endif

# Use this parameter to pass additional options for simulation build command
SIM_BUILD_OPTS ?=

export XLEN  ?= 32
export ABI   ?= ilp32
# Testbench memory delay patterns\
  (FFFFFFFF - no delay, 00000000 - random delay, 00000001 - max delay)
imem_pattern ?= FFFFFFFF
dmem_pattern ?= FFFFFFFF

VERILATOR_OPTS ?=

current_goal := $(MAKECMDGOALS:run_%=%)
ifeq ($(current_goal),)
    current_goal := verilator
endif

# Paths
# export root_dir := $(shell pwd)/../
export tst_dir  := $(root_dir)/tests
export inc_dir  := $(root_dir)/tests/common
export bld_dir  ?= $(root_dir)/build/

test_results := $(bld_dir)/test_results.txt
test_info    := $(bld_dir)/test_info
sim_results  := $(bld_dir)/sim_results.txt

todo_list    := $(bld_dir)/todo.txt
# Environment
export CROSS_PREFIX  ?= riscv64-unknown-elf-
export RISCV_GCC     ?= $(CROSS_PREFIX)gcc
export RISCV_OBJDUMP ?= $(CROSS_PREFIX)objdump -D
export RISCV_OBJCOPY ?= $(CROSS_PREFIX)objcopy -O verilog
export RISCV_READELF ?= $(CROSS_PREFIX)readelf -s


export rtl_top_files := soc_top.files
export rtl_tb_files  := soc_tb_top.files
export top_module    := soc_top_tb_axi

export rtl_core_dir := $(root_dir)/hw/scr1/
export rtl_top_dir := $(root_dir)/hw/top/
export rtl_tb_dir := $(root_dir)/hw/top/


# Targets
.PHONY: run_verilator run_verilator_wf

run_verilator: 
	$(MAKE) -C $(root_dir)/sim build_verilator SIM_CFG_DEF=$(SIM_CFG_DEF) SIM_TRACE_DEF=$(SIM_TRACE_DEF) SIM_BUILD_OPTS="$(SIM_BUILD_OPTS)";
	printf "" > $(test_results);
	cd $(bld_dir); \
	echo $(top_module) | tee $(sim_results); \
	$(bld_dir)/verilator/V$(top_module) \
	+test_info=$(test_info) \
	+test_results=$(test_results) \
	+imem_pattern=$(imem_pattern) \
	+dmem_pattern=$(dmem_pattern) \
	$(VERILATOR_OPTS) | tee -a $(sim_results) ;\
	printf "Simulation performed on $$(verilator -version) \n" ;\
	printf "                          Test               | build | simulation \n" ; \
	printf "$$(cat $(test_results)) \n";\
    echo "\n root_dir is $(root_dir)\n"; 

run_verilator_wf: 
	$(MAKE) -C $(tst_dir); \
	$(MAKE) -C $(root_dir)/sim build_verilator_wf SIM_CFG_DEF=$(SIM_CFG_DEF) SIM_TRACE_DEF=$(SIM_TRACE_DEF) SIM_BUILD_OPTS="$(SIM_BUILD_OPTS)";\
	printf "" > $(test_results);\
	cd $(bld_dir); \
	echo $(top_module) | tee $(sim_results); \
	$(bld_dir)/verilator/V$(top_module) \
	+test_info=$(test_info) \
	+test_results=$(test_results) \
	+imem_pattern=$(imem_pattern) \
	+dmem_pattern=$(dmem_pattern) \
	$(VERILATOR_OPTS) | tee -a $(sim_results)  ;\
	printf "Simulation performed on $$(verilator -version) \n" ;\
	printf "                          Test               | build | simulation \n" ; \
	printf "$$(cat $(test_results)) \n"
clean:
	$(RM) -R $(root_dir)/build/*
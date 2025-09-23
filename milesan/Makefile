# Copyright 2024 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

PYTHON ?= python3

TOP_MODULE = openc910_mem_top
TOP_SOC = openc910_tiny_soc
TOP_EXECUTABLE_NAME = V$(TOP_SOC)
TOP_FOR_INSTRUMENTATION = openc910_mem_top
TARGET_NAMES = vanilla cellift
RESOURCEWRAPPER_TAG ?= openc910
VCD_REGEX = i_dut/i_mem_top/x_cpu_sub_system_axi/x_rv_integration_platform/x_cpu_top/x_ct_top_0/*
APB_BASE_ADDR = "40'h40000000"

# Use common design Makefile rules
include common.mk

include filelists.mk

#
# 1. Gather the source code.
#

generated/bender.sources: Bender.yml | generated
	bender sources -f -t openc910 > generated/tmp.sources
	sed -i "s/synopsys_sram/util\/sram/g" generated/tmp.sources
	grep -v "_trace" generated/tmp.sources > $@
	rm -rf generated/tmp.sources

generated/sv2v_out.v: | generated generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_sv2v_out_start.txt
	sv2v -DAPB_BASE_ADDR=$(APB_BASE_ADDR) $(SV2V_FLAGS) $(FILELIST_NOSRAM) $(FILELIST_SRAMONLY) -w $@
	echo >> $@
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_sv2v_out_end.txt

generated/sv2v_out_nosram.v: | generated generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_sv2v_out_nosram_start.txt
	sv2v -DAPB_BASE_ADDR=$(APB_BASE_ADDR) $(SV2V_FLAGS) $(FILELIST_NOSRAM) -w $@
	echo >> $@
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_sv2v_out_nosram_end.txt


generated/sv2v_axi_to_mem.v: | generated/out
	sv2v -DAPB_BASE_ADDR=$(APB_BASE_ADDR) $(SV2V_FLAGS) $(FILELIST_AXI_ONLY) -w $@

generated/openc910_pickled.sv: generated/sv2v_out.v | generated/out
	cp $< $@

generated/cellift_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/sv2v_out.v | generated/out logs generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_cellift_precompact_start.txt
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_FOR_INSTRUMENTATION) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_cellift_precompact_end.txt

# generated/hybridift_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/sv2v_out_blackboxsrams.v | generated/out logs generated/timestamps
# 	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_hybridift_precompact_start.txt
# 	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_FOR_INSTRUMENTATION) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log
# 	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_hybridift_precompact_end.txt


generated/hybridift_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/hybridift_interm.sv | generated/out logs generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_hybridift_precompact_start.txt
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_FOR_INSTRUMENTATION) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_hybridift_precompact_end.txt

# generated/drfuzz_mem_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/sv2v_out_blackboxsrams.v | generated/out logs generated/timestamps
# 	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_FOR_INSTRUMENTATION) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log

generated/drfuzz_mem_precompact.sv: $(CELLIFT_YS)/instrument.ys.tcl  generated/hybridift_interm_no_unwanted_t0s.sv | generated/out logs generated/timestamps
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_FOR_INSTRUMENTATION) $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log


# TODO: use recipe, right now I created it manually since we need to instrument from the top to the memory but replace the memory with the IFT sram.
# src/util/ift_axi_to_mem.sv is therefore obtained by manually replacing the sram in generated/ift_axi_to_mem.sv 
generated/ift_axi_to_mem.sv: $(CELLIFT_YS)/instrument.ys.tcl generated/sv2v_axi_to_mem.v | generated/out logs generated/timestamps
	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=cellift VERILOG_OUTPUT=$@ TOP_MODULE=milesan_axi_slave128 $(CELLIFT_META_ROOT)/resourcewrapper $(RESOURCEWRAPPER_TAG) cellift instr yosys -c $< -l $@.log

generated/out/cellift.sv: generated/cellift_precompact.sv | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_cellift_start.txt
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_left_operand.py $< generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_right_operand.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compress_concats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/divide_concat_into_subconcats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/correct_too_wide_lvalues.py generated/interm.sv generated/interm.sv
	sed 's/assign xx_intc_vld/\/\/assign xx_intc_vld/g' generated/interm.sv > $@
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_cellift_end.txt

generated/out/hybridift.sv: generated/hybridift_precompact.sv | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_hybridift_start.txt
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_left_operand.py $< generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_right_operand.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compress_concats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/divide_concat_into_subconcats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/correct_too_wide_lvalues.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_clkt0.py generated/interm.sv generated/interm.sv
	sed 's/assign xx_intc_vld/\/\/assign xx_intc_vld/g' generated/interm.sv > $@
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_hybridift_end.txt


generated/out/drfuzz_mem.sv: generated/drfuzz_mem_precompact.sv | generated/timestamps
	sed 's/\$func\$\/cellift-cva6\/cellift\/generated\/hybridift_interm.sv/mypath/g' $< > generated/interm.sv 
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_left_operand.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/expand_right_operand.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compress_concats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/divide_concat_into_subconcats.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/correct_too_wide_lvalues.py generated/interm.sv generated/interm.sv
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_clkt0.py generated/interm.sv generated/interm.sv
	sed 's/assign xx_intc_vld/\/\/assign xx_intc_vld/g' generated/interm.sv > $@



# Black-box memory modules, instrumented separately
tmp/all_blackbox.v: testinstr.py | tmp
	$(PYTHON) testinstr.py

generated/sv2v_out_blackboxsrams.v: tmp/all_blackbox.v generated/sv2v_out_nosram.v | generated/out
	cat $^ > $@

generated/sv2v_out_with_sram_mem_blackbox.v: generated/sv2v_out.v src/util/sram_mem_blackbox.sv
	cat $^ > $@

#
# 2. Pickle the source code.
#

# openc910_SMALLER_CACHES = -Dopenc910_SMALLER_CACHES

# $(PYTHON) $(CELLIFT_PYTHON_COMMON)/ascend_package_in_pickle.py cva6_config_pkg generated/pickled_interm.sv
# $(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_pragma_translate_off.py generated/pickled_interm.sv generated/pickled_interm.sv
# $(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_attributes.py generated/pickled_interm.sv generated/pickled_interm.sv
# $(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_modules.py generated/pickled_interm.sv $@ pad_functional_pd pad_functional_pu axi_lite_to_apb axi_lite_to_apb_intf axi_lite_xbar axi_lite_to_axi axi_modify_address axi_to_axi_lite axi_to_axi_lite_intf axi_to_axi_lite_id_reflect
# rm -rf generated/pickled_interm.sv

#
# 3. Apply sv2v and discard signal strengths.
#

#
# 5. Apply some Python scripts to:
# - compacify the wide concatenations.
# - properly run with Verilator.
#

generated/out/vanilla.sv: generated/openc910_pickled.sv | generated/out generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_vanilla_start.txt
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_modules.py $< generated/interm.sv openc910_testharness cva6_mmu_sv32 pad_functional_pd pad_functional_pu
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compress_concats.py generated/interm.sv $@
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_out_vanilla_end.txt

generated/passthrough_precompact.sv: $(CELLIFT_YS)/passthrough_metareset.ys.tcl generated/sv2v_out_with_sram_mem_blackbox.v | generated/out logs generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_passthrough_start.txt
	DECOMPOSE_MEMORY=0 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=vanilla VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_MODULE) yosys -DRANDOMIZE_MEM_INIT -DRANDOMIZE_REG_INIT -c $< -l $@.log
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/generated_passthrough_end.txt

generated/passthrough_precompact_smaller.sv: generated/passthrough_precompact.sv | generated
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/remove_unused_modules.py $< $@ openc910_mem_top

generated/hybridift_interm.sv: generated/passthrough_precompact_smaller.sv | generated
	$(PYTHON) hybridift.py $< $@

generated/hybridift_interm_no_unwanted_t0s.sv: generated/hybridift_interm.sv
	$(PYTHON) replace_unwanted_t0s.py $< $@

# generated/out/vanilla.sv.log: | generated/out
# 	touch $@

# # rfuzz coverage metric
# generated/out/rfuzz.sv: $(OUR_YS)/rfuzz.ys.tcl generated/sv2v_out.v | generated/out logs
# 	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=$* VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_MODULE) yosys -c $< -l $@.log
# # Active RFUZZ
# generated/out/drfuzz.sv: $(OUR_YS)/drfuzz.ys.tcl generated/sv2v_out.v | generated/out logs
# 	DECOMPOSE_MEMORY=1 VERILOG_INPUT=$(word 2,$^) INSTRUMENTATION=drfuzz VERILOG_OUTPUT=$@ TOP_MODULE=$(TOP_MODULE) EXCLUDE_SIGNALS=$(EXCLUDE_SIGNALS) TOP_RESET=$(TOP_RESET) VERBOSE=$(VERBOSE) yosys -c $< -l $@.log

# # Core files
# CORE_FILES_NOTRACE=$(patsubst %,run_%_notrace.core, $(TARGET_NAMES))
# $(CORE_FILES_NOTRACE): run_%.core: run_%.core.template
# 	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/gen_corefiles.py $< $@

# #
# # Recompile, if only the software has changed since the previous step.
# #

# RECOMPILE_TARGETS_NOTRACE=$(patsubst %,recompile_%_notrace, $(TARGET_NAMES))
# RECOMPILE_TARGETS_TRACE=$(patsubst %,recompile_%_trace, $(TARGET_NAMES))
# RECOMPILE_TARGETS_TRACE_FST=$(patsubst %,recompile_%_trace_fst, $(TARGET_NAMES))
# RECOMPILE_TARGETS = $(RECOMPILE_TARGETS_NOTRACE) $(RECOMPILE_TARGETS_TRACE) $(RECOMPILE_TARGETS_TRACE_FST)

# .PHONY: $(RECOMPILE_TARGETS)
# $(RECOMPILE_TARGETS): recompile_%: build/run_%_0.1
# # rm -f $</default-verilator/*.o
# 	rm -f $</default-verilator/toplevel.o
# 	rm -f $</default-verilator/$(TOP_EXECUTABLE_NAME)
# 	rm -rf $</src/run_$*_0.1/dv
# 	rm -rf ./build/dv
# 	cp -r dv $</src/run_$*_0.1
# 	cp -r $(CELLIFT_DESIGN_PROCESSING_ROOT)/common/dv ./build
# 	make -C $</default-verilator -j $(MILESAN_JOBS)

#
# Rerun a simulation.
#

# RERUN_TARGETS_NOTRACE=$(patsubst %,rerun_%_notrace, $(TARGET_NAMES))
# RERUN_TARGETS_TRACE=$(patsubst %,rerun_%_trace, $(TARGET_NAMES))
# RERUN_TARGETS_TRACE_FST=$(patsubst %,rerun_%_trace_fst, $(TARGET_NAMES))
# RERUN_TARGETS = $(RERUN_TARGETS_NOTRACE) $(RERUN_TARGETS_TRACE) $(RERUN_TARGETS_TRACE_FST)

# .PHONY: $(RERUN_TARGETS) | traces
# $(RERUN_TARGETS): rerun_%: build/run_%_0.1/
# 	$</default-verilator/$(TOP_EXECUTABLE_NAME)

#
# 7. Run with Verilator through FuseSoC
# - properly run with Verilator.
# - insert the right SRAMs.
#

# # Phony targets

# PREPARE_TARGETS_NOTRACE=$(patsubst %,prepare_%_notrace, $(TARGET_NAMES))
# PREPARE_TARGETS_TRACE=$(patsubst %,prepare_%_trace, $(TARGET_NAMES))
# PREPARE_TARGETS_TRACE_FST=$(patsubst %,prepare_%_trace_fst, $(TARGET_NAMES))
# PREPARE_TARGETS = $(PREPARE_TARGETS_NOTRACE) $(PREPARE_TARGETS_TRACE) $(PREPARE_TARGETS_TRACE)
# .PHONY: $(PREPARE_TARGETS)
# $(PREPARE_TARGETS): prepare_%: build/run_%_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)

# # Actual targets

# BUILD_TARGETS_NOTRACE=$(patsubst %,build/run_%_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))
# BUILD_TARGETS_TRACE=$(patsubst %,build/run_%_trace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))
# BUILD_TARGETS_TRACE_FST=$(patsubst %,build/run_%_trace_fst_0.1/default-verilator/$(TOP_EXECUTABLE_NAME), $(TARGET_NAMES))
# BUILD_TARGETS = $(BUILD_TARGETS_NOTRACE) $(BUILD_TARGETS_TRACE) $(BUILD_TARGETS_TRACE_FST)

# $(BUILD_TARGETS_NOTRACE): build/run_%_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME):
# 	rm -f fusesoc.conf
# 	fusesoc library add run_$*_notrace .
# 	fusesoc run --build run_$*_notrace
# 	cp $<.log $@.log
# $(BUILD_TARGETS_TRACE): build/run_%_trace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME):
# 	rm -f fusesoc.conf
# 	fusesoc library add run_$*_trace .
# 	fusesoc run --build run_$*_trace
# 	cp $<.log $@.log
# $(BUILD_TARGETS_TRACE_FST): build/run_%_trace_fst_0.1/default-verilator/$(TOP_EXECUTABLE_NAME):
# 	rm -f fusesoc.conf
# 	fusesoc library add run_$*_trace_fst .
# 	fusesoc run --build run_$*_trace_fst
# 	cp $<.log $@.log

# #
# # Run, potentially after compiling.
# #

# RUN_TARGETS_NOTRACE=$(patsubst %,run_%_notrace, $(TARGET_NAMES))
# RUN_TARGETS_TRACE=$(patsubst %,run_%_trace, $(TARGET_NAMES))
# RUN_TARGETS_TRACE_FST=$(patsubst %,run_%_trace_fst, $(TARGET_NAMES))
# RUN_TARGETS = $(RUN_TARGETS_NOTRACE) $(RUN_TARGETS_TRACE) $(RUN_TARGETS_TRACE_FST)

# $(RUN_TARGETS_TRACE) $(RUN_TARGETS_TRACE_FST): | traces
# $(RUN_TARGETS): run_%: ./build/run_%_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
# 	cd build/run_$*_0.1/default-verilator && ./$(TOP_EXECUTABLE_NAME)

.PHONY: run_vanilla_notrace
run_vanilla_notrace: generated/out/vanilla.sv | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_vanilla_notrace_start.txt
	rm -f fusesoc.conf
	fusesoc library add run_vanilla_notrace .
	fusesoc run --build run_vanilla_notrace; echo Done
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_vanilla_notrace_end.txt
.PHONY: run_cellift_notrace
run_cellift_notrace: generated/out/cellift.sv | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_cellift_notrace_start.txt
	rm -f fusesoc.conf
	fusesoc library add run_cellift_notrace .
	fusesoc run --build run_cellift_notrace; echo Done
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_cellift_notrace_end.txt
.PHONY: run_hybridift_notrace
run_hybridift_notrace: generated/out/hybridift.sv | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_hybridift_notrace_start.txt
	rm -f fusesoc.conf
	fusesoc library add run_hybridift_notrace .
	fusesoc run --build run_hybridift_notrace; echo Done
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/run_hybridift_notrace_end.txt
.PHONY: run_drfuzz_mem_notrace
run_drfuzz_mem_notrace: generated/out/drfuzz_mem.sv | generated/timestamps # generated/ift_axi_to_mem.sv
	rm -f fusesoc.conf
	fusesoc library add run_drfuzz_mem_notrace .
	fusesoc run --build run_drfuzz_mem_notrace; echo Done
run_drfuzz_mem_trace: generated/out/drfuzz_mem.sv | generated/timestamps # generated/ift_axi_to_mem.sv
	rm -f fusesoc.conf
	fusesoc library add run_drfuzz_mem_trace .
	fusesoc run --build run_drfuzz_mem_trace; echo Done


.PHONY: rerun_vanilla_notrace
rerun_vanilla_notrace: | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_vanilla_notrace_start.txt
	./build/run_vanilla_notrace_0.1/default-verilator/Vopenc910_tiny_soc
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_vanilla_notrace_end.txt
.PHONY: rerun_cellift_notrace
rerun_cellift_notrace: | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_cellift_notrace_start.txt
	./build/run_cellift_notrace_0.1/default-verilator/Vopenc910_tiny_soc
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_cellift_notrace_end.txt
.PHONY: rerun_hybridift_notrace
rerun_hybridift_notrace: | generated/timestamps
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_hybridift_notrace_start.txt
	./build/run_hybridift_notrace_0.1/default-verilator/Vopenc910_tiny_soc
	date +%Y-%m-%dT%H:%M:%S > generated/timestamps/rerun_hybridift_notrace_end.txt
.PHONY: rerun_drfuzz_mem_notrace
rerun_drfuzz_mem_notrace: | generated/timestamps
	./build/run_drfuzz_mem_notrace_0.1/default-verilator/Vopenc910_tiny_soc
.PHONY: rerun_drfuzz_mem_notrace
rerun_drfuzz_mem_trace: | generated/timestamps
	./build/run_drfuzz_mem_trace_0.1/default-verilator/Vopenc910_tiny_soc


.PHONY: recompile_vanilla_notrace
recompile_vanilla_notrace: # generated/out/vanilla.sv
	rm -f build/run_vanilla_notrace_0.1/default-verilator/toplevel.o
	rm -f build/run_vanilla_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
	rm -rf build/run_vanilla_notrace_0.1/default-verilator/src/milesan/dv
	cp -r dv build/run_vanilla_notrace_0.1/default-verilator/src/milesan/dv
	make -C build/run_vanilla_notrace_0.1/default-verilator -j $(MILESAN_JOBS)

.PHONY: recompile_cellift_notrace
recompile_cellift_notrace: # generated/out/cellift.sv
	rm -f build/run_cellift_notrace_0.1/default-verilator/toplevel.o
	rm -f build/run_cellift_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
	rm -rf build/run_cellift_notrace_0.1/default-verilator/src/run_cellift_0.1/dv
	rm -rf ./build/dv
	cp -r dv build/run_cellift_notrace_0.1//default-verilator/src/run_cellift_0.1
	cp -r $(CELLIFT_DESIGN_PROCESSING_ROOT)/common/dv ./build
	make -C build/run_cellift_notrace_0.1/default-verilator -j $(MILESAN_JOBS)

.PHONY: recompile_hybridift_notrace
recompile_hybridift_notrace: # generated/out/hybridift.sv
	rm -f build/run_hybridift_notrace_0.1/default-verilator/toplevel.o
	rm -f build/run_hybridift_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
	rm -rf build/run_hybridift_notrace_0.1//default-verilator/src/run_hybridift_0.1/dv
	rm -rf ./build/dv
	cp -r dv build/run_hybridift_notrace_0.1/default-verilator/src/run_hybridift_0.1
	cp -r $(CELLIFT_DESIGN_PROCESSING_ROOT)/common/dv ./build
	make -C build/run_hybridift_notrace_0.1/default-verilator -j $(MILESAN_JOBS)

.PHONY: recompile_drfuzz_mem_notrace
recompile_drfuzz_mem_notrace: 
	rm -f build/run_drfuzz_mem_notrace_0.1/default-verilator/toplevel.o
	rm -f build/run_drfuzz_mem_notrace_0.1/default-verilator/$(TOP_EXECUTABLE_NAME)
	rm -rf build/run_drfuzz_mem_notrace_0.1/default-verilator/src/milesan/dv
	cp -r dv build/run_drfuzz_mem_notrace_0.1/default-verilator/src/milesan/dv
	make -C build/run_drfuzz_mem_notrace_0.1/default-verilator -j $(MILESAN_JOBS)


tmp generated/timestamps:
	mkdir -p $@

.PHONY: durations_cellift
durations_cellift:
	@echo "For cellift:"
	@echo "Build"
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compute_duration.py generated/timestamps/generated_cellift_precompact_start.txt generated/timestamps/generated_cellift_precompact_end.txt
	@echo "Verilator elaboration"
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compute_duration.py generated/timestamps/run_cellift_notrace_start.txt generated/timestamps/run_cellift_notrace_end.txt

.PHONY: durations_hybridift
durations_hybridift:
	@echo "For hybridift:"
	@echo "Build"
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compute_duration.py generated/timestamps/generated_hybridift_precompact_start.txt generated/timestamps/generated_hybridift_precompact_end.txt
	@echo "Verilator elaboration"
	$(PYTHON) $(CELLIFT_PYTHON_COMMON)/compute_duration.py generated/timestamps/run_hybridift_notrace_start.txt generated/timestamps/run_hybridift_notrace_end.txt


#
# Modelsim
#
# MODELSIM_INCDIRSTR := ~/ssh_mnt/milesan-designs/hybridift-openc910/openc910/milesan/src/util/milesan_axi_slave128.sv

MILESAN_DIR := ${shell dirname ${shell pwd}}/milesan
MODELSIM_PATH_TO_BUILD_TCL=$(MILESAN_DIR)/modelsim_build.tcl
IFT_AXI_TO_MEM=$(MILESAN_DIR)/src/util/ift_axi_to_mem.sv
ALL_MEMSHADE=$(MILESAN_DIR)/tmp/all_memshade.v
FPGA_SRAM=$(MILESAN_DIR)/src/util/my_fpga_ram.v
include $(MILESAN_DIR)/modelsim.mk


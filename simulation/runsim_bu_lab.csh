#!/bin/csh
# Variant of the script for running on the PHO 307 machines. It simply has a different path to the ModelSim applications.
if ($1 !~ "") then
  set vsimargs = +ROM_FILE=${1}
else
  set vsimargs = +ROM_FILE=gcd
endif

/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlib work

/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/ALU.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/bram.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/bsram.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/control_unit.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/decode.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/execute.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/mem_interface.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/memory.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/regFile.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/RISC_V_Core.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/tb_RISC_V_Core.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/writeback.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/fetch.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/branch_predictor.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vlog -reportprogress 300 -work work ../hardware/src/two_bit_sat_cntr.v
/ad/eng/opt/mentor/modelsim/modeltech/bin/linux_x86_64/vsim -voptargs=+acc work.tb_RISC_V_Core ${vsimargs} -do ./run.tcl

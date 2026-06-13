catch {file delete -force brain_wave_detector}

open_project brain_wave_detector
set_top brainwave_recognizer

add_files src/brainwave_recognizer.hpp
add_files src/brainwave_recognizer.cpp
add_files -tb tb/tb.cpp

open_solution solution1 -flow_target vivado
set_part {xc7a100tcsg324-1}
create_clock -period 10.0 -name default

csynth_design
cosim_design -rtl vhdl
exit
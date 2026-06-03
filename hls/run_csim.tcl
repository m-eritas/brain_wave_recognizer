open_project brain_wave_detector
set_top brainwave_recognizer
add_files src/brainwave_recognizer.hpp
add_files src/brainwave_recognizer.cpp
add_files -tb tb/tb.cpp
open_solution solution1 -flow_target vivado
set_part xa7a12tcpg238-2I
csim_design
exit
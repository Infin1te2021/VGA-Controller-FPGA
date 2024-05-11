create_clock -name "CLK" -period 20.0ns [get_ports {CLK}]
derive_pll_clocks
derive_clock_uncertainty
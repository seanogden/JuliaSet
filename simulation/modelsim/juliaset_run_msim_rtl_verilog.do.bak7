transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/Reset_Delay.v}
vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/VGA_PLL.v}
vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/video_buffer.v}
vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/juliaset.v}
vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet/db {C:/JuliaSet/JuliaSet/db/vga_pll_altpll.v}
vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/VGA_Controller.v}

vlog -vlog01compat -work work +incdir+C:/JuliaSet/JuliaSet {C:/JuliaSet/JuliaSet/testbench.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc" testbench

add wave *
view structure
view signals
run -all

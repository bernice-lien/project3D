# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {VGA signals}


############# SRAM INTERFACE (inside M1_SRAM_interface) #############
add wave -divider -height 10 {M1 SRAM interface}
add wave -uns  UUT/M1_unit/M1_SRAM_state
add wave -uns  UUT/M1_unit/SRAM_address
add wave -hex  UUT/M1_unit/SRAM_write_data
add wave -bin  UUT/M1_unit/SRAM_we_n
add wave -hex  UUT/M1_unit/SRAM_read_data
add wave -hex  UUT/M1_unit/leadout
add wave -hex  UUT/M1_unit/M1_stop


# Helpful internal addresses (declared in module)
add wave -uns  UUT/M1_unit/SRAM_address_Y
add wave -uns  UUT/M1_unit/SRAM_address_U
add wave -uns  UUT/M1_unit/SRAM_address_V
add wave -uns  UUT/M1_unit/SRAM_address_RGB

# Flags and helpers
add wave -divider -height 10 {M1 flags}
add wave -bin  UUT/M1_unit/parity
add wave -bin  UUT/M1_unit/leadout
add wave -uns  UUT/M1_unit/writeoff

# ------------------- MILESTONE 1: Y / U / V -----------------------
add wave -divider -height 10 {M1 YUV registers}
add wave -hex UUT/M1_unit/Yeven
add wave -hex UUT/M1_unit/Yodd
add wave -hex UUT/M1_unit/Ubuff
add wave -hex UUT/M1_unit/Vbuff
add wave -hex UUT/M1_unit/U_calc
add wave -hex UUT/M1_unit/V_calc
add wave -hex UUT/M1_unit/Re_c
add wave -hex UUT/M1_unit/Ge_c

############# Shift Registers #############
add wave -hex UUT/M1_unit/Ureg
##add wave -hex UUT/M1_unit/Ureg(1)
##add wave -hex UUT/M1_unit/Ureg(2)
##add wave -hex UUT/M1_unit/Ureg(3)
##add wave -hex UUT/M1_unit/Ureg(4)
##add wave -hex UUT/M1_unit/Ureg(5)
##add wave -hex UUT/M1_unit/Ureg(6)
##add wave -hex UUT/M1_unit/Ureg(7)
##add wave -hex UUT/M1_unit/Ureg(8)
##add wave -hex UUT/M1_unit/Ureg(9)

add wave -hex UUT/M1_unit/Vreg
##add wave -hex UUT/M1_unit/Vreg(1)
##add wave -hex UUT/M1_unit/Vreg(2)
##add wave -hex UUT/M1_unit/Vreg(3)
##add wave -hex UUT/M1_unit/Vreg(4)
##add wave -hex UUT/M1_unit/Vreg(5)
##add wave -hex UUT/M1_unit/Vreg(6)
##add wave -hex UUT/M1_unit/Vreg(7)
##add wave -hex UUT/M1_unit/Vreg(8)
##add wave -hex UUT/M1_unit/Vreg(9)

# ------------------- MILESTONE 1: MULT PATH -----------------------
add wave -divider -height 10 {M1 multiplier path}
# 32-bit multiplicand/multiplier and 32/64-bit results
add wave -dec UUT/M1_unit/M_a1
add wave -dec UUT/M1_unit/M_a2
add wave -dec UUT/M1_unit/M_b1
add wave -dec UUT/M1_unit/M_b2
add wave -dec UUT/M1_unit/M_c1
add wave -dec UUT/M1_unit/M_c2
add wave -dec UUT/M1_unit/M_d1
add wave -dec UUT/M1_unit/M_d2
add wave -dec UUT/M1_unit/M_ar
add wave -dec UUT/M1_unit/M_br
add wave -dec UUT/M1_unit/M_cr
add wave -dec UUT/M1_unit/M_dr
# 64-bit raw products (optional but handy for debug)
add wave -dec UUT/M1_unit/M_arl
add wave -dec UUT/M1_unit/M_brl
add wave -dec UUT/M1_unit/M_crl
add wave -dec UUT/M1_unit/M_drl

# ------------------- MILESTONE 1: RGB RESULTS ---------------------
add wave -divider -height 10 {M1 RGB results}
add wave -dec UUT/M1_unit/Re_accum
add wave -dec UUT/M1_unit/Ge_accum
add wave -dec UUT/M1_unit/Be_accum
add wave -dec UUT/M1_unit/Ro_accum
add wave -dec UUT/M1_unit/Go_accum
add wave -dec UUT/M1_unit/Bo_accum

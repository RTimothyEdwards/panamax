#----------------------------------------------------
# Panamax pad generation script
#----------------------------------------------------
# Written by Tim Edwards, Efabless
# Jan. 17, 2024 to May 29, 2024
#----------------------------------------------------
# Source this file from magic, in the mag/ directory
#----------------------------------------------------
# Sept. 10, 2024:  This script is behind the layout,
# which has several manual modifications:
# (1) The amuxbus tap cell needs to be flipped
#     sideways.
# (2) Two additional vdda bus disconnect cells are
#     needed on the left and right sides at the
#     bottom.

#-----------------------------------------------------
# Define all procedures used in this script
#-----------------------------------------------------

# Given a selected cell, move right (east) by the
# width of the cell's abutment box.

proc move_abutment_east {} {
    box values {*}[instance list abutment]
    box move e [box width]
}

# Same thing in the left (west) direction

proc move_abutment_west {} {
    box values {*}[instance list abutment]
    box move w [box width]
}

# Given a selected cell, move up (north) by the
# height of the cell's abutment box.

proc move_abutment_north {} {
    box values {*}[instance list abutment]
    box move n [box height]
}

# Same thing in the downward (south) direction

proc move_abutment_south {} {
    box values {*}[instance list abutment]
    box move s [box height]
}

# Place a cell on the bottom row and move
# forward by its abutment box.

proc get_cell_bottom {cellname {instname ""}} {
    getcell $cellname 180 child ur
    if {$instname != ""} {
	identify $instname
    }
    move_abutment_east
}

# Place a cell on the right side and move
# forward by its abutment box.

proc get_cell_right {cellname {instname ""}} {
    getcell $cellname 90 child ur parent lr
    if {$instname != ""} {
	identify $instname
    }
    move_abutment_north
}

# Place a cell on the top row and move
# forward by its abutment box.

proc get_cell_top {cellname {instname ""}} {
    getcell $cellname child ul parent ul
    if {$instname != ""} {
	identify $instname
    }
    move_abutment_east
}

# Place a cell on the left side and move
# forward by its abutment box.

proc get_cell_left {cellname {instname ""}} {
    getcell $cellname 270 child ul
    if {$instname != ""} {
	identify $instname
    }
    move_abutment_north
}

# Add spacers between cells on the bottom.  If "extra"
# is 1, add additional space, and if "extra" is 2, add
# the space needed at the end.

proc place_bottom_spacers {{extra 0}} {
    get_cell_bottom sky130_ef_io__com_bus_slice_20um
    get_cell_bottom sky130_ef_io__com_bus_slice_10um
    if {$extra != 2} {
	get_cell_bottom sky130_ef_io__com_bus_slice_5um
    }
    if {$extra == 1} {
	get_cell_bottom sky130_ef_io__com_bus_slice_20um
    }
    if {$extra == 2} {
	get_cell_bottom sky130_ef_io__com_bus_slice_1um
	get_cell_bottom sky130_ef_io__com_bus_slice_1um
	get_cell_bottom sky130_ef_io__com_bus_slice_1um
	get_cell_bottom sky130_ef_io__com_bus_slice_1um
    }
    if {$extra == 3} {
	# Use this position to tie the VCCHIB and VSWITCH buses
	get_cell_bottom sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um
    }
}

# Add spacers between cells on the right.  If "extra"
# is 1, add additional space, and if "extra" is 2, add
# the space needed at the end.

proc place_right_spacers {{extra 0}} {
    if {$extra != 2} {
	get_cell_right sky130_ef_io__com_bus_slice_20um
	get_cell_right sky130_ef_io__com_bus_slice_5um
    }
    if {$extra == 1} {
	get_cell_right sky130_ef_io__com_bus_slice_20um
    }
    if {$extra == 2} {
	get_cell_right sky130_ef_io__disconnect_vdda_slice_5um
    }
}

# Add spacers between cells on the top.  If "extra"
# is 1, add additional space, and if "extra" is 2, add
# the space needed at the end.

proc place_top_spacers {{extra 0}} {
    if {$extra != 3} {
	get_cell_top sky130_ef_io__com_bus_slice_20um
    }
    if {$extra < 2} {
	get_cell_top sky130_ef_io__com_bus_slice_20um
    }
    if {$extra == 3} {
	get_cell_top sky130_ef_io__com_bus_slice_10um
	get_cell_top sky130_ef_io__com_bus_slice_5um
	get_cell_top sky130_ef_io__com_bus_slice_1um
	get_cell_top sky130_ef_io__com_bus_slice_1um
	get_cell_top sky130_ef_io__com_bus_slice_1um
	get_cell_top sky130_ef_io__com_bus_slice_1um
    }
}

# Add spacers between cells on the left.  If "extra"
# is 1, add additional space, and if "extra" is 2, add
# the space needed at the end.

proc place_left_spacers {{extra 0}} {
    if {$extra != 2} {
	get_cell_left sky130_ef_io__com_bus_slice_20um
	get_cell_left sky130_ef_io__com_bus_slice_5um
    }
    if {$extra == 1} {
	get_cell_left sky130_ef_io__com_bus_slice_10um
	get_cell_left sky130_ef_io__com_bus_slice_5um
    }
    if {$extra == 2} {
	get_cell_left sky130_ef_io__disconnect_vdda_slice_5um
    }
}

# Determine port use and class based on pin name

proc set_chip_pin_use_class {pin} {
    set ststart [string range $pin 0 1]
    if {$ststart == {vd}} {
	port class inout
	port use power
    } elseif {$ststart == {vc}} {
	port class inout
	port use power
    } elseif {$ststart == {vs}} {
	port class inout
	port use ground
    } elseif {$ststart == {re}} {
	port class input
	port use signal
    } else {
	port class inout
	port use signal
    }
}

# Add a core-side analog pin on the bottom row.  All analog pins are
# on metal3 and need to be switched down to metal2.

proc add_bottom_analog_pin {padname} {
    set instname ${padname}_pad
    select cell $instname
    move_abutment_north
    box height 4um
    fill n m3
    select area m3
    box values {*}[select bbox]
    box grow s -2um
    pushbox
    box grow c -0.06um
    paint via2
    popbox
    box grow n 3um
    paint m2
    box grow s -3um
    label ${padname}_core FreeSans 0.2um 0 0 0 c m2
    port make
    port use analog
    port class inout
}

proc add_top_analog_pin {padname} {
    set instname ${padname}_pad
    select cell $instname
    box values {*}[instance list abutment]
    box move s 4um
    box height 4um
    fill s m3
    select area m3
    box values {*}[select bbox]
    box grow n -2um
    pushbox
    box grow c -0.06um
    paint via2
    popbox
    box grow s 3um
    paint m2
    box grow n -3um
    label ${padname}_core FreeSans 0.2um 0 0 0 c m2
    port make
    port use analog
    port class inout
}

# Add a core-side pin on the bottom row.  All pins on the bottom row are
# on metal2.  "pinname" is the name of the pin in the cell.  Certain
# translations are made for the core pins:  Make the string lowercase,
# and convert angle brackets to square brackets.

proc add_bottom_core_pin {padname pinname {class input}} {
    if {$padname == {sio}} {
        set instname sio_macro_pads
    } elseif {$padname == {pwrdet}} {
        set instname pwrdet_s
    } else {
        set instname ${padname}_pad
    }
    # Translate cell pin name to core pin name
    set corepinname [string map {< \[ > \]} [string tolower $pinname]]
    # Extend pins to 3um north of the cell
    select cell $instname
    move_abutment_north
    box height 3um
    set bbox [box values]
    set pinyl [lindex $bbox 1]
    set pinyh [lindex $bbox 3]
    # "padname" is the pad-facing pin name;  add "_pad" to get the cell name
    goto ${instname}/$pinname    
    select area m2
    set bbox [select bbox]
    set pinbox "[lindex $bbox 0] $pinyl [lindex $bbox 2] $pinyh"
    box values {*}$pinbox
    paint m2
    box grow s -1.5um
    label ${padname}_${corepinname} FreeSans 0.2um 90 0 0 c m2
    port make
    port use signal
    port class $class
}

# Add a core-side pin on the top row.  All pins on the top row are
# on metal2.  "pinname" is the name of the pin in the cell.
# This routine is used only for the two pins on the amuxbus tap cell,
# and the "padname" is the instance name.

proc add_top_core_pin {padname pinname {class inout}} {

    select cell $padname
    box height 3um
    set bbox [box values]
    set pinyl [lindex $bbox 1]
    set pinyh [lindex $bbox 3]
    goto ${padname}/$pinname    
    select area m2
    set bbox [select bbox]
    set pinbox "[lindex $bbox 0] $pinyl [lindex $bbox 2] $pinyh"
    box values {*}$pinbox
    paint m2
    box grow n -1.5um
    label ${pinname} FreeSans 0.2um 90 0 0 c m2
    port make
    port use signal
    port class $class
}

# Same as above, but on the right side (used for OVT pads)

proc add_right_core_pin {padname pinname {class input} {metal m3}} {
    if {[string range $padname 0 3] == {gpio}} {
	set instname ${padname}_pad
    } else {
	set instname ${padname}
    }
    # For muxsplit cells, pin is made to the connects cell, so remove
    # "connects" from the pad name
    set padname [string map {_connects_ _} $padname]

    # Translate cell pin name to core pin name
    set corepinname [string map {< \[ > \]} [string tolower $pinname]]
    # Extend pins to 3um west of the cell
    select cell $instname
    box values {*}[instance list abutment]
    box move w 3um
    box width 3um
    set bbox [box values]
    set pinxl [lindex $bbox 0]
    set pinxh [lindex $bbox 2]
    # "padname" is the pad-facing pin name;  add "_pad" to get the cell name
    goto ${instname}/$pinname    
    select area $metal
    set bbox [select bbox]
    set pinbox "$pinxl [lindex $bbox 1] $pinxh [lindex $bbox 3]"
    box values {*}$pinbox
    paint $metal
    box grow e -1.5um
    label ${padname}_${corepinname} FreeSans 0.2um 0 0 0 c $metal
    port make
    port use signal
    port class $class
}

# Same as above, but on the left side (used for OVT pads)

proc add_left_core_pin {padname pinname {class input} {metal m3}} {
    if {[string range $padname 0 3] == {gpio}} {
	set instname ${padname}_pad
    } else {
	set instname ${padname}
    }
    # For muxsplit cells, pin is made to the connects cell, so remove
    # "connects" from the pad name
    set padname [string map {_connects_ _} $padname]

    # Translate cell pin name to core pin name
    set corepinname [string map {< \[ > \]} [string tolower $pinname]]
    # Extend pins to 3um east of the cell
    select cell $instname
    move_abutment_east
    box width 3um
    set bbox [box values]
    set pinxl [lindex $bbox 0]
    set pinxh [lindex $bbox 2]
    # "padname" is the pad-facing pin name;  add "_pad" to get the cell name
    goto ${instname}/$pinname    
    select area $metal
    set bbox [select bbox]
    set pinbox "$pinxl [lindex $bbox 1] $pinxh [lindex $bbox 3]"
    box values {*}$pinbox
    paint $metal
    box grow w -1.5um
    label ${padname}_${corepinname} FreeSans 0.2um 0 0 0 c $metal
    port make
    port use signal
    port class $class
}

# add_bottom_gpio_pin is like add_bottom_core_pin, but the GPIO cells
# have a "_connect" sell on top, and it is this cell where the pins are
# placed, coincident with the top of the cell and overlapping the pins.
# Pins in the connect cell are already where we want the top level pins,
# so just go to the pin and duplicate it on top.

proc add_vert_gpio_pin {padname pinname {class input}} {
    set instname ${padname}_connects
    goto ${instname}/$pinname    
    paint m2
    label ${padname}_${pinname} FreeSans 0.2um 90 0 0 c m2
    port make
    port use signal
    port class $class
}

proc add_horiz_gpio_pin {padname pinname {class input}} {
    set instname ${padname}_connects
    goto ${instname}/$pinname    
    paint m3
    label ${padname}_${pinname} FreeSans 0.2um 0 0 0 c m3
    port make
    port use signal
    port class $class
}

# Like add_bottom_core_pin but for power pins.  These have two separate
# connections, one on each side of the pad.

proc add_bottom_power_pin {padname} {
    # Extend pins to 3um north of the cell
    select cell ${padname}_pad
    move_abutment_north
    box height 6um
    pushbox
    box grow e -50um
    fill n m3
    select area m3
    box values {*}[select bbox]
    box grow s -1um
    set pwrname [string range $padname 0 4]
    label ${pwrname} FreeSans 5um 0 0 0 c m3
    port make
    set portnum [port index]
    set_chip_pin_use_class $pwrname

    popbox
    box grow w -50um
    fill n m3
    select area m3
    box values {*}[select bbox]
    box grow s -1um
    label ${pwrname} FreeSans 5um 0 0 0 c m3
    port make
    port index $portnum
    set_chip_pin_use_class $pwrname
}

proc add_right_power_pin {padname {suffix ""}} {
    # Extend pins to 3um west of the cell
    select cell ${padname}_pad
    box values {*}[instance list abutment]
    box move w 6um
    box width 6um
    pushbox
    box grow n -50um
    fill w m3
    select area m3
    box values {*}[select bbox]
    box grow e -1um
    set pwrname [string range $padname 0 4]
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    set portnum [port index]
    set_chip_pin_use_class $pwrname

    popbox
    box grow s -50um
    fill w m3
    select area m3
    box values {*}[select bbox]
    box grow e -1um
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    port index $portnum
    set_chip_pin_use_class $pwrname
}

# Add the center opposite pin on the vccd1 and vccd2
# domain power and ground pins, since these don't
# connect to the pad ring.

proc add_right_center_power_pin {padname suffix} {
    # Extend pins to 3um west of the cell
    select cell ${padname}_pad
    box values {*}[instance list abutment]
    box move w 6um
    box width 6um

    box grow n -50um
    box grow s -50um
    fill w m3
    select area m3
    box values {*}[select bbox]
    box grow e -1um
    set pwrname [string map {cc ss ss cc} [string range $padname 0 4]]
    paint m3
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    set_chip_pin_use_class $pwrname
}


proc add_top_power_pin {padname {suffix ""}} {
    # Extend pins to 3um south of the cell
    select cell ${padname}_pad
    box values {*}[instance list abutment]
    box move s 6um
    box height 6um
    pushbox
    box grow w -50um
    fill s m3
    select area m3
    box values {*}[select bbox]
    box grow n -1um
    set pwrname [string range $padname 0 4]
    label ${pwrname}${suffix} FreeSans 5um 0 0 0 c m3
    port make
    set portnum [port index]
    set_chip_pin_use_class $pwrname

    popbox
    box grow e -50um
    fill s m3
    select area m3
    box values {*}[select bbox]
    box grow n -1um
    label ${pwrname}${suffix} FreeSans 5um 0 0 0 c m3
    port make
    port index $portnum
    set_chip_pin_use_class $pwrname
}

# Add the center opposite pin on the vccd1 and vccd2
# domain power and ground pins, since these don't
# connect to the pad ring.

proc add_top_center_power_pin {padname suffix} {
    # Extend pins to 3um south of the cell
    select cell ${padname}_pad
    box values {*}[instance list abutment]
    box move s 6um
    box height 6um
    box grow w -50um
    box grow e -50um
    fill s m3
    select area m3
    box values {*}[select bbox]
    box grow n -1um
    set pwrname [string map {cc ss ss cc} [string range $padname 0 4]]
    paint m3
    label ${pwrname}${suffix} FreeSans 5um 0 0 0 c m3
    port make
    set_chip_pin_use_class $pwrname
}

proc add_left_power_pin {padname {suffix ""}} {
    # Extend pins to 3um west of the cell
    select cell ${padname}_pad
    move_abutment_east
    box width 6um
    pushbox
    box grow n -50um
    fill e m3
    select area m3
    box values {*}[select bbox]
    box grow w -1um
    set pwrname [string range $padname 0 4]
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    set portnum [port index]
    set_chip_pin_use_class $pwrname

    popbox
    box grow s -50um
    fill e m3
    select area m3
    box values {*}[select bbox]
    box grow w -1um
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    port index $portnum
    set_chip_pin_use_class $pwrname
}

# Add the center opposite pin on the vccd1 and vccd2
# domain power and ground pins, since these don't
# connect to the pad ring.

proc add_left_center_power_pin {padname suffix} {
    # Extend pins to 3um west of the cell
    select cell ${padname}_pad
    move_abutment_east
    box width 6um
    box grow n -50um
    box grow s -50um
    fill e m3
    select area m3
    box values {*}[select bbox]
    box grow w -1um
    set pwrname [string map {cc ss ss cc} [string range $padname 0 4]]
    paint m3
    label ${pwrname}${suffix} FreeSans 5um 90 0 0 c m3
    port make
    set_chip_pin_use_class $pwrname
}

# Add core pins to a GPIO cell.  Each GPIO cell has a related
# connection cell with the pin name + "_connects"
proc add_vert_gpio_pins {pinname} {
   add_vert_gpio_pin ${pinname} tie_lo_esd output
   add_vert_gpio_pin ${pinname} in output
   add_vert_gpio_pin ${pinname} tie_hi_esd output
   add_vert_gpio_pin ${pinname} enable_vddio
   add_vert_gpio_pin ${pinname} slow
   add_vert_gpio_pin ${pinname} pad_a_esd_0_h inout
   add_vert_gpio_pin ${pinname} pad_a_esd_1_h inout
   add_vert_gpio_pin ${pinname} pad_a_noesd_h inout
   add_vert_gpio_pin ${pinname} analog_en
   add_vert_gpio_pin ${pinname} analog_pol
   add_vert_gpio_pin ${pinname} inp_dis
   add_vert_gpio_pin ${pinname} enable_inp_h
   add_vert_gpio_pin ${pinname} enable_h
   add_vert_gpio_pin ${pinname} hld_h_n
   add_vert_gpio_pin ${pinname} analog_sel
   add_vert_gpio_pin ${pinname} dm\[2\]
   add_vert_gpio_pin ${pinname} dm\[1\]
   add_vert_gpio_pin ${pinname} dm\[0\]
   add_vert_gpio_pin ${pinname} hld_ovr
   add_vert_gpio_pin ${pinname} out
   add_vert_gpio_pin ${pinname} enable_vswitch_h
   add_vert_gpio_pin ${pinname} enable_vdda_h
   add_vert_gpio_pin ${pinname} vtrip_sel
   add_vert_gpio_pin ${pinname} ib_mode_sel
   add_vert_gpio_pin ${pinname} oe_n
   add_vert_gpio_pin ${pinname} in_h
   add_vert_gpio_pin ${pinname} zero output
   add_vert_gpio_pin ${pinname} one output
}

proc add_horiz_gpio_pins {pinname} {
   add_horiz_gpio_pin ${pinname} tie_lo_esd output
   add_horiz_gpio_pin ${pinname} in output
   add_horiz_gpio_pin ${pinname} tie_hi_esd output
   add_horiz_gpio_pin ${pinname} enable_vddio
   add_horiz_gpio_pin ${pinname} slow
   add_horiz_gpio_pin ${pinname} pad_a_esd_0_h inout
   add_horiz_gpio_pin ${pinname} pad_a_esd_1_h inout
   add_horiz_gpio_pin ${pinname} pad_a_noesd_h inout
   add_horiz_gpio_pin ${pinname} analog_en
   add_horiz_gpio_pin ${pinname} analog_pol
   add_horiz_gpio_pin ${pinname} inp_dis
   add_horiz_gpio_pin ${pinname} enable_inp_h
   add_horiz_gpio_pin ${pinname} enable_h
   add_horiz_gpio_pin ${pinname} hld_h_n
   add_horiz_gpio_pin ${pinname} analog_sel
   add_horiz_gpio_pin ${pinname} dm\[2\]
   add_horiz_gpio_pin ${pinname} dm\[1\]
   add_horiz_gpio_pin ${pinname} dm\[0\]
   add_horiz_gpio_pin ${pinname} hld_ovr
   add_horiz_gpio_pin ${pinname} out
   add_horiz_gpio_pin ${pinname} enable_vswitch_h
   add_horiz_gpio_pin ${pinname} enable_vdda_h
   add_horiz_gpio_pin ${pinname} vtrip_sel
   add_horiz_gpio_pin ${pinname} ib_mode_sel
   add_horiz_gpio_pin ${pinname} oe_n
   add_horiz_gpio_pin ${pinname} in_h output
   add_horiz_gpio_pin ${pinname} zero output
   add_horiz_gpio_pin ${pinname} one output
}

proc add_right_ovt_pins {pinname} {
   add_right_core_pin ${pinname} TIE_HI_ESD output
   add_right_core_pin ${pinname} DM\[2\]
   add_right_core_pin ${pinname} DM\[1\]
   add_right_core_pin ${pinname} DM\[0\]
   add_right_core_pin ${pinname} SLOW
   add_right_core_pin ${pinname} OE_N
   add_right_core_pin ${pinname} TIE_LO_ESD output
   add_right_core_pin ${pinname} INP_DIS
   add_right_core_pin ${pinname} ENABLE_VDDIO
   add_right_core_pin ${pinname} VTRIP_SEL
   add_right_core_pin ${pinname} IB_MODE_SEL\[1\]
   add_right_core_pin ${pinname} IB_MODE_SEL\[0\]
   add_right_core_pin ${pinname} OUT
   add_right_core_pin ${pinname} SLEW_CTL\[1\]
   add_right_core_pin ${pinname} SLEW_CTL\[0\]
   add_right_core_pin ${pinname} ANALOG_POL
   add_right_core_pin ${pinname} ANALOG_SEL
   add_right_core_pin ${pinname} HYS_TRIM
   add_right_core_pin ${pinname} VINREF
   add_right_core_pin ${pinname} HLD_OVR
   add_right_core_pin ${pinname} IN_H output
   add_right_core_pin ${pinname} ENABLE_H
   add_right_core_pin ${pinname} IN output
   add_right_core_pin ${pinname} HLD_H_N
   add_right_core_pin ${pinname} ENABLE_VDDA_H
   add_right_core_pin ${pinname} ANALOG_EN
   add_right_core_pin ${pinname} ENABLE_INP_H
   add_right_core_pin ${pinname} ENABLE_VSWITCH_H
   add_right_core_pin ${pinname} PAD_A_NOESD_H inout
   add_right_core_pin ${pinname} PAD_A_ESD_0_H inout
   add_right_core_pin ${pinname} PAD_A_ESD_1_H inout

   add_horiz_gpio_pin ${pinname} zero output
   add_horiz_gpio_pin ${pinname} one output
}

proc add_left_ovt_pins {pinname} {
   add_left_core_pin ${pinname} TIE_HI_ESD output
   add_left_core_pin ${pinname} DM\[2\]
   add_left_core_pin ${pinname} DM\[1\]
   add_left_core_pin ${pinname} DM\[0\]
   add_left_core_pin ${pinname} SLOW
   add_left_core_pin ${pinname} OE_N
   add_left_core_pin ${pinname} TIE_LO_ESD output
   add_left_core_pin ${pinname} INP_DIS
   add_left_core_pin ${pinname} ENABLE_VDDIO
   add_left_core_pin ${pinname} VTRIP_SEL
   add_left_core_pin ${pinname} IB_MODE_SEL\[1\]
   add_left_core_pin ${pinname} IB_MODE_SEL\[0\]
   add_left_core_pin ${pinname} OUT
   add_left_core_pin ${pinname} SLEW_CTL\[1\]
   add_left_core_pin ${pinname} SLEW_CTL\[0\]
   add_left_core_pin ${pinname} ANALOG_POL
   add_left_core_pin ${pinname} ANALOG_SEL
   add_left_core_pin ${pinname} HYS_TRIM
   add_left_core_pin ${pinname} VINREF
   add_left_core_pin ${pinname} HLD_OVR
   add_left_core_pin ${pinname} IN_H output
   add_left_core_pin ${pinname} ENABLE_H
   add_left_core_pin ${pinname} IN output
   add_left_core_pin ${pinname} HLD_H_N
   add_left_core_pin ${pinname} ENABLE_VDDA_H
   add_left_core_pin ${pinname} ANALOG_EN
   add_left_core_pin ${pinname} ENABLE_INP_H
   add_left_core_pin ${pinname} ENABLE_VSWITCH_H
   add_left_core_pin ${pinname} PAD_A_NOESD_H inout
   add_left_core_pin ${pinname} PAD_A_ESD_0_H inout
   add_left_core_pin ${pinname} PAD_A_ESD_1_H inout

   add_horiz_gpio_pin ${pinname} zero output
   add_horiz_gpio_pin ${pinname} one output
}

#-----------------------------------------------------
# Initialization
#-----------------------------------------------------

# Generate box in this edit cell
snap internal
box values 0 0 0 0
suspendall

# Define the names of all of the pad-connected pins around the padframe

# Bottom row pad names, from left to right:
set bottom_row_pins {vccd0_0 select resetb gpio8_0 gpio8_1 gpio8_2 gpio8_3 \
vssio_8 vssd0_0 xi0 xo0 xi1 xo1 vddio_9 vccd0_1 gpio8_4 gpio8_5 gpio8_6 gpio8_7 \
vssio_9 vssa3_0 vdda3_0 vssd0_1 sio0 sio1}

# Right side pad names, from bottom to top:
set right_side_pins {vddio_0 gpio0_0 gpio0_1 gpio0_2 gpio0_3 vssd1_0 vssio_0 \
gpio0_4 gpio0_5 gpio0_6 gpio0_7 vddio_1 vdda1_0 vssa1_0 gpio1_0 gpio1_1 gpio1_2 \
gpio1_3 vccd1_0 vssio_1 gpio1_4 gpio1_5 gpio1_6 gpio1_7 vddio_2 vdda1_1 vssa1_1 \
vssd1_1 gpio2_0 gpio2_1 gpio2_2 gpio2_3 vssio_2 gpio2_4 gpio2_5 gpio2_6 gpio2_7 \
vccd1_1 vddio_3}

# Left side pad names, from bottom to top:
set left_side_pins {vddio_8 gpio7_7 gpio7_6 gpio7_5 gpio7_4 vccd2_2 vssio_7 \
gpio7_3 gpio7_2 gpio7_1 gpio7_0 vddio_7 vdda2_1 vssa2_1 gpio6_7 gpio6_6 \
gpio6_5 gpio6_4 vssd2_2 vssio_6 gpio6_3 gpio6_2 gpio6_1 gpio6_0 vddio_6 \
vdda2_0 vssa2_0 vccd2_1 gpio5_7 gpio5_6 gpio5_5 gpio5_4 vssio_5 gpio5_3 \
gpio5_2 gpio5_1 gpio5_0 vssd2_1 vddio_5}

# Top row pad names, from left to right:
set top_row_pins {vccd2_0 gpio4_7 gpio4_6 gpio4_5 gpio4_4 vssio_4 vssd2_0 \
gpio4_3 gpio4_2 gpio4_1 gpio4_0 vssa0_0 analog_1 analog_0 vdda0_0 vddio_4 \
gpio3_7 gpio3_6 gpio3_5 gpio3_4 vccd1_2 vssio_3 gpio3_3 gpio3_2 gpio3_1 \
gpio3_0 vssd1_2}

#-----------------------------------------------------
# Cell placement
#-----------------------------------------------------

# Place the corner cells---These are fixed and positions cannot be changed
box position 0 0
getcell sky130_ef_io__corner_pad 180
identify corner_sw
box position 3384um 0
getcell sky130_ef_io__corner_pad 90
identify corner_se
box position 3388um 4984um
getcell sky130_ef_io__corner_pad
identify corner_ne
box position 0 4988um
getcell sky130_ef_io__corner_pad 270
identify corner_nw

# Bottom row, from left to right
select cell corner_sw
move_abutment_east
place_bottom_spacers
get_cell_bottom sky130_ef_io__vccd_lvc_clamped_pad vccd0_0_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad select_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_xres4v2 resetb_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_0_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_1_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_2_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_3_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__vssio_hvc_clamped_pad vssio_8_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__vssd_lvc_clamped_pad vssd0_0_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_analog_pad xi0_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_analog_pad xo0_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_analog_pad xi1_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_analog_pad xo1_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__vddio_hvc_clamped_pad vddio_9_pad
place_bottom_spacers 1
get_cell_bottom sky130_ef_io__vccd_lvc_clamped_pad vccd0_1_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_4_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_5_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_6_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__gpiov2_pad gpio8_7_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__vssio_hvc_clamped_pad vssio_9_pad
place_bottom_spacers
get_cell_bottom sky130_ef_io__vssa_hvc_clamped_pad vssa3_0_pad
place_bottom_spacers 1
get_cell_bottom sky130_ef_io__vdda_hvc_clamped_pad vdda3_0_pad
place_bottom_spacers 3
get_cell_bottom sky130_ef_io__vssd_lvc_clamped_pad vssd0_1_pad
place_bottom_spacers
get_cell_bottom sky130_fd_io__top_sio_macro sio_macro_pads
place_bottom_spacers 2

# Add power detect cell;  this runs under the bus spacers between
# vssa3 and vdda3
#
# To be done:  Create pwrdet overlay cell to connect power buses
select cell vssa3_0_pad
move_abutment_east
box move w 0.1um
getcell sky130_fd_io__top_pwrdetv2 180
identify pwrdet_s

# Right side, from bottom to top
select cell corner_se
move_abutment_north
get_cell_right sky130_fd_io__top_amuxsplitv2 muxsplit_se
place_right_spacers
get_cell_right sky130_ef_io__vddio_hvc_clamped_pad vddio_0_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_0_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_1_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_2_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_3_pad
place_right_spacers
get_cell_right sky130_ef_io__vssd_lvc_clamped3_pad vssd1_0_pad
place_right_spacers
get_cell_right sky130_ef_io__vssio_hvc_clamped_pad vssio_0_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_4_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_5_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_6_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio0_7_pad
place_right_spacers
get_cell_right sky130_ef_io__vddio_hvc_clamped_pad vddio_1_pad
place_right_spacers
get_cell_right sky130_ef_io__vdda_hvc_clamped_pad vdda1_0_pad
place_right_spacers 1
get_cell_right sky130_ef_io__vssa_hvc_clamped_pad vssa1_0_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_0_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_1_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_2_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_3_pad
place_right_spacers
get_cell_right sky130_ef_io__vccd_lvc_clamped3_pad vccd1_0_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpiovrefv2	vref_e
get_cell_right sky130_fd_io__top_vrefcapv2	vcap_e
# vrefcap cell is not a multiple of 1um.  Fix that here. . .
box move s 0.28um
get_cell_right sky130_ef_io__com_bus_slice_1um
place_right_spacers
get_cell_right sky130_ef_io__vssio_hvc_clamped_pad vssio_1_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_4_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_5_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_6_pad
place_right_spacers
get_cell_right sky130_fd_io__top_gpio_ovtv2 gpio1_7_pad
place_right_spacers
get_cell_right sky130_ef_io__vddio_hvc_clamped_pad vddio_2_pad
place_right_spacers
get_cell_right sky130_ef_io__vdda_hvc_clamped_pad vdda1_1_pad
place_right_spacers 1
get_cell_right sky130_ef_io__vssa_hvc_clamped_pad vssa1_1_pad
place_right_spacers
get_cell_right sky130_ef_io__vssd_lvc_clamped3_pad vssd1_1_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_0_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_1_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_2_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_3_pad
place_right_spacers
get_cell_right sky130_ef_io__vssio_hvc_clamped_pad vssio_2_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_4_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_5_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_6_pad
place_right_spacers
get_cell_right sky130_ef_io__gpiov2_pad gpio2_7_pad
place_right_spacers
get_cell_right sky130_ef_io__vccd_lvc_clamped3_pad vccd1_1_pad
place_right_spacers 1
get_cell_right sky130_ef_io__vddio_hvc_clamped_pad vddio_3_pad
place_right_spacers 2
get_cell_right sky130_fd_io__top_amuxsplitv2 muxsplit_ne

# Top row, starting upper left-hand corner
select cell corner_nw
move_abutment_east
place_top_spacers 2
get_cell_top sky130_ef_io__vccd_lvc_clamped3_pad vccd2_0_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_7_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_6_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_5_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_4_pad
place_top_spacers
get_cell_top sky130_ef_io__vssio_hvc_clamped_pad vssio_4_pad
place_top_spacers
get_cell_top sky130_ef_io__vssd_lvc_clamped3_pad vssd2_0_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_3_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_2_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_1_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio4_0_pad
place_top_spacers
get_cell_top sky130_ef_io__vssa_hvc_clamped_pad vssa0_0_pad
place_top_spacers
get_cell_top sky130_fd_io__top_analog_pad analog_1_pad
place_top_spacers
get_cell_top sky130_fd_io__top_analog_pad analog_0_pad
place_top_spacers
get_cell_top sky130_ef_io__vdda_hvc_clamped_pad vdda0_0_pad
place_top_spacers
get_cell_top sky130_ef_io__vddio_hvc_clamped_pad vddio_4_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_7_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_6_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_5_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_4_pad
place_top_spacers
get_cell_top sky130_ef_io__vccd_lvc_clamped3_pad vccd1_2_pad
place_top_spacers 1
get_cell_top sky130_ef_io__vssio_hvc_clamped_pad vssio_3_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_3_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_2_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_1_pad
place_top_spacers
get_cell_top sky130_ef_io__gpiov2_pad gpio3_0_pad
place_top_spacers
get_cell_top sky130_ef_io__vssd_lvc_clamped3_pad vssd1_2_pad
place_top_spacers 3
 
# Left side, starting lower left-hand corner
select cell corner_sw
move_abutment_north
get_cell_left sky130_fd_io__top_amuxsplitv2 muxsplit_sw
place_left_spacers
get_cell_left sky130_ef_io__vddio_hvc_clamped_pad vddio_8_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_7_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_6_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_5_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_4_pad
place_left_spacers
get_cell_left sky130_ef_io__vccd_lvc_clamped3_pad vccd2_2_pad
place_left_spacers 1
get_cell_left sky130_ef_io__vssio_hvc_clamped_pad vssio_7_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_3_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_2_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_1_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio7_0_pad
place_left_spacers
get_cell_left sky130_ef_io__vddio_hvc_clamped_pad vddio_7_pad
place_left_spacers
get_cell_left sky130_ef_io__vdda_hvc_clamped_pad vdda2_1_pad
place_left_spacers 1
get_cell_left sky130_ef_io__vssa_hvc_clamped_pad vssa2_1_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_7_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_6_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_5_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_4_pad
place_left_spacers
get_cell_left sky130_ef_io__vssd_lvc_clamped3_pad vssd2_2_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpiovrefv2	vref_w
get_cell_left sky130_fd_io__top_vrefcapv2	vcap_w
# vrefcap cell is not a multiple of 1um.  Fix that here. . .
box move s 0.28um
get_cell_left sky130_ef_io__com_bus_slice_1um
place_left_spacers
get_cell_left sky130_ef_io__vssio_hvc_clamped_pad vssio_6_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_3_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_2_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_1_pad
place_left_spacers
get_cell_left sky130_fd_io__top_gpio_ovtv2 gpio6_0_pad
place_left_spacers
get_cell_left sky130_ef_io__vddio_hvc_clamped_pad vddio_6_pad
place_left_spacers
get_cell_left sky130_ef_io__vdda_hvc_clamped_pad vdda2_0_pad
place_left_spacers 1
get_cell_left sky130_ef_io__vssa_hvc_clamped_pad vssa2_0_pad
place_left_spacers
get_cell_left sky130_ef_io__vccd_lvc_clamped3_pad vccd2_1_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_7_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_6_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_5_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_4_pad
place_left_spacers
get_cell_left sky130_ef_io__vssio_hvc_clamped_pad vssio_5_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_3_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_2_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_1_pad
place_left_spacers
get_cell_left sky130_ef_io__gpiov2_pad gpio5_0_pad
place_left_spacers
get_cell_left sky130_ef_io__vssd_lvc_clamped3_pad vssd2_1_pad
place_left_spacers 1
get_cell_left sky130_ef_io__vddio_hvc_clamped_pad vddio_5_pad
place_left_spacers 2
get_cell_left sky130_fd_io__top_amuxsplitv2 muxsplit_nw

#---------------------------------------------------------
# Add GPIO routing block on each GPIO
#---------------------------------------------------------

set i 0
foreach pin $bottom_row_pins {
    if {[string range $pin 0 3] == {gpio} || $pin == {select}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_north
	getcell chip_io_gpio_connects_vert 90 child lr
	identify ${pin}_connects
    }
    incr i
}

set i 0
foreach pin $right_side_pins {
    if {[string range $pin 0 4] == {gpio0} || [string range $pin 0 4] == {gpio2}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_west
	getcell chip_io_gpio_connects_horiz child lr parent lr
	identify ${pin}_connects
    }
    if {[string range $pin 0 4] == {gpio1}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_west
	getcell chip_io_ovt_connects_horiz child lr parent lr
	identify ${pin}_connects
    }
    incr i
}

set i 0
foreach pin $top_row_pins {
    if {[string range $pin 0 3] == {gpio}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_south
	getcell chip_io_gpio_connects_vert 270 child ur parent ul
	identify ${pin}_connects
    }
    incr i
}

set i 0
foreach pin $left_side_pins {
    if {[string range $pin 0 4] == {gpio5} || [string range $pin 0 4] == {gpio7}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_east
	getcell chip_io_gpio_connects_horiz 180 child ur
	identify ${pin}_connects
    }
    if {[string range $pin 0 4] == {gpio6}} {
	set inst ${pin}_pad
	select cell $inst
	move_abutment_east
	getcell chip_io_ovt_connects_horiz 180 child ur
	identify ${pin}_connects
    }
    incr i
}

# Add amuxsplit routing block to each amuxsplit cell
# to move the pins from metal2 up to metal3 for the
# preferred horizontal direction.

select cell muxsplit_se
box move w 300
getcell muxsplit_connects 180
identify muxsplit_connects_se

select cell muxsplit_ne
box move w 300
getcell muxsplit_connects 180
identify muxsplit_connects_ne

select cell muxsplit_sw
move_abutment_east
getcell muxsplit_connects
identify muxsplit_connects_sw

select cell muxsplit_nw
move_abutment_east
getcell muxsplit_connects
identify muxsplit_connects_nw

# Add vref routing block to each gpiovrefv2 cell
# to move the pins from metal2 up to metal3 for the
# preferred horizontal direction.

select cell vref_e
box move w 300
getcell vref_connects v
identify vref_connects_e

select cell vref_w
move_abutment_east
getcell vref_connects
identify vref_connects_w

# Add amuxbus tap cell

# amuxbus_a and amuxbus_b need taps from the top row
# Put them to the right of analog_0_pad
select cell analog_0_pad
move_abutment_east
box move e 6um
get_cell_top amuxbus_tap n_amuxbus_tap

# Add SIO routing block on the SIO (may not be necessary)

#-------------------------------------------------
# Add logo/copyright stuff
#-------------------------------------------------

box position 58.25um 55.75um
getcell user_id_textblock

box position 3354.7um 32.4um
getcell copyright_block_frigate

box position 21.5um 5039.2um
getcell caravel_logo

box position 109.8um 5086.9um
getcell caravel_motto

box position 3381.4um 5091.7um
getcell open_source

#-----------------------------------------------------
# Add pad-side ports
#-----------------------------------------------------

# Return to origin
box position 0 0

# Label all of the pads.  For each pad, search the pad area for the
# glass cut, compute the glass cut center, and place the label
# centered on that point.

setlabel -default sticky true
select top cell
expand

set i 0
set sioidx1 [expr {[llength $bottom_row_pins] - 2}]
set sioidx2 [expr {[llength $bottom_row_pins] - 1}]

foreach pin $bottom_row_pins {
    if {$i == $sioidx1} {
	select cell sio_macro_pads
	box grow e -200um
	select area glass
	set padbox [select bbox]
	set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
	set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    } elseif {$i == $sioidx2} {
	select cell sio_macro_pads
	box grow w -282um
	select area glass
	set padbox [select bbox]
	set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
	set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    } else {
	select cell ${pin}_pad
	select area glass
	set padbox [select bbox]
	set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
	set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    }
    box size 0 0
    box position $pincx $pincy
    box grow c 20um
    paint m5
    set pinname [lindex $bottom_row_pins $i]
    label $pinname FreeSans 15um 0 0 0 c m5
    port make
    set_chip_pin_use_class $pinname
    incr i
}

set i 0
foreach pin $right_side_pins {
    select cell ${pin}_pad
    select area glass
    set padbox [select bbox]
    set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
    set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    box size 0 0
    box position $pincx $pincy
    box grow c 20um
    paint m5
    set pinname [lindex $right_side_pins $i]
    label $pinname FreeSans 15um 0 0 0 c m5
    port make
    set_chip_pin_use_class $pinname
    incr i
}

set i 0
foreach pin $top_row_pins {
    select cell ${pin}_pad
    select area glass
    set padbox [select bbox]
    set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
    set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    box size 0 0
    box position $pincx $pincy
    box grow c 20um
    paint m5
    set pinname [lindex $top_row_pins $i]
    label $pinname FreeSans 15um 0 0 0 c m5
    port make
    set_chip_pin_use_class $pinname
    incr i
}

set i 0
foreach pin $left_side_pins {
    select cell ${pin}_pad
    select area glass
    set padbox [select bbox]
    set pincx [expr {([lindex $padbox 2] + [lindex $padbox 0]) / 2}]
    set pincy [expr {([lindex $padbox 3] + [lindex $padbox 1]) / 2}]
    box size 0 0
    box position $pincx $pincy
    box grow c 20um
    paint m5
    set pinname [lindex $left_side_pins $i]
    label $pinname FreeSans 15um 0 0 0 c m5
    port make
    set_chip_pin_use_class $pinname
    incr i
}

#-----------------------------------------------------
# Add core-side ports
#-----------------------------------------------------

# Expand all subcells so core pins can be found
select top cell
expand

# Add core-side power pins first.
# To-do:  Ensure that core pins in the same domain have the
# same port number.

add_bottom_power_pin vccd0_0
add_bottom_power_pin vssio_8
add_bottom_power_pin vssd0_0
add_bottom_power_pin vddio_9
add_bottom_power_pin vccd0_1
add_bottom_power_pin vssio_9
add_bottom_power_pin vssa3_0
add_bottom_power_pin vdda3_0
add_bottom_power_pin vssd0_1

add_right_power_pin vddio_0
add_right_power_pin vssd1_0 \[0\]
add_right_center_power_pin vssd1_0 \[0\]
add_right_power_pin vssio_0
add_right_power_pin vddio_1
add_right_power_pin vdda1_0
add_right_power_pin vssa1_0
add_right_power_pin vccd1_0 \[1\]
add_right_center_power_pin vccd1_0 \[1\]
add_right_power_pin vssio_1
add_right_power_pin vddio_2
add_right_power_pin vdda1_1
add_right_power_pin vssa1_1
add_right_power_pin vssd1_1 \[2\]
add_right_center_power_pin vssd1_1 \[2\]
add_right_power_pin vssio_2
add_right_power_pin vccd1_1 \[3\]
add_right_center_power_pin vccd1_1 \[3\]
add_right_power_pin vddio_3

add_top_power_pin vssd1_2 \[4\]
add_top_center_power_pin vssd1_2 \[4\]
add_top_power_pin vssio_3
add_top_power_pin vccd1_2 \[5\]
add_top_center_power_pin vccd1_2 \[5\]
add_top_power_pin vddio_4
add_top_power_pin vdda0_0
add_top_power_pin vssa0_0
add_top_power_pin vssd2_0 \[0\]
add_top_center_power_pin vssd2_0 \[0\]
add_top_power_pin vssio_4
add_top_power_pin vccd2_0 \[1\]
add_top_center_power_pin vccd2_0 \[1\]

add_left_power_pin vddio_5
add_left_power_pin vssd2_1 \[2\]
add_left_center_power_pin vssd2_1 \[2\]
add_left_power_pin vssio_5
add_left_power_pin vccd2_1 \[3\]
add_left_center_power_pin vccd2_1 \[3\]
add_left_power_pin vssa2_0
add_left_power_pin vdda2_0
add_left_power_pin vddio_6
add_left_power_pin vssio_6
add_left_power_pin vssd2_2 \[4\]
add_left_center_power_pin vssd2_2 \[4\]
add_left_power_pin vssa2_1
add_left_power_pin vdda2_1
add_left_power_pin vddio_7
add_left_power_pin vssio_7
add_left_power_pin vccd2_2 \[5\]
add_left_center_power_pin vccd2_2 \[5\]
add_left_power_pin vddio_8

# Add the remainder of the core-side pins, with port numbers
# generated counterclockwise starting at the lower left.

add_vert_gpio_pins select

# XRES pad resetb
add_bottom_core_pin resetb TIE_WEAK_HI_H output
add_bottom_core_pin resetb DISABLE_PULLUP_H
add_bottom_core_pin resetb TIE_HI_ESD output
add_bottom_core_pin resetb XRES_H_N output
add_bottom_core_pin resetb TIE_LO_ESD output

# INP_SEL_H is on metal1 and needs special handling
goto resetb_pad/INP_SEL_H
box height 1um
paint m1
box move n 1um
box height 0.23um
box grow c 0.02um
box height 1um
sky130::via1_draw
box height 2.35um
paint m2
box grow s -1um
label resetb_inp_sel_h FreeSans 0.2um 90 0 0 c m2
port make
port use signal
port class input

add_bottom_core_pin resetb EN_VDDIO_SIG_H
add_bottom_core_pin resetb FILT_IN_H
add_bottom_core_pin resetb PAD_A_ESD_H output
add_bottom_core_pin resetb PULLUP_H
add_bottom_core_pin resetb ENABLE_H
add_bottom_core_pin resetb ENABLE_VDDIO


for {set i 0} {$i < 4} {incr i} {
    add_vert_gpio_pins gpio8_$i
}

# Crystal oscillator pads
add_bottom_analog_pin xi0
add_bottom_analog_pin xo0
add_bottom_analog_pin xi1
add_bottom_analog_pin xo1

for {set i 4} {$i < 8} {incr i} {
    add_vert_gpio_pins gpio8_$i
}

# pwrdet cell
add_bottom_core_pin pwrdet out2_vddio_hv output
add_bottom_core_pin pwrdet out1_vddd_hv output
add_bottom_core_pin pwrdet in1_vddio_hv
add_bottom_core_pin pwrdet in2_vddd_hv
add_bottom_core_pin pwrdet in1_vddd_hv
add_bottom_core_pin pwrdet out1_vddio_hv output
add_bottom_core_pin pwrdet out2_vddd_hv output
add_bottom_core_pin pwrdet out3_vddd_hv output
add_bottom_core_pin pwrdet vddio_present_vddd_hv output
add_bottom_core_pin pwrdet out3_vddio_hv output
add_bottom_core_pin pwrdet tie_lo_esd output
add_bottom_core_pin pwrdet in3_vddd_hv
add_bottom_core_pin pwrdet vddd_present_vddio_hv output
add_bottom_core_pin pwrdet in2_vddio_hv
add_bottom_core_pin pwrdet in3_vddio_hv
add_bottom_core_pin pwrdet rst_por_hv_n

# SIO macro pad
add_bottom_core_pin sio vinref_dft
add_bottom_core_pin sio voutref_dft
# NOTE:  The enable_h here is a duplicate pin.
add_bottom_core_pin sio vref_sel<1>
add_bottom_core_pin sio vref_sel<0>
add_bottom_core_pin sio enable_vdda_h
add_bottom_core_pin sio dft_refgen
add_bottom_core_pin sio voh_sel<2>
add_bottom_core_pin sio voh_sel<1>
add_bottom_core_pin sio voh_sel<0>

add_top_core_pin n_amuxbus_tap amuxbus_a_n
add_top_core_pin n_amuxbus_tap amuxbus_b_n

# (amuxbus_a and amuxbus_b need special handling or else they are found on m4)
goto sio_voh_sel\[0\]
box move e 0.72um
box grow s 1.5um
box grow e 0.045um
paint m2
box grow s -1.5um
label sio_amuxbus_b FreeSans 0.2um 90 0 0 c m2
port make
port use analog
port class inout
box grow s 1.5um
box move e 0.75um
paint m2
box grow s -1.5um
label sio_amuxbus_a FreeSans 0.2um 90 0 0 c m2
port make
port use analog
port class inout

add_bottom_core_pin sio vreg_en_refgen
add_bottom_core_pin sio ibuf_sel_refgen
add_bottom_core_pin sio vohref
add_bottom_core_pin sio hld_h_n_refgen
add_bottom_core_pin sio vtrip_sel_refgen
add_bottom_core_pin sio pad_a_esd_0_h<1>
add_bottom_core_pin sio pad_a_noesd_h<1>
add_bottom_core_pin sio inp_dis<1>
add_bottom_core_pin sio tie_lo_esd<1> output
add_bottom_core_pin sio out<1>
add_bottom_core_pin sio vtrip_sel<1>
add_bottom_core_pin sio ibuf_sel<1>
add_bottom_core_pin sio hld_h_n<1>
add_bottom_core_pin sio hld_ovr<1>
add_bottom_core_pin sio in<1> output
add_bottom_core_pin sio in_h<1> output
add_bottom_core_pin sio oe_n<1>
add_bottom_core_pin sio slow<1>
add_bottom_core_pin sio vreg_en<1>
add_bottom_core_pin sio enable_h
add_bottom_core_pin sio dm1<2>
add_bottom_core_pin sio dm1<1>
add_bottom_core_pin sio dm1<0>
add_bottom_core_pin sio pad_a_esd_1_h<1> inout
add_bottom_core_pin sio pad_a_esd_1_h<0> inout
add_bottom_core_pin sio dm0<0>
add_bottom_core_pin sio dm0<1>
add_bottom_core_pin sio dm0<2>
add_bottom_core_pin sio vreg_en<0>
add_bottom_core_pin sio slow<0>
add_bottom_core_pin sio oe_n<0>
add_bottom_core_pin sio in_h<0>
add_bottom_core_pin sio in<0>
add_bottom_core_pin sio hld_ovr<0>
add_bottom_core_pin sio hld_h_n<0>
add_bottom_core_pin sio ibuf_sel<0>
add_bottom_core_pin sio vtrip_sel<0>
add_bottom_core_pin sio out<0>
add_bottom_core_pin sio tie_lo_esd<0> output
add_bottom_core_pin sio inp_dis<0>
add_bottom_core_pin sio pad_a_noesd_h<0> inout
add_bottom_core_pin sio pad_a_esd_0_h<0> inout

# Amuxsplit
add_right_core_pin muxsplit_connects_se hld_vdda_h_n input m3
add_right_core_pin muxsplit_connects_se enable_vdda_h input m3
add_right_core_pin muxsplit_connects_se switch_aa_sl input m3
add_right_core_pin muxsplit_connects_se switch_aa_s0 input m3
add_right_core_pin muxsplit_connects_se switch_bb_s0 input m3
add_right_core_pin muxsplit_connects_se switch_bb_sl input m3
add_right_core_pin muxsplit_connects_se switch_bb_sr input m3
add_right_core_pin muxsplit_connects_se switch_aa_sr input m3

# GPIO pads.  NOTE:  There is a separate for-loop for each one so
# that the port numbers are in order

for {set i 0} {$i < 8} {incr i} {
    add_horiz_gpio_pins gpio0_$i
}

for {set i 0} {$i < 4} {incr i} {
    add_right_ovt_pins gpio1_$i
}

# Vrefgen
add_right_core_pin vref_connects_e ref_sel<1> input m3
add_right_core_pin vref_connects_e ref_sel<0> input m3
add_right_core_pin vref_connects_e vinref output m3
add_right_core_pin vref_connects_e ref_sel<2> input m3
add_right_core_pin vref_connects_e enable_h input m3
add_right_core_pin vref_connects_e hld_h_n input m3
add_right_core_pin vref_connects_e vrefgen_en input m3
add_right_core_pin vref_connects_e ref_sel<4> input m3
add_right_core_pin vref_connects_e ref_sel<3> input m3

#Vrefcap
add_right_core_pin vcap_e cpos
# add_right_core_pin vcap_e cneg
# Tie negative side to vssio_q
select cell vcap_e
box grow c -1.43um
set capbox [box values]
box values 3446.23um [lindex $capbox 1] 3450.68um [lindex $capbox 3]
paint m3
box grow c -0.2um
paint via3

for {set i 4} {$i < 8} {incr i} {
    add_right_ovt_pins gpio1_$i
}
for {set i 0} {$i < 8} {incr i} {
    add_horiz_gpio_pins gpio2_$i
}

# Amuxsplit
add_right_core_pin muxsplit_connects_ne hld_vdda_h_n input m3
add_right_core_pin muxsplit_connects_ne enable_vdda_h input m3
add_right_core_pin muxsplit_connects_ne switch_aa_sl input m3
add_right_core_pin muxsplit_connects_ne switch_aa_s0 input m3
add_right_core_pin muxsplit_connects_ne switch_bb_s0 input m3
add_right_core_pin muxsplit_connects_ne switch_bb_sl input m3
add_right_core_pin muxsplit_connects_ne switch_bb_sr input m3
add_right_core_pin muxsplit_connects_ne switch_aa_sr input m3

for {set i 0} {$i < 8} {incr i} {
    add_vert_gpio_pins gpio3_$i
}

# Dedicated analog pins
add_top_analog_pin analog_0
add_top_analog_pin analog_1

for {set i 0} {$i < 8} {incr i} {
    add_vert_gpio_pins gpio4_$i
}

# Amuxsplit
add_left_core_pin muxsplit_connects_nw hld_vdda_h_n input m3
add_left_core_pin muxsplit_connects_nw enable_vdda_h input m3
add_left_core_pin muxsplit_connects_nw switch_aa_sl input m3
add_left_core_pin muxsplit_connects_nw switch_aa_s0 input m3
add_left_core_pin muxsplit_connects_nw switch_bb_s0 input m3
add_left_core_pin muxsplit_connects_nw switch_bb_sl input m3
add_left_core_pin muxsplit_connects_nw switch_bb_sr input m3
add_left_core_pin muxsplit_connects_nw switch_aa_sr input m3

for {set i 0} {$i < 8} {incr i} {
    add_horiz_gpio_pins gpio5_$i
}
for {set i 0} {$i < 4} {incr i} {
    add_left_ovt_pins gpio6_$i
}

#Vrefcap
add_left_core_pin vcap_w cpos inout
# add_left_core_pin vcap_w cneg inout
# Tie negative side to vssio_q
select cell vcap_w
box grow c -1.43um
set capbox [box values]
box values 137.32um [lindex $capbox 1] 141.76um [lindex $capbox 3]
paint m3
box grow c -0.2um
paint via3

#Vrefgen
add_left_core_pin vref_connects_w ref_sel<1> input m3
add_left_core_pin vref_connects_w ref_sel<0> input m3
add_left_core_pin vref_connects_w vinref output m3
add_left_core_pin vref_connects_w ref_sel<2> input m3
add_left_core_pin vref_connects_w enable_h input m3
add_left_core_pin vref_connects_w hld_h_n input m3
add_left_core_pin vref_connects_w vrefgen_en input m3
add_left_core_pin vref_connects_w ref_sel<4> input m3
add_left_core_pin vref_connects_w ref_sel<3> input m3


for {set i 4} {$i < 8} {incr i} {
    add_left_ovt_pins gpio6_$i
}
for {set i 0} {$i < 8} {incr i} {
    add_horiz_gpio_pins gpio7_$i
}

# Amuxsplit
add_left_core_pin muxsplit_connects_sw hld_vdda_h_n input m3
add_left_core_pin muxsplit_connects_sw enable_vdda_h input m3
add_left_core_pin muxsplit_connects_sw switch_aa_sl input m3
add_left_core_pin muxsplit_connects_sw switch_aa_s0 input m3
add_left_core_pin muxsplit_connects_sw switch_bb_s0 input m3
add_left_core_pin muxsplit_connects_sw switch_bb_sl input m3
add_left_core_pin muxsplit_connects_sw switch_bb_sr input m3
add_left_core_pin muxsplit_connects_sw switch_aa_sr input m3

resumeall

#--------------------------------------------------
# Final
#--------------------------------------------------

save panamax

# Generate a verilog module of the padframe
source ../scripts/write_padframe_verilog.tcl


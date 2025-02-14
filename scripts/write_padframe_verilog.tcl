#---------------------------------------------------
# Caravel ML-SoC padframe verilog module
# generation script
#---------------------------------------------------
# Written by Tim Edwards, Efabless
# Jan. 25, 2024 to May 29, 2024
#---------------------------------------------------
# Source this file from magic in the mag/ directory
# while editing the panamax layout.
#---------------------------------------------------
# NOTE: Sept. 11, 2024:  Need to fix vdda domains
# for the amuxsplit cells (hand-edited in the
# verilog).  Requires moving the Y limits that
# determine vddalocal---The amuxsplit cells are
# connected to the top and bottom vdda domains, not
# the left and right.
#---------------------------------------------------

proc write_padframe_verilog {} {
    set modname [cellname list self]
    set ofile [open ../verilog/rtl/${modname}.v w]
    set pinstart [port first]
    set pinend [port last]

    puts $ofile "// Verilog module of padframe $modname generated from layout"
    puts $ofile ""
    puts $ofile "module $modname ("

    set arrdict {}
    
    # Do two passes, one to get the array bounds of any array indexes.
    # Only the maximum index is kept, which assumes all indexes go down
    # to zero.

    for {set i $pinstart} {$i <= $pinend} {incr i} {
	set portname [port $i name]
	set arrbound [string first {[} $portname]
	if {$arrbound > 0} {
	    set arrend [string first {]} $portname]
	    set arrmax [string range $portname $arrbound+1 $arrend-1]
	    set portname [string range $portname 0 $arrbound-1]
	    if {[catch {set arridx [dict get $arrdict $portname]}]} {
		dict set arrdict $portname $arrmax
	    } else {
		if {$arrmax > $arridx} {
		    dict set arrdict $portname $arrmax
		}
	    }
	}
    }

    for {set i $pinstart} {$i <= $pinend} {incr i} {
	set portname [port $i name]
	set portdir [port $i class]
	if {$portdir == "bidirectional"} {set portdir inout}
        # Handle bit arrays.
	set arrbound [string first {[} $portname]
	if {$arrbound > 0} {
	    set portname [string range $portname 0 $arrbound-1]
	    set arrmax [dict get $arrdict $portname]
	    if {$arrmax > 0} {
		puts -nonewline $ofile "\t${portdir}\t\[${arrmax}:0\]\t${portname}"
		dict set arrdict $portname 0
		if {$i < $pinend} {
		    puts $ofile ","
		} else {
		    puts $ofile ""
		}
	    }
	} else {
	    puts -nonewline $ofile "\t${portdir}\t${portname}"
	    if {$i < $pinend} {
		puts $ofile ","
	    } else {
		puts $ofile ""
	    }
	}
    }

    puts $ofile ");"
    puts $ofile ""

    set allinsts [cellname list childinst] 
    set allpads {}
    foreach inst $allinsts {
	if {[string range $inst end-2 end] == "pad"} {
	    lappend allpads $inst
	} elseif {[string range $inst end-3 end] == "pads"} {
	    lappend allpads $inst
	} elseif {[string range $inst 0 3] == "vref"} {
	    if {[string range $inst 4 end-2] != "_connects"} {
		lappend allpads $inst
	    }
	} elseif {[string range $inst 0 3] == "vcap"} {
	    lappend allpads $inst
	} elseif {[string range $inst 0 7] == "muxsplit"} {
	    if {[string range $inst 8 end-3] != "_connects"} {
		lappend allpads $inst
	    }
	} elseif {[string range $inst 0 5] == "pwrdet"} {
	    lappend allpads $inst
	}
    }

    foreach padinst $allpads {
        # Get the bounding box of the instance to determine which power
	# domain and amuxbus domain the cell attaches to.
	select cell $padinst
	set instbox [box values]
	set instllx [magic::i2u [lindex $instbox 0]]
	set instlly [magic::i2u [lindex $instbox 1]]
	set insturx [magic::i2u [lindex $instbox 2]]
	set instury [magic::i2u [lindex $instbox 3]]

	# Check north and south first so that corners are set
	# to the right amuxbus domain.

	if {$instlly < 100} {
	    set amuxbus_a_local amuxbus_a_s
	    set amuxbus_b_local amuxbus_b_s
	    set vccdlocal vccd0
	    set vssdlocal vssd0
	    set vddalocal vdda3
	    set vssalocal vssa3
	} elseif {$instury > 5100} {
	    set amuxbus_a_local amuxbus_a_n
	    set amuxbus_b_local amuxbus_b_n
	    set vddalocal vdda0
	    set vssalocal vssa0
	    if {$instllx < 1600} {
		set vccdlocal vccd2
		set vssdlocal vssd2
	    } else {
		set vccdlocal vccd1
		set vssdlocal vssd1
	    }
	} elseif {$instllx < 100} {
	    set amuxbus_a_local amuxbus_a_w
	    set amuxbus_b_local amuxbus_b_w
	    set vccdlocal vccd2
	    set vssdlocal vssd2
	    set vddalocal vdda2
	    set vssalocal vssa2
	} elseif {$insturx > 3500} {
	    set amuxbus_a_local amuxbus_a_e
	    set amuxbus_b_local amuxbus_b_e
	    set vccdlocal vccd1
	    set vssdlocal vssd1
	    set vddalocal vdda1
	    set vssalocal vssa1
	} else {
	    puts stderr "Invalid pad $padinst"
	}

	# Further subdivide the vccd1/2 and vssd1/2 domains into
	# indexes [0] to [5], as these domains are not in the
	# pad rings and need to be connected together internally.

	if {$padinst == "vssd1_0_pad"} {
	    set vccdlocal vccd1\[0\]
	    set vssdlocal vssd1\[0\]
	} elseif {$padinst == "vccd1_0_pad"} {
	    set vccdlocal vccd1\[1\]
	    set vssdlocal vssd1\[1\]
	} elseif {$padinst == "vssd1_1_pad"} {
	    set vccdlocal vccd1\[2\]
	    set vssdlocal vssd1\[2\]
	} elseif {$padinst == "vccd1_1_pad"} {
	    set vccdlocal vccd1\[3\]
	    set vssdlocal vssd1\[3\]
	} elseif {$padinst == "vssd1_2_pad"} {
	    set vccdlocal vccd1\[4\]
	    set vssdlocal vssd1\[4\]
	} elseif {$padinst == "vccd1_2_pad"} {
	    set vccdlocal vccd1\[5\]
	    set vssdlocal vssd1\[5\]
	} elseif {$padinst == "vssd2_0_pad"} {
	    set vccdlocal vccd2\[0\]
	    set vssdlocal vssd2\[0\]
	} elseif {$padinst == "vccd2_0_pad"} {
	    set vccdlocal vccd2\[1\]
	    set vssdlocal vssd2\[1\]
	} elseif {$padinst == "vssd2_1_pad"} {
	    set vccdlocal vccd2\[2\]
	    set vssdlocal vssd2\[2\]
	} elseif {$padinst == "vccd2_1_pad"} {
	    set vccdlocal vccd2\[3\]
	    set vssdlocal vssd2\[3\]
	} elseif {$padinst == "vssd2_2_pad"} {
	    set vccdlocal vccd2\[4\]
	    set vssdlocal vssd2\[4\]
	} elseif {$padinst == "vccd2_2_pad"} {
	    set vccdlocal vccd2\[5\]
	    set vssdlocal vssd2\[5\]
	}

	# For amuxsplitters, find which bus name is the
	# "left" or the "right" relative to the splitter cell.

	if {$instlly < 2600 && $instllx < 1700} {
	    # sw corner:  l = s, r = w
	    set amuxbus_a_left amuxbus_a_s
	    set amuxbus_b_left amuxbus_b_s
	    set amuxbus_a_right amuxbus_a_w
	    set amuxbus_b_right amuxbus_b_w
	} elseif {$instlly < 2600 && $instllx > 1700} {
	    # se corner:  l = e, r = s
	    set amuxbus_a_left amuxbus_a_e
	    set amuxbus_b_left amuxbus_b_e
	    set amuxbus_a_right amuxbus_a_s
	    set amuxbus_b_right amuxbus_b_s
	} elseif {$instlly > 2600 && $instllx < 1700} {
	    # nw corner:  l = w, r = n
	    set amuxbus_a_left amuxbus_a_w
	    set amuxbus_b_left amuxbus_b_w
	    set amuxbus_a_right amuxbus_a_n
	    set amuxbus_b_right amuxbus_b_n
	} else {
	    # ne corner: l = n, r = e
	    set amuxbus_a_left amuxbus_a_n
	    set amuxbus_b_left amuxbus_b_n
	    set amuxbus_a_right amuxbus_a_e
	    set amuxbus_b_right amuxbus_b_e
	}
        
	set padcell [instance list celldef $padinst]
        if {[string range $padinst end-3 end] == "_pad"} {
	    set pad [string range $padinst 0 end-4]
	} else {
	    set pad $padinst
	}
	puts $ofile "    $padcell $padinst ("
	case $padcell in {
	    sky130_fd_io__top_gpio_ovtv2 {
		puts $ofile "\t.OUT(${pad}_out),"
		puts $ofile "\t.OE_N(${pad}_oe_n),"
		puts $ofile "\t.HLD_H_N(${pad}_hld_h_n),"
		puts $ofile "\t.ENABLE_H(${pad}_enable_h),"
		puts $ofile "\t.ENABLE_INP_H(${pad}_enable_inp_h),"
		puts $ofile "\t.ENABLE_VDDA_H(${pad}_enable_vdda_h),"
		puts $ofile "\t.ENABLE_VDDIO(${pad}_enable_vddio),"
		puts $ofile "\t.ENABLE_VSWITCH_H(${pad}_enable_vswitch_h),"
		puts $ofile "\t.INP_DIS(${pad}_inp_dis),"
		puts $ofile "\t.VTRIP_SEL(${pad}_vtrip_sel),"
		puts $ofile "\t.HYS_TRIM(${pad}_hys_trim),"
		puts $ofile "\t.SLOW(${pad}_slow),"
		puts $ofile "\t.SLEW_CTL(${pad}_slew_ctl),"
		puts $ofile "\t.HLD_OVR(${pad}_hld_ovr),"
		puts $ofile "\t.ANALOG_EN(${pad}_analog_en),"
		puts $ofile "\t.ANALOG_SEL(${pad}_analog_sel),"
		puts $ofile "\t.ANALOG_POL(${pad}_analog_pol),"
		puts $ofile "\t.DM(${pad}_dm),"
		puts $ofile "\t.IB_MODE_SEL(${pad}_ib_mode_sel),"
		puts $ofile "\t.VINREF(${pad}_vinref),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VSWITCH(vddio),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.PAD(${pad}),"
		puts $ofile "\t.PAD_A_NOESD_H(${pad}_pad_a_noesd_h),"
		puts $ofile "\t.PAD_A_ESD_0_H(${pad}_pad_a_esd_0_h),"
		puts $ofile "\t.PAD_A_ESD_1_H(${pad}_pad_a_esd_1_h),"
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.IN(${pad}_in),"
		puts $ofile "\t.IN_H(${pad}_in_h),"
		puts $ofile "\t.TIE_HI_ESD(${pad}_tie_hi_esd),"
		puts $ofile "\t.TIE_LO_ESD(${pad}_tie_lo_esd)"

		# Add constant block
		puts $ofile "    );"
		puts $ofile ""
		puts $ofile "    constant_block ${pad}_const ("
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.one(${pad}_one),"
		puts $ofile "\t.zero(${pad}_zero)"
	    }
	    sky130_fd_io__top_xres4v2 {
		puts $ofile "\t.XRES_H_N(${pad}_xres_h_n),"
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.PAD(${pad}),"
		puts $ofile "\t.DISABLE_PULLUP_H(${pad}_disable_pullup_h),"
		puts $ofile "\t.ENABLE_H(${pad}_enable_h),"
		puts $ofile "\t.EN_VDDIO_SIG_H(${pad}_en_vddio_sig_h),"
		puts $ofile "\t.INP_SEL_H(${pad}_inp_sel_h),"
		puts $ofile "\t.FILT_IN_H(${pad}_filt_in_h),"
		puts $ofile "\t.PULLUP_H(${pad}_pullup_h),"
		puts $ofile "\t.ENABLE_VDDIO(${pad}_enable_vddio),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_fd_io__top_vrefcapv2 {
		puts $ofile "\t.amuxbus_a(${amuxbus_a_local}),"
		puts $ofile "\t.amuxbus_b(${amuxbus_b_local}),"
		# NOTE:  cneg connected to vssio_q bus with a via3
		puts $ofile "\t.cneg(vssio_q),"
		puts $ofile "\t.cpos(${pad}_cpos),"
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vcchib(vccd0),"
		puts $ofile "\t.vdda(${vddalocal}),"
		puts $ofile "\t.vddio(vddio),"
		puts $ofile "\t.vddio_q(vddio_q),"
		puts $ofile "\t.vssa(${vssalocal}),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.vssio(vssio),"
		puts $ofile "\t.vssio_q(vssio_q),"
		puts $ofile "\t.vswitch(vddio)"
	    }
	    sky130_fd_io__top_gpiovrefv2 {
		puts $ofile "\t.amuxbus_a(${amuxbus_a_local}),"
		puts $ofile "\t.amuxbus_b(${amuxbus_b_local}),"
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vcchib(vccd0),"
		puts $ofile "\t.vdda(${vddalocal}),"
		puts $ofile "\t.vddio(vddio),"
		puts $ofile "\t.vddio_q(vddio_q),"
		puts $ofile "\t.vssa(${vssalocal}),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.vssio(vssio),"
		puts $ofile "\t.vssio_q(vssio_q),"
		puts $ofile "\t.vswitch(vddio),"
		puts $ofile "\t.enable_h(${pad}_enable_h),"
		puts $ofile "\t.hld_h_n(${pad}_hld_h_n),"
		puts $ofile "\t.ref_sel(${pad}_ref_sel),"
		puts $ofile "\t.vrefgen_en(${pad}_vrefgen_en),"
		puts $ofile "\t.vinref(${pad}_vinref)"
	    }
	    sky130_fd_io__top_amuxsplitv2 {
		puts $ofile "\t.amuxbus_a_l(${amuxbus_a_left}),"
		puts $ofile "\t.amuxbus_a_r(${amuxbus_a_right}),"
		puts $ofile "\t.amuxbus_b_l(${amuxbus_b_left}),"
		puts $ofile "\t.amuxbus_b_r(${amuxbus_b_right}),"
		puts $ofile "\t.enable_vdda_h(${pad}_enable_vdda_h),"
		puts $ofile "\t.hld_vdda_h_n(${pad}_hld_vdda_h_n),"
		puts $ofile "\t.switch_aa_s0(${pad}_switch_aa_s0),"
		puts $ofile "\t.switch_aa_sl(${pad}_switch_aa_sl),"
		puts $ofile "\t.switch_aa_sr(${pad}_switch_aa_sr),"
		puts $ofile "\t.switch_bb_s0(${pad}_switch_bb_s0),"
		puts $ofile "\t.switch_bb_sl(${pad}_switch_bb_sl),"
		puts $ofile "\t.switch_bb_sr(${pad}_switch_bb_sr),"
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vcchib(vccd0),"
		puts $ofile "\t.vdda(${vddalocal}),"
		puts $ofile "\t.vddio(vddio),"
		puts $ofile "\t.vddio_q(vddio_q),"
		puts $ofile "\t.vssa(${vssalocal}),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.vssio(vssio),"
		puts $ofile "\t.vssio_q(vssio_q),"
		puts $ofile "\t.vswitch(vddio)"
	    }
	    sky130_fd_io__top_pwrdetv2 {
		# There is only one of these and the pin names are prefixed "pwrdet"
		set pad_prefix pwrdet
		puts $ofile "\t.out1_vddd_hv(${pad_prefix}_out1_vddd_hv),"
		puts $ofile "\t.out1_vddio_hv(${pad_prefix}_out1_vddio_hv),"
		puts $ofile "\t.out2_vddd_hv(${pad_prefix}_out2_vddd_hv),"
		puts $ofile "\t.out2_vddio_hv(${pad_prefix}_out2_vddio_hv),"
		puts $ofile "\t.out3_vddd_hv(${pad_prefix}_out3_vddd_hv),"
		puts $ofile "\t.out3_vddio_hv(${pad_prefix}_out3_vddio_hv),"
		puts $ofile "\t.tie_lo_esd(${pad_prefix}_tie_lo_esd),"
		puts $ofile "\t.vddd_present_vddio_hv(${pad_prefix}_vddd_present_vddio_hv),"
		puts $ofile "\t.vddio_present_vddd_hv(${pad_prefix}_vddio_present_vddd_hv),"
		puts $ofile "\t.in1_vddd_hv(${pad_prefix}_in1_vddd_hv),"
		puts $ofile "\t.in1_vddio_hv(${pad_prefix}_in1_vddio_hv),"
		puts $ofile "\t.in2_vddd_hv(${pad_prefix}_in2_vddd_hv),"
		puts $ofile "\t.in2_vddio_hv(${pad_prefix}_in2_vddio_hv),"
		puts $ofile "\t.in3_vddd_hv(${pad_prefix}_in3_vddd_hv),"
		puts $ofile "\t.in3_vddio_hv(${pad_prefix}_in3_vddio_hv),"
		puts $ofile "\t.rst_por_hv_n(${pad_prefix}_rst_por_hv_n),"
		puts $ofile "\t.vccd(vccd0),"
		# What should vddd1 and vddd2 be connected to?
		puts $ofile "\t.vddd1(vccd0),"
		puts $ofile "\t.vddd2(vccd0),"
		puts $ofile "\t.vssa(${vssalocal}),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.vddio_q(vddio_q),"
		puts $ofile "\t.vssio_q(vssio_q)"
	    }
	    sky130_fd_io__top_sio_macro {
		# The name used for signals is "sio", not "sio_macro_pads"
		set sio_pad sio
		puts $ofile "\t.OUT(${sio_pad}_out),"
		puts $ofile "\t.OE_N(${sio_pad}_oe_n),"
		puts $ofile "\t.HLD_H_N(${sio_pad}_hld_h_n),"
		puts $ofile "\t.ENABLE_H(${sio_pad}_enable_h),"
		puts $ofile "\t.ENABLE_VDDA_H(${sio_pad}_enable_vdda_h),"
		puts $ofile "\t.INP_DIS(${sio_pad}_inp_dis),"
		puts $ofile "\t.VTRIP_SEL(${sio_pad}_vtrip_sel),"
		puts $ofile "\t.SLOW(${sio_pad}_slow),"
		puts $ofile "\t.HLD_OVR(${sio_pad}_hld_ovr),"
		puts $ofile "\t.IBUF_SEL(${sio_pad}_ibuf_sel),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VSWITCH(vddio),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSSIO(vssio),"
		# NOTE:  Pad maps to vector {sio1, sio0}.  This is hard-coded
		# here since there is only one SIO macro on the chip.
		puts $ofile "\t.PAD({sio1, sio0}),"
		puts $ofile "\t.PAD_A_NOESD_H(${sio_pad}_pad_a_noesd_h),"
		puts $ofile "\t.PAD_A_ESD_0_H(${sio_pad}_pad_a_esd_0_h),"
		puts $ofile "\t.PAD_A_ESD_1_H(${sio_pad}_pad_a_esd_1_h),"
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.IN(${sio_pad}_in),"
		puts $ofile "\t.IN_H(${sio_pad}_in_h),"
		puts $ofile "\t.TIE_LO_ESD(${sio_pad}_tie_lo_esd),"
		puts $ofile "\t.VINREF_DFT(${sio_pad}_vinref_dft),"
		puts $ofile "\t.VOUTREF_DFT(${sio_pad}_voutref_dft),"
		puts $ofile "\t.DFT_REFGEN(${sio_pad}_dft_refgen),"
		puts $ofile "\t.DM0(${sio_pad}_dm0),"
		puts $ofile "\t.DM1(${sio_pad}_dm1),"
		puts $ofile "\t.HLD_H_N_REFGEN(${sio_pad}_hld_h_n_refgen),"
		puts $ofile "\t.IBUF_SEL_REFGEN(${sio_pad}_ibuf_sel_refgen),"
		puts $ofile "\t.VOHREF(${sio_pad}_vohref),"
		puts $ofile "\t.VOH_SEL(${sio_pad}_voh_sel),"
		puts $ofile "\t.VREF_SEL(${sio_pad}_vref_sel),"
		puts $ofile "\t.VREG_EN(${sio_pad}_vreg_en),"
		puts $ofile "\t.VREG_EN_REFGEN(${sio_pad}_vreg_en_refgen),"
		puts $ofile "\t.VTRIP_SEL_REFGEN(${sio_pad}_vtrip_sel_refgen)"
	    }
	    sky130_ef_io__corner_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__gpiov2_pad {
		puts $ofile "\t.IN_H(${pad}_in_h),"
		puts $ofile "\t.IN(${pad}_in),"
		puts $ofile "\t.OUT(${pad}_out),"
		puts $ofile "\t.OE_N(${pad}_oe_n),"
		puts $ofile "\t.HLD_H_N(${pad}_hld_h_n),"
		puts $ofile "\t.ENABLE_H(${pad}_enable_h),"
		puts $ofile "\t.ENABLE_INP_H(${pad}_enable_inp_h),"
		puts $ofile "\t.ENABLE_VDDA_H(${pad}_enable_vdda_h),"
		puts $ofile "\t.ENABLE_VDDIO(${pad}_enable_vddio),"
		puts $ofile "\t.ENABLE_VSWITCH_H(${pad}_enable_vswitch_h),"
		puts $ofile "\t.INP_DIS(${pad}_inp_dis),"
		puts $ofile "\t.VTRIP_SEL(${pad}_vtrip_sel),"
		puts $ofile "\t.SLOW(${pad}_slow),"
		puts $ofile "\t.HLD_OVR(${pad}_hld_ovr),"
		puts $ofile "\t.ANALOG_EN(${pad}_analog_en),"
		puts $ofile "\t.ANALOG_SEL(${pad}_analog_sel),"
		puts $ofile "\t.ANALOG_POL(${pad}_analog_pol),"
		puts $ofile "\t.DM(${pad}_dm),"
		puts $ofile "\t.IB_MODE_SEL(${pad}_ib_mode_sel),"
		puts $ofile "\t.PAD(${pad}),"
		puts $ofile "\t.PAD_A_NOESD_H(${pad}_pad_a_noesd_h),"
		puts $ofile "\t.PAD_A_ESD_0_H(${pad}_pad_a_esd_0_h),"
		puts $ofile "\t.PAD_A_ESD_1_H(${pad}_pad_a_esd_1_h),"
		puts $ofile "\t.TIE_HI_ESD(${pad}_tie_hi_esd),"
		puts $ofile "\t.TIE_LO_ESD(${pad}_tie_lo_esd),"
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"

		# Add constant block
		puts $ofile "    );"
		puts $ofile ""
		puts $ofile "    constant_block ${pad}_const ("
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.one(${pad}_one),"
		puts $ofile "\t.zero(${pad}_zero)"
	    }
	    sky130_ef_io__vddio_hvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VDDIO_PAD(${pad}),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vssio_hvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VSSIO_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vccd_lvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VCCD_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vssd_lvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VSSD_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vdda_hvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VDDA_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vssa_hvc_clamped_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VSSA_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio)"
	    }
	    sky130_ef_io__vccd_lvc_clamped3_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VCCD_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio),"
		puts $ofile "\t.VCCD1(${vccdlocal}),"
		puts $ofile "\t.VSSD1(${vssdlocal})"
	    }
	    sky130_ef_io__vssd_lvc_clamped3_pad {
		puts $ofile "\t.AMUXBUS_A(${amuxbus_a_local}),"
		puts $ofile "\t.AMUXBUS_B(${amuxbus_b_local}),"
		puts $ofile "\t.VSSD_PAD(${pad}),"
		puts $ofile "\t.VCCD(vccd0),"
		puts $ofile "\t.VCCHIB(vccd0),"
		puts $ofile "\t.VDDA(${vddalocal}),"
		puts $ofile "\t.VDDIO(vddio),"
		puts $ofile "\t.VDDIO_Q(vddio_q),"
		puts $ofile "\t.VSSA(${vssalocal}),"
		puts $ofile "\t.VSSD(vssd0),"
		puts $ofile "\t.VSSIO(vssio),"
		puts $ofile "\t.VSSIO_Q(vssio_q),"
		puts $ofile "\t.VSWITCH(vddio),"
		puts $ofile "\t.VCCD1(${vccdlocal}),"
		puts $ofile "\t.VSSD1(${vssdlocal})"
	    }
	    sky130_fd_io__top_analog_pad {
		puts $ofile "\t.pad_core(${pad}_core),"
		puts $ofile "\t.pad(${pad}),"
		puts $ofile "\t.amuxbus_a(${amuxbus_a_local}),"
		puts $ofile "\t.amuxbus_b(${amuxbus_b_local}),"
		puts $ofile "\t.vccd(vccd0),"
		puts $ofile "\t.vcchib(vccd0),"
		puts $ofile "\t.vdda(${vddalocal}),"
		puts $ofile "\t.vddio(vddio),"
		puts $ofile "\t.vddio_q(vddio_q),"
		puts $ofile "\t.vssa(${vssalocal}),"
		puts $ofile "\t.vssd(vssd0),"
		puts $ofile "\t.vssio(vssio),"
		puts $ofile "\t.vssio_q(vssio_q),"
		puts $ofile "\t.vswitch(vddio)"
	    }
	}
	puts $ofile "    );"
	puts $ofile ""
    }

    puts $ofile "endmodule"
    puts $ofile ""
    close $ofile
}

write_padframe_verilog

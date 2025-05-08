#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2025 Open Circuit Design, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

#----------------------------------------------------------------------
#
# set_product_id.py ---
#
# Manipulate the magic database and verilog source files for the
# product_id_rom_8bit block to set the project ID number.
#
# The product ID number is an 8-bit value that is passed to this routine
# as a 2-digit hex number.  If not given as an option, then the script
# will look for the value of the key "product_id" in the info.yaml file
# in the project top level directory.  If in "-report" mode, it will
# check the RTL top-level verilog to see if set_product_id.py has already
# been applied, and pull the value from there.
#
# product_id_rom_8bit layout map:
# Positions marked (in microns) for value = 0.  For value = 1, move
# the via 0.69um to the left.
#
# Signal          Via position (um)
# name		  X      Y     
#--------------------------------
# product_id[0]    2.870  3.910
# product_id[1]	   4.250  3.910
# product_id[2]	   5.630  3.910
# product_id[3]	   7.010  3.910
# product_id[4]	   8.390  3.910
# product_id[5]	   9.770  3.910
# product_id[6]	  12.070  3.910
# product_id[7]   13.450  3.910
#----------------------------------------------------------------------

import os
import sys
import re
import subprocess

def usage():
    print("Usage:")
    print("set_product_id.py [<product_id_value>] [<path_to_project>]")
    print("")
    print("where:")
    print("    <product_id_value>   is a character string of eight hex digits, and")
    print("    <path_to_project> is the path to the project top level directory.")
    print("")
    print("  If <product_id_value> is not given, then it must exist in the info.yaml file.")
    print("  If <path_to_project> is not given, then it is assumed to be the cwd.")
    return 0

if __name__ == '__main__':

    # Coordinate pairs in microns for the zero position on each bit
    product_id = (
	(2.870, 3.910), (4.250, 3.910), (5.630, 3.910), (7.010, 3.910),
	(8.390, 3.910), (9.770, 3.910), (12.070, 3.910), (13.450, 3.910));

    optionlist = []
    arguments = []

    debugmode = False
    reportmode = False

    for option in sys.argv[1:]:
        if option.find('-', 0) == 0:
            optionlist.append(option)
        else:
            arguments.append(option)

    if len(arguments) > 2:
        print("Wrong number of arguments given to set_product_id.py.")
        usage()
        sys.exit(0)

    if '-debug' in optionlist:
        debugmode = True
    if '-report' in optionlist:
        reportmode = True

    product_id_value = None
    project_path = None

    if len(arguments) > 0:
        product_id_value = arguments[0]

        # Convert to binary
        try:
            product_id_int = int('0x' + product_id_value, 0)
            product_id_bits = '{0:08b}'.format(product_id_int)[::-1]
        except:
            project_path = arguments[0]

    if len(arguments) == 0:
        project_path = os.getcwd()
    elif len(arguments) == 2:
        project_path = arguments[1]
    elif project_path == None:
        project_path = arguments[0]
    else:
        project_path = os.getcwd()

    if not os.path.isdir(project_path):
        print('Error:  Project path "' + project_path + '" does not exist or is not readable.')
        sys.exit(1)

    # Check for valid directories

    if not product_id_value:
        if os.path.isfile(project_path + '/info.yaml'):
            with open(project_path + '/info.yaml', 'r') as ifile:
                infolines = ifile.read().splitlines()
                for line in infolines:
                    kvpair = line.split(':')
                    if len(kvpair) == 2:
                        key = kvpair[0].strip()
                        value = kvpair[1].strip()
                        if key == 'product_id':
                            product_id_value = value.strip('"\'')
                            break

            if not product_id_value:
                print('Error:  No product_id key:value pair found in project info.yaml.')
                sys.exit(1)

            try:
                product_id_int = int('0x' + product_id_value, 0)
                product_id_bits = '{0:08b}'.format(product_id_int)[::-1]
            except:
                print('Error:  Cannot parse product ID "' + product_id_value + '" as a 2-digit hex number.')
                sys.exit(1)

        elif reportmode:
            found = False
            idrex = re.compile("parameter PRODUCT_ID = 8'h([0-9A-F]+);")

            # Check if PRODUCT_ID has a non-zero value in panamax.v
            rtl_top_path = project_path + '/verilog/rtl/panamax.v'
            if os.path.isfile(rtl_top_path):
                with open(rtl_top_path, 'r') as ifile:
                    vlines = ifile.read().splitlines()
                    outlines = []
                    for line in vlines:
                        imatch = idrex.search(line)
                        if imatch:
                            product_id_int = int('0x' + imatch.group(1), 0)
                            found = True
                            break
            else:
                print('Error:  Cannot find top-level RTL ' + rtl_top_path + '.  Is this script being run in the project directory?')
            if not found:
                if reportmode:
                    product_id_int = 0
                else:
                    print('Error:  No PRODUCT_ID found in panamax top level verilog.')
                    sys.exit(1)
        else:
            print('Error:  No info.yaml file and no project ID argument given.')
            sys.exit(1)

    if reportmode:
        print(str(product_id_int))
        sys.exit(0)

    if product_id_int == 0:
        print('Value zero is an invalid product ID.  Exiting.')
        sys.exit(1)

    print('Setting product ID to: ' + product_id_value)

    magpath = project_path + '/mag'
    vpath = project_path + '/verilog'
    errors = 0 

    if not os.path.isdir(vpath):
        print('No directory ' + vpath + ' found (path to verilog).')
        sys.exit(1)

    if not os.path.isdir(magpath):
        print('No directory ' + magpath + ' found (path to magic databases).')
        sys.exit(1)

    print('Step 1:  Modify layout of the product_id_rom_8bit subcell')

    # Read the ID programming layout.  If a backup was made of the
    # zero-value program, then use it.

    magbak = magpath + '/product_id_rom_8bit_zero.mag'
    magfile = magpath + '/product_id_rom_8bit.mag'

    if os.path.isfile(magbak):
        with open(magbak, 'r') as ifile:
            magdata = ifile.read()
    else:
        with open(magfile, 'r') as ifile:
            magdata = ifile.read()

    for i in range(0,8):
        # Ignore any zero bits.
        if product_id_bits[i] == '0':
            continue

        coords = product_id[i]
        xum = coords[0]
        yum = coords[1]

        # Contact is 0.17 x 0.17, so add and subtract 0.085 to get
        # the corner positions.

        xllum = xum - 0.085
        yllum = yum - 0.085
        xurum = xum + 0.085
        yurum = yum + 0.085
 
        # Get the values for the corner coordinates in magic internal units
        xlli = int(round(xllum * 200))
        ylli = int(round(yllum * 200))
        xuri = int(round(xurum * 200))
        yuri = int(round(yurum * 200))

        viaoldposdata = f"rect {xlli} {ylli} {xuri} {yuri}"

        # For "one" bits, the X position is moved 0.69 microns to the left
        newxllum = xllum - 0.69
        newxurum = xurum - 0.69

        # Get the values for the new corner coordinates in magic internal units
        newxlli = int(round(newxllum * 200))
        newxuri = int(round(newxurum * 200))

        vianewposdata = f"rect {newxlli} {ylli} {newxuri} {yuri}"

        # Diagnostic
        if debugmode:
            print('Bit ' + str(i) + ':')
            print('Via position ({0:3.2f}, {1:3.2f}) to ({2:3.2f}, {3:3.2f})'.format(xllum, yllum, xurum, yurum))
            print('Old string = "' + viaoldposdata + '"')
            print('New string = "' + vianewposdata + '"')

        # Replace the old data with the new
        if viaoldposdata not in magdata:
            print('Error: via not found for bit position ' + str(i))
            errors += 1 
        else:
            magdata = magdata.replace(viaoldposdata, vianewposdata)

    if errors == 0:
        # Keep a copy of the original 
        if not os.path.isfile(magbak):
            os.rename(magfile, magbak)

        with open(magfile, 'w') as ofile:
            ofile.write(magdata)

        print('Done!')
            
    else:
        print('There were errors in processing.  No file written.')
        print('Ending process.')
        sys.exit(1)

    print('Step 2:  Add product ID parameter to source verilog.')

    changed = False
    with open(vpath + '/rtl/panamax.v', 'r') as ifile:
        vlines = ifile.read().splitlines()
        outlines = []
        for line in vlines:
            oline = re.sub("parameter PRODUCT_ID = 8'h[0-9A-F]+;",
			"parameter PRODUCT_ID = 8'h" + product_id_value + ";",
			line)
            if oline != line:
                changed = True
            outlines.append(oline)

    if changed:
        with open(vpath + '/rtl/panamax.v', 'w') as ofile:
            for line in outlines:
                print(line, file=ofile)
            print('Done!')
    else:
        print('Error:  No substitutions done on verilog/rtl/panamax.v.')
        print('Ending process.')
        sys.exit(1)

    print('Step 3:  Add product ID parameter to gate-level verilog.')

    changed = False
    with open(vpath + '/gl/product_id_rom_8bit.v', 'r') as ifile:
        vdata = ifile.read()

    for i in range(0,8):
        # Ignore any zero bits.
        if product_id_bits[i] == '0':
            continue

        vdata = vdata.replace('high[' + str(i) + ']', 'XXXX')
        vdata = vdata.replace('low[' + str(i) + ']', 'high[' + str(i) + ']')
        vdata = vdata.replace('XXXX', 'low[' + str(i) + ']')
        vdata = vdata.replace('LO(product_id[' + str(i) + ']',
				  'HI(product_id[' + str(i) + ']')
        vdata = vdata.replace('HI(\\prod_id_low', 'LO(\\prod_id_low')
        changed = True

    if changed:
        with open(vpath + '/gl/product_id_rom_8bit.v', 'w') as ofile:
            ofile.write(vdata)
            print('Done!')
    else:
        print('Error:  No substitutions done on verilog/gl/product_id_rom_8bit.v.')
        print('Ending process.')
        sys.exit(1)

    sys.exit(0)

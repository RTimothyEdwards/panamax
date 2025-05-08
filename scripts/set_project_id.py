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
# set_project_id.py ---
#
# Manipulate the magic database and verilog source files for the
# project_id_rom_32bit block to set the project ID number.
#
# The project ID number is a 32-bit value that is passed to this routine
# as an 8-digit hex number.  If not given as an option, then the script
# will look for the value of the key "project_id" in the info.yaml file
# in the project top level directory.  If in "-report" mode, it will
# check the RTL top-level verilog to see if set_project_id.py has already
# been applied, and pull the value from there.
#
# project_id_rom_32bit layout map:
# Positions marked (in microns) for value = 0.  For value = 1, move
# the via 0.69um to the left.
#
# Signal          Via position (um)
# name		  X      Y     
#--------------------------------
# project_id[0]    2.870  3.910
# project_id[1]	   2.870  9.430
# project_id[2]	   4.250  3.910
# project_id[3]	   4.250  9.430
# project_id[4]	   5.630  3.910
# project_id[5]	   5.630  9.430
# project_id[6]	   7.010  3.910
# project_id[7]    7.010  9.430
# project_id[8]    8.390  3.910
# project_id[9]    8.390  9.430
# project_id[10]   9.770  3.910
# project_id[11]   9.770  9.430
# project_id[12]  12.070  3.910
# project_id[13]  12.070  9.430
# project_id[14]  13.450  3.910
# project_id[15]  13.450  9.430
# project_id[16]  14.830  3.910
# project_id[17]  14.830  9.430
# project_id[18]  16.670  3.910
# project_id[19]  16.670  9.430
# project_id[20]  18.050  3.910
# project_id[21]  18.050  9.430
# project_id[22]  19.430  3.910
# project_id[23]  19.430  9.430
# project_id[24]  20.810  3.910
# project_id[25]  20.810  9.430
# project_id[26]  22.190  3.910
# project_id[27]  22.190  9.430
# project_id[28]  24.030  3.910
# project_id[29]  24.030  9.430
# project_id[30]  25.410  3.910
# project_id[31]  25.410  9.430
#----------------------------------------------------------------------

import os
import sys
import re
import subprocess

def usage():
    print("Usage:")
    print("set_project_id.py [<project_id_value>] [<path_to_project>]")
    print("")
    print("where:")
    print("    <project_id_value>   is a character string of eight hex digits, and")
    print("    <path_to_project> is the path to the project top level directory.")
    print("")
    print("  If <project_id_value> is not given, then it must exist in the info.yaml file.")
    print("  If <path_to_project> is not given, then it is assumed to be the cwd.")
    return 0

if __name__ == '__main__':

    # Coordinate pairs in microns for the zero position on each bit
    project_id = (
	(2.870, 3.910), (2.870, 9.430), (4.250, 3.910), (4.250, 9.430),
	(5.630, 3.910), (5.630, 9.430), (7.010, 3.910), (7.010, 9.430),
	(8.390, 3.910), (8.390, 9.430), (9.770, 3.910), (9.770, 9.430),
	(12.070, 3.910), (12.070, 9.430), (13.450, 3.910), (13.450, 9.430),
	(14.830, 3.910), (14.830, 9.430), (16.670, 3.910), (16.670, 9.430),
	(18.050, 3.910), (18.050, 9.430), (19.430, 3.910), (19.430, 9.430),
	(20.810, 3.910), (20.810, 9.430), (22.190, 3.910), (22.190, 9.430),
	(24.030, 3.910), (24.030, 9.430), (25.410, 3.910), (25.410, 9.430));

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
        print("Wrong number of arguments given to set_project_id.py.")
        usage()
        sys.exit(0)

    if '-debug' in optionlist:
        debugmode = True
    if '-report' in optionlist:
        reportmode = True

    project_id_value = None
    project_path = None

    if len(arguments) > 0:
        project_id_value = arguments[0]

        # Convert to binary
        try:
            project_id_int = int('0x' + project_id_value, 0)
            project_id_bits = '{0:032b}'.format(project_id_int)[::-1]
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

    if not project_id_value:
        if os.path.isfile(project_path + '/info.yaml'):
            with open(project_path + '/info.yaml', 'r') as ifile:
                infolines = ifile.read().splitlines()
                for line in infolines:
                    kvpair = line.split(':')
                    if len(kvpair) == 2:
                        key = kvpair[0].strip()
                        value = kvpair[1].strip()
                        if key == 'project_id':
                            project_id_value = value.strip('"\'')
                            break

            if not project_id_value:
                print('Error:  No project_id key:value pair found in project info.yaml.')
                sys.exit(1)

            try:
                project_id_int = int('0x' + project_id_value, 0)
                project_id_bits = '{0:032b}'.format(project_id_int)[::-1]
            except:
                print('Error:  Cannot parse project ID "' + project_id_value + '" as an 8-digit hex number.')
                sys.exit(1)

        elif reportmode:
            found = False
            idrex = re.compile("parameter PROJECT_ID = 32'h([0-9A-F]+);")

            # Check if PROJECT_ID has a non-zero value in panamax.v
            rtl_top_path = project_path + '/verilog/rtl/panamax.v'
            if os.path.isfile(rtl_top_path):
                with open(rtl_top_path, 'r') as ifile:
                    vlines = ifile.read().splitlines()
                    outlines = []
                    for line in vlines:
                        imatch = idrex.search(line)
                        if imatch:
                            project_id_int = int('0x' + imatch.group(1), 0)
                            found = True
                            break
            else:
                print('Error:  Cannot find top-level RTL ' + rtl_top_path + '.  Is this script being run in the project directory?')
            if not found:
                if reportmode:
                    project_id_int = 0
                else:
                    print('Error:  No PROJECT_ID found in panamax top level verilog.')
                    sys.exit(1)
        else:
            print('Error:  No info.yaml file and no project ID argument given.')
            sys.exit(1)

    if reportmode:
        print(str(project_id_int))
        sys.exit(0)

    if project_id_int == 0:
        print('Value zero is an invalid project ID.  Exiting.')
        sys.exit(1)

    print('Setting project ID to: ' + project_id_value)

    magpath = project_path + '/mag'
    vpath = project_path + '/verilog'
    errors = 0 

    if not os.path.isdir(vpath):
        print('No directory ' + vpath + ' found (path to verilog).')
        sys.exit(1)

    if not os.path.isdir(magpath):
        print('No directory ' + magpath + ' found (path to magic databases).')
        sys.exit(1)

    print('Step 1:  Modify layout of the project_id_rom_32bit subcell')

    # Read the ID programming layout.  If a backup was made of the
    # zero-value program, then use it.

    magbak = magpath + '/project_id_rom_32bit_zero.mag'
    magfile = magpath + '/project_id_rom_32bit.mag'

    if os.path.isfile(magbak):
        with open(magbak, 'r') as ifile:
            magdata = ifile.read()
    else:
        with open(magfile, 'r') as ifile:
            magdata = ifile.read()

    for i in range(0,32):
        # Ignore any zero bits.
        if project_id_bits[i] == '0':
            continue

        coords = project_id[i]
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

    print('Step 2:  Add project ID parameter to source verilog.')

    changed = False
    with open(vpath + '/rtl/panamax.v', 'r') as ifile:
        vlines = ifile.read().splitlines()
        outlines = []
        for line in vlines:
            oline = re.sub("parameter PROJECT_ID = 32'h[0-9A-F]+;",
			"parameter PROJECT_ID = 32'h" + project_id_value + ";",
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

    print('Step 3:  Add project ID parameter to gate-level verilog.')

    changed = False
    with open(vpath + '/gl/project_id_rom_32bit.v', 'r') as ifile:
        vdata = ifile.read()

    for i in range(0,32):
        # Ignore any zero bits.
        if project_id_bits[i] == '0':
            continue

        vdata = vdata.replace('high[' + str(i) + ']', 'XXXX')
        vdata = vdata.replace('low[' + str(i) + ']', 'high[' + str(i) + ']')
        vdata = vdata.replace('XXXX', 'low[' + str(i) + ']')
        vdata = vdata.replace('LO(project_id[' + str(i) + ']',
				  'HI(project_id[' + str(i) + ']')
        vdata = vdata.replace('HI(\\proj_id_low', 'LO(\\proj_id_low')
        changed = True

    if changed:
        with open(vpath + '/gl/project_id_rom_32bit.v', 'w') as ofile:
            ofile.write(vdata)
            print('Done!')
    else:
        print('Error:  No substitutions done on verilog/gl/project_id_rom_32bit.v.')
        print('Ending process.')
        sys.exit(1)

    print('Step 4:  Add project ID text to top level layout.')

    with open(magpath + '/project_id_textblock.mag', 'r') as ifile:
        maglines = ifile.read().splitlines()
        outlines = []
        digit = 0
        wasseen = {}
        for line in maglines:
            if 'alphaX_' in line:
                dchar = project_id_value[7 - digit].upper()
                oline = re.sub('alpha_[0-9A-F]', 'alpha_' + dchar, line)
                # Add path reference if cell was not previously found in the file
                if dchar not in wasseen:
                    if 'hexdigits' not in oline:
                        oline += ' hexdigits'
                outlines.append(oline)
                wasseen[dchar] = True
                digit += 1
            else:
                outlines.append(line)

    if digit == 8:
        with open(magpath + '/project_id_textblock.mag', 'w') as ofile:
            for line in outlines:
                print(line, file=ofile)
        print('Done!')
    elif digit == 0:
        print('Error:  No digits were replaced in the layout.')
    else:
        print('Error:  Only ' + str(digit) + ' digits were replaced in the layout.')

    sys.exit(0)

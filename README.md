# WT280
enable Cura slicing for IdeaWerk RS Pro WT280

I aquired an RS PRO IdeaWerk Pro 3D Printer, RS Stock No.:862-5705

The model is WT280A which appears to be a Weistek 280. It is a capable and solidly built printer with a heated build plate, a modification of the WT150 model for which there seems more information. This comes with its own slicing software Doraware-P. That in turns seems to be a modified version of RepRap. That software is functional, but slow to slice objects and has comparatively few options to control slicing. 

That software outputs .WTK files, which, upon inspection are really S3G/X3G binary files. This repository contains files and instructions to use Cura, the GPX utility and Powershell script to be able to output WTK files without using Doraware-P. THe setup is for Windows, I should have written the PowerShell part in Python to make it cross-platform compatible.

After set up the workflow is to import and slice .STL files in Cura, then export as a .gcode file drag and drop that .gcode onto the PowerShell shorcut and the .WTK file is output.

# Setup
tested with GPX 2.6.8

1. download GPX utility from https://github.com/markwal/GPX/releases/latest

I unzipped the 64bit version and put the folder at C:\Program Files\gpx-2.6.8-win64

2. put the file **wt280.ini** into this folder at C:\Program Files\gpx-2.6.8-win64
3. put the file **WTK-conversion.ps1** into this folder at C:\Program Files\gpx-2.6.8-win64

The .ini file contains some specific parameters for the printer when converting to X3G commands.

tested with Cura 4.8 & 5.2.2

In Cura go to **Help > Show Configuration Folder**, this should open File Explorer at e.g. C:\Users\<username>\AppData\Roaming\cura\5.2

4. copy the file **weistek_wt280.def.json** to the **definitions** folder
5. copy the file **weistek_wt280_extruder_0.def.json** to the **extruders** folder

## Add the Printer
6. in Cura go to **Settings > Printers > Add Printer...**

Add non-networked printer and scroll to the bottom of the list, you should see the manufacturer Weistek and the model WeistekWT280 listed, add that printer
[image]
**Settings > Printers > Manage Printers > WeistekWT280 > Machine Settings**

7. Set the Z height to the maximum measured distance from the nozzle to build plate (use the printers on-board LCD control panel to measure this). 

In my case the measured value was 142.9mm, but to get better bed adhesion I used 143.0mm. Set this value too small and the printer bed will be jamming into the nozzle - top tip if this happens and you pull power then the (relatively heavy) metal bed construction will drop immediately and with a loud bang, 'Warning Hands Pinching' indeed!

[image]

optionally import the custom print profile. I have been using 0.2mm layers and a raft with decent results;

8. in Cura Ctrl+J > Import > and select the file **WT280_standard.curaprofile**

## Prep the PowerShell script
You will need to manually run the PowerShell script, the script will then prompt you to navigate to the .gcode file for conversion. To simplify this I created a shortcut to the PowerShell script and placed the chortcut where I save my 3d models on my computer. In that folder;

9. right click and select New > Shortcut
in that dialogue 

`powershell.exe -noexit -ExecutionPolicy Bypass -File "C:\Program Files\gpx-2.6.8-win64\WTK-conversion.ps1"`

[image]

You could also add this to the Send To context menu by typing shell:sendto in the Explorer address bar then place a copy of the shortcut in that folder

# Convert to WTK
The setup being done your workflow might be open Cura, select the WT280 pritner, slice your .STL file and save as .gcode. Go to that newly created .gcode file and send to WTK conversion

[image]

the output should be a file that is compatible with the WT280 printer.

# Method
There is a Cura plugin for GPX, but I was unable to modify the output to my requirements. If you look in the PowerShell file you will see the options that are used. One crucial option was the `-F` switch. 
> write X3G on-wire framing data to output file

This prefixes each command with 0xD5, follows with another byte that contains the command length and adds a single byte checksum at the end of the command.
GPX inserts some commands that attempt to query the printer, see for example;
https://github.com/makerbot/s3g/blob/master/doc/s3gProtocol.md#10---tool-query-query-a-tool-for-information
When encountering these commands the WT280 simply halts. I guess the printer may be responding to the request, but the SD card isn't going to handle that response. In any case it stops working.

To resolve this, once the X3G is output by GPX the script continues by parsing the X3G file. Specifically looking for any commands that query and expect a response from the printer. Those commands are removed and the final file is saved as a WTK. 

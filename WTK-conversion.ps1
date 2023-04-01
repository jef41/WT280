# get x3g file reference
# 
Function Get-FileName($initialDirectory)
{  
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = “GCode files (*.gcode)| *.gcode”
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}
# have we been passed a file or shoulde we browse for one
if ($args[0]) {
   $fileRef = $args[0]
   } else {
   $fileRef = Get-FileName -initialDirectory “%MyDocuments%..\”
   #Write-Host $fileRef
}
# test for valid file or exit
if ($fileRef) { write-host "got gcode file" } else { exit }

$exe = "C:\Program Files\gpx-2.6.8-win64\gpx.exe"
# cannot pipe binary data
# so get a temporary file to hold the initial X3G file;
$TempX3G = New-TemporaryFile

# initial conversion
write-host "converting to X3G"
&$exe -c wt280.ini -qFpN ht $fileRef $TempX3G


write-host "load file"
#load to a mutable array, using get-content is waaaay slower
[System.Collections.ArrayList]$fileContent =[System.IO.File]::ReadAllBytes($TempX3G)
#[System.Collections.ArrayList]$fileContent = Get-Content $TempX3G -Encoding Byte

# any command < 28 (0x1c) is waiting for a response from the printer
# now get rid of any lines that query the printer for values, these cause a hang;
write-host "parsing for invalid commands"
# look for 0xd5 (213) byte to signify a command
for($i = 0; $i -lt $fileContent.Count; $i++) { 
    if($fileContent[$i] -eq 0xd5) { 
        # found a command, process 1 cmd at a time
        $cmd_len = $fileContent[$i+1]
        #Write-Host "len: $cmd_len"
        $end_pos = [int]$cmd_len + 2 + $i
        $cmd_val = $fileContent[$i+2]
        if ($cmd_val -lt 0x1c) {
            # the command  is 27 or less
            Write-Host "at $i found: $($fileContent[$i..$end_pos])"
            # remove this command
            $fileContent.RemoveRange($i,$cmd_len+3)# = $null
            $i -= 2 # need to (re)search from last find position
        } else {
            # this is not the command we are looking for
            # move on cmd_len bytes
            $i += $cmd_len+2
            #Write-Host "$i no match $cmd_val"
        }
    }
}
# save to same directory as input gcode file;  
$outfileRef = $($(Split-Path -Path $fileRef) + "\" + $((Get-Item $fileRef ).Basename) + ".wtk")
# or save to USB drive;
#$outfileRef = $("g:\3dmodel" + "\" + $((Get-Item $fileRef ).Basename) + ".wtk")

write-host "saving to WTK file $outfileRef"
#echo $outfileRef
Set-Content "$outfileRef" -Value ([byte[]]$fileContent) -Encoding Byte 
# echo $($(Split-Path -Path $fileRef) + $fileRef.BaseName + ".wtk")
Remove-Item $TempX3G
write-host "done"

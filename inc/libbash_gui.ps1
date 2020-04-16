########################################################
#                                                      #
#  libbash.sh GUI for Windows                          #
#  Functions for display GUI tools using PowerShell    #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017-2020 Jean Prunneaux              #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
########################################################

Param(
[String] [Parameter(Mandatory=$true, Position=0)] $Method,
[String[]] [Parameter(ValueFromRemainingArguments)] $MethodParameters = $null
)

Add-Type -AssemblyName System.Windows.Forms

# Choose file
function choosefile($path, $title = "", $save = "", $filters = "") {

    $type = 'OpenFileDialog'
    if ($save -eq 'save') {
        $type = 'SaveFileDialog'
    }

    $filter = ""

    if ($filters -ne "") {
        foreach ($f in $filters.Split(',')) {
            $filter += $f + '|' + $f + '|'
        }
    }

    $filter += "All files (*.*)|*.*"

    $FileBrowser = New-Object System.Windows.Forms.$type -Property @{
        Title = $title
        InitialDirectory = $path
        Filter = $filter
    }

    if ($FileBrowser.ShowDialog() -eq "OK") {
        echo $FileBrowser.filename
    } else {
        exit 1
    }
}

& $Method @MethodParameters

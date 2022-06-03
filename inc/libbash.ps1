##################################################
#                                                #
#  libbash.sh for Windows                        #
#  Functions using PowerShell                    #
#                                                #
#  Sources: https://github.com/pruje/libbash.sh  #
#                                                #
##################################################

Param(
[String] [Parameter(Mandatory=$true, Position=0)] $Method,
[String[]] [Parameter(ValueFromRemainingArguments)] $MethodParameters = $null
)

Add-Type -AssemblyName System.Speech

# Say something
function say($text) {
    (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak($text)
}

& $Method @MethodParameters

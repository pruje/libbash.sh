#
#  libbash.sh GUI for Windows
#  Functions for display GUI tools using PowerShell
#
#  Sources: https://github.com/pruje/libbash.sh
#

Param(
[String] [Parameter(Mandatory=$true, Position=0)] $Method,
[String[]] [Parameter(ValueFromRemainingArguments)] $MethodParameters = $null
)

Add-Type -AssemblyName System.Windows.Forms

# Display desktop notification
function send-notification($message, $title = "") {

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($title)) > $null
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($message)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}


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

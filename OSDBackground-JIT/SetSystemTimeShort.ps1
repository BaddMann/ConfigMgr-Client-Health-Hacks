<#
    Name: SetSystemTimeShort.ps1
    Version: 0.5
    Author: Johan Schrewelius, Onevinn AB
    Modify: Oliver Baddeley
    Date: 2017-11-28
    Command: powershell.exe -executionpolicy bypass -file SetSystemTimeShort.ps1
    Usage: Run as first step in SCCM Task Sequence during Windows PE to sync time with Management Point, rerun after 'Restart Computer' steps.
    Config: $dt_format = "yyyy-MM-dd HH:mm:ss" or "dd.MM.yyyy HH:mm:ss" etc.... Keep seconds resolution for best experience.
#>

$dt_format = "yyyy-MM-dd HH:mm:ss"

Try {
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $lp = $tsenv.Value("_SMSTSLogPath")
    $st = $tsenv.Value("OSDStartTime")
   
    $nt = Get-Date -Format $dt_format

    if(!$st) {
        $tsenv.Value("OSDDateTimeFormat") = "$dt_format"
        $tsenv.Value("OSDStartTime") = "$nt"
        "Set TS Variable OSDStartTime = $nt" | Out-File -FilePath "$lp\SetTimeScript.log" -Append
    }

    "Succesfuly updated System Time to: $nt" | Out-File -FilePath "$lp\SetTimeScript.log" -Append
}
catch {
    "Failed to get and set system time, with Powershell Com Object, error: $($_.Exception.Message)" | Out-File -FilePath "$lp\SetTimeScript.log" -Append
    tsenv2 set "OSDDateTimeFormat=$dt_format"
}

Exit 0

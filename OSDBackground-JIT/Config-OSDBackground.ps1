##### Configures OSDBackground Config XML on the fly in the Task Sequence. 
##### Looks for Group Names within the Task Sequence and Sets them as status messages in OSDbackground.
##### Another Script will evaluate steps each minute while the task sequence is running and sets the correct status message on OSDBackground, will execute outside of TS workflow.

#TaskSequence Variable Grabs
#$OutputVariable = (Shell command) | Out-String
$CurrentAction = ((tsenv2.exe get _SMSTSCurrentActionName).replace('_SMSTSCurrentActionName=', "") | Out-String).trim()
$TaskSquencexml = ((tsenv2.exe get _SMSTSTaskSequence).replace('_SMSTSTaskSequence=', "") | Out-String).trim()
$PCModel = ((tsenv2.exe get Model).replace('Model=', "") | Out-String).trim()


## Testing: $xmlGroups = Select-Xml -XPath "//group[count(ancestor::*)=1][not(@disable)]" -Path 'C:\test.xml' |

## Grab First Groups in the task sequence then parse all thier children groups for status messages.
$xmlGroups = $TaskSquencexml | Select-Xml -XPath "//group[count(ancestor::*)=1][not(@disable)]" |
Select-Object -Expand Node | Select-Object -Property Name, HasChildNodes, group, IsEmpty

# $StatusArray keeps Our future Messages for the OSDBackground, The First message member is the Model Type of the Device
$StatusArray = New-Object System.Collections.ArrayList
$StatusArray.Add( ("$PCModel"| Out-String).trim() ) > $null


### Initial Coding attempt - Streamlined later with function Expand-Group
#$xmlGroups.group
# Foreach ($Group in $xmlGroups.group)
# {
#     if (( -not ($Group.disable)) -And ( -not ($Group.IsEmpty))) {
#         Write-Host $Group.name
#         $StatusArray.Add( ($Group.name | Out-String) ) > $null
#     }
#     Foreach ($SubGroup in $Group.group)
#     {
#         if (( -not ($SubGroup.disable)) -And ( -not ($SubGroup.IsEmpty))) {
#             Write-Host ">" $SubGroup.name.tostring()
#             $StatusArray.Add( ("> " + ($SubGroup.name | Out-String)) ) > $null
#         }
#         Foreach ($SubSubGroup in $SubGroup.group)
#         {
#             if (( -not ($SubSubGroup.disable)) -And ( -not ($SubSubGroup.IsEmpty))) {
#                 Write-Host ">>" $SubSubGroup.name.tostring()
#                 $StatusArray.Add( (">> " + ($SubSubGroup.name | Out-String)) )  > $null
#             }
#             Foreach ($SubSubSubGroup in $SubSubGroup.group)
#             {
#                 if (( -not ($SubSubSubGroup.disable)) -And ( -not ($SubSubSubGroup.IsEmpty))) {
#                     Write-Host ">>> " $SubSubSubGroup.name
#                     $StatusArray.Add( (">>> " + ($SubSubSubGroup.name |Out-String)) ) > $null
#                 }
#             }
#         }
#     }
# }


function Expand-Groups ($Groups, [int]$Level) {
    #Write-Host $Groups $Level
    $pad=" " + ">" * $Level + " "
    If ($Level -eq 0){$pad=""} 
    Foreach ($Group in $Groups)
    {
        if ( ( -not ($Group.disable)) -And ( -not ($Group.IsEmpty))  -And ($Group.name -notlike "Capture*") -And ($Group.name -notlike "Error Catch") ) {
            #Write-Host $Group.name
            $StatusArray.Add( ($pad  + ($Group.name | Out-String).trim()) ) > $null
            Expand-Groups -Groups $Group.group -Level ($Level + 1)
        }
    }
}

Expand-Groups -Groups $xmlGroups -Level 0
$StatusArray.Add( ('End Of Task Sequence'| Out-String).trim() ) > $null
$StatusArray

#Third Party Function to Pretty Print XML
Function Format-XMLIndent
{
    [Cmdletbinding()]
    [Alias("IndentXML")]
    param
    (
        [xml]$Content,
        [int]$Indent
    )

    # String Writer and XML Writer objects to write XML to string
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 

    # Default = None, change Formatting to Indented
    $xmlWriter.Formatting = "indented" 

    # Gets or sets how many IndentChars to write for each level in 
    # the hierarchy when Formatting is set to Formatting.Indented
    $xmlWriter.Indentation = $Indent
    
    $Content.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush();$StringWriter.Flush() 
    $StringWriter.ToString()
}

function Create-ConfigXML ($StatusList) {
    
    # Document creation
    [xml]$xmlDoc = New-Object system.Xml.XmlDocument
    $xmlDoc.LoadXml("<?xml version=`"1.0`" encoding=`"utf-8`"?><configuration></configuration>")

    # Creation of appSettings node
    $xmlElt = $xmlDoc.CreateElement("appSettings")

    for ($i=0; $i -lt $StatusList.count; $i++) {
	    #$StatusList[$i]
        $KeyValue = "StatusMsg" + ($i+1).tostring("00") 
        # Creation of a sub node
        $xmlSubElt = $xmlDoc.CreateElement("add")
        $xmlAtt = $xmlDoc.CreateAttribute("key")
        $xmlAtt.Value = $KeyValue
        $xmlSubElt.Attributes.Append($xmlAtt)  > $null

        $xmlAtt2 = $xmlDoc.CreateAttribute("value")
        $xmlAtt2.Value = $StatusList[$i]
        $xmlSubElt.Attributes.Append($xmlAtt2)  > $null
        $xmlElt.AppendChild($xmlSubElt)  > $null

        # Add the node to the document
        $xmlDoc.LastChild.AppendChild($xmlElt)  > $null
    }
    
    # Load exisitng Config
    $XMLOldConfig = [xml](Get-Content -Path "$PSScriptRoot\OSDBackground.exe.config")
    
    # Copy Exisiting Config, Clean Out Current StatusMsgs
    $XMLCleaned = $XMLOldConfig.SelectNodes( "//add[not(contains(@key,'StatusMsg'))]")

    ForEach ($Node in $XMLCleaned) {
        $aNodeName = $Node.Name
        $aNodeAttrkey = $Node.key
        $aNodeAttrvalue = $Node.value

        $xmlSubElt = $xmlDoc.CreateElement($aNodeName)
        $xmlAtt = $xmlDoc.CreateAttribute("key")
        $xmlAtt.Value = $aNodeAttrkey
        $xmlSubElt.Attributes.Append($xmlAtt)  > $null

        $xmlAtt2 = $xmlDoc.CreateAttribute("value")
        $xmlAtt2.Value = $aNodeAttrvalue
        $xmlSubElt.Attributes.Append($xmlAtt2)  > $null
        $xmlElt.AppendChild($xmlSubElt)  > $null

        # Add the node to the document
        $xmlDoc.LastChild.AppendChild($xmlElt)  > $null
    }

    return $xmlDoc
}

#Create New XML Document Based on Task sequence XMl and Vurrent OSDBackground Config
$XMLNewConfig = Create-ConfigXML -StatusList $StatusArray

#Write Out xml to Config with Pretty Print Formatting
IndentXML -Content $XMLNewConfig.OuterXml -Indent 1 | Out-File -encoding ASCII "$PSScriptRoot/OSDBackground.exe.config"

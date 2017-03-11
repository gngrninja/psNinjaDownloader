﻿<#
.SYNOPSIS   
   This script downloads specific tools and programs from the internet based on scripts located in %scriptDir%\scripts.   
.DESCRIPTION 
   To use this script, execute it with the parameters set for the download you'd like to get. If you do not specify a folder, it will default to %scriptDir%\downloads
   Download scripts are stored in %scriptDir%\scripts
   
   The parameter downloadName must match a script name in the %scriptDir%\scripts folder (omitting .ps1).
   Specify 'all' to execute all the .ps1 files in %scriptDir%\scripts, minus template.ps1

   You can create your own script, just be sure to return the following object from it:

   $downloadInfo = [PSCustomObject]@{

        DownloadName = ''
        Content      = ''
        Success      = $false
        Error        = ''  

    } 

    IMPORTANT: This is the format of the object needed to be returned to the description
    Whichever way you get the information, you need to return an object with the following properties:
    DownloadName (string, file name)
    Content (byte array, file contents)
    Success (boolean)
    Error (string, any error received)   
.PARAMETER downloadName
    Argument: This is the name of the script you'd like to execute (use 'all' to execute all scripts)
    Scripts located in %scriptDir%\scripts       
.PARAMETER outputType
    Argument: This parameter affects the type of text you'd like to display.

    Valid types:
    XML
    CSV
    HTML
    All

    Results exported to %scriptDir%\output
.PARAMETER downloadFolder
    Argument: The path you'd like to download the files to.

    Will use %scriptDir%\output if nothing is specified.
    If the directory does not exist, it will be created.
.NOTES   
    Name: download.ps1
    Author: Mike Roberts aka Ginger Ninja
    DateCreated: 3/10/2017
.EXAMPLE   
    .\download.ps1 -downloadName Chrome -outputType html
    ---------------------------------------------------------------

    1. Script %scriptDir%\scripts\Chrome.ps1 executed
    2. File downloaded to %scriptDir%\downloads
    3. Results exported to %scriptDir%\output as HTML

.EXAMPLE   
    .\download.ps1 -downloadName all -outputType all
    ---------------------------------------------------------------

    1. All scripts in %scriptDir%\scripts executed
    2. Files downloaded to %scriptDir%\downloads
    3. Results exported to %scriptDir%\output as HTML, XML, and CSV
.EXAMPLE   
    .\download.ps1 -downloadName all -outputType all -downloadFolder C:\temp\downloads
    ---------------------------------------------------------------

    1. All scripts in %scriptDir%\scripts executed
    2. Files downloaded to C:\temp\downloads (created if it does not exist)
    3. Results exported to %scriptDir%\output as HTML, XML, and CSV          
.OUTPUTS
    A custom object is output that contains the following:
    ScriptName (string, name of file)
    Success (boolean, true if file was downloaded)
    Error  (string, any errors)
    FileInfo (A custom object itself with file information)
        FileName (string, the file name)
        LocalPath (string, full path of file)                                                                             
        Error (string, any errors)
        VerifiedToExist (boolean, true if file exists)

.LINK  
    http://www.gngrninja.com/script-ninja/2017/3/10/powershell-ninjadownloader-modular-file-download-utility  
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [String]    
    $downloadName,
    [Parameter(Mandatory = $false)]
    [String]
    $downloadFolder,
    [Parameter(Mandatory = $false)]
    [ValidateSet('html','csv','xml','all')]
    [String]
    $outputType
)

#Script setup
#Get the path of the script folder and then set the path to the scripts
$scriptFolder  = Split-Path -Parent $MyInvocation.MyCommand.Path
$pathToScripts = "$scriptFolder\scripts"
$outputDir     = "$scriptFolder\output"

#If $downloadFolder is not specified, attempt to set it to scriptFolder\downloads (and creat if it doesn't exist)
if ([String]::IsNullOrEmpty($downloadFolder)) { #Begin if for downloadFolder not being specified

    if (Test-Path -Path "$scriptFolder\downloads") {

        $downloadFolder = "$scriptFolder\downloads"

        Write-Verbose "No download folder specified, using [$downloadFolder]"

    } else {

        Write-Verbose "Download folder doesn't exist in [$scriptFolder], attempting to create!"

        Try {
        
            New-Item -ItemType Directory -Path "$scriptFolder\downloads" 
            
            $downloadFolder = "$scriptFolder\downloads"

            Write-Verbose "Download folder [$downloadFolder] created!"

        
        }
        Catch {

            $errorMessage = $_.Exception.Message

            Write-Error "Error creating folder [$errorMessage], exiting!"

            Break

        }    

    }
    
} else { #End if/begin else for downloadFolder not being specified

    if (Test-Path -Path $downloadFolder) {

        Write-Verbose "Folder accessible! Using [$downloadFolder]"

    } else {

        Write-Verbose "Download folder doesn't exist [$downloadFolder], attempting to create!"

        Try {
        
            New-Item -ItemType Directory -Path $downloadFolder            

            Write-Verbose "Download folder [$downloadFolder] created!"

        
        }
        Catch {

            $errorMessage = $_.Exception.Message

            Write-Error "Error creating folder [$errorMessage], exiting!"

            Break

        }    

    }

} #End if for downloadFolder

if (!(Test-Path -Path $outputDir)) {

    Write-Verbose "Creating output folder as it does not exist! [$scriptFolder\output]"

    New-Item -ItemType Directory -Path $outputDir

}

#Empty array for our results, later
[System.Collections.ArrayList]$resultsArray = @()

function Invoke-FileWrite { #Begin function Invoke-FileWrite
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $content,
        [Parameter(Mandatory)]
        [String]
        $localFolder,
        [Parameter(Mandatory)]
        [string]
        $fileName
    )

    if (Test-Path $localFolder -ErrorAction SilentlyContinue) {

        $localFullPath = "$localFolder\$fileName"

        [io.file]::WriteAllBytes($localFullPath,$content)

        if (Test-Path $localFullPath -ErrorAction SilentlyContinue) {
        
            $returnObject = [PSCustomObject]@{

                FileName        = $fileName
                LocalPath       = $localFullPath
                Error           = ''
                VerifiedToExist = $true

            }

        } 

        else {

            $returnObject = [PSCustomObject]@{

                FileName        = $fileName
                LocalPath       = $localFullPath
                Error           = ''
                VerifiedToExist = $false

            }

        }

        return $returnObject

    }

    else {        

        $returnObject = [PSCustomObject]@{

                FileName        = $fileName
                LocalPath       = $localFullPath
                Error           = "Invoke-FileWrite -> Folder [$localFolder] inaccessible!" 
                VerifiedToExist = $false

            }        

        return $returnObject

    }    

} #End function Invoke-FileWrite

function Invoke-FileCheck { #Begin function Invoke-FileCheck
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $downloadName
    )

    if ($downloadName -eq 'all') {

        [System.Collections.ArrayList]$scriptInfo = @()

        $scriptList = Get-ChildItem -Path $pathToScripts | Where-Object {$_.Extension -eq '.ps1' -and $_.Name -notmatch '^template'}

        foreach ($script in $scriptList) {

            $scriptObject = $null

            $scriptObject = [PSCustomObject]@{

                ScriptName = $script.Name
                ScriptPath = $script.FullName
                ScriptExists = $true

            }

            $scriptInfo.Add($scriptObject) | Out-Null

        }

    } else {

        $scriptInfo = [PSCustomObject]@{

            ScriptName = "$downloadName.ps1"
            ScriptPath = "$pathToScripts\$downloadName.ps1"
            ScriptExists = $false

        }

        Write-Verbose "Checking for script that matches [$downloadName]!"

        If (Test-Path -Path $scriptInfo.ScriptPath) {

            $scriptInfo.ScriptExists = $true  

        }
    
    }
    
    Return $scriptInfo
} #End function Invoke-FileCheck

function Invoke-CsvFormat { #Begin function Invoke-CsvFormat
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true
        )]        
        [PSCustomObject]
        $formattedResults
    )

    $formattedResults | Export-Csv -Path ("$outputDir\download_results-{0:MMddyy_HHmm}.csv" -f (Get-Date)) -NoTypeInformation -Force
    
} #End function Invoke-CsvFormat

function Invoke-HtmlFormat { #Begin function Invoke-HtmlFormat
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $formattedResults
    )

    $style = @" 
<style>
BODY{background-color:black;}
TABLE{border-width: 3px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{border-width: 2px;padding: 2px;border-style: solid;border-color: black;background-color:gray}
TD{border-width: 2px;padding: 2px;border-style: dotted;border-color: black;background-color:darkgray}
</style>
"@
       
    $formattedResults | ConvertTo-HTML -head $style | Out-File -FilePath ("$outputDir\download_results-{0:MMddyy_HHmm}.html" -f (Get-Date))
    
} #End function Invoke-HtmlFormat

#Script actions, starting with checking the downloadName parameter value
$fileCheck = Invoke-FileCheck -downloadName $downloadName

foreach ($file in $fileCheck) { #Begin file/script foreach loop

    $result = $null

    $result = [PSCustomObject]@{

        ScriptName   = $file.ScriptName
        Success      = $false
        Error        = ''    
        FileInfo     = $null

    }

    if ($file.ScriptExists) { #Begin if for script existance

        try {

            Write-Verbose "Attempting to execute [$($file.ScriptPath)]"

            $getFile = Invoke-Expression -Command "$($file.ScriptPath) -matchText "

        }
        catch {

            $errorMessage = $_.Exception.Message
            $result.Error = $errorMessage

            $resultsArray.Add($result) | Out-Null
            
            Continue

        }

        if ($getFile.Success) { #Begin successful download actions

            $fileWriteResult = Invoke-FileWrite -content $getFile.Content -localFolder $downloadFolder -fileName $getFile.DownloadName

            if ($fileWriteResult.Error) {

                $result.Error    = $fileWriteResult.Error

            }

            $result.FileInfo = $fileWriteResult
            $result.Success  = $fileWriteResult.VerifiedToExist

        } else { #End successful download actions

            $result.Error = "Error getting [$downloadName] -> $($getFile.Error)"

        }

    } else { #Begin if/begin else for script existance

        $result.Error = "Script does not exist for [$downloadName]!"    

    }
    
    Write-Verbose "Adding result for [$($getFile.DownloadName) to results array!]"

    $resultsArray.Add($result) | Out-Null

} #End file/script foreach loop

if ($outputType) { #Begin if for outputType existing
    
    [System.Collections.ArrayList]$formattedObjectArray = @()
    
    foreach ($result in $resultsArray)  {

        Write-Verbose "Working with [$result]"
        
        $formattedObject = $null
        $formattedObject = [PSCustomObject]@{

            ScriptName      = $result.ScriptName
            Success         = $result.Success
            FileName        = $result.FileInfo.FileName
            FilePath        = $result.FileInfo.LocalPath
            Error           = $result.Error
            VerifiedToExist = $result.FileInfo.VerifiedToExist

        }                

        $formattedObjectArray.Add($formattedObject) | Out-Null
        
    }        

} #Enf if for outputType existing

switch ($outputType) { #Begin outputType switch

    'html' {

        Write-Verbose "Formatting HTML..."

        Invoke-HTMLFormat -formattedResults $formattedObjectArray

        Write-Verbose "HTML exported to [$outputDir]"

    }

    'csv' {

        Write-Verbose "Formatting CSV..."

        Invoke-CsvFormat -formattedResults $formattedObjectArray

        Write-Verbose "CSV exported to [$outputDir]"

    }

    'xml' {

        Write-Verbose "Formatting XML..."

        $resultsArray | Export-Clixml  -Path ("$outputDir\download_results-{0:MMddyy_HHmm}.xml" -f (Get-Date))

        Write-Verbose "XML exported to [$outputDir]"

    }

    'all' {

        Write-Verbose "Working on exporting as all formats (XML, CSV, and HTML)..."
        
        Invoke-HTMLFormat -formattedResults $formattedObjectArray
        Invoke-CsvFormat -formattedResults $formattedObjectArray
        $resultsArray | Export-Clixml  -Path ("$outputDir\download_results-{0:MMddyy_HHmm}.xml" -f (Get-Date))

        Write-Verbose "All formats (XML, CSV, and HTML) exported to [$outputDir]"

    }

} #End outputType switch

return $resultsArray
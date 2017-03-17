# psNinjaDownloader
Modular PowerShell File Downloading Utility

See this blog post for details on how to use it!
http://www.gngrninja.com/script-ninja/2017/3/10/powershell-ninjadownloader-modular-file-download-utility

You can also use the following command to get started:
Get-Help .\download.ps1 -Full


#-------------------------- EXAMPLE --------------------------
PS C:\>.\download.ps1 -DownloadName all -OutputType all

1. All scripts in %scriptDir%\scripts executed
2. Files downloaded to %scriptDir%\downloads
3. Results exported to %scriptDir%\output as HTML, XML, and CSV


#-------------------------- EXAMPLE  --------------------------
PS C:\>.\download.ps1 -DownloadName all -OutputType all -DownloadFolder C:\temp\downloads

1. All scripts in %scriptDir%\scripts executed
2. Files downloaded to C:\temp\downloads (created if it does not exist)
3. Results exported to %scriptDir%\output as HTML, XML, and CSV
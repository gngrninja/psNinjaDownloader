function Invoke-IEWait { #Begin function Invoke-IEWait
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipeLine
        )]
        $ieObject
    )

    While ($ieObject.Busy) {

        Start-Sleep -Milliseconds 10

    }

} #End function Invoke-IEWait

function Invoke-IECleanUp { #Begin function Invoke-IECleanUp
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeLine
        )]
        $ieObject        
    )    

    #Wait for logout
    $ieObject | Invoke-IEWait

    #Clean up IE Object
    $ieObject.Quit()

    #Release COM Object
    [void][Runtime.Interopservices.Marshal]::ReleaseComObject($ieObject)

} #End function Invoke-IECleanUp

$downloadInfo = [PSCustomObject]@{

    DownloadName = ''
    Content      = ''
    Success      = $false
    Error        = ''  

} 

Try {

    #Instantiate new IE Object
    $ieObject = New-Object -comobject "InternetExplorer.Application"

    #Navigate to download list where we have to accept
    $ieObject.Navigate("http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html")

    #Important! Wait for page to load
    $ieObject | Invoke-IEWait

    #Click the accept radio button
    ($ieObject.Document.IHTMLDocument3_getElementsByTagName('input')  | Where-Object {$_.Name -eq 'agreementjre-8u121-oth-JPR' -and $_.Status -eq $false}).Click()

    #Wait for page to load
    $ieObject | Invoke-IEWait

    #Get the download URL now that we can see it
    $downloadUrl = $ieObject.Document.links | Where-Object {$_.href -match '^http://download\.oracle\.com.+windows\-x64\.exe$'} | Select-Object -expandProperty Href

    #Get just the file name from the downloadUrl
    $shortFileName = $downloadUrl.Substring($downloadUrl.LastIndexOf('/')+1)
    $downloadInfo.DownloadName = $shortFileName

    #Close and clean up the IE Object, we no longer need it
    $ieObject | Invoke-IECleanUp

    #Create the cookie that says we accepted the agreement
    $cookie        = New-Object System.Net.Cookie 
    $cookie.Name   = "oraclelicense"
    $cookie.Value  = "accept-securebackup-cookie"
    $cookie.Domain = 'oracle.com'

    #Create web session, and add the cookie we created to it
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $session.Cookies.Add($cookie)

    #Use Invoke-WebRequest with the session we created (that has the cookie), and the download URL
    $getFile              = Invoke-WebRequest -Uri $downloadUrl -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer -ErrorAction SilentlyContinue -WebSession $session
    $downloadInfo.Content = $getFile.Content
    $downloadInfo.Success = $true
    
    return $downloadInfo

} 
Catch {
    
    $errorMessage = $_.Exception.Message
    $downloadInfo.Error = $errorMessage
    
    return $downloadInfo

}
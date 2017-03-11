#Script setup
$navUrl = 'https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B96F81EF0-C92E-71F2-6061-14395891B357%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeSetup.exe'

$downloadInfo = [PSCustomObject]@{

    DownloadName = ''
    Content      = ''
    Success      = $false
    Error        = ''  

} 

#Go to first page
Try {

    $downloadRequest = Invoke-WebRequest -Uri $navURL -MaximumRedirection 0 -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -ErrorAction SilentlyContinue

}
Catch {

    $errorMessage = $_.Exception.Message

    $downloadInfo.Error = $errorMessage

    return $downloadInfo

}

#Get file info
$downloadFile = $downloadRequest.Headers.Location

#Parse file name
Switch ($downloadRequest.BaseResponse.ContentType) {

    'application/octet-stream' {

        $downloadInfo.DownloadName = 'Chrome.exe'
        $downloadInfo.Content      = $downloadRequest.Content
        $downloadInfo.Success      = $true

        return $downloadInfo

    }    

    Default {

        $downloadInfo.Error = "Content type [$($downloadRequest.BaseResponse.ContentType)] not handled!"
        
        return $downloadInfo

    }

}
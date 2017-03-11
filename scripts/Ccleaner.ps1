#Script setup
$navUrl = 'http://www.piriform.com/ccleaner/download/portable/downloadfile'

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

    'unknown/unknown' {
        
        $downloadInfo.DownloadName = $downloadRequest.Headers.'content-disposition'.Split('=')[1]
        $downloadInfo.Content      = $downloadRequest.Content
        $downloadInfo.Success      = $true

        return $downloadInfo

    }

    Default {

        $downloadInfo.Error = "Content type [$($downloadRequest.BaseResponse.ContentType)] not handled!"
        
        return $downloadInfo

    }

}
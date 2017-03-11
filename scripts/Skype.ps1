#Script setup
$navUrl = 'https://get.skype.com/go/getskype-full'
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


if ($downloadRequest.Headers.Location -match '.+\.exe') {

    $downloadURL = $downloadRequest.Headers.Location

} else {

    $downloadInfo.Error = "Unable to find exe in header information."

    return $downloadInfo

}    

#Get file info
$downloadFile = $downloadRequest.Headers.Location

#Parse file name
if ($downloadRequest.Headers.Location) {

    $downloadInfo.DownloadName = $downloadFile.SubString($downloadFile.LastIndexOf('/')+1).Replace('%20',' ')

}    

Switch ($downloadRequest.StatusDescription) {

    'Found' {
    
        #Write-Host "Status Description is [Found], downloading from redirect URL [$($downloadRequest.Headers.Location)]."`n
        $downloadRequest = Invoke-WebRequest -Uri $downloadRequest.Headers.Location -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox 

    }

    default {

        $downloadInfo.Error = "Status description [$($downloadRequest.StatusDescription)] not handled!"

        return $downloadInfo

    }

}

Switch ($downloadRequest.BaseResponse.ContentType) {

    'application/x-msdownload' {

        $downloadInfo.Content = $downloadRequest.Content
        $downloadInfo.Success = $true

        return $downloadInfo

    }

    Default {

        $downloadInfo.Error = "Content type [$($downloadRequest.BaseResponse.ContentType)] not handled!"
        
        return $downloadInfo

    }

}
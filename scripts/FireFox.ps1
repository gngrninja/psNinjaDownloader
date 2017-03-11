#Script setup
$navUrl    = 'https://www.mozilla.org/en-US/firefox/all/' 
$matchText = '.+windows.+64.+English.+\(US\)'
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

#Look for urls that match
$downloadURL = $downloadRequest.Links | Where-Object {$_.Title -Match $matchText} | Select-Object -ExpandProperty href

#Go to matching URL, look for download file (keeping redirects at 0)
try {

    $downloadRequest = Invoke-WebRequest -Uri $downloadURL -MaximumRedirection 0 -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -ErrorAction SilentlyContinue

}
catch {
    
    $errorMessage = $_.Exception.Message

    $downloadInfo.Error = $errorMessage

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
                
        $downloadRequest = Invoke-WebRequest -Uri $downloadRequest.Headers.Location -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox 

    }

    default {

        $downloadInfo.Error = "Status description [$($downloadRequest.StatusDescription)] not handled!"
        
        return $downloadInfo

    }

}

#Switch out the proper content type for the file download
Switch ($downloadRequest.BaseResponse.ContentType) {

    'application/x-msdos-program' {
                
        $downloadInfo.Content = $downloadRequest.Content
        $downloadInfo.Success = $true

        return $downloadInfo

    }
   
    Default {

        $downloadInfo.Error = "Content type [$($downloadRequest.BaseResponse.ContentType)] not handled!"
        
        return $downloadInfo

    }

}
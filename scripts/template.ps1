#Template example (works for Firefox, adjust as needed for your download)

#Set this to the URL you'll be navigating to first
$navUrl    = 'https://www.mozilla.org/en-US/firefox/all/' 

#Text to match on, if applicable
$matchText = '.+windows.+64.+English.+\(US\)'

# IMPORTANT: This is the format of the object needed to be returned to the description
# Whichever way you get the information, you need to return an object with the following properties:
# DownloadName (string, file name)
# Content (byte array, file contents)
# Success (boolean)
# Error (string, any error received)
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

#Parse file name, whichever way needed
if ($downloadRequest.Headers.Location) {
            
    $downloadInfo.DownloadName = $downloadFile.SubString($downloadFile.LastIndexOf('/')+1).Replace('%20',' ')

}  

#Switch out the StatusDescription, as applicable
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
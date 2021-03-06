function Invoke-CertificateMintResume {
    <#
    .SYNOPSIS
		Resume the minting process for certificates from online Microsoft CA that required approval

    .DESCRIPTION

    .PARAMETER SVCDir
	
    .PARAMETER CertFile

    .EXAMPLE
        The example below shows the command line use with Parameters.

        Invoke-CertificateMintResume -SVCDir < > -CertFile < >

        PS C:\> Invoke-CertificateMintResume

    .NOTES
        Author: Michael van Blijdesteijn
        Last Edit: 2019-10-24
        Version 1.0 - Invoke-CertificateMintResume
    #>
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)]
		$SVCDir,
		[Parameter(Mandatory=$true)]
		$CertFile
	)

    # initialize objects to use for external processes
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $script:certsWaitingForApproval = $false
    # skip if there's no requestid.txt file
    if (-not(Test-Path "$CertDir\$SVCDir\requestid.txt")) {continue}
    $reqID = Get-Content "$CertDir\$SVCDir\requestid.txt"
    Write-Verbose "Found RequestId: $reqID for $SVCDir"
    # retrieve the signed certificate
    $psi.FileName = "certreq.exe"
    $psi.Arguments = @("-retrieve -f -config `"$IssuingCA`" $reqID `"$CertDir\$SVCDir\$CertFile`"")
    Write-Host "Downloading the signed $SVCDir certificate..." -ForegroundColor Yellow
    [void]$Process.Start()
    $cmdOut = $process.StandardOutput.ReadToEnd()
    if (-not(Test-Path "$CertDir\$SVCDir\$CertFile")) {
        # it's not there, so check if the request is still pending
        if ($cmdOut.Trim() -like "*request is pending*") {
            $script:certsWaitingForApproval = $true
            Write-Host "RequestId: $reqID is pending" -ForegroundColor Yellow
        } else {
			Write-Warning "There was a problem downloading the signed certificate" -foregroundcolor red
			Write-Warning $cmdOut
			continue
        }
    }
    if ($script:certsWaitingForApproval) {
        Write-Host
        Write-Host "One or more certificate requests require manual approval before they can be downloaded." -ForegroundColor Yellow
        Write-Host "Contact your CA administrator to approve the request IDs listed above." -ForegroundColor Yellow
    }
    $script:certsWaitingForApproval = $false
}
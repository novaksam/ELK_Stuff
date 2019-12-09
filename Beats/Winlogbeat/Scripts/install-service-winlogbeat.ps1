param (
	[Parameter(Mandatory = $true)]
	[string]$InstallPath =""
)
# Delete and stop the service if it already exists.
if (Get-Service -Name "winlogbeat" -ErrorAction SilentlyContinue) {
  $WMIservice = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
  $PSService = Get-Service -Name "winlogbeat"
  if (Get-Command -Name 'stop-service' -errorAction SilentlyContinue) {
	Stop-Service -Name "winlogbeat"
  } else {
	$WMIservice.StopService()
  }
  while ($PSService.Status -ne 'Stopped') {
    Start-Sleep -seconds 5
    $PSService.Refresh()
  }
  if (Get-Command -Name 'remove-service' -ErrorAction SilentlyContinue) {
	remove-service -Name "winlogbeat"
  } else {
	$WMIservice.delete()
  }
  $serviceExists = $true
  while ($serviceExists) {
    if (Get-Service -name "winlogbeat" -ErrorAction SilentlyContinue) {
      start-sleep -seconds 5
    } else {
      $serviceExists = $false
    }
  }
}

#$workdir = Split-Path $MyInvocation.MyCommand.Path
$workdir = "$InstallPath"
# Create the new service.
New-Service -name winlogbeat `
  -displayName Winlogbeat `
  -binaryPathName "`"$workdir\winlogbeat.exe`" -c `"C:\ProgramData\winlogbeat\winlogbeat.yml`" -path.home `"$workdir`" -path.data `"C:\ProgramData\winlogbeat`" -path.logs `"C:\ProgramData\winlogbeat\logs`" -E logging.files.redirect_stderr=true"

# Attempt to set the service to delayed start using sc config.
Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start= delayed-auto'
}
Catch { Write-Host -f red "An error occured setting the service to delayed start." }


# Checks the Zonelog API credentials and shows the latest reading for each
# logger in tanks.json. Asks for the credentials each time; nothing is saved.
#
# Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File scripts\test-zonelog.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content (Join-Path $root "tanks.json") -Raw | ConvertFrom-Json

$companyGuid = Read-Host "Company GUID (API Key)"
$clientId = Read-Host "OAuth Client ID"
$secure = Read-Host "OAuth Client Secret" -AsSecureString
$clientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "`nGetting access token..."
try {
  $tok = Invoke-RestMethod -Method Post -Uri "https://zonelogidentity.net/connect/token" -Body @{
    grant_type = "client_credentials"; client_id = $clientId; client_secret = $clientSecret; scope = "AG_DatabaseAPI"
  }
} catch {
  Write-Host "Token request FAILED: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Check the Client ID and Client Secret."
  exit 1
}
Write-Host "Token OK." -ForegroundColor Green
$headers = @{ Authorization = "Bearer $($tok.access_token)" }

$end = (Get-Date).ToUniversalTime()
$start = $end.AddHours(-48)
# Same date format the GitHub updater uses.
$fmt = "yyyy-MM-ddTHH:mm:ss"

foreach ($t in $config.tanks) {
  Write-Host "`n$($t.name) (logger $($t.serial))"
  $qs = "companyGuid=$companyGuid&serial=$($t.serial)&startDate=$($start.ToString($fmt))&endDate=$($end.ToString($fmt))"
  try {
    $rows = @(Invoke-RestMethod -Uri "https://api.zonelog.net/api/waternet/pressure?$qs" -Headers $headers)
  } catch {
    Write-Host "  Request FAILED: $($_.Exception.Message)" -ForegroundColor Red
    continue
  }
  $rows = @($rows | Where-Object { $_.data -ne $null -and "$($_.serial)" -eq "$($t.serial)" })
  if (-not $rows.Count) { Write-Host "  No readings in the last 48 hours." -ForegroundColor Yellow; continue }
  $latest = $rows | Sort-Object { [datetime]$_.readingDateUTC } | Select-Object -Last 1
  Write-Host ("  {0} readings. Latest: {1} {2} (channel {3}, {4}) at {5} UTC" -f `
    $rows.Count, $latest.data, $latest.units, $latest.channelLetter, $latest.channelType, $latest.readingDateUTC) -ForegroundColor Green
  $channels = $rows | Group-Object channelLetter | ForEach-Object { $_.Name }
  if ($channels.Count -gt 1) { Write-Host "  Note: more than one channel returned: $($channels -join ', ')" -ForegroundColor Yellow }
}

$clientSecret = $null
Write-Host "`nDone."

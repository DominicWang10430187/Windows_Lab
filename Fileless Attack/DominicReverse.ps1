param(
  [string]$RemoteHost  = "10.10.36.245",  # 接收端 IP
  [int]   $RemotePort  = 443,            # 接收端 Port
  [string]$SniHost     = "example.com",  # SNI/目標主機名（測試用）
  [int]   $IntervalSec = 5               # 心跳間隔秒數
)

# 建立 TCP 並升級為 TLS（LAB 專用：放寬憑證驗證）
$client    = New-Object System.Net.Sockets.TcpClient
$client.Connect($RemoteHost, $RemotePort)

$netStream = $client.GetStream()
$sslStream = New-Object System.Net.Security.SslStream(
  $netStream, $false, { $true }  # 一律接受憑證（僅限實驗）
)

$sslStream.AuthenticateAsClient(
  $SniHost,
  $null,
  [System.Security.Authentication.SslProtocols]::Tls12,
  $false
)

$writer = New-Object System.IO.StreamWriter($sslStream, [Text.Encoding]::UTF8, 1024, $true)
$writer.AutoFlush = $true

Write-Host ("[*] Connected to {0}:{1} via TLS; sending heartbeats every {2}s." -f $RemoteHost, $RemotePort, $IntervalSec)

try {
  while ($true) {
    $payloadObj = [pscustomobject]@{
      host = $env:COMPUTERNAME
      user = $env:USERNAME
      pid  = $PID
      time = (Get-Date).ToString("s")
      note = "edr-lab-heartbeat"
    }

    $payload = $payloadObj | ConvertTo-Json -Compress
    $writer.WriteLine($payload)
    Start-Sleep -Seconds $IntervalSec
  }
}
finally {
  $writer.Dispose()
  $sslStream.Dispose()
  $netStream.Dispose()
  $client.Close()
}

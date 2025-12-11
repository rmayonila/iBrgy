# PowerShell script to fix deprecated withOpacity calls

$libPath = "c:\Flutter_project\iBrgy\lib"
$dartFiles = Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse

$fixedCount = 0

foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Replace .withOpacity(number) with .withValues(alpha: number)
    $content = $content -replace '\.withOpacity\(([0-9.]+)\)', '.withValues(alpha: $1)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Fixed: $($file.FullName)"
        $fixedCount++
    }
}

Write-Host "`nTotal files fixed: $fixedCount"

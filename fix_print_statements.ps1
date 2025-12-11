# PowerShell script to comment out print statements in Dart files

$files = @(
    "c:\Flutter_project\iBrgy\lib\access_code_page.dart",
    "c:\Flutter_project\iBrgy\lib\admin\account.dart",
    "c:\Flutter_project\iBrgy\lib\audit_log_service.dart",
    "c:\Flutter_project\iBrgy\lib\services\activity_service.dart",
    "c:\Flutter_project\iBrgy\lib\services\notification_service.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw -Encoding UTF8
        
        # Comment out print statements (but not if already commented)
        $content = $content -replace '(\s+)print\(', '$1// print('
        
        Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Fixed print statements in: $file"
    }
}

Write-Host "`nAll print statements have been commented out!"

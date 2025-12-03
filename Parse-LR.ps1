param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateSet("Text", "Csv", "Json")]
    [string]$Format = "Text"
)

$records = @()
$lineNumber = 0

Get-Content -Path $InputPath | ForEach-Object {
    $lineNumber++
    $raw = $_
    $line = $raw.Trim()

    if (-not $line) {
        # blank line
        return
    }

    if ($line -match '^\s*([LlRr])\s*(\d+)\s*$') {
        $letter = $matches[1].ToUpper()
        $num = [int]$matches[2]

        if ($letter -eq 'L') {
            $num = -$num
        }

        $records += [pscustomobject]@{
            Index  = $lineNumber
            Letter = $letter
            Value  = $num
        }
    }
    else {
        Write-Warning "Malformed line $lineNumber: '$raw'"
    }
}

# 🔁 Second loop: same idea as Python version
$position  = 0
$maxRight  = 0
$maxLeft   = 0

foreach ($r in $records) {
    $position += $r.Value
    if ($position -gt $maxRight) { $maxRight = $position }
    if ($position -lt $maxLeft)  { $maxLeft  = $position }
}

Write-Host "Summary from second loop:"
Write-Host "  final_position = $position"
Write-Host "  max_right      = $maxRight"
Write-Host "  max_left       = $maxLeft"

switch ($Format.ToLower()) {
    "text" {
        $lines = $records | ForEach-Object { "$($_.Letter) $($_.Value)" }
        Set-Content -Path $OutputPath -Value $lines
    }
    "csv" {
        $records | Export-Csv -Path $OutputPath -NoTypeInformation
    }
    "json" {
        $records | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath
    }
}

Write-Host "Done. Output saved to:"
Write-Host "  $(Resolve-Path $OutputPath)"

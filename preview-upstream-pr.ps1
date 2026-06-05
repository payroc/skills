#Requires -Version 5.1
<#
.SYNOPSIS
    Generates an HTML preview of what create-pr-to-upstream.ps1 would contribute.

.DESCRIPTION
    Applies the same diff and ignore-filtering logic as create-pr-to-upstream.ps1 but
    produces a self-contained HTML report instead of cloning, pushing, or creating a PR.
    Opens the report in the default browser automatically.

.PARAMETER OutputFile
    Path to write the HTML report. Defaults to upstream-pr-preview.html in the system temp
    directory (overwritten on each run).

.PARAMETER NoBrowser
    Skip opening the report in the browser.

.PARAMETER UpstreamRepo
    The upstream repo in owner/name form. Default: payroc/skills.
#>
[CmdletBinding()]
param(
    [string]$OutputFile   = (Join-Path ([System.IO.Path]::GetTempPath()) "upstream-pr-preview.html"),
    [switch]$NoBrowser,
    [string]$UpstreamRepo = "payroc/skills"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$UpstreamSshUrl = "git@github.com:$UpstreamRepo.git"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Invoke-Git {
    param([string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') exited with code $LASTEXITCODE"
    }
}

function Get-RepoRoot {
    $root = & git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Not inside a git repository." }
    return $root.Trim()
}

function ConvertTo-Regex {
    param([string]$Pattern)
    $escaped = [regex]::Escape($Pattern)
    $escaped = $escaped -replace '\\\*', '.*'
    $escaped = $escaped -replace '\\\?', '.'
    return $escaped
}

# Returns a hashtable {Source, Pattern} for the first ignore rule that matches,
# or $null if no rule matches.
function Find-IgnoreMatch {
    param(
        [string]$RelativePath,
        [array]$PatternSets
    )
    $normalised = $RelativePath -replace '\\', '/'
    $segments   = $normalised -split '/'

    foreach ($set in $PatternSets) {
        foreach ($pattern in $set.Patterns) {
            if ([string]::IsNullOrWhiteSpace($pattern) -or $pattern.StartsWith('#')) { continue }
            $rx = "^$(ConvertTo-Regex $pattern)$"
            if ($normalised -match $rx) { return @{ Source = $set.Source; Pattern = $pattern } }
            foreach ($seg in $segments) {
                if ($seg -match $rx) { return @{ Source = $set.Source; Pattern = $pattern } }
            }
        }
    }
    return $null
}

function ConvertTo-HtmlEncoded {
    param([string]$Text)
    $Text = $Text -replace '&', '&amp;'
    $Text = $Text -replace '<', '&lt;'
    $Text = $Text -replace '>', '&gt;'
    return $Text
}

function Build-DiffHtml {
    param([string]$DiffText)
    if ([string]::IsNullOrWhiteSpace($DiffText)) {
        return '<span class="ctx faded">(file deleted - no diff to show)</span>'
    }
    $lines = $DiffText -split "`n"
    $sb = [System.Text.StringBuilder]::new()
    foreach ($line in $lines) {
        $encoded = ConvertTo-HtmlEncoded $line
        if     ($line -match '^@@')              { [void]$sb.AppendLine("<span class=`"hunk`">$encoded</span>") }
        elseif ($line -match '^\+\+\+|^---')     { [void]$sb.AppendLine("<span class=`"fhdr`">$encoded</span>") }
        elseif ($line -match '^\+')              { [void]$sb.AppendLine("<span class=`"add`">$encoded</span>") }
        elseif ($line -match '^-')               { [void]$sb.AppendLine("<span class=`"del`">$encoded</span>") }
        else                                     { [void]$sb.AppendLine("<span class=`"ctx`">$encoded</span>") }
    }
    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$repoRoot = Get-RepoRoot
Push-Location $repoRoot
try {
    $currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()

    if ($currentBranch -eq "main") {
        Write-Warning "Running from 'main' - the diff against upstream/main will likely be empty."
    }

    $dirty = (& git status --porcelain) -join ''
    if (-not [string]::IsNullOrWhiteSpace($dirty)) {
        Write-Warning "Working tree has uncommitted changes; these would be included if create-pr-to-upstream.ps1 were run now."
    }

    # Ensure upstream remote points at the right URL
    $remotes = & git remote
    if ($remotes -notcontains "upstream") {
        Write-Host "Adding 'upstream' remote: $UpstreamSshUrl"
        Invoke-Git "remote", "add", "upstream", $UpstreamSshUrl
    } else {
        $currentUrl = (& git remote get-url upstream).Trim()
        if ($currentUrl -ne $UpstreamSshUrl) {
            Invoke-Git "remote", "set-url", "upstream", $UpstreamSshUrl
        }
    }

    Write-Host "Fetching upstream..."
    Invoke-Git "fetch", "upstream"

    $diffBase    = "upstream/main"
    $statusLines = & git diff --name-status "${diffBase}..${currentBranch}" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Failed to diff against $diffBase." }
    $statusLines = $statusLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # Load ignore patterns, preserving which file each pattern came from
    $patternSets = @()
    foreach ($ignoreFileName in @("upstream-ignore.txt", "pr-ignore.txt")) {
        $ignoreFile = Join-Path $repoRoot $ignoreFileName
        if (Test-Path $ignoreFile) {
            $filePatterns = [string[]](Get-Content $ignoreFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            $patternSets += ,@{ Source = $ignoreFileName; Patterns = $filePatterns }
        }
    }

    # Partition changed files into included / excluded
    $included = [System.Collections.Generic.List[object]]::new()
    $excluded  = [System.Collections.Generic.List[object]]::new()

    foreach ($line in $statusLines) {
        $parts  = $line -split "`t"
        $status = $parts[0].Substring(0, 1)
        $path   = $parts[-1]   # destination for renames/copies

        $match = Find-IgnoreMatch -RelativePath $path -PatternSets $patternSets
        if ($null -ne $match) {
            $excluded.Add([pscustomobject]@{ Path = $path; Source = $match.Source; Pattern = $match.Pattern })
        } else {
            $included.Add([pscustomobject]@{ Status = $status; Path = $path; Diff = [string]::Empty })
        }
    }

    # Capture per-file unified diffs for included files
    Write-Host "Capturing diffs for $($included.Count) included file(s)..."
    foreach ($entry in $included) {
        if ($entry.Status -ne 'D') {
            $diffLines  = & git diff $diffBase -- $entry.Path 2>&1
            $entry.Diff = ($diffLines -join "`n")
        }
    }

    $addedCount    = @($included | Where-Object { $_.Status -eq 'A' }).Count
    $modifiedCount = @($included | Where-Object { $_.Status -eq 'M' }).Count
    $deletedCount  = @($included | Where-Object { $_.Status -eq 'D' }).Count
    $renamedCount  = @($included | Where-Object { $_.Status -eq 'R' }).Count
    $excludedCount = $excluded.Count
    $totalIncluded = $included.Count

    # -----------------------------------------------------------------------
    # Build included-files section
    # -----------------------------------------------------------------------
    $includedHtml = [System.Text.StringBuilder]::new()
    if ($included.Count -eq 0) {
        [void]$includedHtml.Append('<p class="empty-msg">No files will be included in the upstream PR.</p>')
    } else {
        foreach ($entry in $included) {
            $badgeClass = switch ($entry.Status) {
                'A' { 'badge-added' }
                'M' { 'badge-modified' }
                'D' { 'badge-deleted' }
                'R' { 'badge-renamed' }
                default { 'badge-modified' }
            }
            $badgeLabel  = $entry.Status
            $pathEncoded = ConvertTo-HtmlEncoded $entry.Path
            $diffHtml    = Build-DiffHtml -DiffText $entry.Diff

            [void]$includedHtml.Append(@"
<details class="file-entry">
  <summary>
    <span class="badge $badgeClass">$badgeLabel</span>
    <span class="filepath">$pathEncoded</span>
  </summary>
  <pre class="diff-block"><code>$diffHtml</code></pre>
</details>
"@)
        }
    }

    # -----------------------------------------------------------------------
    # Build excluded-files section
    # -----------------------------------------------------------------------
    $excludedHtml = [System.Text.StringBuilder]::new()
    if ($excluded.Count -eq 0) {
        [void]$excludedHtml.Append('<p class="empty-msg">No files were excluded.</p>')
    } else {
        [void]$excludedHtml.Append('<table class="excluded-table"><thead><tr><th>File</th><th>Ignore file</th><th>Pattern</th></tr></thead><tbody>')
        foreach ($entry in $excluded) {
            $pathEncoded    = ConvertTo-HtmlEncoded $entry.Path
            $sourceEncoded  = ConvertTo-HtmlEncoded $entry.Source
            $patternEncoded = ConvertTo-HtmlEncoded $entry.Pattern
            [void]$excludedHtml.Append("<tr><td class=`"filepath`">$pathEncoded</td><td class=`"source-cell`">$sourceEncoded</td><td class=`"pattern-cell`"><code>$patternEncoded</code></td></tr>")
        }
        [void]$excludedHtml.Append('</tbody></table>')
    }

    # -----------------------------------------------------------------------
    # Assemble final HTML
    # -----------------------------------------------------------------------
    $generatedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $branchEncoded   = ConvertTo-HtmlEncoded $currentBranch
    $diffBaseEncoded = ConvertTo-HtmlEncoded $diffBase
    $repoEncoded     = ConvertTo-HtmlEncoded $UpstreamRepo
    $includedHtmlStr = $includedHtml.ToString()
    $excludedHtmlStr = $excludedHtml.ToString()

    # Pre-compute chip classes so the heredoc uses only simple $var references
    $chipAddedClass    = if ($addedCount    -eq 0) { 'chip chip-added chip-zero'    } else { 'chip chip-added'    }
    $chipModifiedClass = if ($modifiedCount -eq 0) { 'chip chip-modified chip-zero' } else { 'chip chip-modified' }
    $chipDeletedClass  = if ($deletedCount  -eq 0) { 'chip chip-deleted chip-zero'  } else { 'chip chip-deleted'  }
    $chipRenamedClass  = if ($renamedCount  -eq 0) { 'chip chip-renamed chip-zero'  } else { 'chip chip-renamed'  }
    $chipExcludedClass = if ($excludedCount -eq 0) { 'chip chip-excluded chip-zero' } else { 'chip chip-excluded' }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Upstream PR Preview - $branchEncoded</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 14px; color: #24292e; background: #f6f8fa; line-height: 1.5; }
    .container { max-width: 1100px; margin: 24px auto; padding: 0 16px; }

    .header-card { background: #fff; border: 1px solid #e1e4e8; border-radius: 8px; padding: 20px 24px; margin-bottom: 20px; }
    .header-card h1 { font-size: 20px; font-weight: 600; margin-bottom: 8px; }
    .meta { font-size: 13px; color: #586069; margin-bottom: 16px; display: flex; flex-wrap: wrap; gap: 12px; }
    .meta code { background: #f3f4f6; padding: 1px 5px; border-radius: 3px; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; font-size: 12px; }

    .chips { display: flex; flex-wrap: wrap; gap: 8px; }
    .chip { display: inline-flex; align-items: center; gap: 5px; padding: 4px 14px; border-radius: 20px; font-size: 13px; font-weight: 500; text-decoration: none; border: 1px solid transparent; }
    .chip:hover { opacity: 0.8; }
    .chip-added    { background: #dcffe4; color: #22863a; border-color: #c3e6cb; }
    .chip-modified { background: #fff3cd; color: #856404; border-color: #ffc107; }
    .chip-deleted  { background: #ffeef0; color: #b31d28; border-color: #f5c6cb; }
    .chip-renamed  { background: #dbeafe; color: #1d4ed8; border-color: #bfdbfe; }
    .chip-excluded { background: #f0f0f0; color: #586069; border-color: #d1d5da; }
    .chip-zero     { opacity: 0.45; cursor: default; pointer-events: none; }

    .section { background: #fff; border: 1px solid #e1e4e8; border-radius: 8px; margin-bottom: 20px; overflow: hidden; }
    .section-header { display: flex; align-items: center; justify-content: space-between; padding: 10px 16px; background: #f6f8fa; border-bottom: 1px solid #e1e4e8; }
    .section-header h2 { font-size: 14px; font-weight: 600; }
    .toolbar { display: flex; gap: 6px; }
    .btn { font-size: 12px; padding: 3px 10px; border: 1px solid #e1e4e8; border-radius: 4px; background: #fff; cursor: pointer; color: #24292e; }
    .btn:hover { background: #f6f8fa; }

    .file-entry { border-bottom: 1px solid #e1e4e8; }
    .file-entry:last-child { border-bottom: none; }
    .file-entry > summary { display: flex; align-items: center; gap: 10px; padding: 9px 16px; cursor: pointer; list-style: none; user-select: none; }
    .file-entry > summary::-webkit-details-marker { display: none; }
    .file-entry > summary:hover { background: #f6f8fa; }
    .file-entry > summary::before { content: '\25B6'; font-size: 9px; color: #6a737d; flex-shrink: 0; transition: transform 0.12s; }
    .file-entry[open] > summary::before { transform: rotate(90deg); }

    .badge { display: inline-flex; align-items: center; justify-content: center; width: 20px; height: 20px; border-radius: 4px; font-size: 11px; font-weight: 700; flex-shrink: 0; }
    .badge-added    { background: #dcffe4; color: #22863a; }
    .badge-modified { background: #fff3cd; color: #856404; }
    .badge-deleted  { background: #ffeef0; color: #b31d28; }
    .badge-renamed  { background: #dbeafe; color: #1d4ed8; }

    .filepath { font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; font-size: 12px; word-break: break-all; }

    .diff-block { margin: 0; overflow-x: auto; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; font-size: 12px; line-height: 1.55; tab-size: 4; border-top: 1px solid #e1e4e8; }
    .diff-block code { display: block; }
    .diff-block span { display: block; padding: 0 16px; white-space: pre; }
    .diff-block .add  { background: #e6ffed; }
    .diff-block .del  { background: #ffebe9; }
    .diff-block .hunk { background: #f0f7ff; color: #005cc5; }
    .diff-block .fhdr { background: #f6f8fa; color: #586069; }
    .diff-block .ctx  { background: #fff; color: #24292e; }
    .diff-block .faded { color: #959da5; font-style: italic; padding: 12px 16px; }

    .excluded-table { width: 100%; border-collapse: collapse; }
    .excluded-table th { padding: 8px 16px; background: #f6f8fa; border-bottom: 1px solid #e1e4e8; text-align: left; font-size: 12px; font-weight: 600; color: #586069; text-transform: uppercase; letter-spacing: 0.04em; }
    .excluded-table td { padding: 8px 16px; border-bottom: 1px solid #f0f0f0; vertical-align: top; }
    .excluded-table tr:last-child td { border-bottom: none; }
    .excluded-table tr:hover td { background: #f6f8fa; }
    .source-cell  { font-size: 12px; color: #586069; white-space: nowrap; }
    .pattern-cell code { background: #f3f4f6; padding: 1px 6px; border-radius: 3px; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; font-size: 12px; }

    .empty-msg { padding: 16px; color: #959da5; font-style: italic; }
    footer { text-align: center; font-size: 12px; color: #959da5; padding: 24px 0; }
  </style>
</head>
<body>
<div class="container">

  <div class="header-card">
    <h1>Upstream PR Preview</h1>
    <div class="meta">
      <span>Branch: <code>$branchEncoded</code></span>
      <span>Diff base: <code>$diffBaseEncoded</code></span>
      <span>Upstream: <code>$repoEncoded</code></span>
      <span>Generated: $generatedAt</span>
    </div>
    <div class="chips">
      <a class="$chipAddedClass"    href="#included">$addedCount Added</a>
      <a class="$chipModifiedClass" href="#included">$modifiedCount Modified</a>
      <a class="$chipDeletedClass"  href="#included">$deletedCount Deleted</a>
      <a class="$chipRenamedClass"  href="#included">$renamedCount Renamed</a>
      <a class="$chipExcludedClass" href="#excluded">$excludedCount Excluded</a>
    </div>
  </div>

  <div class="section" id="included">
    <div class="section-header">
      <h2>Included in upstream PR &mdash; $totalIncluded file(s)</h2>
      <div class="toolbar">
        <button class="btn" onclick="document.querySelectorAll('#included details').forEach(function(d){d.open=true})">Expand all</button>
        <button class="btn" onclick="document.querySelectorAll('#included details').forEach(function(d){d.open=false})">Collapse all</button>
      </div>
    </div>
    <div class="section-body">
$includedHtmlStr
    </div>
  </div>

  <div class="section" id="excluded">
    <div class="section-header">
      <h2>Excluded by ignore files &mdash; $excludedCount file(s)</h2>
    </div>
    <div class="section-body">
$excludedHtmlStr
    </div>
  </div>

  <footer>Generated by preview-upstream-pr.ps1 &middot; $generatedAt</footer>
</div>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($OutputFile, $html, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Report written to: $OutputFile" -ForegroundColor Green

    if (-not $NoBrowser) {
        Start-Process $OutputFile
    }
}
finally {
    Pop-Location
}

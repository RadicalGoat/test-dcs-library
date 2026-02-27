# ---------------------------------------------------------------------------
# DPM-015: Request to add DCS aircraft configuration changes to uas library
# Description: Created a GitHub issue for DCS aircraft changes
# ---------------------------------------------------------------------------

param (
    [switch]$Debug # Use -Debug to enable verbose output
)

$Branch      = "main"

# --- CONFIGURATION ---
$ApiUrl = "https://api.github.com/repos/RadicalGoat/dcs-config-library/issues"
$RootDir    = "C:\Utils\dcs-config-manager"
$SecretFile = Join-Path $RootDir ".secrets-dcs-library-sim-config-bot"


# Load Token
$GithubToken = Get-Content -Path $SecretFile -Raw

if ([string]::IsNullOrWhiteSpace($GithubToken)) { 
    Write-Error "Token cannot be empty. Exiting."
    exit 1 
}


Write-Host "Checking for local commits..."


# if ($Debug) {
#     Write-Host "???"
#     command
#     command
# } else {
#     command *> $LogFile
#     command *>> $LogFile
# }


# Fetch latest remote state
git fetch origin $Branch

# Check for commits ahead of origin/main
$LocalCommits = git rev-list --count origin/$Branch..HEAD

if ($LocalCommits -eq 0) {
    Write-Host "No local commits to submit."
    exit 0
}

Write-Host "$LocalCommits local commit(s) detected."

# Generate patch content
$Patch = git format-patch origin/$Branch --stdout

# Build issue title
$MachineName = $env:COMPUTERNAME
$DateStamp   = Get-Date -Format "yyyy-MM-dd HH:mm"

$Title = "Config Update Request from $MachineName ($DateStamp)"

# Build issue body
$Body = @"
A configuration update has been submitted from machine: **$MachineName**

Number of commits: **$LocalCommits**

---

### Patch

\`\`\`diff
$Patch
\`\`\`

---
Generated automatically by DCS Config Sync.
"@

# Build JSON payload
$Payload = @{
    title = $Title
    body  = $Body
} | ConvertTo-Json -Depth 5

# Prepare headers
$Headers = @{
    Authorization = "Bearer $GithubToken"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "DCS-Config-Script"
}

Write-Host "Creating GitHub issue..."

try {
    $Response = Invoke-RestMethod -Method Post `
        -Uri $ApiUrl `
        -Headers $Headers `
        -Body $Payload `
        -ContentType "application/json"

    Write-Host "Issue created successfully:"
    Write-Host $Response.html_url
}
catch {
    Write-Error "Failed to create issue:"
    Write-Error $_
    exit 1
}
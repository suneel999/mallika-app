# Sets the one number and fixed code that app store reviewers sign in with.
#
# Run from this computer:   powershell -File infra\set-review-login.ps1
#
# Reviewers cannot receive a WhatsApp code, so this one number signs in with a
# code you choose and nothing is sent to it. Use a number the hospital owns.
# Give the number and the code only in the store's "review notes" box.
# Run it again with an empty number to switch the review login off.

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = "mallika"
$env:AWS_REGION = "ap-south-2"
$env:AWS_PAGER = ""
$instance = "i-023a7aae2ad686bf8"
$noBom = New-Object System.Text.UTF8Encoding($false)

$mobile = (Read-Host "Review mobile number, 10 digits (press Enter to switch the review login off)").Trim()
$code = ""
if ($mobile -ne "") {
    if ($mobile -notmatch "^[6-9]\d{9}$") {
        throw "Enter a 10-digit Indian mobile number. Nothing was changed."
    }
    if ($mobile -eq "9999999999") {
        throw "9999999999 is the app's offline test number and never reaches the server. Choose another number. Nothing was changed."
    }
    $secure = Read-Host "Choose a 6-digit code for reviewers (it stays hidden)" -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $code = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer).Trim()
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    if ($code -notmatch "^\d{6}$") {
        throw "The code must be exactly 6 digits. Nothing was changed."
    }
    if ($code -in @("123456", "000000", "111111", "654321")) {
        throw "That code is too easy to guess. Choose another. Nothing was changed."
    }
}

$account = (aws sts get-caller-identity --query Account --output text).Trim()
$bucket = "mallika-hospitals-backups-" + $account.Substring($account.Length - 6)
$object = "s3://$bucket/deploy/review.env"
$lines = "REVIEW_MOBILE=$mobile`nREVIEW_OTP=$code`n"
$valueFile = Join-Path $env:TEMP ("mallika-review-" + [guid]::NewGuid().ToString() + ".txt")
$paramFile = Join-Path $env:TEMP ("mallika-review-" + [guid]::NewGuid().ToString() + ".json")

try {
    [IO.File]::WriteAllText($valueFile, $lines, $noBom)
    aws s3 cp $valueFile $object --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw "Could not upload to the bucket. Nothing was changed on the server." }

    # These commands hold no secret. The server reads the values from the bucket.
    $commands = @(
        "set -eu",
        "cd /home/ubuntu/mallika-app/infra",
        "aws s3 cp $object /tmp/review.env --only-show-errors",
        "cp -p .env .env.new",
        "sed -i '/^REVIEW_MOBILE=/d;/^REVIEW_OTP=/d' .env.new",
        "cat /tmp/review.env >> .env.new",
        "chmod 600 .env.new && chown ubuntu:ubuntu .env.new && mv .env.new .env",
        "shred -u /tmp/review.env",
        "docker compose up -d --force-recreate api 2>&1 | tail -2",
        "sleep 8",
        "docker compose exec -T api python -c `"import os; m = os.environ.get('REVIEW_MOBILE', ''); c = os.environ.get('REVIEW_OTP', ''); print('Review login is ON for the number ending ' + m[-4:] if m and len(c) == 6 else 'Review login is OFF')`"",
        "docker compose ps --format '{{.Service}} {{.State}}'"
    )
    $params = @{ commands = $commands } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($paramFile, $params, $noBom)

    $commandId = (aws ssm send-command --instance-ids $instance --document-name AWS-RunShellScript `
        --comment "set review login" --parameters "file://$paramFile" `
        --query Command.CommandId --output text).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Could not reach the server." }

    Write-Host "Updating the server..."
    $status = "Pending"
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 5
        $status = (aws ssm get-command-invocation --command-id $commandId --instance-id $instance `
            --query Status --output text)
        if ($status -in @("Success", "Failed", "TimedOut", "Cancelled")) { break }
    }
    $output = aws ssm get-command-invocation --command-id $commandId --instance-id $instance `
        --query StandardOutputContent --output text
    Write-Host $output
    if ($status -ne "Success") {
        $errors = aws ssm get-command-invocation --command-id $commandId --instance-id $instance `
            --query StandardErrorContent --output text
        Write-Host $errors
        throw "The server did not finish the update (status $status)."
    }
}
finally {
    aws s3 rm $object --only-show-errors
    Remove-Item $valueFile, $paramFile -Force -ErrorAction SilentlyContinue
    $code = $null
    $lines = $null
}

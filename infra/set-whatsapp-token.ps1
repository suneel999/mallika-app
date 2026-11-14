# Puts a new WhatsApp token on the live server and checks it with Meta.
#
# Run from this computer:   powershell -File infra\set-whatsapp-token.ps1
#
# The token is typed hidden. It travels through the private, encrypted backup
# bucket, not through chat and not through the Session Manager command history.
# The copy in the bucket and the copy on this computer are deleted at the end.

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = "mallika"
$env:AWS_REGION = "ap-south-2"
$env:AWS_PAGER = ""
$instance = "i-023a7aae2ad686bf8"
$noBom = New-Object System.Text.UTF8Encoding($false)

$secure = Read-Host "Paste the new WhatsApp token (it stays hidden)" -AsSecureString
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer).Trim()
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
if ($token.Length -lt 50 -or $token -match "\s") {
    throw "That does not look like a WhatsApp token. Nothing was changed."
}

$phone = (Read-Host "Phone number ID (press Enter to keep the one on the server)").Trim()
if ($phone -ne "" -and $phone -notmatch "^\d+$") {
    throw "The phone number ID is digits only. Nothing was changed."
}

$account = (aws sts get-caller-identity --query Account --output text).Trim()
$bucket = "mallika-hospitals-backups-" + $account.Substring($account.Length - 6)
$object = "s3://$bucket/deploy/whatsapp.env"

$lines = "WHATSAPP_TOKEN=$token`n"
if ($phone -ne "") {
    $lines += "WHATSAPP_PHONE_NUMBER_ID=$phone`n"
}
$valueFile = Join-Path $env:TEMP ("mallika-wa-" + [guid]::NewGuid().ToString() + ".txt")
$paramFile = Join-Path $env:TEMP ("mallika-wa-" + [guid]::NewGuid().ToString() + ".json")

try {
    [IO.File]::WriteAllText($valueFile, $lines, $noBom)
    aws s3 cp $valueFile $object --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw "Could not upload to the bucket. Nothing was changed on the server." }

    # These commands hold no secret. The server reads the token from the bucket.
    $commands = @(
        "set -eu",
        "cd /home/ubuntu/mallika-app/infra",
        "aws s3 cp $object /tmp/whatsapp.env --only-show-errors",
        "cp -p .env .env.new",
        "for key in `$(cut -d= -f1 /tmp/whatsapp.env); do sed -i `"/^`$key=/d`" .env.new; done",
        "cat /tmp/whatsapp.env >> .env.new",
        "chmod 600 .env.new && chown ubuntu:ubuntu .env.new && mv .env.new .env",
        "shred -u /tmp/whatsapp.env",
        "docker compose up -d --force-recreate api 2>&1 | tail -2",
        "sleep 8",
        "set -a; . ./.env; set +a",
        "code=`$(curl -s -m 20 -o /dev/null -w '%{http_code}' -H `"Authorization: Bearer `$WHATSAPP_TOKEN`" `"https://graph.facebook.com/v21.0/`$WHATSAPP_PHONE_NUMBER_ID?fields=id`")",
        "echo `"Meta answered `$code for this token and phone number ID`"",
        "docker compose ps --format '{{.Service}} {{.State}}'"
    )
    $params = @{ commands = $commands } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($paramFile, $params, $noBom)

    $commandId = (aws ssm send-command --instance-ids $instance --document-name AWS-RunShellScript `
        --comment "set WhatsApp token" --parameters "file://$paramFile" `
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
    if ($output -match "Meta answered 200") {
        Write-Host "Done. Meta accepts the new token. Sign-in codes can be sent."
    } else {
        Write-Host "The token is on the server, but Meta did not accept it. Check the token and the phone number ID, then run this again."
    }
}
finally {
    aws s3 rm $object --only-show-errors
    Remove-Item $valueFile, $paramFile -Force -ErrorAction SilentlyContinue
    $token = $null
    $lines = $null
}

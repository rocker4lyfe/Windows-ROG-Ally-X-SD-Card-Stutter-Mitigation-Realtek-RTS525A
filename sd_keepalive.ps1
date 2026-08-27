# SD-card keep-alive for ROG Ally X (Realtek RTS525A)
# Writes a 1-byte file every 3 seconds to prevent the
# controller/card from entering a faulty low-power state.

$CARD_DRIVE = "D:"
$KEEPALIVE_FILE = "$CARD_DRIVE\.sd_keepalive"
$INTERVAL_SECONDS = 3

function Log($Message) {
    Write-Host "[sd_keepalive] $Message"
}

Log "Starting SD keep-alive on $CARD_DRIVE (interval: ${INTERVAL_SECONDS}s)"

while ($true) {

    if (Test-Path "$CARD_DRIVE\") {
        try {
            # Write exactly one byte: ASCII "."
            $Bytes = [System.Text.Encoding]::ASCII.GetBytes(".")
            [System.IO.File]::WriteAllBytes($KEEPALIVE_FILE, $Bytes)
        }
        catch {
            Log "Failed to write keepalive file: $_"
        }
    }
    else {
        Log "SD card not found: $CARD_DRIVE"
    }

    Start-Sleep -Seconds $INTERVAL_SECONDS
}

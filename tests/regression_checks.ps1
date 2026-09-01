$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Source([string]$relativePath) {
    return Get-Content -Raw -LiteralPath (Join-Path $repoRoot $relativePath)
}

function Check([bool]$condition, [string]$message) {
    if (-not $condition) {
        $failures.Add($message)
    }
}

$gunUsed = Read-Source "scripts/guns/gun_used_functions.lua"
$triggerSystem = Read-Source "scripts/magics/trigger_system.lua"
$pickup = Read-Source "scripts/pickup.lua"
$gun = Read-Source "scripts/gun.lua"
$characters = Read-Source "scripts/characters.lua"
$data = Read-Source "scripts/data.lua"
$deerCallback = Read-Source "scripts/entities/entity/deer.lua"
$deerLogic = Read-Source "scripts/entities/entity/entity_logic/deer_logic.lua"
$magicFunction = Read-Source "scripts/magics/magic_function.lua"
$developmentDocs = Read-Source "docs/DEVELOPMENT.md"

Check (-not (($gunUsed + $triggerSystem) -match 'TBoN\.Magic\.Info\.TriggerType')) `
    "Trigger types must use TBoN.Magic.Table.Info.TriggerType."
Check (-not ($developmentDocs -match 'TBoN\.Magic\.Info\.')) `
    "Development examples must use the real TBoN.Magic.Table.Info namespace."

Check ($pickup -match 'AddCallback\(ModCallbacks\.MC_POST_PICKUP_INIT,\s*TBoN_MOD\.Wand_Pickup_Init,\s*TBoN\.Magic\.Table\.Info\.Variant\.Pickup_Wand\)') `
    "Wand_Pickup_Init must be filtered to the custom wand pickup variant."

$inputCheck = [regex]::Match(
    $gun,
    'function TBoN_MOD:Input_Check\(player\)(.*?)TBoN_MOD:AddCallback\(ModCallbacks\.MC_POST_PLAYER_UPDATE, TBoN_MOD\.Input_Check\)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
).Groups[1].Value
Check ($inputCheck.Length -gt 0) "Input_Check must accept the callback player."
Check (-not ($inputCheck -match 'GetNumPlayers\(\)')) `
    "Input_Check must not loop over every player from a per-player callback."
Check ($gun -match 'last_state_update_frame') `
    "Shared gun state must have a once-per-frame update guard."
Check ($gun -match 'last_cast_frame\s*=\s*Game\(\):GetFrameCount\(\)') `
    "last_cast_frame must use the current game frame explicitly."
Check (-not ($gun -match 'collectgarbage\(')) `
    "Casting must not force a garbage-collection step."

Check (-not ($characters -match 'GetPlayerType\(\)\s*~=\s*TBoN\.Character\.Variable\.Num\.Mina_Type\s*then\s*return')) `
    "A non-Mina player must not abort initialization of later co-op players."

Check (-not ($data -match '=\s*TBoN\.Data\.Table\.(bag_magic_data_init|gun_magic_data_init|gun_info_init)')) `
    "Runtime save fallbacks must deep-copy initialization templates."
Check ($data -match 'if IsContinued and not TBoN_MOD:HasData\(\)') `
    "Continuing after enabling the mod must initialize fresh Mina data."

$magicCollision = [regex]::Match(
    $pickup,
    'function TBoN_MOD:Col_With_Pickup_Magic\(.*?\)(.*?)TBoN_MOD:AddCallback\(ModCallbacks\.MC_PRE_PICKUP_COLLISION, TBoN_MOD\.Col_With_Pickup_Magic',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
).Groups[1].Value
$magicNaturalIndex = $magicCollision.IndexOf('local is_natural_spawn')
$magicDeleteIndex = $magicCollision.IndexOf('dropped_spell_temp[pickup_hash] = nil')
Check ($magicNaturalIndex -ge 0 -and $magicDeleteIndex -ge 0 -and $magicNaturalIndex -lt $magicDeleteIndex) `
    "Spell natural-spawn state must be captured before temporary metadata is deleted."
Check ($magicCollision -match 'if pickup_collected then\s*Isaac\.RunCallback\(TBoN\.Callback\.TBON_POST_PICKUP_MAGIC') `
    "Spell pickup callback must run only after an inventory slot is filled."

$wandCollision = [regex]::Match(
    $pickup,
    'function TBoN_MOD:Col_With_Pickup_Wand\(.*?\)(.*?)TBoN_MOD:AddCallback\(ModCallbacks\.MC_PRE_PICKUP_COLLISION, TBoN_MOD\.Col_With_Pickup_Wand',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
).Groups[1].Value
$wandNaturalIndex = $wandCollision.IndexOf('local is_natural_spawn')
$wandDeleteIndex = $wandCollision.IndexOf('dropped_wand_temp[pickup_index] = nil')
Check ($wandNaturalIndex -ge 0 -and $wandDeleteIndex -ge 0 -and $wandNaturalIndex -lt $wandDeleteIndex) `
    "Wand natural-spawn state must be captured before temporary metadata is deleted."
Check ($wandCollision -match 'if pickup_collected then\s*Isaac\.RunCallback\(TBoN\.Callback\.TBON_POST_PICKUP_WAND') `
    "Wand pickup callback must run only after an inventory slot is filled."

Check ($deerLogic -match 'entitynpc:IsEnemy\(\) and entitynpc\.Type ~= TBoN\.Entity\.Table\.Info\.Type\.Deer') `
    "Deer targeting must compare the candidate enemy type, not the deer type."
Check ($deerCallback -match 'function TBoN_MOD:Deer_Death\(entity\)\s*Deer:Remove\(entity\)\s*end') `
    "Deer death must clear its state-machine data."
Check (-not ($deerLogic -match 'Isaac\.Explode\(')) `
    "Deer state cleanup must not create an unrelated explosion side effect."

Check ($magicFunction -match 'magic_hash\[GetPtrHash\(entity\)\]') `
    "Generic effect rotation must be limited to tracked mod projectiles."
Check (-not ($magicFunction -match 'entity\.Variant\s*>=\s*3100')) `
    "Generic effect rotation must not mutate other mods based on a broad variant range."

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    throw "$($failures.Count) regression check(s) failed."
}

Write-Output "All regression checks passed."

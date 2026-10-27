#Requires -Version 5.1
# =====================================================================
#  GeHi Windows 11 Optimizer
#  Один скрипт: на старті обираєте дію
#     [1] Оптимізація Windows 11
#     [2] Відновлення змін (відкат за Backup_*\undo.csv)
#  Запуск: у PowerShell від імені адміністратора:
#     Set-ExecutionPolicy -Scope Process Bypass; .\GeHi_Optimizer.ps1
# =====================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ПОМИЛКА] Запустіть цей скрипт від імені Адміністратора!" -ForegroundColor Red
    Read-Host "Натисніть Enter для виходу" | Out-Null
    Exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "   GeHi Windows 11 Optimizer" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Що ви хочете зробити?" -ForegroundColor Yellow
Write-Host "  [1] Оптимізація: застосувати налаштування"
Write-Host "  [2] Відновлення: скасувати зміни, зроблені раніше цим скриптом"
Write-Host "  [3] Вихід"
Write-Host ""
do { $Action = Read-Host "Ваш вибір [1-3]" } until ($Action -in '1', '2', '3')
if ($Action -eq '3') { Exit }

if ($Action -eq '1') {
    $TS        = Get-Date -Format "yyyyMMdd_HHmmss"
    $Root      = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $LogPath   = Join-Path $Root "Optimization_log_$TS.txt"
    $BackupDir = Join-Path $Root "Backup_$TS"
    $UndoPath  = Join-Path $BackupDir "undo.csv"
    $GuidRx    = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    # ---------------------------------------------------------------------
    #  Допоміжні функції
    # ---------------------------------------------------------------------
    function Log([string]$Msg, [string]$Color = 'Gray') {
        Write-Host $Msg -ForegroundColor $Color
        Add-Content -Path $LogPath -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Msg) -Encoding UTF8
    }

    function Add-Undo([string]$Type, [string]$Target, [string]$Name = '', [string]$Kind = '', [string]$Old = '') {
        [pscustomobject]@{ Type = $Type; Target = $Target; Name = $Name; Kind = $Kind; Old = $Old } |
            Export-Csv -Path $UndoPath -Append -NoTypeInformation -Encoding UTF8
    }

    # Запис у реєстр із збереженням старого значення для відкату
    function Set-Reg {
        param([string]$Path, [string]$Name, $Value, [string]$Kind = 'DWord', [switch]$NoUndo)
        try {
            $old = '<absent>'
            if (Test-Path -LiteralPath $Path) {
                $cur = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
                if ($null -ne $cur -and $null -ne $cur.$Name) { $old = [string]$cur.$Name }
            } else {
                New-Item -Path $Path -Force | Out-Null
            }
            if (-not $NoUndo) { Add-Undo 'reg' $Path $Name $Kind $old }
            Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Kind -ErrorAction Stop
        } catch {
            Log "  [!] Не вдалося записати $Path\$Name : $($_.Exception.Message)" 'DarkYellow'
        }
    }

    # Вимкнення служби із запам'ятовуванням попереднього типу запуску
    function Disable-Svc([string]$Name) {
        try {
            $s = Get-Service -Name $Name -ErrorAction SilentlyContinue
            if (-not $s -or $s.StartType -eq 'Disabled') { return }
            $kind = [string]$s.StartType
            if ($kind -eq 'Automatic') {
                $d = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -ErrorAction SilentlyContinue).DelayedAutostart
                if ($d -eq 1) { $kind = 'AutomaticDelayed' }
            }
            Add-Undo 'service' $Name '' '' $kind
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Name -StartupType Disabled -ErrorAction Stop
            Log "  служба $Name вимкнена"
        } catch {
            Log "  [!] Служба ${Name}: $($_.Exception.Message)" 'DarkYellow'
        }
    }

    function Do-Step([string]$Key, [string]$Title, [scriptblock]$Code) {
        if ($T[$Key] -ne 1) { return }
        Log "> $Title" 'Cyan'
        try { & $Code } catch { Log "  [!] Помилка: $($_.Exception.Message)" 'Red' }
    }

    function Ask-YN([string]$Text) {
        $a = Read-Host "$Text [Y/N]"
        return ($a -match '^[YyТт]')
    }

    "Оптимізація Windows 11 (v2), запуск $TS" | Out-File -FilePath $LogPath -Encoding utf8

    # ---------------------------------------------------------------------
    #  Меню
    # ---------------------------------------------------------------------
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "   GeHi Windows 11 Optimizer" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Виберіть тип пристрою:" -ForegroundColor Yellow
    Write-Host "  [1] Стаціонарний ПК"
    Write-Host "  [2] Ноутбук"
    Write-Host ""
    do { $DeviceChoice = Read-Host "Ваш вибір [1 або 2]" } until ($DeviceChoice -in '1', '2')
    $IsPC = ($DeviceChoice -eq '1')

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "   Спосіб налаштування" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [1] Автоматично: безпечний рекомендований набір"
    Write-Host "  [2] Вручну: відповідаєте Y/N на кожен пункт"
    Write-Host "  [3] GeHi: повний набір для ПК (усі 27 пунктів)"
    Write-Host "  [4] Вихід"
    Write-Host ""
    do { $Method = Read-Host "Ваш вибір [1-4]" } until ($Method -in '1', '2', '3', '4')
    if ($Method -eq '4') { Exit }

    # K = ключ, D = значення в авто-режимі, PC = лише для стаціонарного ПК
    $Items = @(
        @{ K='RP';          D=1; PC=$false; Q='Створити точку відновлення' },
        @{ K='CTX';         D=0; PC=$false; Q='Класичне контекстне меню (як у Windows 10)' },
        @{ K='HVCI';        D=0; PC=$false; Q='Вимкнути ізоляцію ядра VBS/HVCI  [ЗНИЖУЄ БЕЗПЕКУ]' },
        @{ K='SAC';         D=0; PC=$false; Q='Вимкнути Smart App Control  [НЕЗВОРОТНО без перевстановлення Windows]' },
        @{ K='FAST';        D=0; PC=$false; Q='Швидкий інтерфейс (без затримки меню, швидше закриття програм)' },
        @{ K='EDGE';        D=1; PC=$false; Q='Вимкнути фонову роботу й Startup Boost у Edge' },
        @{ K='CLEAN';       D=1; PC=$false; Q='Очистити Temp і DNS-кеш' },
        @{ K='QOL';         D=1; PC=$false; Q='Зручності: End Task на панелі завдань, секунди в годиннику, NumLock' },
        @{ K='TIMER';       D=0; PC=$true;  Q='Глобальний точний таймер (трохи більше споживання)' },
        @{ K='DRV';         D=1; PC=$false; Q='Заборонити встановлення драйверів через Windows Update' },
        @{ K='NETPM';       D=1; PC=$true;  Q='Вимкнути енергозбереження мережевих адаптерів' },
        @{ K='HARD';        D=1; PC=$false; Q='Безпека мережі: вимкнути RDP і SMBv1' },
        @{ K='FS';          D=1; PC=$false; Q='NTFS: не оновлювати час останнього доступу до файлів' },
        @{ K='EXPL';        D=0; PC=$false; Q='Провідник: приховані файли, розширення, відкривати "Цей ПК"' },
        @{ K='SXS';         D=0; PC=$false; Q='Очистити сховище компонентів WinSxS (може тривати кілька хвилин)' },
        @{ K='ESPORTS';     D=0; PC=$false; Q='Кіберспорт: MPO вимк., DisablePagingExecutive, без стиснення пам''яті (потрібно 16+ ГБ RAM)' },
        @{ K='VISUAL';      D=0; PC=$false; Q='Легкі візуальні ефекти (без анімацій і прозорості)' },
        @{ K='BG';          D=0; PC=$false; Q='Заборонити фонову роботу програм' },
        @{ K='SERV';        D=0; PC=$false; Q='Вимкнути зайві служби (карти, факс, демо-режим, віддалений реєстр, геолокація)' },
        @{ K='INDEX';       D=0; PC=$false; Q='Вимкнути індексацію пошуку Windows Search (пошук стане повільнішим)' },
        @{ K='PRINT';       D=0; PC=$false; Q='Вимкнути диспетчер друку (лише якщо немає принтерів)' },
        @{ K='UI';          D=0; PC=$false; Q='Прибрати рекламу в Пуску, поради, Widgets і Copilot' },
        @{ K='SECNOTIFY';   D=0; PC=$false; Q='Вимкнути сповіщення Центру безпеки (сам захист лишається)' },
        @{ K='MAINT';       D=0; PC=$false; Q='Вимкнути автоматичне обслуговування Windows' },
        @{ K='UCPD';        D=0; PC=$false; Q='Вимкнути UCPD (дозволяє утилітам міняти браузер за замовчуванням)' },
        @{ K='SMARTSCREEN'; D=0; PC=$false; Q='Вимкнути SmartScreen  [ЗНИЖУЄ БЕЗПЕКУ]' },
        @{ K='MANUALWU';    D=0; PC=$false; Q='Оновлення Windows вручну  [самі стежте за оновленнями безпеки]' }
    )

    $T = @{}
    foreach ($i in $Items) { $T[$i.K] = 0 }

    switch ($Method) {
        '1' {
            foreach ($i in $Items) { if (-not ($i.PC -and -not $IsPC)) { $T[$i.K] = $i.D } }
        }
        '3' {
            if (-not $IsPC -and -not (Ask-YN "Пресет GeHi призначений для ПК. На ноутбуці продовжити")) { Exit }
            foreach ($i in $Items) { if (-not ($i.PC -and -not $IsPC)) { $T[$i.K] = 1 } }
        }
        '2' {
            Clear-Host
            Write-Host "Відповідайте Y [так] або N [ні]" -ForegroundColor Cyan
            $n = 0
            foreach ($i in $Items) {
                if ($i.PC -and -not $IsPC) { continue }
                $n++
                $T[$i.K] = if (Ask-YN "$n. $($i.Q)") { 1 } else { 0 }
            }
        }
    }

    if ($T.SAC -eq 1) {
        if (-not (Ask-YN "Smart App Control вимикається НЕЗВОРОТНО. Підтвердити")) { $T.SAC = 0 }
    }

    Clear-Host
    Write-Host "Буде застосовано:" -ForegroundColor Yellow
    Write-Host "  - базові налаштування (миша/клавіатура, телеметрія, Bing-пошук, Game DVR)"
    if ($IsPC) { Write-Host "  - ПК: план Ultimate Performance, USB/енергозбереження, гібернація вимк., таймер ядра" }
    foreach ($i in $Items) { if ($T[$i.K] -eq 1) { Write-Host "  - $($i.Q)" } }
    Write-Host ""
    if (-not (Ask-YN "Продовжити")) { Exit }

    Clear-Host
    Log "Запуск оптимізації. Пристрій: $(if ($IsPC) {'ПК'} else {'Ноутбук'}), режим: $Method" 'Yellow'

    # ---------------------------------------------------------------------
    #  Точка відновлення та резервні копії
    # ---------------------------------------------------------------------
    Do-Step 'RP' 'Створення точки відновлення' {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0 -NoUndo
        Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "GeHi before optimization" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    }

    Log "> Резервні копії реєстру та BCD" 'Cyan'
    reg export "HKCU\Control Panel\Mouse"    "$BackupDir\Mouse.reg"      /y >$null 2>&1
    reg export "HKCU\Control Panel\Keyboard" "$BackupDir\Keyboard.reg"   /y >$null 2>&1
    reg export "HKCU\Control Panel\Desktop"  "$BackupDir\Desktop.reg"    /y >$null 2>&1
    reg export "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "$BackupDir\DeviceGuard.reg" /y >$null 2>&1
    bcdedit /export "$BackupDir\bcd.bak" >$null 2>&1

    # ---------------------------------------------------------------------
    #  Базові налаштування (завжди)
    # ---------------------------------------------------------------------
    Log "> Введення: без акселерації миші, швидка клавіатура" 'Cyan'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' -Kind String

    Log "> Пошук, телеметрія, Game DVR, мережевий тротлінг" 'Cyan'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCloudSearch' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    Disable-Svc 'DiagTrack'
    Disable-Svc 'dmwappushservice'
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' -1

    # ---------------------------------------------------------------------
    #  Тільки для стаціонарного ПК
    # ---------------------------------------------------------------------
    if ($IsPC) {
        Log "> ПК: живлення, USB, гібернація, таймер" 'Cyan'
        try {
            Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
            Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction Stop | ForEach-Object {
                $_.Enable = $false
                Set-CimInstance -InputObject $_ -ErrorAction SilentlyContinue
            }
            Add-Undo 'action' 'wmi_power_on'
        } catch { }

        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
        $hib = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction SilentlyContinue).HibernateEnabled
        if ($hib -eq 1) { Add-Undo 'action' 'hibernate_on' }
        powercfg /hibernate off

        $act = [regex]::Match((powercfg /getactivescheme | Out-String), $GuidRx).Value
        if ($act) { Add-Undo 'action' 'powerplan' '' '' $act }
        $ultGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        $out = (powercfg -duplicatescheme $ultGuid 2>&1 | Out-String)
        $new = [regex]::Match($out, $GuidRx).Value
        if ($new -and ($new -ne $ultGuid)) { powercfg /setactive $new } else { powercfg /setactive SCHEME_MIN }

        bcdedit /set disabledynamictick yes | Out-Null
        Add-Undo 'action' 'dynamictick'
        bcdedit /deletevalue useplatformclock 2>$null | Out-Null
        bcdedit /deletevalue useplatformtick  2>$null | Out-Null
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    }

    # ---------------------------------------------------------------------
    #  Вибрані пункти
    # ---------------------------------------------------------------------
    Do-Step 'CTX' 'Класичне контекстне меню' {
        $clsid = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
        if (-not (Test-Path -LiteralPath $clsid)) {
            Add-Undo 'regkey' $clsid
            New-Item -Path "$clsid\InprocServer32" -Force | Out-Null
            Set-ItemProperty -LiteralPath "$clsid\InprocServer32" -Name '(default)' -Value '' -ErrorAction SilentlyContinue
        }
    }

    Do-Step 'HVCI' 'Вимкнення VBS/HVCI' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
    }

    Do-Step 'SAC' 'Вимкнення Smart App Control (незворотно)' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' 'VerifiedAndReputablePolicyState' 0 -NoUndo
    }

    Do-Step 'FAST' 'Швидкий інтерфейс' {
        Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' -Kind String
        Set-Reg 'HKCU:\Control Panel\Desktop' 'WaitToKillAppTimeout' '2000' -Kind String
    }

    Do-Step 'EDGE' 'Edge: без фонової роботи' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0
    }

    Do-Step 'CLEAN' 'Очистка Temp та DNS-кешу' {
        $tmp = [string]$env:TEMP
        $wt  = "$env:SystemRoot\Temp"
        if ($Root.StartsWith($tmp, [StringComparison]::OrdinalIgnoreCase) -or $Root.StartsWith($wt, [StringComparison]::OrdinalIgnoreCase)) {
            Log "  [!] Скрипт лежить у папці Temp. Очистку пропущено, щоб не видалити бекап і лог." 'DarkYellow'
        } else {
            Remove-Item "$tmp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "$wt\*"  -Recurse -Force -ErrorAction SilentlyContinue
        }
        ipconfig /flushdns | Out-Null
    }

    Do-Step 'QOL' 'Зручності: End Task, секунди, NumLock' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 1
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemTray' 1
        Set-Reg 'HKCU:\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' -Kind String
        Set-Reg 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' -Kind String
    }

    Do-Step 'TIMER' 'Глобальний точний таймер' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
    }

    Do-Step 'DRV' 'Заборона драйверів через Windows Update' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate' 1
    }

    Do-Step 'NETPM' 'Енергозбереження мережевих адаптерів' {
        Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Disable-NetAdapterPowerManagement -Name $_.Name -NoRestart -ErrorAction Stop
                Add-Undo 'action' 'netpm' $_.Name
                Log "  адаптер $($_.Name)"
            } catch { }
        }
    }

    Do-Step 'HARD' 'Безпека мережі: RDP і SMBv1' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections' 1
        $f = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($f -and $f.State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Add-Undo 'action' 'smb1_on'
        }
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
    }

    Do-Step 'FS' 'NTFS: без оновлення часу останнього доступу' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 1
    }

    Do-Step 'EXPL' 'Провідник' {
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-Reg $adv 'Hidden' 1
        Set-Reg $adv 'HideFileExt' 0
        Set-Reg $adv 'LaunchTo' 1
    }

    Do-Step 'SXS' 'Очистка WinSxS (зачекайте)' {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
    }

    Do-Step 'ESPORTS' 'Кіберспортивні твіки' {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
        $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        if ($ram -ge 16) {
            Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
            if ((Get-MMAgent).MemoryCompression) {
                Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
                Add-Undo 'action' 'mmagent_on'
            }
        } else {
            Log "  [!] RAM $ram ГБ (<16): DisablePagingExecutive і вимкнення стиснення пам'яті пропущено." 'DarkYellow'
        }
    }

    Do-Step 'VISUAL' 'Легкі візуальні ефекти' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
        Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' -Kind String
        Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    }

    Do-Step 'BG' 'Заборона фонових програм' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
    }

    Do-Step 'SERV' 'Вимкнення зайвих служб' {
        foreach ($s in 'MapsBroker', 'Fax', 'RetailDemo', 'RemoteRegistry', 'lfsvc', 'WMPNetworkSvc') { Disable-Svc $s }
    }

    Do-Step 'INDEX' 'Вимкнення індексації (WSearch)' {
        Disable-Svc 'WSearch'
    }

    Do-Step 'PRINT' 'Вимкнення диспетчера друку' {
        $real = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'PDF|XPS|OneNote|Fax' })
        if ($real.Count -gt 0) {
            Log "  [!] Знайдено принтери ($($real.Name -join ', ')). Диспетчер друку не чіпаю." 'DarkYellow'
        } else {
            Disable-Svc 'Spooler'
        }
    }

    Do-Step 'UI' 'Реклама, поради, Widgets, Copilot' {
        $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        foreach ($n in 'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled',
                       'SubscribedContent-353696Enabled', 'SubscribedContent-310093Enabled', 'SystemPaneSuggestionsEnabled',
                       'SoftLandingEnabled', 'RotatingLockScreenOverlayEnabled', 'SilentInstalledAppsEnabled',
                       'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled') {
            Set-Reg $cdm $n 0
        }
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
        Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    }

    Do-Step 'SECNOTIFY' 'Сповіщення Центру безпеки' {
        $p = 'HKLM:\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications'
        Set-Reg $p 'DisableNotifications' 1
        Set-Reg $p 'DisableEnhancedNotifications' 1
    }

    Do-Step 'MAINT' 'Автоматичне обслуговування' {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance' 'MaintenanceDisabled' 1
    }

    Do-Step 'UCPD' 'Вимкнення UCPD (діє після перезавантаження)' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\UCPD' 'Start' 4
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\AppxDeployment\' -TaskName 'UCPD velocity' -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne 'Disabled') {
            Add-Undo 'task' '\Microsoft\Windows\AppxDeployment\' 'UCPD velocity'
            Disable-ScheduledTask -InputObject $task | Out-Null
        }
    }

    Do-Step 'SMARTSCREEN' 'Вимкнення SmartScreen' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen' 0
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'Off' -Kind String
    }

    Do-Step 'MANUALWU' 'Оновлення Windows вручну' {
        $au = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        Set-Reg $au 'NoAutoUpdate' 0
        Set-Reg $au 'AUOptions' 2
    }

    # ---------------------------------------------------------------------
    Log "" 
    Log "====================================================" 'Green'
    Log "   ГОТОВО! ПЕРЕЗАВАНТАЖТЕ КОМП'ЮТЕР" 'Green'
    Log "====================================================" 'Green'
    Log "Лог:             $LogPath" 'Yellow'
    Log "Папка відкату:   $BackupDir" 'Yellow'
    Log "Відкат змін:     запустіть цей скрипт знову і виберіть [2] Відновлення змін" 'Yellow'
    Log "Не відкочується: Smart App Control, очистка Temp/WinSxS." 'Yellow'
    Read-Host "Натисніть Enter для виходу" | Out-Null

}
else {
    function Info([string]$m, [string]$c = 'Gray') { Write-Host $m -ForegroundColor $c }


    # Вибір папки бекапу
    $folders = @(Get-ChildItem -Path $Root -Directory -Filter 'Backup_*' -ErrorAction SilentlyContinue |
                 Where-Object { Test-Path (Join-Path $_.FullName 'undo.csv') } |
                 Sort-Object Name -Descending)
    if ($folders.Count -eq 0) {
        Write-Host "Не знайдено жодної папки Backup_* з файлом undo.csv поруч зі скриптом." -ForegroundColor Red
        Read-Host "Натисніть Enter для виходу" | Out-Null
        Exit
    }

    Write-Host "Доступні резервні копії (новіші зверху):" -ForegroundColor Yellow
    for ($k = 0; $k -lt $folders.Count; $k++) { Write-Host ("  [{0}] {1}" -f ($k + 1), $folders[$k].Name) }
    $sel = Read-Host "Яку відкотити? [Enter = найновішу]"
    $idx = 0
    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $folders.Count) { $idx = [int]$sel - 1 }
    $Dir = $folders[$idx].FullName
    $UndoPath = Join-Path $Dir 'undo.csv'

    $rows = @(Import-Csv -Path $UndoPath -Encoding UTF8)
    [array]::Reverse($rows)   # відкат у зворотному порядку
    Write-Host "Відкат $($rows.Count) записів із $Dir ..." -ForegroundColor Cyan

    foreach ($r in $rows) {
        try {
            switch ($r.Type) {

                'reg' {
                    if ($r.Old -eq '<absent>') {
                        Remove-ItemProperty -LiteralPath $r.Target -Name $r.Name -ErrorAction SilentlyContinue
                    } else {
                        if (-not (Test-Path -LiteralPath $r.Target)) { New-Item -Path $r.Target -Force | Out-Null }
                        $v = if ($r.Kind -eq 'DWord') { [int]$r.Old } else { $r.Old }
                        Set-ItemProperty -LiteralPath $r.Target -Name $r.Name -Value $v -Type $r.Kind -ErrorAction Stop
                    }
                    Info "реєстр: $($r.Target)\$($r.Name)"
                }

                'regkey' {
                    Remove-Item -LiteralPath $r.Target -Recurse -Force -ErrorAction SilentlyContinue
                    Info "ключ видалено: $($r.Target)"
                }

                'service' {
                    switch ($r.Old) {
                        'AutomaticDelayed' { sc.exe config $r.Target start= delayed-auto | Out-Null }
                        'Automatic'        { Set-Service -Name $r.Target -StartupType Automatic -ErrorAction Stop }
                        'Manual'           { Set-Service -Name $r.Target -StartupType Manual -ErrorAction Stop }
                        default            { }
                    }
                    Info "служба: $($r.Target) -> $($r.Old)"
                }

                'task' {
                    Enable-ScheduledTask -TaskPath $r.Target -TaskName $r.Name -ErrorAction Stop | Out-Null
                    Info "завдання увімкнено: $($r.Name)"
                }

                'action' {
                    switch ($r.Target) {
                        'hibernate_on' { powercfg /hibernate on; Info "гібернацію увімкнено" }
                        'dynamictick'  { bcdedit /deletevalue disabledynamictick 2>$null | Out-Null; Info "dynamic tick повернуто" }
                        'powerplan'    { powercfg /setactive $r.Old; Info "план живлення повернуто: $($r.Old)" }
                        'mmagent_on'   { Enable-MMAgent -MemoryCompression -ErrorAction Stop; Info "стиснення пам'яті увімкнено" }
                        'netpm'        { Enable-NetAdapterPowerManagement -Name $r.Name -NoRestart -ErrorAction Stop; Info "енергозбереження адаптера: $($r.Name)" }
                        'wmi_power_on' {
                            Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue | ForEach-Object {
                                $_.Enable = $true
                                Set-CimInstance -InputObject $_ -ErrorAction SilentlyContinue
                            }
                            Info "енергозбереження пристроїв повернуто"
                        }
                        'smb1_on' {
                            $a = Read-Host "SMBv1 небезпечний. Справді увімкнути знову? [Y/N]"
                            if ($a -match '^[Yy]') {
                                Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                                Info "SMBv1 увімкнено"
                            } else { Info "SMBv1 залишено вимкненим" }
                        }
                    }
                }
            }
        } catch {
            Write-Host "  [!] $($r.Type) $($r.Target) $($r.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    Write-Host ""
    Write-Host "Готово. Перезавантажте комп'ютер." -ForegroundColor Green
    Write-Host "Не відкочується: Smart App Control (лише перевстановлення Windows), очистка Temp/WinSxS." -ForegroundColor Yellow
    Write-Host "Резервні .reg-файли (миша, клавіатура, Desktop, DeviceGuard) та bcd.bak лежать у $Dir" -ForegroundColor Yellow
    Read-Host "Натисніть Enter для виходу" | Out-Null

}

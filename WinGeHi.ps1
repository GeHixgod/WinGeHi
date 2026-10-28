#Requires -Version 5.1
# =====================================================================
#  WinGeHi
#  One script, two actions: [1] Optimize  [2] Restore (undo) changes.
#  Language is detected automatically: Ukrainian Windows UI -> Ukrainian,
#  anything else -> English. Override for testing:  $env:GEHI_LANG = 'en' | 'uk'
#
#  Run in PowerShell as Administrator:
#     Set-ExecutionPolicy -Scope Process Bypass; .\WinGeHi.ps1
# =====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------
#  Language detection
# ---------------------------------------------------------------------
$Lang = if ($env:GEHI_LANG -in 'uk', 'en') { $env:GEHI_LANG }
        elseif ((Get-UICulture).TwoLetterISOLanguageName -eq 'uk') { 'uk' }
        else { 'en' }

$Strings = @{
    uk = @{
        'errAdmin'    = '[ПОМИЛКА] Запустіть цей скрипт від імені Адміністратора!'
        'pressEnter'  = 'Натисніть Enter для виходу'
        'choice'      = 'Ваш вибір [{0}]'
        'mainQ'       = 'Що ви хочете зробити?'
        'main1'       = '  [1] Оптимізація: застосувати налаштування'
        'main2'       = '  [2] Відновлення: скасувати зміни, зроблені раніше цим скриптом'
        'main3'       = '  [3] Вихід'
        'devQ'        = 'Виберіть тип пристрою:'
        'dev1'        = '  [1] Стаціонарний ПК'
        'dev2'        = '  [2] Ноутбук'
        'devPCName'   = 'ПК'
        'devLapName'  = 'Ноутбук'
        'methTitle'   = '   Спосіб налаштування'
        'meth1'       = '  [1] Автоматично: безпечний рекомендований набір'
        'meth2'       = '  [2] Вручну: відповідаєте Y/N на кожен пункт'
        'meth3'       = '  [3] GeHi: повний набір для ПК (усі 27 пунктів)'
        'meth4'       = '  [4] Вихід'
        'manualHint'  = 'Відповідайте Y [так] або N [ні]'
        'presetLap'   = 'Пресет GeHi призначений для ПК. На ноутбуці продовжити'
        'sacConfirm'  = 'Smart App Control вимикається НЕЗВОРОТНО. Підтвердити'
        'willApply'   = 'Буде застосовано:'
        'baseList'    = '  - базові налаштування (миша/клавіатура, телеметрія, Bing-пошук, Game DVR)'
        'pcList'      = '  - ПК: план Ultimate Performance, USB/енергозбереження, гібернація вимк., таймер ядра'
        'cont'        = 'Продовжити'
        'logHeader'   = 'WinGeHi, запуск {0}'
        'startLog'    = 'Запуск оптимізації. Пристрій: {0}, режим: {1}'
        'warnReg'     = '  [!] Не вдалося записати {0}\{1} : {2}'
        'svcOff'      = '  служба {0} вимкнена'
        'warnSvc'     = '  [!] Служба {0}: {1}'
        'warnStep'    = '  [!] Помилка: {0}'
        'sBackup'     = 'Резервні копії реєстру та BCD'
        'sInput'      = 'Введення: без акселерації миші, швидка клавіатура'
        'sBase'       = 'Пошук, телеметрія, Game DVR, мережевий тротлінг'
        'sPC'         = 'ПК: живлення, USB, гібернація, таймер'
        'cleanSkip'   = '  [!] Скрипт лежить у папці Temp. Очистку пропущено, щоб не видалити бекап і лог.'
        'adapter'     = '  адаптер {0}'
        'ramSkip'     = '  [!] RAM {0} ГБ (<16): DisablePagingExecutive і вимкнення стиснення пам''яті пропущено.'
        'printerFound'= '  [!] Знайдено принтери ({0}). Диспетчер друку не чіпаю.'
        'done'        = "   ГОТОВО! ПЕРЕЗАВАНТАЖТЕ КОМП'ЮТЕР"
        'logLine'     = 'Лог:             {0}'
        'backupLine'  = 'Папка відкату:   {0}'
        'undoHint'    = 'Відкат змін:     запустіть цей скрипт знову і виберіть [2] Відновлення'
        'notUndoable' = 'Не відкочується: Smart App Control, очистка Temp/WinSxS.'
        'noBackups'   = 'Не знайдено жодної папки Backup_* з файлом undo.csv (шукав у: {0}).'
        'avail'       = 'Доступні резервні копії (новіші зверху):'
        'whichUndo'   = 'Яку відкотити? [Enter = найновішу]'
        'undoing'     = 'Відкат {0} записів із {1} ...'
        'uReg'        = 'реєстр: {0}\{1}'
        'uKey'        = 'ключ видалено: {0}'
        'uSvc'        = 'служба: {0} -> {1}'
        'uTask'       = 'завдання увімкнено: {0}'
        'uHib'        = 'гібернацію увімкнено'
        'uTick'       = 'dynamic tick повернуто'
        'uPlan'       = 'план живлення повернуто: {0}'
        'uMM'         = 'стиснення пам''яті увімкнено'
        'uNet'        = 'енергозбереження адаптера: {0}'
        'uWmi'        = 'енергозбереження пристроїв повернуто'
        'smbAsk'      = 'SMBv1 небезпечний. Справді увімкнути знову'
        'smbOn'       = 'SMBv1 увімкнено'
        'smbKeep'     = 'SMBv1 залишено вимкненим'
        'uWarn'       = '  [!] {0} {1} {2}: {3}'
        'undoDone'    = "Готово. Перезавантажте комп'ютер."
        'undoNot'     = 'Не відкочується: Smart App Control (лише перевстановлення Windows), очистка Temp/WinSxS.'
        'undoFiles'   = 'Резервні .reg-файли (миша, клавіатура, Desktop, DeviceGuard) та bcd.bak лежать у {0}'

        's_RP'        = 'Створення точки відновлення'
        's_CTX'       = 'Класичне контекстне меню'
        's_HVCI'      = 'Вимкнення VBS/HVCI'
        's_SAC'       = 'Вимкнення Smart App Control (незворотно)'
        's_FAST'      = 'Швидкий інтерфейс'
        's_EDGE'      = 'Edge: без фонової роботи'
        's_CLEAN'     = 'Очистка Temp та DNS-кешу'
        's_QOL'       = 'Зручності: End Task, секунди, NumLock'
        's_TIMER'     = 'Глобальний точний таймер'
        's_DRV'       = 'Заборона драйверів через Windows Update'
        's_NETPM'     = 'Енергозбереження мережевих адаптерів'
        's_HARD'      = 'Безпека мережі: RDP і SMBv1'
        's_FS'        = 'NTFS: без оновлення часу останнього доступу'
        's_EXPL'      = 'Провідник'
        's_SXS'       = 'Очистка WinSxS (зачекайте)'
        's_ESPORTS'   = 'Кіберспортивні твіки'
        's_VISUAL'    = 'Легкі візуальні ефекти'
        's_BG'        = 'Заборона фонових програм'
        's_SERV'      = 'Вимкнення зайвих служб'
        's_INDEX'     = 'Вимкнення індексації (WSearch)'
        's_PRINT'     = 'Вимкнення диспетчера друку'
        's_UI'        = 'Реклама, поради, Widgets, Copilot'
        's_SECNOTIFY' = 'Сповіщення Центру безпеки'
        's_MAINT'     = 'Автоматичне обслуговування'
        's_UCPD'      = 'Вимкнення UCPD (діє після перезавантаження)'
        's_SMARTSCREEN' = 'Вимкнення SmartScreen'
        's_MANUALWU'  = 'Оновлення Windows вручну'

        'q_RP'        = 'Створити точку відновлення'
        'q_CTX'       = 'Класичне контекстне меню (як у Windows 10)'
        'q_HVCI'      = 'Вимкнути ізоляцію ядра VBS/HVCI  [ЗНИЖУЄ БЕЗПЕКУ]'
        'q_SAC'       = 'Вимкнути Smart App Control  [НЕЗВОРОТНО без перевстановлення Windows]'
        'q_FAST'      = 'Швидкий інтерфейс (без затримки меню, швидше закриття програм)'
        'q_EDGE'      = 'Вимкнути фонову роботу й Startup Boost у Edge'
        'q_CLEAN'     = 'Очистити Temp і DNS-кеш'
        'q_QOL'       = 'Зручності: End Task на панелі завдань, секунди в годиннику, NumLock'
        'q_TIMER'     = 'Глобальний точний таймер (трохи більше споживання)'
        'q_DRV'       = 'Заборонити встановлення драйверів через Windows Update'
        'q_NETPM'     = 'Вимкнути енергозбереження мережевих адаптерів'
        'q_HARD'      = 'Безпека мережі: вимкнути RDP і SMBv1'
        'q_FS'        = 'NTFS: не оновлювати час останнього доступу до файлів'
        'q_EXPL'      = 'Провідник: приховані файли, розширення, відкривати "Цей ПК"'
        'q_SXS'       = 'Очистити сховище компонентів WinSxS (може тривати кілька хвилин)'
        'q_ESPORTS'   = 'Кіберспорт: MPO вимк., DisablePagingExecutive, без стиснення пам''яті (потрібно 16+ ГБ RAM)'
        'q_VISUAL'    = 'Легкі візуальні ефекти (без анімацій і прозорості)'
        'q_BG'        = 'Заборонити фонову роботу програм'
        'q_SERV'      = 'Вимкнути зайві служби (карти, факс, демо-режим, віддалений реєстр, геолокація)'
        'q_INDEX'     = 'Вимкнути індексацію пошуку Windows Search (пошук стане повільнішим)'
        'q_PRINT'     = 'Вимкнути диспетчер друку (лише якщо немає принтерів)'
        'q_UI'        = 'Прибрати рекламу в Пуску, поради, Widgets і Copilot'
        'q_SECNOTIFY' = 'Вимкнути сповіщення Центру безпеки (сам захист лишається)'
        'q_MAINT'     = 'Вимкнути автоматичне обслуговування Windows'
        'q_UCPD'      = 'Вимкнути UCPD (дозволяє утилітам міняти браузер за замовчуванням)'
        'q_SMARTSCREEN' = 'Вимкнути SmartScreen  [ЗНИЖУЄ БЕЗПЕКУ]'
        'q_MANUALWU'  = 'Оновлення Windows вручну  [самі стежте за оновленнями безпеки]'
    }
    en = @{
        'errAdmin'    = '[ERROR] Please run this script as Administrator!'
        'pressEnter'  = 'Press Enter to exit'
        'choice'      = 'Your choice [{0}]'
        'mainQ'       = 'What would you like to do?'
        'main1'       = '  [1] Optimize: apply tweaks'
        'main2'       = '  [2] Restore: undo changes previously made by this script'
        'main3'       = '  [3] Exit'
        'devQ'        = 'Select device type:'
        'dev1'        = '  [1] Desktop PC'
        'dev2'        = '  [2] Laptop'
        'devPCName'   = 'PC'
        'devLapName'  = 'Laptop'
        'methTitle'   = '   Setup method'
        'meth1'       = '  [1] Automatic: safe recommended set'
        'meth2'       = '  [2] Manual: answer Y/N for each item'
        'meth3'       = '  [3] GeHi: full desktop preset (all 27 items)'
        'meth4'       = '  [4] Exit'
        'manualHint'  = 'Answer Y [yes] or N [no]'
        'presetLap'   = 'The GeHi preset is designed for desktop PCs. Continue on a laptop'
        'sacConfirm'  = 'Smart App Control will be disabled PERMANENTLY. Confirm'
        'willApply'   = 'The following will be applied:'
        'baseList'    = '  - base tweaks (mouse/keyboard, telemetry, Bing search, Game DVR)'
        'pcList'      = '  - PC: Ultimate Performance power plan, USB/device power saving off, hibernation off, kernel timer'
        'cont'        = 'Continue'
        'logHeader'   = 'WinGeHi, started {0}'
        'startLog'    = 'Starting optimization. Device: {0}, mode: {1}'
        'warnReg'     = '  [!] Failed to write {0}\{1} : {2}'
        'svcOff'      = '  service {0} disabled'
        'warnSvc'     = '  [!] Service {0}: {1}'
        'warnStep'    = '  [!] Error: {0}'
        'sBackup'     = 'Registry and BCD backups'
        'sInput'      = 'Input: no mouse acceleration, fast keyboard'
        'sBase'       = 'Search, telemetry, Game DVR, network throttling'
        'sPC'         = 'PC: power, USB, hibernation, timer'
        'cleanSkip'   = '  [!] The script is located in a Temp folder. Cleanup skipped to avoid deleting the backup and log.'
        'adapter'     = '  adapter {0}'
        'ramSkip'     = '  [!] RAM {0} GB (<16): DisablePagingExecutive and memory compression changes skipped.'
        'printerFound'= '  [!] Printers found ({0}). Print Spooler left untouched.'
        'done'        = '   DONE! PLEASE RESTART YOUR COMPUTER'
        'logLine'     = 'Log:             {0}'
        'backupLine'  = 'Undo folder:     {0}'
        'undoHint'    = 'To undo changes: run this script again and choose [2] Restore'
        'notUndoable' = 'Not undoable:    Smart App Control, Temp/WinSxS cleanup.'
        'noBackups'   = 'No Backup_* folder containing undo.csv was found (searched in: {0}).'
        'avail'       = 'Available backups (newest first):'
        'whichUndo'   = 'Which one to restore? [Enter = newest]'
        'undoing'     = 'Restoring {0} entries from {1} ...'
        'uReg'        = 'registry: {0}\{1}'
        'uKey'        = 'key removed: {0}'
        'uSvc'        = 'service: {0} -> {1}'
        'uTask'       = 'task enabled: {0}'
        'uHib'        = 'hibernation enabled'
        'uTick'       = 'dynamic tick restored'
        'uPlan'       = 'power plan restored: {0}'
        'uMM'         = 'memory compression enabled'
        'uNet'        = 'adapter power saving: {0}'
        'uWmi'        = 'device power saving restored'
        'smbAsk'      = 'SMBv1 is insecure. Really re-enable it'
        'smbOn'       = 'SMBv1 enabled'
        'smbKeep'     = 'SMBv1 left disabled'
        'uWarn'       = '  [!] {0} {1} {2}: {3}'
        'undoDone'    = 'Done. Please restart your computer.'
        'undoNot'     = 'Not undoable: Smart App Control (only by reinstalling Windows), Temp/WinSxS cleanup.'
        'undoFiles'   = 'Backup .reg files (mouse, keyboard, Desktop, DeviceGuard) and bcd.bak are in {0}'

        's_RP'        = 'Creating a restore point'
        's_CTX'       = 'Classic context menu'
        's_HVCI'      = 'Disabling VBS/HVCI'
        's_SAC'       = 'Disabling Smart App Control (irreversible)'
        's_FAST'      = 'Snappy UI'
        's_EDGE'      = 'Edge: no background activity'
        's_CLEAN'     = 'Cleaning Temp and DNS cache'
        's_QOL'       = 'Quality of life: End Task, clock seconds, NumLock'
        's_TIMER'     = 'Global high-resolution timer'
        's_DRV'       = 'Blocking drivers via Windows Update'
        's_NETPM'     = 'Network adapter power saving'
        's_HARD'      = 'Network hardening: RDP and SMBv1'
        's_FS'        = 'NTFS: no last-access time updates'
        's_EXPL'      = 'File Explorer'
        's_SXS'       = 'Cleaning WinSxS (please wait)'
        's_ESPORTS'   = 'Esports tweaks'
        's_VISUAL'    = 'Light visual effects'
        's_BG'        = 'Blocking background apps'
        's_SERV'      = 'Disabling unneeded services'
        's_INDEX'     = 'Disabling indexing (WSearch)'
        's_PRINT'     = 'Disabling Print Spooler'
        's_UI'        = 'Ads, tips, Widgets, Copilot'
        's_SECNOTIFY' = 'Security Center notifications'
        's_MAINT'     = 'Automatic maintenance'
        's_UCPD'      = 'Disabling UCPD (takes effect after reboot)'
        's_SMARTSCREEN' = 'Disabling SmartScreen'
        's_MANUALWU'  = 'Manual Windows Update'

        'q_RP'        = 'Create a system restore point'
        'q_CTX'       = 'Classic context menu (Windows 10 style)'
        'q_HVCI'      = 'Disable core isolation VBS/HVCI  [LOWERS SECURITY]'
        'q_SAC'       = 'Disable Smart App Control  [IRREVERSIBLE without reinstalling Windows]'
        'q_FAST'      = 'Snappy UI (no menu delay, faster app shutdown)'
        'q_EDGE'      = 'Disable Edge background activity and Startup Boost'
        'q_CLEAN'     = 'Clean Temp folders and DNS cache'
        'q_QOL'       = 'Quality of life: End Task on taskbar, seconds in clock, NumLock on boot'
        'q_TIMER'     = 'Global high-resolution timer (slightly higher power use)'
        'q_DRV'       = 'Block driver installs via Windows Update'
        'q_NETPM'     = 'Disable power saving on network adapters'
        'q_HARD'      = 'Network hardening: disable RDP and SMBv1'
        'q_FS'        = 'NTFS: stop updating last-access timestamps'
        'q_EXPL'      = 'File Explorer: show hidden files and extensions, open "This PC"'
        'q_SXS'       = 'Clean up the WinSxS component store (may take several minutes)'
        'q_ESPORTS'   = 'Esports: MPO off, DisablePagingExecutive, no memory compression (16+ GB RAM required)'
        'q_VISUAL'    = 'Light visual effects (no animations or transparency)'
        'q_BG'        = 'Block background apps'
        'q_SERV'      = 'Disable unneeded services (maps, fax, retail demo, remote registry, geolocation)'
        'q_INDEX'     = 'Disable Windows Search indexing (search becomes slower)'
        'q_PRINT'     = 'Disable Print Spooler (only if you have no printers)'
        'q_UI'        = 'Remove Start menu ads, tips, Widgets and Copilot'
        'q_SECNOTIFY' = 'Disable Security Center notifications (protection stays on)'
        'q_MAINT'     = 'Disable automatic Windows maintenance'
        'q_UCPD'      = 'Disable UCPD (lets tools change the default browser)'
        'q_SMARTSCREEN' = 'Disable SmartScreen  [LOWERS SECURITY]'
        'q_MANUALWU'  = 'Manual Windows Update  [you must watch for security updates yourself]'
    }
}

# Translate a key; extra arguments are used with the -f format operator
function Tr([string]$Key) {
    $s = $Strings[$Lang][$Key]
    if ($null -eq $s) { $s = $Strings['en'][$Key] }
    if ($null -eq $s) { return $Key }
    if ($args.Count -gt 0) { return ($s -f $args) }
    return $s
}

function Ask-YN([string]$Text) {
    $a = Read-Host "$Text [Y/N]"
    return ($a -match '^[YyТт]')
}

function Info([string]$m, [string]$c = 'Gray') { Write-Host $m -ForegroundColor $c }

# ---------------------------------------------------------------------
#  Administrator check
# ---------------------------------------------------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host (Tr 'errAdmin') -ForegroundColor Red
    Read-Host (Tr 'pressEnter') | Out-Null
    Exit
}

# Where logs and backups live: next to the script; when run via "irm | iex"
# there is no script folder, so use ProgramData instead of the current folder.
$DataDir    = Join-Path $env:ProgramData 'WinGeHi'
$LegacyDir  = Join-Path $env:ProgramData 'GeHi-Optimizer'   # backups made before the rename
$Root       = if ($PSScriptRoot) { $PSScriptRoot } else { $DataDir }
$SearchDirs = @($Root, $DataDir, $LegacyDir) | Select-Object -Unique

# ---------------------------------------------------------------------
#  Main menu
# ---------------------------------------------------------------------
Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "   WinGeHi" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host (Tr 'mainQ') -ForegroundColor Yellow
Write-Host (Tr 'main1')
Write-Host (Tr 'main2')
Write-Host (Tr 'main3')
Write-Host ""
do { $Action = Read-Host (Tr 'choice' '1-3') } until ($Action -in '1', '2', '3')
if ($Action -eq '3') { Exit }

if ($Action -eq '1') {
    # =================================================================
    #  OPTIMIZE
    # =================================================================
    $TS        = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogPath   = Join-Path $Root "Optimization_log_$TS.txt"
    $BackupDir = Join-Path $Root "Backup_$TS"
    $UndoPath  = Join-Path $BackupDir "undo.csv"
    $GuidRx    = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    # ---------------------------------------------------------------
    #  Helper functions
    # ---------------------------------------------------------------
    function Log([string]$Msg, [string]$Color = 'Gray') {
        Write-Host $Msg -ForegroundColor $Color
        Add-Content -Path $LogPath -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Msg) -Encoding UTF8
    }

    function Add-Undo([string]$Type, [string]$Target, [string]$Name = '', [string]$Kind = '', [string]$Old = '') {
        [pscustomobject]@{ Type = $Type; Target = $Target; Name = $Name; Kind = $Kind; Old = $Old } |
            Export-Csv -Path $UndoPath -Append -NoTypeInformation -Encoding UTF8
    }

    # Write a registry value and remember the old one for the undo journal
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
            Log (Tr 'warnReg' $Path $Name ($_.Exception.Message)) 'DarkYellow'
        }
    }

    # Disable a service and remember its previous start type
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
            Log (Tr 'svcOff' $Name)
        } catch {
            Log (Tr 'warnSvc' $Name ($_.Exception.Message)) 'DarkYellow'
        }
    }

    function Do-Step([string]$Key, [scriptblock]$Code) {
        if ($T[$Key] -ne 1) { return }
        Log "> $(Tr "s_$Key")" 'Cyan'
        try { & $Code } catch { Log (Tr 'warnStep' ($_.Exception.Message)) 'Red' }
    }

    (Tr 'logHeader' $TS) | Out-File -FilePath $LogPath -Encoding utf8

    # ---------------------------------------------------------------
    #  Device type and setup method
    # ---------------------------------------------------------------
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "   WinGeHi" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host (Tr 'devQ') -ForegroundColor Yellow
    Write-Host (Tr 'dev1')
    Write-Host (Tr 'dev2')
    Write-Host ""
    do { $DeviceChoice = Read-Host (Tr 'choice' '1-2') } until ($DeviceChoice -in '1', '2')
    $IsPC = ($DeviceChoice -eq '1')

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host (Tr 'methTitle') -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host (Tr 'meth1')
    Write-Host (Tr 'meth2')
    Write-Host (Tr 'meth3')
    Write-Host (Tr 'meth4')
    Write-Host ""
    do { $Method = Read-Host (Tr 'choice' '1-4') } until ($Method -in '1', '2', '3', '4')
    if ($Method -eq '4') { Exit }

    # K = key, D = default in automatic mode, PC = desktop PCs only
    $Items = @(
        @{ K='RP';          D=1; PC=$false },
        @{ K='CTX';         D=0; PC=$false },
        @{ K='HVCI';        D=0; PC=$false },
        @{ K='SAC';         D=0; PC=$false },
        @{ K='FAST';        D=0; PC=$false },
        @{ K='EDGE';        D=1; PC=$false },
        @{ K='CLEAN';       D=1; PC=$false },
        @{ K='QOL';         D=1; PC=$false },
        @{ K='TIMER';       D=0; PC=$true  },
        @{ K='DRV';         D=1; PC=$false },
        @{ K='NETPM';       D=1; PC=$true  },
        @{ K='HARD';        D=1; PC=$false },
        @{ K='FS';          D=1; PC=$false },
        @{ K='EXPL';        D=0; PC=$false },
        @{ K='SXS';         D=0; PC=$false },
        @{ K='ESPORTS';     D=0; PC=$false },
        @{ K='VISUAL';      D=0; PC=$false },
        @{ K='BG';          D=0; PC=$false },
        @{ K='SERV';        D=0; PC=$false },
        @{ K='INDEX';       D=0; PC=$false },
        @{ K='PRINT';       D=0; PC=$false },
        @{ K='UI';          D=0; PC=$false },
        @{ K='SECNOTIFY';   D=0; PC=$false },
        @{ K='MAINT';       D=0; PC=$false },
        @{ K='UCPD';        D=0; PC=$false },
        @{ K='SMARTSCREEN'; D=0; PC=$false },
        @{ K='MANUALWU';    D=0; PC=$false }
    )
    foreach ($i in $Items) { $i.Q = Tr "q_$($i.K)" }

    $T = @{}
    foreach ($i in $Items) { $T[$i.K] = 0 }

    switch ($Method) {
        '1' {
            foreach ($i in $Items) { if (-not ($i.PC -and -not $IsPC)) { $T[$i.K] = $i.D } }
        }
        '3' {
            if (-not $IsPC -and -not (Ask-YN (Tr 'presetLap'))) { Exit }
            foreach ($i in $Items) { if (-not ($i.PC -and -not $IsPC)) { $T[$i.K] = 1 } }
        }
        '2' {
            Clear-Host
            Write-Host (Tr 'manualHint') -ForegroundColor Cyan
            $n = 0
            foreach ($i in $Items) {
                if ($i.PC -and -not $IsPC) { continue }
                $n++
                $T[$i.K] = if (Ask-YN "$n. $($i.Q)") { 1 } else { 0 }
            }
        }
    }

    if ($T.SAC -eq 1) {
        if (-not (Ask-YN (Tr 'sacConfirm'))) { $T.SAC = 0 }
    }

    Clear-Host
    Write-Host (Tr 'willApply') -ForegroundColor Yellow
    Write-Host (Tr 'baseList')
    if ($IsPC) { Write-Host (Tr 'pcList') }
    foreach ($i in $Items) { if ($T[$i.K] -eq 1) { Write-Host "  - $($i.Q)" } }
    Write-Host ""
    if (-not (Ask-YN (Tr 'cont'))) { Exit }

    Clear-Host
    Log (Tr 'startLog' $(if ($IsPC) { Tr 'devPCName' } else { Tr 'devLapName' }) $Method) 'Yellow'

    # ---------------------------------------------------------------
    #  Restore point and backups
    # ---------------------------------------------------------------
    Do-Step 'RP' {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0 -NoUndo
        Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WinGeHi before optimization" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    }

    Log "> $(Tr 'sBackup')" 'Cyan'
    reg export "HKCU\Control Panel\Mouse"    "$BackupDir\Mouse.reg"      /y >$null 2>&1
    reg export "HKCU\Control Panel\Keyboard" "$BackupDir\Keyboard.reg"   /y >$null 2>&1
    reg export "HKCU\Control Panel\Desktop"  "$BackupDir\Desktop.reg"    /y >$null 2>&1
    reg export "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "$BackupDir\DeviceGuard.reg" /y >$null 2>&1
    bcdedit /export "$BackupDir\bcd.bak" >$null 2>&1

    # ---------------------------------------------------------------
    #  Base tweaks (always applied)
    # ---------------------------------------------------------------
    Log "> $(Tr 'sInput')" 'Cyan'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' -Kind String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' -Kind String

    Log "> $(Tr 'sBase')" 'Cyan'
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

    # ---------------------------------------------------------------
    #  Desktop PC only
    # ---------------------------------------------------------------
    if ($IsPC) {
        Log "> $(Tr 'sPC')" 'Cyan'
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

    # ---------------------------------------------------------------
    #  Selected items
    # ---------------------------------------------------------------
    Do-Step 'CTX' {
        $clsid = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
        if (-not (Test-Path -LiteralPath $clsid)) {
            Add-Undo 'regkey' $clsid
            New-Item -Path "$clsid\InprocServer32" -Force | Out-Null
            Set-ItemProperty -LiteralPath "$clsid\InprocServer32" -Name '(default)' -Value '' -ErrorAction SilentlyContinue
        }
    }

    Do-Step 'HVCI' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
    }

    Do-Step 'SAC' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' 'VerifiedAndReputablePolicyState' 0 -NoUndo
    }

    Do-Step 'FAST' {
        Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' -Kind String
        Set-Reg 'HKCU:\Control Panel\Desktop' 'WaitToKillAppTimeout' '2000' -Kind String
    }

    Do-Step 'EDGE' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0
    }

    Do-Step 'CLEAN' {
        $tmp = [string]$env:TEMP
        $wt  = "$env:SystemRoot\Temp"
        if ($Root.StartsWith($tmp, [StringComparison]::OrdinalIgnoreCase) -or $Root.StartsWith($wt, [StringComparison]::OrdinalIgnoreCase)) {
            Log (Tr 'cleanSkip') 'DarkYellow'
        } else {
            Remove-Item "$tmp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "$wt\*"  -Recurse -Force -ErrorAction SilentlyContinue
        }
        ipconfig /flushdns | Out-Null
    }

    Do-Step 'QOL' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 1
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemTray' 1
        Set-Reg 'HKCU:\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' -Kind String
        Set-Reg 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' -Kind String
    }

    Do-Step 'TIMER' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
    }

    Do-Step 'DRV' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate' 1
    }

    Do-Step 'NETPM' {
        Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Disable-NetAdapterPowerManagement -Name $_.Name -NoRestart -ErrorAction Stop
                Add-Undo 'action' 'netpm' $_.Name
                Log (Tr 'adapter' $_.Name)
            } catch { }
        }
    }

    Do-Step 'HARD' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections' 1
        $f = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($f -and $f.State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Add-Undo 'action' 'smb1_on'
        }
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
    }

    Do-Step 'FS' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 1
    }

    Do-Step 'EXPL' {
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-Reg $adv 'Hidden' 1
        Set-Reg $adv 'HideFileExt' 0
        Set-Reg $adv 'LaunchTo' 1
    }

    Do-Step 'SXS' {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
    }

    Do-Step 'ESPORTS' {
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
            Log (Tr 'ramSkip' $ram) 'DarkYellow'
        }
    }

    Do-Step 'VISUAL' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
        Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' -Kind String
        Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    }

    Do-Step 'BG' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
    }

    Do-Step 'SERV' {
        foreach ($s in 'MapsBroker', 'Fax', 'RetailDemo', 'RemoteRegistry', 'lfsvc', 'WMPNetworkSvc') { Disable-Svc $s }
    }

    Do-Step 'INDEX' {
        Disable-Svc 'WSearch'
    }

    Do-Step 'PRINT' {
        $real = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'PDF|XPS|OneNote|Fax' })
        if ($real.Count -gt 0) {
            Log (Tr 'printerFound' ($real.Name -join ', ')) 'DarkYellow'
        } else {
            Disable-Svc 'Spooler'
        }
    }

    Do-Step 'UI' {
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

    Do-Step 'SECNOTIFY' {
        $p = 'HKLM:\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications'
        Set-Reg $p 'DisableNotifications' 1
        Set-Reg $p 'DisableEnhancedNotifications' 1
    }

    Do-Step 'MAINT' {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance' 'MaintenanceDisabled' 1
    }

    Do-Step 'UCPD' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\UCPD' 'Start' 4
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\AppxDeployment\' -TaskName 'UCPD velocity' -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne 'Disabled') {
            Add-Undo 'task' '\Microsoft\Windows\AppxDeployment\' 'UCPD velocity'
            Disable-ScheduledTask -InputObject $task | Out-Null
        }
    }

    Do-Step 'SMARTSCREEN' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen' 0
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'Off' -Kind String
    }

    Do-Step 'MANUALWU' {
        $au = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        Set-Reg $au 'NoAutoUpdate' 0
        Set-Reg $au 'AUOptions' 2
    }

    # ---------------------------------------------------------------
    Log ""
    Log "====================================================" 'Green'
    Log (Tr 'done') 'Green'
    Log "====================================================" 'Green'
    Log (Tr 'logLine' $LogPath) 'Yellow'
    Log (Tr 'backupLine' $BackupDir) 'Yellow'
    Log (Tr 'undoHint') 'Yellow'
    Log (Tr 'notUndoable') 'Yellow'
    Read-Host (Tr 'pressEnter') | Out-Null
}
else {
    # =================================================================
    #  RESTORE (UNDO)
    # =================================================================
    $folders = @(Get-ChildItem -Path $SearchDirs -Directory -Filter 'Backup_*' -ErrorAction SilentlyContinue |
                 Where-Object { Test-Path (Join-Path $_.FullName 'undo.csv') } |
                 Sort-Object Name -Descending)
    if ($folders.Count -eq 0) {
        Write-Host (Tr 'noBackups' ($SearchDirs -join ', ')) -ForegroundColor Red
        Read-Host (Tr 'pressEnter') | Out-Null
        Exit
    }

    Write-Host (Tr 'avail') -ForegroundColor Yellow
    for ($k = 0; $k -lt $folders.Count; $k++) { Write-Host ("  [{0}] {1}" -f ($k + 1), $folders[$k].FullName) }
    $sel = Read-Host (Tr 'whichUndo')
    $idx = 0
    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $folders.Count) { $idx = [int]$sel - 1 }
    $Dir = $folders[$idx].FullName
    $UndoPath = Join-Path $Dir 'undo.csv'

    $rows = @(Import-Csv -Path $UndoPath -Encoding UTF8)
    [array]::Reverse($rows)   # undo in reverse order
    Write-Host (Tr 'undoing' $rows.Count $Dir) -ForegroundColor Cyan

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
                    Info (Tr 'uReg' $r.Target $r.Name)
                }

                'regkey' {
                    Remove-Item -LiteralPath $r.Target -Recurse -Force -ErrorAction SilentlyContinue
                    Info (Tr 'uKey' $r.Target)
                }

                'service' {
                    switch ($r.Old) {
                        'AutomaticDelayed' { sc.exe config $r.Target start= delayed-auto | Out-Null }
                        'Automatic'        { Set-Service -Name $r.Target -StartupType Automatic -ErrorAction Stop }
                        'Manual'           { Set-Service -Name $r.Target -StartupType Manual -ErrorAction Stop }
                        default            { }
                    }
                    Info (Tr 'uSvc' $r.Target $r.Old)
                }

                'task' {
                    Enable-ScheduledTask -TaskPath $r.Target -TaskName $r.Name -ErrorAction Stop | Out-Null
                    Info (Tr 'uTask' $r.Name)
                }

                'action' {
                    switch ($r.Target) {
                        'hibernate_on' { powercfg /hibernate on; Info (Tr 'uHib') }
                        'dynamictick'  { bcdedit /deletevalue disabledynamictick 2>$null | Out-Null; Info (Tr 'uTick') }
                        'powerplan'    { powercfg /setactive $r.Old; Info (Tr 'uPlan' $r.Old) }
                        'mmagent_on'   { Enable-MMAgent -MemoryCompression -ErrorAction Stop; Info (Tr 'uMM') }
                        'netpm'        { Enable-NetAdapterPowerManagement -Name $r.Name -NoRestart -ErrorAction Stop; Info (Tr 'uNet' $r.Name) }
                        'wmi_power_on' {
                            Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue | ForEach-Object {
                                $_.Enable = $true
                                Set-CimInstance -InputObject $_ -ErrorAction SilentlyContinue
                            }
                            Info (Tr 'uWmi')
                        }
                        'smb1_on' {
                            if (Ask-YN (Tr 'smbAsk')) {
                                Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                                Info (Tr 'smbOn')
                            } else { Info (Tr 'smbKeep') }
                        }
                    }
                }
            }
        } catch {
            Write-Host (Tr 'uWarn' $r.Type $r.Target $r.Name ($_.Exception.Message)) -ForegroundColor DarkYellow
        }
    }

    Write-Host ""
    Write-Host (Tr 'undoDone') -ForegroundColor Green
    Write-Host (Tr 'undoNot') -ForegroundColor Yellow
    Write-Host (Tr 'undoFiles' $Dir) -ForegroundColor Yellow
    Read-Host (Tr 'pressEnter') | Out-Null
}

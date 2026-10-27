<div id="english"></div>
<p align="right">
  <b>🇬🇧 English</b> | <a href="#ukrainian">🇺🇦 Українська</a>
</p>

# 🚀 GeHi Windows 11 Optimizer

> An open-source PowerShell script that applies a set of well-known Windows 11 tweaks, **writes an undo journal for them**, and can roll the changes back. The console interface switches automatically between English and Ukrainian.

---

## ✨ Features

- **🔍 Transparent:** one readable `.ps1` file, no binaries, no installers. Read it before you run it.
- **🌐 Automatic language:** if the Windows display language is Ukrainian, the script speaks Ukrainian; for any other language it uses English.
- **↩️ Undo journal:** every registry value, service start type, scheduled task and system setting the script changes is recorded in `Backup_<timestamp>\undo.csv`. Run the script again and choose **Restore** to put it back.
- **🛡 Safety nets:** optional restore point, `.reg` backups of the mouse, keyboard, Desktop and DeviceGuard keys, a BCD export, and a full log of everything that was done.
- **🧩 27 optional tweaks** grouped by purpose, plus a small set of base tweaks. Pick them automatically, one by one, or use the full GeHi preset.
- **💻 Desktop / laptop aware:** power-related tweaks are applied only on desktop PCs.

> ⚠️ Some tweaks lower security or cannot be undone. They are clearly marked in the list below and in the script's prompts.

---

## 📥 Quick Start

Open **PowerShell as Administrator** and run:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; irm https://raw.githubusercontent.com/GeHixgod/GeHi-Win11-Optimizer/refs/heads/main/GeHi_Optimizer.ps1 | iex
```

When started this way there is no script folder, so logs and backups are stored in `C:\ProgramData\GeHi-Optimizer`.

**Prefer to review first?** Download `GeHi_Optimizer.ps1`, read it, then run it from an Administrator PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\GeHi_Optimizer.ps1
```

Logs and backups are then stored next to the script.

**Force a language** (for testing) by setting this before running: `$env:GEHI_LANG = 'en'` or `'uk'`.

---

## 🧭 How it works

1. **Main menu:** `[1] Optimize` · `[2] Restore` · `[3] Exit`.
2. **Optimize:** choose *Desktop PC* or *Laptop*, then a mode:
   - **Automatic:** a conservative recommended set (marked ✔ in the table).
   - **Manual:** you answer Y/N for every item.
   - **GeHi preset:** all 27 items (desktop-only items are skipped on laptops).
3. The script shows the full list of what will be applied and asks for confirmation.
4. **Restore:** pick one of the `Backup_*` folders (newest by default); changes are reverted in reverse order.

Restart your computer after optimizing or restoring.

---

## 🔧 What the script changes

### Base tweaks (always applied)

| Area | Change |
|---|---|
| Input | Mouse acceleration off, no keyboard repeat delay, maximum repeat rate |
| Search | Bing / web results in Start search off |
| Telemetry | `AllowTelemetry = 0` policy; `DiagTrack` and `dmwappushservice` services disabled. On Home/Pro editions Windows treats `0` as the minimum level, so telemetry is reduced, not fully removed |
| Gaming | Game DVR background recording off; multimedia network throttling off |

### Desktop PC only (always applied when you select *Desktop PC*)

USB selective suspend and device power management off, hibernation and Fast Startup off, **Ultimate Performance** power plan (falls back to High Performance), `disabledynamictick`, `Win32PrioritySeparation = 38`.

### Optional tweaks

✔ = enabled in **Automatic** mode. All items are enabled in the **GeHi preset**.

| # | Tweak | What it does | Auto | Note |
|--:|---|---|:-:|---|
| 1 | Restore point | Creates a system restore point before changes | ✔ | |
| 2 | Classic context menu | Brings back the Windows 10-style right-click menu | | |
| 3 | VBS / HVCI off | Disables virtualization-based security and memory integrity | | ⚠️ lowers security |
| 4 | Smart App Control off | Turns Smart App Control off | | ⛔ cannot be undone without reinstalling Windows |
| 5 | Snappy UI | No menu delay, apps are closed faster (2 s timeout) | | |
| 6 | Edge background | Disables Startup Boost and background mode via policy | ✔ | |
| 7 | Clean Temp | Empties user and Windows `Temp` folders, flushes DNS cache | ✔ | not undoable |
| 8 | Quality of life | End Task on taskbar, seconds in the clock, NumLock on at sign-in | ✔ | |
| 9 | High-res timer | `GlobalTimerResolutionRequests` | | desktop only |
| 10 | Driver updates | Excludes drivers from Windows Update quality updates | ✔ | |
| 11 | Network adapter power saving | Disables power management on physical adapters | ✔ | desktop only |
| 12 | Network hardening | Disables incoming Remote Desktop and SMBv1 | ✔ | |
| 13 | NTFS last access | Stops updating the last-access timestamp | ✔ | |
| 14 | File Explorer | Shows hidden files and extensions, opens to "This PC" | | |
| 15 | WinSxS cleanup | `DISM /StartComponentCleanup` | | slow; not undoable |
| 16 | Esports | `SystemResponsiveness = 0`, MPO off; with **16+ GB RAM** also `DisablePagingExecutive` and memory compression off | | |
| 17 | Light visuals | No animations or transparency effects | | |
| 18 | Background apps | Blocks apps from running in the background | | |
| 19 | Extra services | Disables Maps, Fax, Retail Demo, Remote Registry, Geolocation and WMP Network services | | |
| 20 | Search indexing | Disables the Windows Search service | | search gets slower |
| 21 | Print Spooler | Disables it, **only if no real printer is installed** | | |
| 22 | Ads & UI clutter | Removes Start menu ads, suggestions and recommendations, Widgets and Copilot (via policy) | | |
| 23 | Security Center notifications | Hides notifications; protection itself stays on | | |
| 24 | Automatic maintenance | Disables scheduled Windows maintenance | | |
| 25 | UCPD | Disables the User Choice Protection Driver (lets tools change default apps) | | applies after reboot |
| 26 | SmartScreen off | Disables SmartScreen | | ⚠️ lowers security |
| 27 | Manual Windows Update | Windows notifies you before downloading/installing updates | | ⚠️ you must install security updates yourself |

---

## ↩️ Undo and limits

**Restore** reverts registry values, service start types, scheduled tasks, hibernation, the power plan, dynamic tick, memory compression, network adapter power saving and device power management. SMBv1 is re-enabled only if you confirm.

**Not undoable:** Smart App Control, Temp and WinSxS cleanup.

Notes:
- Mouse and keyboard settings are written to the profile of the user running the script. If you elevate with a different admin account, they will not apply to your own profile.
- Restart the PC after running the script or after a restore.

---

## 📋 Requirements

- Windows 11
- Windows PowerShell 5.1 (included in Windows)
- Administrator rights

## ⚠️ Disclaimer

The script changes system settings, including security-related ones. Use it at your own risk, read the confirmation list before continuing, and keep the restore point option enabled.

---
---

<div id="ukrainian"></div>
<p align="right">
  <a href="#english">🇬🇧 English</a> | <b>🇺🇦 Українська</b>
</p>

# 🚀 GeHi Windows 11 Optimizer

> Відкритий PowerShell-скрипт, який застосовує набір відомих твіків Windows 11, **веде журнал для відкату** і вміє скасовувати свої зміни. Консольний інтерфейс автоматично перемикається між українською та англійською.

---

## ✨ Особливості

- **🔍 Прозорість:** один читабельний `.ps1`-файл, без бінарників і інсталяторів. Прочитайте його перед запуском.
- **🌐 Автоматична мова:** якщо мова інтерфейсу Windows українська, скрипт говорить українською, для будь-якої іншої мови використовується англійська.
- **↩️ Журнал відкату:** кожне змінене значення реєстру, тип запуску служби, заплановане завдання та системне налаштування записується в `Backup_<час>\undo.csv`. Запустіть скрипт знову й оберіть **Відновлення**, щоб усе повернути.
- **🛡 Страховка:** необов'язкова точка відновлення, `.reg`-копії розділів миші, клавіатури, Desktop і DeviceGuard, експорт BCD та повний лог виконаних дій.
- **🧩 27 необов'язкових твіків** за призначенням плюс невеликий набір базових. Обирайте їх автоматично, по одному або повним пресетом GeHi.
- **💻 Враховує тип пристрою:** твіки живлення застосовуються лише на стаціонарних ПК.

> ⚠️ Деякі твіки знижують безпеку або не скасовуються. У списку нижче й у запитах скрипта вони чітко позначені.

---

## 📥 Швидкий запуск

Відкрийте **PowerShell від імені Адміністратора** і виконайте:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; irm https://raw.githubusercontent.com/GeHixgod/GeHi-Win11-Optimizer/refs/heads/main/GeHi_Optimizer.ps1 | iex
```

При такому запуску папки скрипта немає, тому лог і резервні копії зберігаються в `C:\ProgramData\GeHi-Optimizer`.

**Хочете спершу перевірити код?** Завантажте `GeHi_Optimizer.ps1`, прочитайте його й запустіть з PowerShell від імені Адміністратора:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\GeHi_Optimizer.ps1
```

Тоді лог і резервні копії зберігаються поруч зі скриптом.

**Примусова мова** (для тестів): перед запуском задайте `$env:GEHI_LANG = 'uk'` або `'en'`.

---

## 🧭 Як це працює

1. **Головне меню:** `[1] Оптимізація` · `[2] Відновлення` · `[3] Вихід`.
2. **Оптимізація:** оберіть *Стаціонарний ПК* або *Ноутбук*, потім режим:
   - **Автоматично:** обережний рекомендований набір (позначений ✔ у таблиці).
   - **Вручну:** відповідаєте Y/N на кожен пункт.
   - **Пресет GeHi:** усі 27 пунктів (пункти лише для ПК на ноутбуці пропускаються).
3. Скрипт показує повний список змін і просить підтвердження.
4. **Відновлення:** оберіть одну з папок `Backup_*` (за замовчуванням найновішу); зміни скасовуються у зворотному порядку.

Після оптимізації чи відновлення перезавантажте комп'ютер.

---

## 🔧 Що змінює скрипт

### Базові твіки (застосовуються завжди)

| Область | Зміна |
|---|---|
| Введення | Вимкнено акселерацію миші, без затримки повтору клавіш, максимальна швидкість повтору |
| Пошук | Вимкнено результати Bing/інтернету в пошуку Пуску |
| Телеметрія | Політика `AllowTelemetry = 0`; служби `DiagTrack` і `dmwappushservice` вимкнено. У версіях Home/Pro Windows сприймає `0` як мінімальний рівень, тож телеметрія зменшується, а не зникає повністю |
| Ігри | Вимкнено фоновий запис Game DVR та мережеве обмеження для мультимедіа |

### Лише стаціонарний ПК (застосовується завжди, якщо обрано *Стаціонарний ПК*)

Вимкнено USB selective suspend та енергозбереження пристроїв, гібернацію й швидкий запуск, увімкнено план живлення **Ultimate Performance** (якщо його немає, то «Висока продуктивність»), `disabledynamictick`, `Win32PrioritySeparation = 38`.

### Необов'язкові твіки

✔ = увімкнено в режимі **Автоматично**. У **пресеті GeHi** увімкнено всі.

| # | Твік | Що робить | Авто | Примітка |
|--:|---|---|:-:|---|
| 1 | Точка відновлення | Створює точку відновлення системи перед змінами | ✔ | |
| 2 | Класичне контекстне меню | Повертає меню правої кнопки як у Windows 10 | | |
| 3 | VBS / HVCI вимк. | Вимикає ізоляцію ядра на основі віртуалізації та цілісність пам'яті | | ⚠️ знижує безпеку |
| 4 | Smart App Control вимк. | Вимикає Smart App Control | | ⛔ незворотно без перевстановлення Windows |
| 5 | Швидкий інтерфейс | Без затримки меню, програми закриваються швидше (таймаут 2 с) | | |
| 6 | Фонова робота Edge | Вимикає Startup Boost і фоновий режим через політики | ✔ | |
| 7 | Очистка Temp | Очищає папки `Temp` користувача й Windows, скидає DNS-кеш | ✔ | не відкочується |
| 8 | Зручності | End Task на панелі завдань, секунди в годиннику, NumLock при вході | ✔ | |
| 9 | Точний таймер | `GlobalTimerResolutionRequests` | | лише ПК |
| 10 | Оновлення драйверів | Виключає драйвери з якісних оновлень Windows Update | ✔ | |
| 11 | Енергозбереження мережі | Вимикає керування живленням фізичних мережевих адаптерів | ✔ | лише ПК |
| 12 | Безпека мережі | Вимикає вхідні підключення віддаленого робочого столу (RDP) і SMBv1 | ✔ | |
| 13 | Час доступу NTFS | Припиняє оновлення часу останнього доступу до файлів | ✔ | |
| 14 | Провідник | Показує приховані файли й розширення, відкривається на «Цей ПК» | | |
| 15 | Очистка WinSxS | `DISM /StartComponentCleanup` | | повільно; не відкочується |
| 16 | Кіберспорт | `SystemResponsiveness = 0`, MPO вимк.; при **16+ ГБ RAM** ще `DisablePagingExecutive` і вимкнене стиснення пам'яті | | |
| 17 | Легкі ефекти | Без анімацій і ефектів прозорості | | |
| 18 | Фонові програми | Забороняє програмам працювати у фоні | | |
| 19 | Зайві служби | Вимикає служби Карт, Факсу, Retail Demo, Remote Registry, Геолокації та WMP Network | | |
| 20 | Індексація пошуку | Вимикає службу Windows Search | | пошук стає повільнішим |
| 21 | Диспетчер друку | Вимикає його **лише якщо немає жодного справжнього принтера** | | |
| 22 | Реклама й UI | Прибирає рекламу, пропозиції й рекомендації в Пуску, Widgets та Copilot (через політики) | | |
| 23 | Сповіщення Центру безпеки | Ховає сповіщення; сам захист лишається увімкненим | | |
| 24 | Автообслуговування | Вимикає заплановане обслуговування Windows | | |
| 25 | UCPD | Вимикає драйвер User Choice Protection (дозволяє утилітам міняти програми за замовчуванням) | | діє після перезавантаження |
| 26 | SmartScreen вимк. | Вимикає SmartScreen | | ⚠️ знижує безпеку |
| 27 | Оновлення вручну | Windows сповіщає перед завантаженням і встановленням оновлень | | ⚠️ оновлення безпеки встановлюєте самі |

---

## ↩️ Відкат і обмеження

**Відновлення** скасовує значення реєстру, типи запуску служб, заплановані завдання, гібернацію, план живлення, dynamic tick, стиснення пам'яті, енергозбереження мережевих адаптерів і керування живленням пристроїв. SMBv1 знову вмикається лише з вашого підтвердження.

**Не відкочується:** Smart App Control, очистка Temp і WinSxS.

Примітки:
- Налаштування миші й клавіатури записуються в профіль користувача, під яким запущено скрипт. Якщо підвищувати права іншим адміністратором, до вашого профілю вони не застосуються.
- Після запуску скрипта або відновлення перезавантажте ПК.

---

## 📋 Вимоги

- Windows 11
- Windows PowerShell 5.1 (входить до складу Windows)
- Права адміністратора

## ⚠️ Застереження

Скрипт змінює системні налаштування, зокрема пов'язані з безпекою. Користуйтеся на власний ризик, уважно читайте список змін перед підтвердженням і не вимикайте створення точки відновлення.

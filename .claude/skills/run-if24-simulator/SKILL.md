---
name: run-if24-simulator
description: Build, install and drive the IF24 iOS app on a simulator, and seed timer/review state to reach scenarios that would otherwise take 16 hours (goal reached, overtime, review prompt, prompt cap). Use when asked to run, launch, screenshot or manually verify IF24 behaviour on a simulator.
---

# Гонять IF24 на симуляторе

Проверено вживую 16.07.2026 на iPhone 17 Pro / iOS 26.4. Все грабли ниже - настоящие, каждая стоила времени.

## 1. DEVELOPER_DIR обязателен

`xcode-select` на этой машине смотрит в CommandLineTools, поэтому `xcrun simctl` **не находится** и падает с `unable to find utility "simctl"`. В каждой сессии:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Не чинить через `xcode-select -s` - это глобальная настройка машины, трогать её без спроса нельзя.

## 2. Сборка и установка

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SIM=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)   # или конкретный UDID
B=simple-L.if-app.com

xcodebuild -project IFApp.xcodeproj -scheme IFApp \
  -destination "platform=iOS Simulator,id=$SIM" \
  -derivedDataPath /tmp/if24-dd build

xcrun simctl install $SIM /tmp/if24-dd/Build/Products/Debug-iphonesimulator/IFApp.app
xcrun simctl launch $SIM $B
xcrun simctl io $SIM screenshot /tmp/shot.png
```

Схемы: `IFApp`, `IFAppUITests`, `Redux`. Bundle id - `simple-L.if-app.com` (НЕ `com.leonif.if24`).

## 3. Как засеять состояние (главная ловушка)

Апке нужно 16 часов, чтобы дойти до цели. Ждать не надо - состояние подменяется в UserDefaults. Но:

**`xcrun simctl spawn $SIM defaults write $B ключ значение` НЕ РАБОТАЕТ.** Он пишет в домен спавненного процесса, **мимо песочницы апки**. `defaults read` оттуда же покажет твои значения - и ты будешь час смотреть на фантомный plist, гадая, почему апка их игнорирует. Так и было.

Настоящие настройки лежат в контейнере:

```bash
C=$(xcrun simctl get_app_container $SIM $B data)
P="$C/Library/Preferences/$B.plist"
```

**Симулятор надо гасить целиком.** На живом симе `cfprefsd` держит plist в кэше и затирает твою правку своим содержимым - даже если апка убита через `terminate`, даже если убить `cfprefsd` до или после записи. Единственный надёжный порядок:

```bash
xcrun simctl shutdown $SIM; sleep 3
/usr/libexec/PlistBuddy -c "Set :start_timestamp $START" ... "$P"
sync
xcrun simctl boot $SIM; sleep 12
xcrun simctl launch $SIM $B
```

**Чтение plist отстаёт.** Апка пишет через cfprefsd с буферизацией: сразу после действия файл ещё старый. Либо подожди ~10с, либо `xcrun simctl terminate $SIM $B` - тогда флашится на диск.

**Контейнер меняется при переустановке.** Любой `xcodebuild test` или `simctl install` создаёт новый data-контейнер - путь из прошлого прогона протухает, и `PlistBuddy Set` молча пишет в пустоту («Does Not Exist» → создаёт пустой plist, апка стартует с нуля). Всегда бери путь заново через `get_app_container` и сей через `plutil -replace` (создаёт ключ, если его нет), а не `PlistBuddy Set`. Перед запуском **сверяй сид** через `plutil -p`.

## 4. Ключи UserDefaults

| Ключ | Смысл |
|---|---|
| `start_timestamp` | epoch-секунды старта поста |
| `is_running` | пост идёт |
| `has_celebrated` | момент goal-reached уже сыграл для текущего поста (защёлка) |
| `completed_sessions_count` | сколько постов дошло до цели - гейт промпта (порог 2) |
| `plan_idx` | план; `1` = 16:8 |
| `review_prompt_count` | сколько раз показывали шторку (потолок 3) |
| `review_last_shown` | дата последнего показа (не чаще раза в день) |
| `review_left` | тапнул «оценить» - жёсткий стоп навсегда |

## 5. Готовые сценарии

Все - в связке «shutdown → PlistBuddy → boot → launch».

**Цель взята, второй пост → должна вылезти шторка (без тапов):**
```
start_timestamp = now - 59400   # 16.5ч при цели 16ч
is_running = true
has_celebrated = false
completed_sessions_count = 1    # станет 2 в момент цели
удалить review_last_shown, review_left; review_prompt_count = 0
```
Ожидание: `count` → 2, через ~1.6с после момента появляется «Enjoying IF24?», `review_prompt_count` → 1.

**Потолок исчерпан → цель считаем, шторки нет:**
```
... то же, но completed_sessions_count = 2, review_prompt_count = 3
```
Ожидание: `count` → 3, шторки нет, `review_prompt_count` остался 3.

**Пост до цели → не считать, не звать:**
```
start_timestamp = now - 7200    # 2ч
completed_sessions_count = 5    # порог пройден, но цель не взята
review_prompt_count = 0
```
Ожидание: экран `.active`, шторки нет, `count` остался 5.

**Живое пересечение цели:** `start_timestamp = now - 57580` - цель наступит через ~20с после запуска, момент сыграет на глазах.

## 6. Тапать по экрану

`simctl` тапать не умеет. Тапает **Maestro** - флоу живут в отдельном репозитории `if24/maestro-flows` (`flows/*.yaml` + `run.sh`), каталог сценариев - `obs-if24-wiki/test-scenarios.md`.

**computer-use для тапов по апке не использовать.** Кликать по окну симулятора мышкой не нужно: это лезет на рабочий стол владельца, ломается от размера окна и не воспроизводится.

**Исключение - системные алерты (решение владельца 07.08.2026).** Там, где Maestro не дотягивается до системного диалога (разрешение на уведомления и прочие алерты iOS, нарисованные не апкой), закрывать его через computer-use, а потом возвращаться к Maestro. Правило узкое: computer-use берётся ровно на один тап по алерту, всё остальное - по-прежнему Maestro по `id`. Прежде чем тянуться к мышке, проверь, что дешёвый путь не работает: `-suppressPushPrompt` (DEBUG) вообще не даёт диалогу появиться, а `- tapOn: "Allow"` в начале флоу закрывает его штатно, когда Maestro его видит.

Разовый тап - минимальный флоу, сид приезжает launch-аргументами (см. `UITestSeed.swift`), без plist-хирургии и ребутов:

```yaml
appId: simple-L.if-app.com
---
- launchApp:
    arguments: { "-seedElapsed": 59400, "-seedCelebrated": 1 }
- tapOn: { id: "timer.reset" }
- assertVisible: "Reset this fast?"
- takeScreenshot: my_check
```

Запуск - через `run.sh` (он сам поднимает `DEVELOPER_DIR`, `JAVA_HOME`, находит UDID и складывает скриншоты в temp-каталог):

```bash
/Users/leonid/Documents/if24/maestro-flows/run.sh C5_reset_confirm_keep
```

Тапать по `id` (accessibility identifier), а не по координатам - тексты переводятся на 10 локалей. Готовые примеры: `C5_reset_confirm_keep.yaml`, `B3_active_endfast_complete.yaml`.

Прогоны сьюта - работа субагента `qa`, он же владеет флоу и комитит их сам. Если для проверки нужен новый флоу - лучше отдать ему, а не плодить одноразовые ямлы.

**Свернуть апку** - `Cmd+Shift+H` в этой версии Simulator **переключает светлую/тёмную тему**, а не сворачивает; кнопка-домик есть на тулбаре, но это снова клики по десктопу. Из Maestro - `- pressKey: Home`.

**Системный алерт уведомлений** вылезает при первом запуске и закрывает собой пол-экрана. `xcrun simctl privacy` уведомления **не поддерживает** (в списке только calendar/contacts/photos/...). Из Maestro закрывается `- tapOn: "Allow"` (или `"Don't Allow"`) в начале флоу. После ответа он держится, пока апку не переустановят - но `simctl install` поверх сбрасывает разрешение обратно в `notDetermined`, и алерт возвращается.

## 6a. Ловить анимации и баннеры: пиши видео, не гоняйся за скриншотом

**Скриншотами короткие вещи не ловятся.** `simctl io screenshot` тратит ~0.25-0.5с на кадр, а слайд шторки длится 0.3с, баннер пуша ~5с. Прицельные снимки промахиваются, а `sleep` до нужной секунды на переднем плане **убивается** (exit 137). Не трать на это время - пиши видео:

```bash
xcrun simctl io $SIM recordVideo --codec h264 /tmp/rec.mp4 &
RECPID=$!
sleep 2
xcrun simctl launch $SIM $B
sleep 6
kill -INT $RECPID      # именно INT, иначе файл не закроется
```

Разбор кадров (ffmpeg есть в `/opt/homebrew/bin`):

```bash
# все кадры
ffmpeg -i /tmp/rec.mp4 -vf "fps=30" /tmp/frames/f-%03d.png
# плитка нужного отрезка — быстрее всего искать глазами
ffmpeg -i /tmp/rec.mp4 -vf "fps=30,select='between(n\,125\,154)',scale=150:-1,tile=6x5" \
  -frames:v 1 /tmp/tile.png
```

Так слайд шторки виден покадрово на **реальной скорости**: ~10 кадров при 30fps = 0.33с. Тем же способом ловится и баннер goal-пуша.

**Slow Animations** (Debug-меню симулятора) - разглядеть детали моушена. Это меню самого Simulator.app, ни `simctl`, ни Maestro до него не достают, а кликать по десктопу нельзя. Если действительно нужно - попроси владельца включить пункт руками и напомни выключить обратно. В большинстве случаев хватает разбора видео по кадрам выше.

**Тап по пушу - работа iOS, а не кода апки.** Тот же код-путь (апка открывается на взятой цели → момент → счётчик → шторка) детерминированно покрывается холодным запуском из секции 5 (`has_celebrated=false` + уже перейдённая цель). Видео нужно, когда проверяешь именно моушен или факт баннера.

**Факт доставки читается из лога, скриншот не нужен:**

```bash
xcrun simctl spawn $SIM log show --last 2m --style compact \
  --predicate 'subsystem CONTAINS "UserNotifications"' | grep -i "if-app"
```

Что искать:
- `has a trigger date <дата>` - пуш запланирован (сверь с моментом цели);
- `Saving notification E723-33F3: YES [ hasAlertContent: YES, shouldPresentAlert: YES ]` и `Posting notification id: E723-33F3` - доставлен;
- `Removing N pending notification requests` - `NotificationMiddleware` снял пуш (нормально, если цель уже позади);
- `authorizationStatus: Authorized` / `0` (= notDetermined) - текущее разрешение; от него зависит и доставка, и значение user property `push_status`.

**Реальное время срабатывания бери из лога (`trigger date`), а не считай сам.** Между вычислением `START` и запуском проходит boot (~12с), поэтому собственная оценка едет на десятки секунд: насчитал 09:35:33, по факту цель была ~09:34:38.

## 7. Тесты и launch-аргументы

```bash
xcodebuild -project IFApp.xcodeproj -scheme IFApp \
  -destination "platform=iOS Simulator,id=$SIM" test
```

- `-uitestReset` - стартовать с чистого idle (см. `AppStoreFactory`).
- `-showReviewPrompt` - показать шторку отзыва сразу (см. `IFAppApp.init`).

## 8. Логи

Firebase сконфигурирован (`GoogleService-Info.plist` в бандле), поэтому события аналитики **не печатаются в консоль** - ветка `print` в `DefaultAnalyticsClient` работает только когда Firebase не подключён. Системные логи:

```bash
xcrun simctl spawn $SIM log stream --style compact \
  --predicate 'processImagePath CONTAINS "IFApp"'
```

Там видно работу `NotificationMiddleware` (`Removing N pending notification requests`) и `SyncPushStatusThunk` (`Getting notification settings (async)`).

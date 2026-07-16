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

`simctl` тапать не умеет. Нужен computer-use MCP: `request_access` на **Simulator**, потом `screenshot` + `left_click` по координатам окна симулятора.

**Свернуть апку** - кнопка-домик на тулбаре симулятора (~139,77 при дефолтном размере окна). `Cmd+Shift+H` в этой версии Simulator **переключает светлую/тёмную тему**, а не сворачивает. Свайп в центр уведомлений на мелком окне не открывается вообще - ни `left_click_drag`, ни ручной drag через mouse_down/move/up.

**Системный алерт уведомлений** вылезает при первом запуске и закрывает собой пол-экрана. `xcrun simctl privacy` уведомления **не поддерживает** (в списке только calendar/contacts/photos/...), так что алерт надо один раз тапнуть руками через computer-use. После ответа он держится, пока апку не переустановят - но `simctl install` поверх сбрасывает разрешение обратно в `notDetermined`, и алерт возвращается.

## 6a. Goal-пуш: как проверять (и как НЕ надо)

**Не гоняйся за баннером.** Он живёт ~5 секунд, и поймать его скриншотом практически нельзя: два прицельных снимка промахнулись, а третий - с вычисленным `sleep` до самого trigger date - вообще не выполнился, потому что **долгий `sleep` на переднем плане убивается** (exit 137). Если баннер нужен вживую - проси человека тапнуть, автоматом не выйдет.

**Тап по пушу - работа iOS, а не кода апки.** Тот же код-путь (апка открывается на взятой цели → момент → счётчик → шторка) полностью покрывается детерминированным холодным запуском из секции 5 (`has_celebrated=false` + уже перейдённая цель). Проверяй им.

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

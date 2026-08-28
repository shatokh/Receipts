# Archived Patrol pilot cookbook

Эта папка сохраняет результат учебного Android-native E2E-пилота Patrol. Maestro выбран основной нативной E2E-системой; не используйте этот cookbook для регулярных прогонов. Он нужен только для воспроизведения задокументированной проблемы Patrol при явной диагностической необходимости. Не используйте личные чеки, пути, URI или содержимое PDF в тестах, выводе консоли и скриншотах.

## 1. Подготовить консоль

Откройте PowerShell в корне репозитория и укажите Android SDK, если это ещё не сделано в текущей консоли:

```powershell
$env:ANDROID_SDK_ROOT = '<путь-к-Android-SDK>'
$env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
$env:PATH = "$env:LOCALAPPDATA\Pub\Cache\bin;$env:ANDROID_SDK_ROOT\platform-tools;$env:ANDROID_SDK_ROOT\emulator;$env:PATH"
$env:PATROL_ANALYTICS_ENABLED = 'false'
```

Убедитесь, что зависимости проекта готовы:

```powershell
flutter pub get
patrol --version
```

## 2. Запустить и проверить эмулятор

Для обычного доказательного прогона используйте headless AVD. Для визуальной
отладки запустите **тот же** AVD с окном. Не используйте mutable snapshot:

```powershell
& "$env:ANDROID_SDK_ROOT\emulator\emulator.exe" -avd it_api36 -no-snapshot -no-window -gpu host
```

Для видимой диагностики уберите только `-no-window`; такой запуск не является
доказательством для scorecard.

Перед любым тестом дождитесь полной готовности, а не только строки в `adb devices`:

```powershell
$adb = "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $state = (& $adb -s emulator-5554 get-state 2>$null).Trim()
    $boot = (& $adb -s emulator-5554 shell getprop sys.boot_completed 2>$null).Trim()
    if ($state -eq 'device' -and $boot -eq '1') { break }
    Start-Sleep -Seconds 2
}
if ($state -ne 'device' -or $boot -ne '1') { throw 'Emulator is not ready.' }
```

## 3. Воспроизвести архивный cancel-пилот

Это диагностический ручной запуск, а не поддерживаемая E2E-команда. Он собирает Patrol APK и запускает тот же `PatrolJUnitRunner` напрямую через ADB. Такой путь нужен, потому что на этом хосте официальный `patrol test` получает ложный код 1 из-за локального UTP mTLS result-listener после успешного JUnit-теста.

```powershell
.\tool\run_patrol_android.ps1 `
  -DeviceId emulator-5554 `
  -TestTarget patrol_test\document_picker_cancel_test.dart
```

Успех — только `OK (1 test)` и код процесса 0. Не считайте Android Gradle HTML/protobuf-отчёт источником успеха и не игнорируйте код возврата helper-а.

## Статус native-import пилота

`-StageReceiptA` в helper-е подготавливает одобренный синтетический PDF для
диагностики, но не является поддерживаемым доказательным прогоном.
В Patrol JUnit runner Android picker выбирает этот файл, однако `file_picker`
не получает результат в Dart; следовательно, import pipeline не запускается.
Не добавляйте app test hook и не меняйте production import code только ради
этого пилота. Maestro покрывает этот сценарий как выбранная система. Полное
зафиксированное воспроизведение и решение находятся в
`docs/refactoring_subplans/phase_16e_dual_framework_redacted_pdf_pilots.md`.

## 4. Наблюдать реальные UI-действия

Запускайте команду только в интерактивном PowerShell/терминале: `patrol develop` требует TTY для hot restart.

```powershell
patrol develop -t patrol_test\document_picker_cancel_test.dart -d emulator-5554
```

На видимом AVD будут выполнены реальные действия: onboarding → Import → Android document picker → native Back → возврат в Import. После окончания сценария:

- `r` — повторить его;
- `q` — завершить develop-сессию.

Это режим наблюдения и отладки; scorecard-результат фиксируется отдельным headless-прогоном из раздела 3.

## 5. Если Android-зависимости не скачиваются из-за TLS

Симптом: Gradle сообщает `PKIX path building failed` при загрузке Android/Maven зависимостей. Локальный truststore разрешён только вне репозитория. Перед запуском задайте его путь в текущей консоли:

```powershell
$env:RECEIPTS_GRADLE_TRUST_STORE = '<локальный-путь-к-truststore>'
.\tool\run_patrol_android.ps1
```

Не добавляйте truststore, сертификаты, proxy-настройки или исключения антивируса в Git. Для `patrol develop` используйте тот же параметр окружения через `GRADLE_OPTS`:

```powershell
$env:GRADLE_OPTS = "-Djavax.net.ssl.trustStore=$env:RECEIPTS_GRADLE_TRUST_STORE -Djavax.net.ssl.trustStorePassword=changeit"
patrol develop -t patrol_test\document_picker_cancel_test.dart -d emulator-5554
```

## Диагностика старта AVD

| Сообщение | Что делать |
| --- | --- |
| `Failed to load snapshot 'default_boot'` | Запускать с `-no-snapshot`; не использовать `-wipe-data` без явного запроса на сброс данных. |
| `adb ... device offline` во время boot | Дождаться проверок из раздела 2; не запускать второй AVD с тем же именем. |
| `UpdateCheck ... SSL peer certificate` | Это необязательная проверка обновлений эмулятора. Если readiness-проверка прошла, не менять код приложения и не ослаблять безопасность. |
| `StdinException ... terminal echo mode` | Перезапустить `patrol develop` в интерактивном терминале, без pipe/redirection. |
| `patrol test` завершился с кодом 1 после успешных шагов | Использовать helper из раздела 3; это известное ограничение host-local UTP, а не падение сценария. |

`test_bundle.dart` и `patrol_test_bundle.dart` создаются Patrol автоматически и игнорируются Git.

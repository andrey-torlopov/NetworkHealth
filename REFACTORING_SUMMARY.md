# NetworkHealth Refactoring Summary

## ✅ Что было сделано

### 1. Удалены все внешние зависимости
NetworkHealth теперь **полностью атомарный** модуль без зависимостей от Nevod и SpeedTestCore.

**Было:**
```swift
dependencies: [
    .package(name: "SpeedTestCore", path: "../SpeedTestCore"),
    .package(name: "Nevod", path: "../Nevod"),
]
```

**Стало:**
```swift
dependencies: []  // Нет зависимостей!
```

### 2. Протокольная архитектура для Speed Testing

NetworkHealth теперь работает через протокол `SpeedTester`, который может реализовать любой:

```swift
public protocol SpeedTester: Sendable {
    func measureSpeed() async throws -> SpeedTestResult
}
```

### 3. Два режима работы

#### Режим 1: Без тестирования скорости (базовый)
Мониторит только тип соединения: WiFi, LTE, 5G, 2G и т.д.

```swift
// Просто мониторит тип интерфейса
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")  // Базируется на WiFi/LTE/5G
    print("Connection: \(state.connectionType)")
}
```

#### Режим 2: С реальным тестированием скорости
Подключаете любой тестер скорости через протокол и получаете реальные измерения.

```swift
// Подключаем любой тестер (Mock, SpeedTestCore, или свой)
let tester = MockSpeedTester.excellentWiFi
for await state in NetworkHealth.stream(speedTester: tester) {
    print("Quality: \(state.quality)")  // Учитывает реальную скорость!
    print("Download: \(state.downloadSpeedMbps ?? 0) Mbps")
}
```

## 📦 Что включено

### Основной модуль
- `NetworkHealth` - главный API
- `NetworkHealthCoordinator` - координатор
- `NetworkQualityMonitor` - для SwiftUI
- `SpeedTester` протокол - для инъекции тестеров
- Модели: `NetworkQuality`, `ConnectionRawData`, `NetworkQualitySnapshot`

### Моки для тестирования
- `MockSpeedTester` - мок с предустановленными значениями
- `MockDetailedSpeedTester` - расширенный мок
- `RandomMockSpeedTester` - случайные значения

### Примеры интеграции
- `SpeedTestCoreAdapter` - пример интеграции SpeedTestCore (закомментирован)
- `NetworkHealthExamples.swift` - примеры использования

## 🚀 Как использовать

### Базовое использование (без speed test)

```swift
// AsyncStream
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")
}

// Snapshot
let snapshot = await NetworkHealth.snapshot()
print("Current quality: \(snapshot.quality)")

// SwiftUI Observable
@State private var health = NetworkHealth.observable()
```

### С тестированием скорости

#### 1. Используйте Mock для тестирования/демо

```swift
let mockTester = MockSpeedTester(
    latency: 50,
    downloadSpeedMbps: 20,
    uploadSpeedMbps: 10
)

for await state in NetworkHealth.stream(
    speedTester: mockTester,
    speedTestInterval: 60
) {
    print("Download: \(state.downloadSpeedMbps ?? 0) Mbps")
}
```

Или используйте предустановленные:
```swift
MockSpeedTester.excellent5G   // 5G: 100 Mbps
MockSpeedTester.goodLTE        // LTE: 20 Mbps
MockSpeedTester.moderate3G     // 3G: 3 Mbps
MockSpeedTester.poor2G         // 2G: 0.3 Mbps
MockSpeedTester.excellentWiFi  // WiFi: 150 Mbps
MockSpeedTester.slowWiFi       // Медленный WiFi: 2 Mbps
```

#### 2. Интегрируйте SpeedTestCore (опционально)

1. Добавьте SpeedTestCore в зависимости **вашего приложения**
2. Скопируйте `SpeedTestCoreAdapter` из Examples
3. Раскомментируйте код
4. Используйте:

```swift
// В вашем приложении:
import SpeedTestCore
import NetworkHealth

let config = NetworkConfig(/* ... */)
let networkProvider = NetworkProvider(config: config)
let speedTestManager = SpeedTestManager(networkProvider: networkProvider)
let adapter = SpeedTestCoreAdapter(manager: speedTestManager, testMode: .quick)

for await state in NetworkHealth.stream(
    speedTester: adapter,
    speedTestInterval: 120
) {
    print("Real speed: \(state.downloadSpeedMbps ?? 0) Mbps")
}
```

#### 3. Создайте свой тестер

Реализуйте протокол `SpeedTester` для любой библиотеки (Alamofire, URLSession, и т.д.):

```swift
struct MyCustomSpeedTester: SpeedTester {
    func measureSpeed() async throws -> SpeedTestResult {
        // Ваша логика тестирования
        let latency = try await measureLatency()
        let download = try await measureDownload()
        let upload = try await measureUpload()
        
        return SpeedTestResult(
            latency: latency,
            downloadSpeedMbps: download,
            uploadSpeedMbps: upload
        )
    }
}

// Используйте
let myTester = MyCustomSpeedTester()
for await state in NetworkHealth.stream(speedTester: myTester) {
    // ...
}
```

## 📊 Как работает качество сети

### Без speed tester
NetworkQuality определяется по типу интерфейса:
- **Excellent**: WiFi, Ethernet
- **Good**: LTE, 5G
- **Moderate**: 3G
- **Poor**: 2G
- **Offline**: Нет соединения

### Со speed tester
NetworkQuality определяется по **худшему** из двух значений:
1. Базовое качество (по типу интерфейса)
2. Измеренное качество (по реальной скорости)

Пример:
```
WiFi (Excellent) + реальная скорость 1 Mbps (Moderate) = Moderate
LTE (Good) + реальная скорость 50 Mbps (Excellent) = Good
```

## 🎯 API примеры

### Stream Mode
```swift
// Базовый
for await state in NetworkHealth.stream() { }

// С тестером
for await state in NetworkHealth.stream(
    speedTester: myTester,
    speedTestInterval: 60
) { }
```

### Snapshot Mode
```swift
// Быстрый снимок (без speed test)
let snapshot = await NetworkHealth.snapshot()

// Детальный снимок (с speed test)
let detailed = try await NetworkHealth.detailedSnapshot(
    speedTester: myTester
)
```

### Observable Mode (SwiftUI)
```swift
@State private var health = NetworkHealth.observable()

// С тестером
@State private var health = NetworkHealth.observable(
    speedTester: MockSpeedTester.goodLTE,
    speedTestInterval: 60
)
```

### Health Check Mode
```swift
// Проверка под операцию
let check = await NetworkHealth.check(requirement: .videoStreaming)
if check.passed {
    startVideo()
}

// Кастомная проверка
let check = await NetworkHealth.check(
    minimumQuality: .good,
    requireWiFi: true,
    allowExpensive: false
)
```

## ⚙️ Конфигурация через Factory

```swift
// Базовый координатор (без speed test)
let coordinator = NetworkHealthCoordinator.basic()

// С кастомным тестером
let coordinator = NetworkHealthCoordinator.custom(
    speedTester: myTester,
    interval: 120,
    historyMaxSize: 500,
    historyMaxAge: 7 * 24 * 60 * 60
)
```

## 🧪 Тестирование

Используйте моки:

```swift
// В тестах
let mockTester = MockSpeedTester(
    latency: 30,
    downloadSpeedMbps: 50,
    uploadSpeedMbps: 20
)

let coordinator = NetworkHealthCoordinator.custom(
    speedTester: mockTester,
    interval: 1
)

// Тестируйте...
```

## 🔄 Миграция со старой версии

### Было:
```swift
let networkProvider = NetworkProvider(config: config)

for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 60,
    networkProvider: networkProvider
) { }
```

### Стало:
```swift
// Вариант 1: Без speed test (просто убираем параметры)
for await state in NetworkHealth.stream() { }

// Вариант 2: Со speed test (используйте адаптер)
let speedTestManager = SpeedTestManager(networkProvider: networkProvider)
let adapter = SpeedTestCoreAdapter(manager: speedTestManager)

for await state in NetworkHealth.stream(
    speedTester: adapter,
    speedTestInterval: 60
) { }
```

## 📝 Итог

**NetworkHealth теперь:**
- ✅ Атомарный (0 зависимостей)
- ✅ Гибкий (любой speed tester через протокол)
- ✅ Универсальный (работает с/без speed testing)
- ✅ Тестируемый (встроенные моки)
- ✅ Расширяемый (легко интегрировать любую библиотеку)

Пользователь **сам выбирает**:
- Использовать ли speed testing
- Какую библиотеку использовать (SpeedTestCore, Alamofire, URLSession, свою)
- Как часто тестировать скорость

# Руководство по быстрому старту

Начните работу с NetworkHealth менее чем за 5 минут.

## Три простых паттерна использования

### 1️⃣ Stream - Непрерывный мониторинг

Используйте когда нужно непрерывно отслеживать изменения качества сети в реальном времени.

```swift
// Базовый мониторинг
for await state in NetworkHealth.stream() {
    print("Качество: \(state.quality)")
}

// С тестированием скорости
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 60,
    networkProvider: provider
) {
    print("Скорость: \(state.downloadSpeedMbps ?? 0) Мбит/с")
}
```

**Когда использовать**: Фоновый мониторинг, реактивные обновления UI

---

### 2️⃣ Snapshot - Разовая проверка

Используйте для быстрой разовой проверки качества сети.

```swift
// Быстрая проверка
let snapshot = await NetworkHealth.snapshot()
if snapshot.isGoodQuality {
    startDownload()
}

// Детальная проверка с тестом скорости
let detailed = try await NetworkHealth.detailedSnapshot(
    networkProvider: provider
)
print("Пинг: \(detailed.latency ?? 0)мс")
```

**Когда использовать**: Предварительные проверки, периодическая оценка качества

---

### 3️⃣ Observable - Для SwiftUI

Используйте когда нужно привязать состояние сети к UI компонентам.

```swift
struct MyView: View {
    @State private var health = NetworkHealth.observable()
    
    var body: some View {
        VStack {
            Text("Качество: \(health.currentQuality.description)")
            
            Button("Тест скорости") {
                Task { await health.performMeasurement() }
            }
        }
    }
}
```

**Когда использовать**: SwiftUI views, привязка данных в UIKit

---

### 4️⃣ Health Check - Проверка требований

Используйте для проверки соответствия сети требованиям конкретных операций.

```swift
// Готовы для видео стриминга?
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}

// Кастомные требования
let check = await NetworkHealth.check(
    minimumQuality: .good,
    requireWiFi: true
)
if check.passed {
    uploadLargeFile()
}
```

**Когда использовать**: Контроль операций, feature flags

---

## Уровни качества

| Качество | Описание | Примеры |
|----------|----------|---------|
| `offline` | Нет соединения | - |
| `poor` | 2G, нестабильный 3G | Только текст |
| `moderate` | Стабильный 3G, слабый LTE | Текст + изображения |
| `good` | LTE, 5G, хороший WiFi | Видео, стриминг |
| `excellent` | Быстрый WiFi, Ethernet | Без ограничений |

---

## Примеры из реальных проектов

### Адаптивная загрузка контента

```swift
let snapshot = await NetworkHealth.snapshot()

switch snapshot.quality {
case .offline:
    showOfflineMode()
case .poor:
    loadTextOnly()
case .moderate:
    loadWithImages()
case .good, .excellent:
    loadFullContent()
}
```

### Предварительная проверка для API запроса

```swift
guard await NetworkHealth.isGoodEnoughFor(.basicBrowsing) else {
    throw NetworkError.offline
}

try await makeAPICall()
```

### Условный UI

```swift
var body: some View {
    VideoPlayerView()
        .disabled(!health.isGoodQuality)
    
    if health.isDegradedQuality {
        Text("Низкое качество - видео может буферизоваться")
            .foregroundColor(.orange)
    }
}
```

---

## Важные свойства NetworkHealthState

```swift
state.quality              // .offline, .poor, .moderate, .good, .excellent
state.connectionType       // .wifi, .cellular(.lte), .wiredEthernet, и т.д.
state.isOnline            // true если quality != .offline
state.isGoodQuality       // true если quality >= .good
state.isDegradedQuality   // true если poor или moderate
state.isExpensive         // true для cellular с лимитом данных
state.latency             // Пинг в мс (если измерен)
state.downloadSpeedMbps   // Скорость загрузки (если измерена)
state.uploadSpeedMbps     // Скорость выгрузки (если измерена)
```

---

## Предопределенные требования операций

```swift
.basicBrowsing      // Poor или лучше
.imageLoading       // Moderate или лучше
.videoStreaming     // Good или лучше
.largeDownload      // Good или лучше, предпочтительно WiFi
.largeUpload        // Good или лучше, требуется WiFi
```

---

## Лучшие практики

✅ **ДЕЛАЙТЕ**:
- Используйте `snapshot()` для быстрых проверок
- Проверяйте `isExpensive` перед большими загрузками
- Используйте `stream()` для реактивного UI
- Устанавливайте разумные интервалы тестов (60-120 сек)

❌ **НЕ ДЕЛАЙТЕ**:
- Не запускайте тесты скорости слишком часто (тратит трафик и батарею)
- Не забывайте обрабатывать offline состояние
- Не выполняйте тяжелые операции на cellular без предупреждения

---

## Миграция с NetworkHealthCoordinator

### Было (сложно):

```swift
let config = NetworkHealthCoordinator.Configuration(
    speedTester: adapter,
    minimumSpeedCheckInterval: 120
)
let checker = NetworkHealthCoordinator(configuration: config)
for await state in await checker.stateStream() {
    // ...
}
```

### Стало (просто):

```swift
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 120,
    networkProvider: provider
) {
    // ...
}
```

---

## Следующие шаги

- 📚 [Полный справочник API](API.md)
- 💡 [Больше примеров](Examples.md)
- 🔧 [Обзор архитектуры](Architecture.md)
- 📦 [Руководство по установке](Installation.md)

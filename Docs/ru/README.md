# NetworkHealth - Полная документация

Добро пожаловать в полную документацию NetworkHealth - Swift пакета для интеллектуального мониторинга качества сети.

## Содержание

1. [Быстрый старт](QuickStart.md) - Начните работу за несколько минут
2. [Установка](Installation.md) - Подробные инструкции по установке
3. [Справочник API](API.md) - Полная документация API
4. [Архитектура](Architecture.md) - Внутренняя архитектура и принципы проектирования
5. [Примеры](Examples.md) - Примеры использования из реальных проектов
6. [Руководство по миграции](Migration.md) - Переход с NetworkHealthCoordinator

## Обзор

NetworkHealth предоставляет простой и мощный API для мониторинга качества сети и адаптации поведения вашего приложения в зависимости от характеристик соединения. Автоматически определяет типы соединений, измеряет скорость при необходимости и оценивает качество.

### Ключевые возможности

- **Простой API** - Четыре интуитивных паттерна использования (Stream, Snapshot, Observable, Health Check)
- **Оценка качества** - Пятиуровневая шкала от Offline до Excellent
- **Определение типа соединения** - WiFi, Cellular (2G/3G/LTE/5G), Ethernet
- **Тестирование скорости** - Опциональная интеграция со SpeedTestCore
- **Мониторинг в реальном времени** - Непрерывные обновления через AsyncStream
- **Интеграция со SwiftUI** - Observable обертка для бесшовного обновления UI
- **Потокобезопасность** - Архитектура на основе Actor для безопасной конкурентности
- **История измерений** - Автоматическое сохранение снимков и статистика

## Быстрый пример

```swift
import NetworkHealth

// Простая проверка качества
let snapshot = await NetworkHealth.snapshot()

if snapshot.isGoodQuality {
    startDownload()
}

// Непрерывный мониторинг
for await state in NetworkHealth.stream() {
    print("Качество: \(state.quality)")
}

// Интеграция со SwiftUI
@State private var health = NetworkHealth.observable()

// Требования операций
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}
```

## Паттерны использования

### 1. Режим Stream
**Когда использовать**: Фоновый мониторинг, реактивные обновления UI

```swift
for await state in NetworkHealth.stream() {
    adaptToNetworkQuality(state.quality)
}
```

### 2. Режим Snapshot
**Когда использовать**: Предварительные проверки, периодическая оценка качества

```swift
let snapshot = await NetworkHealth.snapshot()
guard snapshot.isOnline else { return }
```

### 3. Режим Observable
**Когда использовать**: SwiftUI views, привязка данных

```swift
@State private var health = NetworkHealth.observable()
```

### 4. Режим Health Check
**Когда использовать**: Контроль операций, feature flags

```swift
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    enableFeature()
}
```

## Уровни качества

| Уровень | Тип сети | Задержка | Скорость | Сценарии использования |
|---------|----------|----------|----------|------------------------|
| **Offline** | Нет | - | - | Только кэшированный контент |
| **Poor** | 2G, нестабильный 3G | >1500мс | <1 Мбит/с | Текстовые сообщения |
| **Moderate** | 3G, слабый LTE | 500-1500мс | 1-5 Мбит/с | Изображения, ленты соцсетей |
| **Good** | LTE, 5G, WiFi | 100-500мс | 5-10 Мбит/с | Видео стриминг |
| **Excellent** | Быстрый WiFi, Ethernet | <100мс | 10+ Мбит/с | HD видео, большие файлы |

## Начало работы

1. **Установка**: Добавьте NetworkHealth в проект через Swift Package Manager
2. **Быстрый старт**: Следуйте [Руководству по быстрому старту](QuickStart.md)
3. **Интеграция**: Изучите [Примеры](Examples.md) для вашего случая использования
4. **Справочник API**: Изучите полную [документацию API](API.md)

## Требования

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Поддержка

- 📖 [Руководство по быстрому старту](QuickStart.md)
- 📚 [Справочник API](API.md)
- 💡 [Примеры](Examples.md)
- 🔧 [Архитектура](Architecture.md)

## Лицензия

NetworkHealth доступен под лицензией MIT. Подробности в файле LICENSE.

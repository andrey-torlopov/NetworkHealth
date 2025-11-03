# Руководство по установке

## Swift Package Manager (Рекомендуется)

NetworkHealth распространяется через Swift Package Manager. Это рекомендуемый способ интеграции библиотеки в ваш проект.

### Добавление в проект Xcode

1. Откройте ваш проект в Xcode
2. Перейдите в **File → Add Package Dependencies...**
3. Введите URL репозитория:
   ```
   https://github.com/yourusername/NetworkHealth.git
   ```
4. Выберите правило версии (например, "Up to Next Major Version" from 1.0.0)
5. Нажмите **Add Package**
6. Выберите таргет **NetworkHealth** и нажмите **Add Package**

### Добавление в Package.swift

Добавьте NetworkHealth как зависимость в ваш файл `Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .iOS(.v17),
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["NetworkHealth"]
        )
    ]
)
```

## Зависимости

NetworkHealth имеет **НОЛЬ внешних зависимостей**! Это полностью автономная библиотека.

### Встроенные зависимости
- **Foundation** - Встроенный фреймворк (не требует внешних зависимостей)
- **Network** - Встроенный фреймворк для NWPathMonitor (не требует внешних зависимостей)
- **CoreTelephony** - Встроенный фреймворк для определения типа сотовой связи (только iOS)

### Опциональное тестирование скорости

NetworkHealth поддерживает тестирование скорости через протокол `SpeedTester`. Вы можете использовать:

1. **Встроенные моки** (включены, не требуют дополнительных зависимостей):
```swift
import NetworkHealth

let mockTester = MockSpeedTester.goodLTE
for await state in NetworkHealth.stream(speedTester: mockTester) {
    print("Качество: \(state.quality)")
}
```

2. **Собственную реализацию** - реализуйте протокол `SpeedTester`:
```swift
struct MySpeedTester: SpeedTester {
    func measureSpeed() async throws -> SpeedTestResult {
        // Ваша реализация
    }
}
```

3. **Сторонние библиотеки** (опционально) - интегрируйте любую библиотеку для тестирования скорости, создав адаптер. См. примеры в `REFACTORING_SUMMARY.md`.

## Проверка установки

После установки проверьте, что все работает:

```swift
import NetworkHealth

// Быстрая проверка
Task {
    let snapshot = await NetworkHealth.snapshot()
    print("NetworkHealth успешно установлен!")
    print("Текущее качество: \(snapshot.quality)")
}
```

## Минимальные требования

- **iOS**: 17.0 или новее
- **macOS**: 15.0 или новее
- **Swift**: 6.1 или новее
- **Xcode**: 16.0 или новее

## Поддержка платформ

Текущая поддержка:
- ✅ iOS 17.0+
- ✅ iPadOS 17.0+
- ✅ macOS 15.0+

Планируется в будущем:
- watchOS (планируется)
- tvOS (планируется)

## Решение проблем

### "No such module 'NetworkHealth'"

**Решение**: Убедитесь, что вы правильно добавили пакет и он отображается в зависимостях проекта. Попробуйте очистить папку сборки (Cmd+Shift+K) и пересобрать проект.

### Ошибка разрешения пакетов

**Решение**:
1. Проверьте интернет-соединение
2. Убедитесь, что URL репозитория корректен
3. Попробуйте сбросить кэш пакетов в Xcode: **File → Packages → Reset Package Caches**

### Ошибки сборки после добавления пакета

**Решение**:
1. Убедитесь, что deployment target вашего проекта соответствует минимальным требованиям:
   - iOS 17.0 или выше
   - macOS 15.0 или выше
2. Очистите папку сборки (Cmd+Shift+K)
3. Закройте и откройте Xcode заново
4. Удалите derived data: `~/Library/Developer/Xcode/DerivedData`

### Тестирование скорости не работает

**Решение**: NetworkHealth включает встроенные mock тестеры скорости. Для production использования реализуйте протокол `SpeedTester` с вашей собственной логикой тестирования. См. документацию для примеров.

## Обновление NetworkHealth

### Xcode
1. Перейдите в **File → Packages → Update to Latest Package Versions**
2. Или кликните правой кнопкой на пакет в Project Navigator и выберите **Update Package**

### Командная строка
```bash
swift package update
```

## Удаление

### Из проекта Xcode
1. Выберите ваш проект в Project Navigator
2. Выберите ваш таргет
3. Перейдите в **Frameworks, Libraries, and Embedded Content**
4. Найдите NetworkHealth и нажмите кнопку "-"

### Из Package.swift
Удалите запись NetworkHealth из массива `dependencies` в вашем файле `Package.swift`.

## Следующие шаги

После установки:
- 📖 [Руководство по быстрому старту](QuickStart.md) - Начните работу за 5 минут
- 📚 [Справочник API](API.md) - Изучите полный API
- 💡 [Примеры](Examples.md) - Посмотрите примеры использования из реальных проектов

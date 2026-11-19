# Payroller Demo

Навчальний застосунок для обліку робочих змін і розрахунку оплати. Інтерфейс написаний на SwiftUI, дані зберігаються локально через SwiftData.

## Запуск

1. Відкрийте `dmitrich_dyplom.xcodeproj` в Xcode 26.3 або новішому.
2. Виберіть симулятор iPhone з iOS 17 або новішою версією та натисніть Run.
3. Додайте співробітника, створіть для нього зміну й додайте завдання. Оплата відображається в деталях зміни та на головному екрані.

На першому запуску база порожня. У налаштуваннях можна змінити ставки й мову, переглянути курси НБУ та вибрати валюту для підсумків (USD, UAH або EUR). Для перевірки Face ID відкрийте розділ «Безпека», задайте PIN і ввімкніть біометрію на сумісному пристрої.

## Де дивитися код

- [Models/WorkShift.swift](dmitrich_dyplom/Models/WorkShift.swift) — дані зміни та розрахунок її тривалості.
- [Services/Payroll/PayrollEngine.swift](dmitrich_dyplom/Services/Payroll/PayrollEngine.swift) — розрахунок оплати за години й завдання.
- [Screens/Shifts/ManualTaskEntryView.swift](dmitrich_dyplom/Screens/Shifts/ManualTaskEntryView.swift) — введення тривалості та збереження завдань.

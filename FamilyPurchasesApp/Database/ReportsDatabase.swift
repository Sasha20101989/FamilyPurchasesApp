import Foundation

class ReportsDatabase: ObservableObject {
    static let shared = ReportsDatabase() // Singleton для использования в приложении
    @Published var reports: [Report] = []

    let fileName = "reports.json"

    private init() {
        loadReportsFromFile()
    }

    // Сохранение отчётов в файл
    func saveReportsToFile() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            let data = try JSONEncoder().encode(reports)
            try data.write(to: fileURL)
            print("Отчёты сохранены в файл \(fileURL)")
        } catch {
            print("Ошибка при сохранении отчётов: \(error)")
        }
    }

    // Загрузка отчётов из файла
    func loadReportsFromFile() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: fileURL)
            let decodedReports = try JSONDecoder().decode([Report].self, from: data)
            self.reports = decodedReports
            print("Отчёты загружены из файла \(fileURL)")
        } catch {
            print("Ошибка при загрузке отчётов: \(error)")
        }
    }
    
    // Добавление или обновление отчета
    func addOrUpdateReport(_ report: Report) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else {
            reports.append(report)
        }
        saveReportsToFile() // Сохраняем после добавления или обновления
    }
    
    // Удаление отчета
    func removeReport(_ report: Report) {
        reports.removeAll { $0.id == report.id }
        saveReportsToFile() // Сохраняем изменения после удаления
    }

    // Получение пути к директории Documents
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

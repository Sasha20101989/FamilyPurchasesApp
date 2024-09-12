import Foundation

class FamiliesDatabase: ObservableObject {
    static let shared = FamiliesDatabase()

    @Published var families: [Family] = []

    let fileName = "families.json"

    private init() {
        loadFromFile()
    }

    // Сохранение семей в файл
    func saveToFile() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            let data = try JSONEncoder().encode(families)
            try data.write(to: fileURL)
            print("Данные сохранены в файл \(fileURL)")
        } catch {
            print("Ошибка при сохранении данных: \(error)")
        }
    }

    // Загрузка семей из файла
    func loadFromFile() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: fileURL)
            let decodedFamilies = try JSONDecoder().decode([Family].self, from: data)
            self.families = decodedFamilies
            print("Данные загружены из файла \(fileURL)")
        } catch {
            print("Ошибка при загрузке данных: \(error)")
        }
    }

    // Получение директории Documents для хранения данных
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Добавление новой семьи
    func addFamily(_ family: Family) {
        families.append(family)
        saveToFile() // Сохраняем обновленные данные
    }

    // Удаление семьи
    func removeFamily(_ family: Family) {
        if let index = families.firstIndex(where: { $0.id == family.id }) {
            families.remove(at: index)
            saveToFile() // Сохраняем обновленные данные
        }
    }
}

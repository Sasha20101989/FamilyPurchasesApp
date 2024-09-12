import Foundation

class Report: Identifiable, Codable, ObservableObject {
    var id = UUID()
    var creationDate: Date
    var title: String?
    var families: [Family] = [] // Семьи внутри отчета

    init(creationDate: Date = Date(), title: String? = nil) {
        self.creationDate = creationDate
        self.title = title
    }

    // Реализация Codable (кодирование и декодирование)
    enum CodingKeys: String, CodingKey {
        case id, creationDate, title, families
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.families = try container.decode([Family].self, forKey: .families)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(families, forKey: .families)
    }

    // Добавляем семью в отчёт
    func addFamily(_ family: Family) {
        families.append(family)
    }

    // Удаляем семью из отчета
    func removeFamily(_ family: Family) {
        if let index = families.firstIndex(where: { $0.id == family.id }) {
            families.remove(at: index)
        }
    }
}

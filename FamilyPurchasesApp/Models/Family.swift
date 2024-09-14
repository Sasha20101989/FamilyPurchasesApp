import Foundation

class Family: Identifiable, ObservableObject, Codable, Hashable {
    var id = UUID()
    var name: String
    var purchases: [Purchase] = []

    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case id, name, purchases
    }

    init(name: String) {
        self.name = name
    }

    // Реализация метода для декодирования
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        // Извлекаем покупки без @Published
        let decodedPurchases = try container.decode([Purchase].self, forKey: .purchases)
        self.purchases = decodedPurchases
    }

    // Реализация метода для кодирования
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        // Кодируем покупки без @Published
        try container.encode(purchases, forKey: .purchases)
    }
    
    // Реализация протокола Equatable
    static func == (lhs: Family, rhs: Family) -> Bool {
        return lhs.id == rhs.id
    }

    // Реализация протокола Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Добавление покупки в семью
    func addPurchase(_ purchase: Purchase) {
        purchases.append(purchase)
    }

    // Удаление покупки из семьи
    func removePurchase(_ purchase: Purchase) {
        if let index = purchases.firstIndex(where: { $0.id == purchase.id }) {
            purchases.remove(at: index)
        }
    }
}

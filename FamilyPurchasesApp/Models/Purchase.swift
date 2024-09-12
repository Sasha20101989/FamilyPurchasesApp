import SwiftUI

struct Purchase: Identifiable, Codable, Equatable {
    var id: UUID // Явно указываем как изменяемое свойство для Codable
    var name: String
    var amount: Double
    var isShared: Bool

    // Пользовательский инициализатор с возможностью задать id вручную
    init(id: UUID = UUID(), name: String, amount: Double, isShared: Bool) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isShared = isShared
    }

    // Явное указание CodingKeys для корректного кодирования/декодирования
    enum CodingKeys: String, CodingKey {
        case id, name, amount, isShared
    }
}

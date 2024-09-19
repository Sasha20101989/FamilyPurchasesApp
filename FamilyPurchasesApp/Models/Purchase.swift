import SwiftUI

struct Purchase: Identifiable, Codable, Equatable {
    var id: UUID // Явно указываем как изменяемое свойство для Codable
    var name: String
    var amount: Double
    var isShared: Bool
    var participatingFamilies: [UUID] // Список семей, участвующих в покупке (по ID)

    // Пользовательский инициализатор с возможностью задать id вручную
    init(id: UUID = UUID(), name: String, amount: Double, isShared: Bool, participatingFamilies: [UUID]) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isShared = isShared
        self.participatingFamilies = isShared ? [] : participatingFamilies
    }

    // Явное указание CodingKeys для корректного кодирования/декодирования
    enum CodingKeys: String, CodingKey {
        case id, name, amount, isShared, participatingFamilies
    }
}

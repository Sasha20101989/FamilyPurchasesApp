import Foundation

class Families: ObservableObject {
    @Published var items: [Family] = [] // Список семей с отслеживанием изменений
}

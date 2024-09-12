import Foundation
import SwiftUI

// Экран для управления семьями за выбранную дату
struct FamiliesForDateView: View {
    @EnvironmentObject var database: FamiliesDatabase
    var selectedDate: Date
    
    @State private var familyName: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var familyToDelete: Family? // Для хранения семьи, которую нужно удалить

    var body: some View {
        VStack {
            if familiesForDate().isEmpty {
                // Если семей нет, показываем сообщение
                Text("Семей пока нет")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    // Отображаем семьи, относящиеся к выбранной дате
                    ForEach(familiesForDate()) { family in
                        HStack {
                            // Переход к покупкам семьи
                            NavigationLink(destination: PurchasesView(family: family)) {
                                Text(family.name)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            // Кнопка удаления семьи
                            Button(action: {
                                familyToDelete = family // Устанавливаем семью для удаления
                                showingDeleteConfirmation = true // Показываем подтверждение
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Избегаем конфликта с NavigationLink
                        }
                    }
                }
            }

            Spacer()

            // Поле для добавления новой семьи
            TextField("Введите название семьи", text: $familyName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                addFamilyForDate()
            }) {
                Text("Добавить семью")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(familyName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(familyName.isEmpty)
            .padding(.horizontal)

            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Удалить семью?"),
                    message: Text("Вы уверены, что хотите удалить эту семью?"),
                    primaryButton: .destructive(Text("Удалить")) {
                        if let family = familyToDelete {
                            removeFamily(family)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationTitle("Семьи за \(formattedDate(selectedDate))")
    }

    // Получаем семьи для выбранной даты
    private func familiesForDate() -> [Family] {
        return database.families.filter { Calendar.current.isDate($0.creationDate, inSameDayAs: selectedDate) }
    }

    // Добавляем новую семью для выбранной даты
    private func addFamilyForDate() {
        let newFamily = Family(name: familyName, creationDate: selectedDate)
        database.families.append(newFamily)
        database.saveToFile() // Сохраняем изменения в файл
        familyName = "" // Очищаем поле
    }

    // Удаление семьи
    private func removeFamily(_ family: Family) {
        if let index = database.families.firstIndex(where: { $0.id == family.id }) {
            database.families.remove(at: index)
            database.saveToFile() // Сохраняем изменения в файл
        }
    }

    // Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

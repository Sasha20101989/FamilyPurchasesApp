//
//  FamiliesForDateView.swift
//  FamilyPurchasesApp
//
//  Created by Aleksander on 12.09.2024.
//

import Foundation
import SwiftUI

struct FamiliesForDateView: View {
    @EnvironmentObject var database: FamiliesDatabase
    var selectedDate: Date
    
    @State private var familyName: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var familyToDelete: Family? // Для хранения семьи, которую нужно удалить

    var body: some View {
        VStack {
            Text("Отчёт за: \(formattedDate(selectedDate))")
                .font(.title)
                .padding()

            List {
                ForEach(familiesForDate()) { family in
                    HStack {
                        Text(family.name)
                        Spacer()
                        Button(action: {
                            familyToDelete = family // Устанавливаем семью для удаления
                            showingDeleteConfirmation = true // Показываем подтверждение
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle()) // Сохраняем стиль списка аналогично AddFamilyView

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
        .padding()
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

struct FamiliesForDateView_Previews: PreviewProvider {
    static var previews: some View {
        FamiliesForDateView(selectedDate: Date())
            .environmentObject(FamiliesDatabase()) // Передаем пустую базу данных для превью
    }
}

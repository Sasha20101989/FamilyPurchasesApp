import SwiftUI

struct ReportDetailView: View {
    @ObservedObject var report: Report
    @EnvironmentObject var database: ReportsDatabase
    @State private var familyName: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var familyToDelete: Family? // Для хранения семьи, которую нужно удалить
    @State private var showingSummaryModal = false // Состояние для отображения модального окна

    var body: some View {
        VStack {
            // Верхняя панель с логотипом и кнопкой
            HStack {
                // Логотип отчета
                Image(systemName: "doc.text.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .padding(.leading)

                Spacer()

                // Кнопка для открытия модального окна с общей суммой
                Button(action: {
                    showingSummaryModal = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                    }
                    .padding()
                    .background(report.families.isEmpty ? Color.gray : Color.blue) // Меняем цвет кнопки
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(report.families.isEmpty) // Делаем кнопку неактивной, если семей нет
                .padding(.trailing)
            }
            .padding()

            // Редактирование названия отчета
            TextField("Название отчёта", text: Binding(
                get: { report.title ?? "" },
                set: { newTitle in
                    report.title = newTitle
                    database.saveReportsToFile() // Сохраняем изменения при каждом изменении названия
                }
            ))
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Добавление новой семьи
            TextField("Название семьи", text: $familyName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: addFamily) {
                Text("Добавить семью")
                    .padding()
                    .background(familyName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(familyName.isEmpty)

            // Список семей в отчете
            List {
                ForEach(report.families) { family in
                    NavigationLink(destination: PurchasesView(family: family, families: report.families)) {
                        Text(family.name)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            familyToDelete = family
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Отчёт за \(formattedDate(report.creationDate))")
        .onDisappear {
            // Сохраняем отчет при уходе с экрана
            database.saveReportsToFile()
        }
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
        // Модальное окно с информацией о суммах
        .sheet(isPresented: $showingSummaryModal) {
            SummaryModalView(purchases: report.families.flatMap { $0.purchases }, families: report.families, report: report)
        }
    }

    // Добавление новой семьи в отчёт
    private func addFamily() {
        let newFamily = Family(name: familyName)
        report.addFamily(newFamily)
        familyName = "" // Очищаем поле после добавления
        database.saveReportsToFile()
    }

    // Удаление семьи из отчета
    private func removeFamily(_ family: Family) {
        report.removeFamily(family)
        database.saveReportsToFile()
    }

    // Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Создаем пример отчёта для предварительного просмотра
        let exampleReport = Report(creationDate: Date())
        exampleReport.addFamily(Family(name: "Семья Ивановых"))
        exampleReport.addFamily(Family(name: "Семья Петровых"))
        
        return ReportDetailView(report: exampleReport)
    }
}

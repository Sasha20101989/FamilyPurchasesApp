import SwiftUI

struct FamiliesOverviewView: View {
    @EnvironmentObject var database: ReportsDatabase // Используем ReportsDatabase для работы с отчетами
    @State private var showingDeleteConfirmation = false
    @State private var reportToDelete: Report? // Для хранения отчета, который нужно удалить

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Группировка отчетов
                    ForEach(database.reports) { report in
                        HStack {
                            NavigationLink(destination: ReportDetailView(report: report)) {
                                VStack(alignment: .leading) {
                                    // Отображаем название отчета, если оно есть
                                    if let title = report.title, !title.isEmpty {
                                        Text("\(title) (\(formattedDate(report.creationDate)))")
                                            .font(.headline)
                                    } else {
                                        // Отображаем только дату, если название отсутствует
                                        Text("Дата отчёта: \(formattedDate(report.creationDate))")
                                            .font(.headline)
                                    }
                                    
                                    Text("Семей: \(report.families.count)") // Исправляем отображение количества семей
                                        .font(.subheadline)
                                    Text("Общая сумма: \(totalAmount(for: report), specifier: "%.2f")") // Общая сумма
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    reportToDelete = report
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                            
                            Spacer()

                        }
                    }
                }
                Spacer()

                // Кнопка для добавления нового отчета
                Button(action: addNewReport) {
                    Text("Добавить новый отчёт")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Отчёты по датам")
            .onAppear {
                // Загружаем данные каждый раз при появлении экрана
                database.loadReportsFromFile()
            }
            // Модальное окно для подтверждения удаления
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Удалить отчёт?"),
                    message: Text("Вы уверены, что хотите удалить этот отчёт? Это действие нельзя отменить."),
                    primaryButton: .destructive(Text("Удалить")) {
                        if let report = reportToDelete {
                            deleteReport(report)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // Добавление нового отчета
    private func addNewReport() {
        let newReport = Report(creationDate: Date())
        database.addOrUpdateReport(newReport)
    }

    // Удаление отчета
    private func deleteReport(_ report: Report) {
        database.removeReport(report)
    }

    // Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Подсчет общей суммы для всех покупок, участвующих в расчете
    private func totalAmount(for report: Report) -> Double {
        return report.families.flatMap { $0.purchases }
            .filter { $0.isShared } // Учитываем только покупки, которые участвуют в расчете
            .reduce(0) { $0 + $1.amount }
    }
}

struct FamiliesOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleReport = Report(creationDate: Date())
        
        let family1 = Family(name: "Семья Ивановых")
        // Здесь создаем покупки с примером UUID или пустым массивом
        family1.addPurchase(Purchase(name: "Хлеб", amount: 1.50, isShared: true, participatingFamilies: []))
        family1.addPurchase(Purchase(name: "Молоко", amount: 2.00, isShared: false, participatingFamilies: [UUID()]))
        
        let family2 = Family(name: "Семья Петровых")
        family2.addPurchase(Purchase(name: "Мясо", amount: 5.00, isShared: true, participatingFamilies: []))

        exampleReport.addFamily(family1)
        exampleReport.addFamily(family2)

        ReportsDatabase.shared.addOrUpdateReport(exampleReport)

        return FamiliesOverviewView().environmentObject(ReportsDatabase.shared)
    }
}


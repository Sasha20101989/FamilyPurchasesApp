import SwiftUI

struct PurchasesView: View {
    @ObservedObject var family: Family
    @EnvironmentObject var database: ReportsDatabase // Подключаем базу данных
    @State private var purchaseName: String = ""
    @State private var purchaseAmount: String = ""
    @State private var isShared: Bool = true // По умолчанию участвует в общем расчёте
    @State private var selectedPurchase: Purchase? // Храним выбранную для редактирования покупку
    @State private var totalSum: Double = 0.0
    @State private var sharedSum: Double = 0.0
    @State private var showingDeleteConfirmation = false // Флаг для показа подтверждения удаления
    @State private var showingSummaryModal = false // Для показа модального окна с суммами

    var body: some View {
        VStack {
            // Верхняя панель с логотипом и кнопкой
            HStack {
                // Логотип
                Image(systemName: "cart.fill")
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.trailing)
            }
            .padding()

            // Добавление или редактирование покупки
            TextField("Название покупки", text: $purchaseName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Сумма покупки", text: $purchaseAmount)
                .padding()
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Переключатель: участвует ли покупка в общем расчёте
            Toggle("Участвует в общем расчёте", isOn: $isShared)
                .padding()

            HStack {
                // Кнопка добавления или изменения покупки
                Button(action: {
                    if let purchase = selectedPurchase {
                        updatePurchase(purchase)
                    } else {
                        addPurchase()
                    }
                }) {
                    Text(selectedPurchase == nil ? "Добавить покупку" : "Изменить")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(purchaseName.isEmpty || purchaseAmount.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(purchaseName.isEmpty || purchaseAmount.isEmpty)

                // Кнопка "Отменить", появляется только в режиме редактирования
                if selectedPurchase != nil {
                    Button(action: cancelEditing) {
                        Text("Отменить")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: .infinity) // Обеспечивает одинаковую ширину для обеих кнопок
            .padding(.horizontal)

            // Список покупок с возможностью удаления свайпом
            List {
                ForEach(family.purchases) { purchase in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(purchase.name)
                            Text("Сумма: \(purchase.amount, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Отметка, если покупка не участвует в общем расчёте
                        if !purchase.isShared {
                            Text("Не участвует")
                                .foregroundColor(.red)
                        }
                    }
                    .onTapGesture {
                        selectPurchaseForEditing(purchase)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            selectedPurchase = purchase
                            showingDeleteConfirmation = true // Показать подтверждение
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Покупки \(family.name)") // Заголовок экрана
        .padding()
        .onAppear {
            recalculateSums() // Пересчет при открытии экрана
        }
        .onDisappear {
            // Сохраняем отчет при уходе с экрана
            database.saveReportsToFile()
        }
        // Подтверждение удаления покупки
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Удалить покупку?"),
                message: Text("Вы уверены, что хотите удалить эту покупку? Это действие нельзя отменить."),
                primaryButton: .destructive(Text("Удалить")) {
                    if let purchase = selectedPurchase {
                        deletePurchase(purchase)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // Модальное окно с информацией о суммах
        .sheet(isPresented: $showingSummaryModal) {
            SummaryModalView(purchases: family.purchases)
        }
    }

    // Функция добавления покупки
    private func addPurchase() {
        if let amount = Double(purchaseAmount) {
            let newPurchase = Purchase(name: purchaseName, amount: amount, isShared: isShared)
            family.purchases.append(newPurchase)
            database.saveReportsToFile() // Сохраняем изменения в базу данных
            clearInputFields()
            recalculateSums() // Пересчет после добавления
        }
    }

    // Функция обновления существующей покупки
    private func updatePurchase(_ purchase: Purchase) {
        if let amount = Double(purchaseAmount), let index = family.purchases.firstIndex(where: { $0.id == purchase.id }) {
            family.purchases[index].name = purchaseName
            family.purchases[index].amount = amount
            family.purchases[index].isShared = isShared
            database.saveReportsToFile() // Сохраняем изменения в базу данных
            clearInputFields()
            selectedPurchase = nil
            recalculateSums() // Пересчет после изменения
        }
    }

    // Функция удаления покупки
    private func deletePurchase(_ purchase: Purchase) {
        if let index = family.purchases.firstIndex(where: { $0.id == purchase.id }) {
            family.purchases.remove(at: index)
            database.saveReportsToFile()
            recalculateSums()

            // Если удаляется выбранная для редактирования покупка, сбрасываем поля
            if selectedPurchase == purchase {
                clearInputFields()
                selectedPurchase = nil
            }
        }
    }

    // Функция для выбора покупки для редактирования
    private func selectPurchaseForEditing(_ purchase: Purchase) {
        purchaseName = purchase.name
        purchaseAmount = String(format: "%.2f", purchase.amount)
        isShared = purchase.isShared
        selectedPurchase = purchase
    }

    // Функция для отмены редактирования
    private func cancelEditing() {
        clearInputFields()
        selectedPurchase = nil
    }

    // Функция для очистки полей ввода
    private func clearInputFields() {
        purchaseName = ""
        purchaseAmount = ""
        isShared = true
    }

    // Функция для расчета общей суммы всех покупок
    private func totalAmount() -> Double {
        return family.purchases.reduce(0) { $0 + $1.amount }
    }

    // Функция для расчета суммы только тех покупок, которые участвуют в общем расчете
    private func sharedAmount() -> Double {
        return family.purchases.filter { $0.isShared }.reduce(0) { $0 + $1.amount }
    }

    // Пересчитываем общие суммы
    private func recalculateSums() {
        totalSum = totalAmount()
        sharedSum = sharedAmount()
    }
}

struct PurchasesView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFamily = Family(name: "Пример семьи")
        sampleFamily.purchases.append(Purchase(name: "Хлеб", amount: 1.50, isShared: true))
        sampleFamily.purchases.append(Purchase(name: "Молоко", amount: 2.00, isShared: false))
        
        return PurchasesView(family: sampleFamily)
            .environmentObject(ReportsDatabase.shared)
    }
}

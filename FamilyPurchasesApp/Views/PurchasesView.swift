import SwiftUI

struct PurchasesView: View {
    @ObservedObject var family: Family
    var families: [Family]
    @EnvironmentObject var database: ReportsDatabase // Подключаем базу данных
    @State private var purchaseName: String = ""
    @State private var purchaseAmount: String = ""
    @State private var isShared: Bool = true // По умолчанию участвует в общем расчёте
    @State private var selectedPurchase: Purchase? // Храним выбранную для редактирования покупку
    @State private var totalSum: Double = 0.0
    @State private var sharedSum: Double = 0.0
    @State private var showingDeleteConfirmation = false // Флаг для показа подтверждения удаления
    @State private var showingSummaryModal = false // Для показа модального окна с суммами
    @State private var selectedFamilies: Set<UUID> = [] // Выбранные семьи для текущей покупки
    @State private var sharedPurchases: [Purchase] = [] // Покупки, разделенные с другими семьями
    @State private var starredPurchases: Set<String> = [] // Покупки с одинаковыми названиями
    @State private var showInfoForPurchase: Purchase? = nil // Покупка, для которой показываем информацию

    var body: some View {
        VStack {
            // Верхняя панель с логотипом и кнопкой
            HStack {
                // Логотип
                Image(systemName: "cart.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
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
                .disabled(purchaseName.isEmpty || purchaseAmount.isEmpty)

            if !isShared && !purchaseName.isEmpty && !purchaseAmount.isEmpty {
                // Если покупка не общая, показать список для выбора участвующих семей
                Text("Выберите семьи, которые участвуют в покупке:")
                    .font(.headline)
                    .padding(.top)

                List(families, id: \.id) { otherFamily in
                    Button(action: {
                        if selectedFamilies.contains(otherFamily.id) {
                            if otherFamily.id != family.id {
                                selectedFamilies.remove(otherFamily.id)
                            }
                        } else {
                            selectedFamilies.insert(otherFamily.id)
                        }
                        if selectedFamilies.count == families.count {
                            isShared = true
                        } else {
                            isShared = false
                        }
                    }) {
                        HStack {
                            Text(otherFamily.name)
                            Spacer()
                            if selectedFamilies.contains(otherFamily.id) || otherFamily.id == family.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(otherFamily.id == family.id)
                }
            }

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
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            // Список покупок с возможностью удаления свайпом
            if selectedPurchase == nil || isShared {
                List {
                    // Покупки текущей семьи
                    ForEach(family.purchases) { purchase in
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(purchase.name)
                                        .font(.headline)
                                    Text("Сумма: \(purchase.amount, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()

                                // Иконка для показа дополнительной информации
                                if starredPurchases.contains(purchase.name) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .onTapGesture {
                                            withAnimation {
                                                showInfoForPurchase = showInfoForPurchase == purchase ? nil : purchase
                                            }
                                        }
                                }
                            }

                            // Анимированное появление информации только для покупок, которые есть у других семей
                            if showInfoForPurchase == purchase && starredPurchases.contains(purchase.name) {
                                Text("Эта покупка также имеется у других семей.")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .slide))
                            }

                            // Покупки, разделенные с другими семьями
                            if !purchase.isShared && !purchase.participatingFamilies.filter({ $0 != family.id }).isEmpty {
                                Text("Разделено с:")
                                    .font(.subheadline)
                                    .padding(.top, 4)
                                    .foregroundColor(.blue)

                                ForEach(purchase.participatingFamilies.filter { $0 != family.id }, id: \.self) { familyID in
                                    if let otherFamily = families.first(where: { $0.id == familyID }) {
                                        Text(otherFamily.name)
                                            .font(.caption)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                        .contentShape(Rectangle()) // Позволяет выделять покупку при клике на пустое место
                        .onTapGesture {
                            selectPurchaseForEditing(purchase) // Покупка будет выбрана для редактирования
                            withAnimation {
                                showInfoForPurchase = purchase // Отображаем уведомление с анимацией только для покупок с общими названиями
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                selectedPurchase = purchase
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }

                    // Покупки других семей
                    if !sharedPurchases.isEmpty {
                        Section(header: Text("Разделенные с вами покупки")) {
                            ForEach(sharedPurchases) { purchase in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(purchase.name)
                                            .font(.headline)
                                        Spacer()
                                        Text("Сумма: \(purchase.amount, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    if starredPurchases.contains(purchase.name) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .onTapGesture {
                                                withAnimation {
                                                    showInfoForPurchase = showInfoForPurchase == purchase ? nil : purchase
                                                }
                                            }
                                    }

                                    if showInfoForPurchase == purchase && starredPurchases.contains(purchase.name) {
                                        Text("Эта покупка также имеется у других семей.")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.top, 4)
                                            .transition(.opacity.combined(with: .slide))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Покупки \(family.name)")
        .padding()
        .onAppear {
            selectedFamilies.insert(family.id)
            recalculateSums()
            loadSharedPurchases()
            checkForStarredPurchases()
        }
        .onDisappear {
            database.saveReportsToFile()
        }
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
        .sheet(isPresented: $showingSummaryModal) {
            SummaryModalView(purchases: family.purchases, families: nil, report: nil)
        }
    }

    private func addPurchase() {
        if let amount = Double(purchaseAmount) {
            let newPurchase = Purchase(
                name: purchaseName,
                amount: amount,
                isShared: isShared,
                participatingFamilies: isShared ? [] : Array(selectedFamilies)
            )
            family.purchases.append(newPurchase)
            database.saveReportsToFile()
            clearInputFields()
            recalculateSums()
            checkForStarredPurchases()
        }
    }

    private func updatePurchase(_ purchase: Purchase) {
        if let amount = Double(purchaseAmount), let index = family.purchases.firstIndex(where: { $0.id == purchase.id }) {
            family.purchases[index].name = purchaseName
            family.purchases[index].amount = amount

            if selectedFamilies.isEmpty || selectedFamilies == [family.id] {
                family.purchases[index].isShared = true
                family.purchases[index].participatingFamilies = []
            } else {
                family.purchases[index].isShared = isShared
                family.purchases[index].participatingFamilies = Array(selectedFamilies)
            }

            database.saveReportsToFile()
            clearInputFields()
            selectedPurchase = nil
            recalculateSums()
            checkForStarredPurchases()
        }
    }

    private func deletePurchase(_ purchase: Purchase) {
        if let index = family.purchases.firstIndex(where: { $0.id == purchase.id }) {
            family.purchases.remove(at: index)
            database.saveReportsToFile()
            recalculateSums()

            if selectedPurchase == purchase {
                clearInputFields()
                selectedPurchase = nil
            }
            checkForStarredPurchases()
        }
    }

    private func selectPurchaseForEditing(_ purchase: Purchase) {
        purchaseName = purchase.name
        purchaseAmount = String(format: "%.2f", purchase.amount)
        isShared = purchase.isShared
        selectedFamilies = Set(purchase.participatingFamilies)
        selectedPurchase = purchase
    }

    private func cancelEditing() {
        clearInputFields()
        selectedPurchase = nil
    }

    private func clearInputFields() {
        purchaseName = ""
        purchaseAmount = ""
        isShared = true
        selectedFamilies = []
    }

    private func totalAmount() -> Double {
        return family.purchases.reduce(0) { $0 + $1.amount }
    }

    private func sharedAmount() -> Double {
        return family.purchases.filter { $0.isShared }.reduce(0) { $0 + $1.amount }
    }

    private func recalculateSums() {
        totalSum = totalAmount()
        sharedSum = sharedAmount()
    }

    private func loadSharedPurchases() {
        sharedPurchases = families
            .flatMap { $0.purchases }
            .filter { $0.participatingFamilies.contains(family.id) }
    }

    private func checkForStarredPurchases() {
        let allPurchases = families.flatMap { $0.purchases }
        let duplicatePurchases = Dictionary(grouping: allPurchases, by: { $0.name })
            .filter { $1.count > 1 }
            .keys
        starredPurchases = Set(duplicatePurchases)
    }
}

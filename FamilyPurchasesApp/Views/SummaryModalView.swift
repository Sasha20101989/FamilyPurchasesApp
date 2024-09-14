import Foundation
import SwiftUI

struct SummaryModalView: View {
    var purchases: [Purchase]?
    var families: [Family]?
    let report: Report?
    @State private var totalSum: Double = 0.0
    @State private var sharedSum: Double = 0.0
    @State private var perFamilyShare: Double = 0.0
    @State private var familyDebts: [(family: Family, debt: Double, creditors: [(Family, Double)])] = [] // Храним долги по каждой семье и кредиторов

    var body: some View {
        VStack {
            if let purchases = purchases {
                // Показываем информацию по покупкам
                Text("Суммы покупок")
                    .font(.title)
                    .padding()

                // Общая сумма и сумма покупок, участвующих в расчёте
                VStack(alignment: .leading, spacing: 10) {
                    Text("Общая сумма всех покупок: \(totalSum, specifier: "%.2f") ₽")
                        .font(.title3)
                    Text("Сумма покупок, участвующих в расчёте: \(sharedSum, specifier: "%.2f") ₽")
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    if let families = families {
                        Text("Разделено на всех: \(perFamilyShare, specifier: "%.2f") ₽ на семью")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                
                if !familyDebts.isEmpty {
                    // Показываем информацию по долгам каждой семьи
                    Text("Долги по семьям")
                        .font(.title)
                        .padding()

                    List(familyDebts, id: \.family.id) { familyDebt in
                        VStack(alignment: .leading) {
                            Text(familyDebt.family.name)
                                .font(.headline)
                            
                            if familyDebt.debt < 0 {
                                ForEach(familyDebt.creditors, id: \.0.id) { creditor, amount in
                                    Text("Долг перед: \(creditor.name) — \(amount.formattedWithCurrency())")
                                        .foregroundColor(.red)
                                }
                            } else if familyDebt.debt > 0 {
                                Text("Заплатили больше, долг перед ними: \(familyDebt.debt.formattedWithCurrency())")
                                    .foregroundColor(.green)
                            } else {
                                Text("Заплатили ровно свою долю.")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
            } else {
                // Если ни семьи, ни покупки не переданы
                Text("Нет данных для отображения.")
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer()

            Button(action: {
                // Закрываем модальное окно
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }) {
                Text("Закрыть")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            if let purchases = purchases {
                // Пересчитываем суммы только если переданы покупки
                recalculateSums(purchases: purchases)
            }
            if let families = families {
                // Рассчитываем долги по семьям
                calculateFamilyDebts(families: families)
            }
        }
    }

    // Функция для пересчета сумм
    private func recalculateSums(purchases: [Purchase]) {
        totalSum = purchases.reduce(0) { $0 + $1.amount }.rounded(toPlaces: 2) // Общая сумма всех покупок
        sharedSum = purchases.filter { $0.isShared }
            .reduce(0) { $0 + $1.amount }.rounded(toPlaces: 2) // Сумма покупок, участвующих в расчёте
        if let families = families {
            perFamilyShare = (sharedSum / Double(families.count)).rounded(toPlaces: 2)
        }
    }

    // Функция для расчета долгов по семьям
    private func calculateFamilyDebts(families: [Family]) {
        // Считаем общую сумму всех покупок, которые участвуют в расчете
        let totalSharedAmount = families.flatMap { $0.purchases }
            .filter { $0.isShared }
            .reduce(0) { $0 + $1.amount }
            .rounded(toPlaces: 2)
        
        // Если сумма покупок равна 0, то возвращаем пустой результат
        guard totalSharedAmount > 0 else {
            familyDebts = []
            return
        }

        // Количество семей
        let familyCount = families.count

        // Рассчитываем среднюю сумму на семью
        let averageAmount = (totalSharedAmount / Double(familyCount)).rounded(toPlaces: 2)

        // Определяем для каждой семьи их итоговую сумму и долг/излишек
        var familyBalances: [Family: Double] = [:]
        for family in families {
            let familyTotal = family.purchases.filter { $0.isShared }
                .reduce(0) { $0 + $1.amount }
                .rounded(toPlaces: 2)
            familyBalances[family] = (familyTotal - averageAmount).rounded(toPlaces: 2)
        }

        // Рассчитываем задолженности
        var debts: [(family: Family, debt: Double, creditors: [(Family, Double)])] = []
        var familyBalancesCopy = familyBalances // Копируем баланс для изменений
        for (family, balance) in familyBalances {
            if balance < 0 {
                // Если семья потратила меньше, добавляем её в должники
                var creditors: [(Family, Double)] = []
                var balanceToPay = -balance
                for (creditorFamily, creditorBalance) in familyBalancesCopy where creditorBalance > 0 {
                    let amountOwed = min(balanceToPay, creditorBalance).rounded(toPlaces: 2)
                    if amountOwed > 0 {
                        creditors.append((creditorFamily, amountOwed))
                        familyBalancesCopy[creditorFamily]! -= amountOwed
                        balanceToPay -= amountOwed
                    }
                    if balanceToPay == 0 { break }
                }
                debts.append((family, balance, creditors))
            } else {
                debts.append((family, balance, [])) // Добавляем все семьи, даже если они заплатили ровно свою долю
            }
        }

        familyDebts = debts
    }
}

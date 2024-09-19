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
            if let purchases = purchases, let families = families {
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
                    
                    Text("Разделено на всех: \(perFamilyShare, specifier: "%.2f") ₽ на семью")
                        .font(.title3)
                        .foregroundColor(.orange)
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
                
                if !getFamiliesThatDidNotParticipate(in: purchases, families: families).isEmpty {
                    List(getFamiliesThatDidNotParticipate(in: purchases, families: families), id: \.id) { family in
                        Text("\(family.name) не участвовали в покупках.")
                            .foregroundColor(.gray)
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

    private func calculateFamilyDebts(families: [Family]) {
        var familyBalances: [Family: Double] = [:]

        // Обрабатываем все покупки
        for family in families {
            for purchase in family.purchases {
                if purchase.isShared {
                    // Если покупка общая, делим на всех семей
                    let amountPerFamily = (purchase.amount / Double(families.count)).rounded(toPlaces: 2)
                    for family in families {
                        familyBalances[family, default: 0] -= amountPerFamily
                    }
                    familyBalances[family, default: 0] += purchase.amount
                } else {
                    // Если покупка частная, делим только на участвующие семьи
                    let participatingFamilies = families.filter { purchase.participatingFamilies.contains($0.id) }
                    let amountPerFamily = (purchase.amount / Double(participatingFamilies.count)).rounded(toPlaces: 2)
                    
                    for family in participatingFamilies {
                        familyBalances[family, default: 0] -= amountPerFamily
                    }
                    familyBalances[family, default: 0] += purchase.amount
                }
            }
        }

        // Рассчитываем итоговые долги
        var debts: [(family: Family, debt: Double, creditors: [(Family, Double)])] = []
        var familyBalancesCopy = familyBalances // Копируем баланс для изменений

        for (family, balance) in familyBalances {
            if balance < 0 {
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
            } else if balance > 0 {
                debts.append((family, balance, [])) // Переплатили
            } else {
                debts.append((family, balance, [])) // Заплатили ровно
            }
        }

        familyDebts = debts
    }


    // Получение семей, которые участвовали в разделении покупок
    private func getFamiliesThatParticipated(in purchases: [Purchase], families: [Family]) -> [Family] {
        let participatingFamilyIDs = Set(purchases.flatMap { $0.participatingFamilies })
        let participatingFamilies = families.filter { participatingFamilyIDs.contains($0.id) || $0.purchases.contains { $0.isShared } }
        return participatingFamilies
    }

    // Получение семей, которые не участвовали в разделении покупок
    private func getFamiliesThatDidNotParticipate(in purchases: [Purchase], families: [Family]) -> [Family] {
        let participatingFamilyIDs = Set(purchases.flatMap { $0.participatingFamilies })
        let nonParticipatingFamilies = families.filter { !participatingFamilyIDs.contains($0.id) && !$0.purchases.contains { $0.isShared } }
        return nonParticipatingFamilies
    }

}

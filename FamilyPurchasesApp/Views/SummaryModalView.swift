import Foundation
import SwiftUI

struct SummaryModalView: View {
    var purchases: [Purchase] // Передаем список покупок, который нужно анализировать
    @State private var totalSum: Double = 0.0
    @State private var sharedSum: Double = 0.0

    var body: some View {
        VStack {
            Text("Суммы покупок")
                .font(.title)
                .padding()

            // Общая сумма и сумма покупок, участвующих в расчёте
            VStack(alignment: .leading, spacing: 10) {
                Text("Общая сумма всех покупок: \(totalSum, specifier: "%.2f")")
                    .font(.title2)
                Text("Сумма покупок, участвующих в расчёте: \(sharedSum, specifier: "%.2f")")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .padding()

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
            // Пересчитываем суммы при открытии модального окна
            recalculateSums()
        }
    }

    // Функция для пересчета сумм
    private func recalculateSums() {
        totalSum = purchases.reduce(0) { $0 + $1.amount } // Общая сумма всех покупок
        sharedSum = purchases.filter { $0.isShared }
            .reduce(0) { $0 + $1.amount } // Сумма покупок, участвующих в расчёте
    }
}

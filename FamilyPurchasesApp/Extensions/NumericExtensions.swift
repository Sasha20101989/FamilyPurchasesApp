import Foundation

// Расширение для округления
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    func formattedWithCurrency() -> String {
        String(format: "%.2f", self) + " ₽"
    }
}

import SwiftUI

@main
struct FamilyPurchasesAppApp: App {
    @StateObject var database = ReportsDatabase.shared // Используем ReportsDatabase для управления отчетами
    
    var body: some Scene {
        WindowGroup {
            FamiliesOverviewView()
                .environmentObject(database) // Передаем ReportsDatabase через EnvironmentObject
        }
    }
}

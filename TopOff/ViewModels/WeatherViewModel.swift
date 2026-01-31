import Foundation
import CoreLocation
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var analysis: ConvertibleAdvisor.Analysis?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let weatherService = WeatherService()

    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil

        do {
            let weatherData = try await weatherService.fetchWeather(for: location)
            self.weather = weatherData
            self.analysis = ConvertibleAdvisor.analyze(weather: weatherData)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh(location: CLLocation?) async {
        guard let location = location else {
            errorMessage = "Location not available"
            return
        }

        await fetchWeather(for: location)
    }
}

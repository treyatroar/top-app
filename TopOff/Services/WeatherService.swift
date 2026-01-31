import Foundation
import CoreLocation

actor WeatherService {
    // IMPORTANT: Replace with your own OpenWeatherMap API key
    // Get a free API key at: https://openweathermap.org/api
    private let apiKey = "YOUR_API_KEY_HERE"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        guard var urlComponents = URLComponents(string: baseURL) else {
            throw WeatherError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]

        guard let url = urlComponents.url else {
            throw WeatherError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.noData
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw WeatherError.apiError(errorResponse.message)
                }
                throw WeatherError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let weatherData = try decoder.decode(WeatherData.self, from: data)
            return weatherData
        } catch let error as WeatherError {
            throw error
        } catch let error as DecodingError {
            throw WeatherError.decodingError(error)
        } catch {
            throw WeatherError.networkError(error)
        }
    }
}

private struct APIErrorResponse: Codable {
    let cod: String
    let message: String
}

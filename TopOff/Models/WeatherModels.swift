import Foundation

struct WeatherData: Codable {
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: Wind
    let clouds: Clouds
    let visibility: Int?
    let name: String

    var temperatureFahrenheit: Double {
        return main.temp
    }

    var feelsLikeFahrenheit: Double {
        return main.feelsLike
    }

    var primaryCondition: WeatherCondition? {
        return weather.first
    }

    var windSpeedMph: Double {
        return wind.speed
    }

    var humidityPercent: Int {
        return main.humidity
    }

    var cloudCoverPercent: Int {
        return clouds.all
    }
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Int
    let pressure: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case humidity
        case pressure
    }
}

struct WeatherCondition: Codable, Identifiable {
    let id: Int
    let main: String
    let description: String
    let icon: String

    var isRainy: Bool {
        let rainyConditions = ["Rain", "Drizzle", "Thunderstorm"]
        return rainyConditions.contains(main)
    }

    var isSnowy: Bool {
        return main == "Snow"
    }

    var isClear: Bool {
        return main == "Clear"
    }

    var isCloudy: Bool {
        return main == "Clouds"
    }

    var systemIconName: String {
        switch main {
        case "Clear":
            return icon.contains("n") ? "moon.stars.fill" : "sun.max.fill"
        case "Clouds":
            return "cloud.fill"
        case "Rain", "Drizzle":
            return "cloud.rain.fill"
        case "Thunderstorm":
            return "cloud.bolt.rain.fill"
        case "Snow":
            return "cloud.snow.fill"
        case "Mist", "Fog", "Haze":
            return "cloud.fog.fill"
        default:
            return "cloud.fill"
        }
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int?
    let gust: Double?

    var directionDescription: String {
        guard let deg = deg else { return "" }

        switch deg {
        case 0..<23, 338...360:
            return "N"
        case 23..<68:
            return "NE"
        case 68..<113:
            return "E"
        case 113..<158:
            return "SE"
        case 158..<203:
            return "S"
        case 203..<248:
            return "SW"
        case 248..<293:
            return "W"
        case 293..<338:
            return "NW"
        default:
            return ""
        }
    }
}

struct Clouds: Codable {
    let all: Int
}

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .noData:
            return "No weather data received"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

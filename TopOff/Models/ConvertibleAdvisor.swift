import Foundation

struct ConvertibleAdvisor {
    enum Recommendation: Equatable {
        case perfect
        case good
        case marginal
        case notRecommended

        var title: String {
            switch self {
            case .perfect:
                return "Perfect!"
            case .good:
                return "Good to Go"
            case .marginal:
                return "Maybe"
            case .notRecommended:
                return "Keep It Up"
            }
        }

        var emoji: String {
            switch self {
            case .perfect:
                return "🌞"
            case .good:
                return "👍"
            case .marginal:
                return "🤔"
            case .notRecommended:
                return "🚗"
            }
        }

        var color: String {
            switch self {
            case .perfect:
                return "green"
            case .good:
                return "blue"
            case .marginal:
                return "orange"
            case .notRecommended:
                return "red"
            }
        }
    }

    struct Analysis {
        let recommendation: Recommendation
        let headline: String
        let reasons: [String]
        let tips: [String]
    }

    // Thresholds for ideal convertible weather
    private static let idealTempRange = 65.0...85.0
    private static let acceptableTempRange = 55.0...95.0
    private static let maxWindSpeed = 20.0
    private static let highWindSpeed = 15.0
    private static let maxHumidity = 80
    private static let highHumidity = 70

    static func analyze(weather: WeatherData) -> Analysis {
        var score = 100
        var reasons: [String] = []
        var tips: [String] = []

        // Check for precipitation
        if let condition = weather.primaryCondition {
            if condition.isRainy {
                score -= 100
                reasons.append("Rain in the forecast")
            } else if condition.isSnowy {
                score -= 100
                reasons.append("Snow conditions")
            } else if condition.isClear {
                reasons.append("Clear skies")
            } else if condition.isCloudy {
                if weather.cloudCoverPercent > 80 {
                    score -= 15
                    reasons.append("Heavy cloud cover (\(weather.cloudCoverPercent)%)")
                } else if weather.cloudCoverPercent > 50 {
                    score -= 5
                    reasons.append("Partly cloudy (\(weather.cloudCoverPercent)%)")
                } else {
                    reasons.append("Light clouds")
                }
            }
        }

        // Check temperature
        let temp = weather.temperatureFahrenheit
        if idealTempRange.contains(temp) {
            reasons.append("Perfect temperature (\(Int(temp))°F)")
        } else if acceptableTempRange.contains(temp) {
            if temp < idealTempRange.lowerBound {
                score -= 20
                reasons.append("A bit cool (\(Int(temp))°F)")
                tips.append("Consider bringing a jacket")
            } else {
                score -= 15
                reasons.append("Warm out there (\(Int(temp))°F)")
                tips.append("Stay hydrated and use sunscreen")
            }
        } else {
            score -= 50
            if temp < acceptableTempRange.lowerBound {
                reasons.append("Too cold (\(Int(temp))°F)")
            } else {
                reasons.append("Too hot (\(Int(temp))°F)")
            }
        }

        // Check wind
        let wind = weather.windSpeedMph
        if wind > maxWindSpeed {
            score -= 40
            reasons.append("High winds (\(Int(wind)) mph)")
            tips.append("Wind may make driving uncomfortable")
        } else if wind > highWindSpeed {
            score -= 20
            reasons.append("Breezy conditions (\(Int(wind)) mph)")
            tips.append("Secure any loose items")
        } else if wind > 5 {
            reasons.append("Light breeze (\(Int(wind)) mph)")
        } else {
            reasons.append("Calm winds")
        }

        // Check humidity
        let humidity = weather.humidityPercent
        if humidity > maxHumidity {
            score -= 25
            reasons.append("High humidity (\(humidity)%)")
            tips.append("May feel muggy")
        } else if humidity > highHumidity {
            score -= 10
            reasons.append("Moderate humidity (\(humidity)%)")
        }

        // Check wind gusts
        if let gust = weather.wind.gust, gust > 25 {
            score -= 15
            tips.append("Watch for wind gusts up to \(Int(gust)) mph")
        }

        // Determine recommendation
        let recommendation: Recommendation
        let headline: String

        score = max(0, score)

        switch score {
        case 85...100:
            recommendation = .perfect
            headline = "It's a perfect day to drop the top!"
        case 65..<85:
            recommendation = .good
            headline = "Great conditions for open-air driving."
        case 40..<65:
            recommendation = .marginal
            headline = "Conditions are okay, but not ideal."
        default:
            recommendation = .notRecommended
            headline = "Better to keep the top up today."
        }

        return Analysis(
            recommendation: recommendation,
            headline: headline,
            reasons: reasons,
            tips: tips
        )
    }
}

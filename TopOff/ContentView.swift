import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if locationManager.authorizationStatus == .notDetermined {
                            locationPermissionView
                        } else if let error = locationManager.errorMessage ?? viewModel.errorMessage {
                            errorView(message: error)
                        } else if viewModel.isLoading {
                            loadingView
                        } else if let analysis = viewModel.analysis, let weather = viewModel.weather {
                            weatherContentView(weather: weather, analysis: analysis)
                        } else {
                            waitingForLocationView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("TopOff")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            locationManager.requestLocation()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                Task {
                    await viewModel.fetchWeather(for: location)
                }
            }
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                // Wait for user to grant permission
            } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                      locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        let colors: [Color]
        if let analysis = viewModel.analysis {
            switch analysis.recommendation {
            case .perfect:
                colors = [Color.green.opacity(0.3), Color.blue.opacity(0.2)]
            case .good:
                colors = [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]
            case .marginal:
                colors = [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)]
            case .notRecommended:
                colors = [Color.gray.opacity(0.3), Color.blue.opacity(0.2)]
            }
        } else {
            colors = [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var locationPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Location Access Needed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("TopOff needs your location to check the weather and tell you if it's a good time to drop your convertible top.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Enable Location") {
                locationManager.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Checking weather conditions...")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var waitingForLocationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Getting your location...")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                locationManager.requestLocation()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func weatherContentView(weather: WeatherData, analysis: ConvertibleAdvisor.Analysis) -> some View {
        VStack(spacing: 20) {
            // Location header
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                Text(locationManager.locationName)
                    .font(.headline)
            }

            // Main recommendation card
            recommendationCard(analysis: analysis)

            // Current conditions
            currentConditionsCard(weather: weather)

            // Details
            if !analysis.reasons.isEmpty || !analysis.tips.isEmpty {
                detailsCard(analysis: analysis)
            }
        }
    }

    private func recommendationCard(analysis: ConvertibleAdvisor.Analysis) -> some View {
        VStack(spacing: 12) {
            Text(analysis.recommendation.emoji)
                .font(.system(size: 60))

            Text(analysis.recommendation.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(recommendationColor(for: analysis.recommendation))

            Text(analysis.headline)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func currentConditionsCard(weather: WeatherData) -> some View {
        VStack(spacing: 16) {
            Text("Current Conditions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                conditionItem(
                    icon: weather.primaryCondition?.systemIconName ?? "cloud.fill",
                    value: "\(Int(weather.temperatureFahrenheit))°F",
                    label: weather.primaryCondition?.description.capitalized ?? "Unknown"
                )

                conditionItem(
                    icon: "thermometer.medium",
                    value: "\(Int(weather.feelsLikeFahrenheit))°F",
                    label: "Feels Like"
                )

                conditionItem(
                    icon: "wind",
                    value: "\(Int(weather.windSpeedMph)) mph",
                    label: "Wind \(weather.wind.directionDescription)"
                )

                conditionItem(
                    icon: "humidity",
                    value: "\(weather.humidityPercent)%",
                    label: "Humidity"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func conditionItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func detailsCard(analysis: ConvertibleAdvisor.Analysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis")
                .font(.headline)

            if !analysis.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(analysis.reasons, id: \.self) { reason in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(reason)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if !analysis.tips.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(analysis.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func recommendationColor(for recommendation: ConvertibleAdvisor.Recommendation) -> Color {
        switch recommendation {
        case .perfect:
            return .green
        case .good:
            return .blue
        case .marginal:
            return .orange
        case .notRecommended:
            return .red
        }
    }
}

#Preview {
    ContentView()
}

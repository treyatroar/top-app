import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var locationName: String = "Unknown Location"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        errorMessage = nil
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Could not determine location name: \(error.localizedDescription)"
                    return
                }

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""

                    if !city.isEmpty && !state.isEmpty {
                        self?.locationName = "\(city), \(state)"
                    } else if !city.isEmpty {
                        self?.locationName = city
                    } else if let name = placemark.name {
                        self?.locationName = name
                    }
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        DispatchQueue.main.async {
            self.location = newLocation
            self.reverseGeocode(newLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "Location access denied. Please enable location services in Settings."
                case .locationUnknown:
                    self.errorMessage = "Unable to determine your location. Please try again."
                default:
                    self.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.requestLocation()
            case .denied, .restricted:
                self.errorMessage = "Location access denied. Please enable location services in Settings."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

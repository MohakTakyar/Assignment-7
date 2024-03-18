//
//  ViewController.swift
//  Assignment 7
//
//  Created by user238229 on 3/12/24.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var StartTapped: UIButton!
    @IBOutlet weak var StopTapped: UIButton!
    @IBOutlet weak var CrntSpd: UILabel!
    @IBOutlet weak var MaxSpd: UILabel!
    @IBOutlet weak var AvgSPd: UILabel!
    @IBOutlet weak var Distancetravel: UILabel!
    @IBOutlet weak var MaxAcc: UILabel!
    @IBOutlet weak var Topbar: UIView!
    @IBOutlet weak var BottomBar: UIView!
    

    let locationManager = CLLocationManager()
        var tripStarted = false
        var tripStartTime: Date?
        var currentSpeed: CLLocationSpeed = 0.0
        var maxSpeed: CLLocationSpeed = 0.0
        var totalDistance: CLLocationDistance = 0.0
        var maxAcceleration: Double = 0.0
        var previousLocation: CLLocation?
        var speeds: [CLLocationSpeed] = []
        var lastSpeed: CLLocationSpeed = 0.0
        var totalTime: TimeInterval = 0

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupLocationManager()
        }
        
        func setupUI() {
            Topbar.backgroundColor = .gray
            BottomBar.backgroundColor = .gray
            CrntSpd.text = "0 km/h"
            MaxSpd.text = "0 km/h"
            AvgSPd.text = "0 km/h"
            Distancetravel.text = "0 km"
            MaxAcc.text = "0 m/s²"
        }
        func setupLocationManager() {
            tripStarted = false
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            locationManager.stopUpdatingLocation()
        }
        
        @IBAction func StrtTrp(_ sender: Any) {
            locationManager.requestAlwaysAuthorization()
            tripStarted = true
            tripStartTime = Date()
            totalTime = 0
            startUpdatingLocation()
        }
        
        @IBAction func StopTrp(_ sender: Any) {
            tripStarted = false
            stopUpdatingLocation()
            updateTripSummary()
            BottomBar.backgroundColor = .gray
            currentSpeed = 0.0
            maxSpeed = 0.0
            totalDistance = 0.0
            maxAcceleration = 0.0
            speeds = []
            previousLocation = nil
            updateUI()
            
        }
        func startUpdatingLocation() {
            locationManager.startUpdatingLocation()
            speeds = []
            previousLocation = nil
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            BottomBar.backgroundColor = .green
        }
        func stopUpdatingLocation() {
            locationManager.stopUpdatingLocation()
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .none
        }
        
        func updateUI() {
            CrntSpd.text = String(format: "%.1f km/h", currentSpeed * 3.6)
            MaxSpd.text = String(format: "%.1f km/h", maxSpeed * 3.6)
            AvgSPd.text = speeds.isEmpty ? "0 km/h" : String(format: "%.1f km/h", (speeds.reduce(0, +) / Double(speeds.count)) * 3.6)
            Distancetravel.text = String(format: "%.1f km", totalDistance / 1000)
            MaxAcc.text = String(format: "%.2f m/s²", maxAcceleration)

            if currentSpeed * 3.6 > 115 {
                Topbar.backgroundColor = .red
                Topbar.isHidden = false
            } else {
                Topbar.backgroundColor = .gray
                Topbar.isHidden = true
            }
            let averageSpeed = totalTime > 0 ? totalDistance / totalTime : 0
            AvgSPd.text = String(format: "%.1f km/h", averageSpeed * 3.6)
        }
        
        func updateTripSummary() {
            let totalTime = tripStartTime != nil ? Date().timeIntervalSince(tripStartTime!) : 0
            let averageSpeed = totalTime > 0 ? totalDistance / totalTime : 0
            var previousSpeed = 0.0
            var accelerations: [Double] = []
            for speed in speeds {
                let acceleration = (speed - previousSpeed) / (totalTime / Double(speeds.count))
                accelerations.append(acceleration)
                previousSpeed = speed
            }
            maxAcceleration = accelerations.max() ?? 0.0
            
            AvgSPd.text = String(format: "%.1f km/h", averageSpeed * 3.6)
            MaxAcc.text = String(format: "%.2f m/s²", maxAcceleration)
            
            speeds = []
            totalDistance = 0.0
            maxSpeed = 0.0
            tripStartTime = nil
        }
        
    }

    extension ViewController {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last, tripStarted else { return }
            
            let speed = location.speed >= 0 ? location.speed : 0
            currentSpeed = speed
            maxSpeed = max(maxSpeed, currentSpeed)
            speeds.append(currentSpeed)
            
            if let tripStart = tripStartTime {
                totalTime = Date().timeIntervalSince(tripStart)
            }
            
            if let previous = previousLocation {
                let timeInterval = location.timestamp.timeIntervalSince(previous.timestamp)
                if timeInterval > 0 {
                    let acceleration = abs(speed - lastSpeed) / timeInterval
                    maxAcceleration = max(maxAcceleration, acceleration)
                    let distance = location.distance(from: previous)
                    totalDistance += distance
                }
            }

            lastSpeed = speed
            previousLocation = location

            let averageSpeed = totalTime > 0 ? totalDistance / totalTime : 0
            AvgSPd.text = String(format: "%.1f km/h", averageSpeed * 3.6)
            
            updateUI()
        }
    }


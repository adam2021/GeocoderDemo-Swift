//
//  ReverseViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/3.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller in charge of reverse geocoding.
 */

import UIKit
import MapKit

@objc(ReverseViewController)
class ReverseViewController: UITableViewController, CLLocationManagerDelegate {
    
    private let kSanFranciscoCoordinate = CLLocationCoordinate2DMake(37.776278, -122.419367)
    
    private var locationManager: CLLocationManager?
    
    private var currentUserCoordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    private var selectedRow: Int = 0
    
    private weak var spinner: UIActivityIndicatorView?
    private weak var currentLocationActivityIndicatorView: UIActivityIndicatorView?
    
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start with San Francisco
        currentUserCoordinate = kCLLocationCoordinate2DInvalid
        selectedRow = 0
    }
    
    
    //MARK: - UI Handling
    
    private func showSpinner(_ whichSpinner: UIActivityIndicatorView, withShowState show: Bool) {
        whichSpinner.isHidden = !show
        if show {
            whichSpinner.startAnimating()
        } else {
            whichSpinner.stopAnimating()
        }
    }
    
    private func showCurrentLocationSpinner(_ show: Bool) {
        let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0))!
        
        if self.currentLocationActivityIndicatorView == nil {
            // add the spinner to the table cell
            let curLocSpinner =
            UIActivityIndicatorView(style: .gray)
            curLocSpinner.startAnimating()
            curLocSpinner.frame = CGRect(x: 200.0, y: 0.0, width: 22.0, height: 22.0)
            curLocSpinner.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            
            currentLocationActivityIndicatorView = curLocSpinner // keep a weak ref around for later
            cell.accessoryView = currentLocationActivityIndicatorView
        }
        
        if !show && selectedRow == 1 {
            cell.accessoryView = nil
            cell.accessoryType = .checkmark
        }
    }
    
    private func showSpinner(_ show: Bool) {
        if self.spinner == nil {
            // add the spinner to the table's footer view
            let containerView = UIView(frame:
                CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.width, height: 22.0))
            let spinner =
            UIActivityIndicatorView(style: .gray)
            
            // size and center the spinner
            spinner.frame = CGRect.zero
            spinner.sizeToFit()
            var frame = spinner.frame
            frame.origin.x = (self.tableView.frame.width - frame.width) / 2.0
            spinner.frame = frame
            spinner.startAnimating()
            
            containerView.addSubview(spinner)
            self.tableView.tableFooterView = containerView
            self.spinner = spinner; // keep a weak ref around for later
        }
        
        self.showSpinner(self.spinner!, withShowState: show)
    }
    
    private func lockUI(_ lock: Bool) {
        // prevent user interaction while we are processing the forward geocoding
        self.tableView.allowsSelection = !lock
        self.showSpinner(lock)
    }
    
    
    //MARK: - Display Results
    
    // display the results
    private func displayPlacemarks(_ placemarks: [CLPlacemark]) {
        DispatchQueue.main.async {
            self.lockUI(false)
            
            let plvc = PlacemarksListViewController(placemarks: placemarks)
            self.navigationController!.pushViewController(plvc, animated: true)
        }
    }
    
    // display a given NSError in an UIAlertView
    private func displayError(_ error: NSError) {
        DispatchQueue.main.async {
            self.lockUI(false)
            
            let message: String
            switch error.code {
            case CLError.Code.geocodeFoundNoResult.rawValue:
                message = "kCLErrorGeocodeFoundNoResult"
            case CLError.Code.geocodeCanceled.rawValue:
                message = "kCLErrorGeocodeCanceled"
            case CLError.Code.geocodeFoundPartialResult.rawValue:
                message = "kCLErrorGeocodeFoundNoResult"
            default: message = error.description
            }
            
            let alertController =
            UIAlertController(title: "An error occurred.",
                message: message,
                preferredStyle: .alert)
            let ok =
            UIAlertAction(title: "OK", style: .default,
                handler: {action in
                    // do some thing here
            })
            alertController.addAction(ok)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Choose a location:"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellID = (indexPath.section == 0) ? "SubtitleCell" : "DefaultCell"
        var protoCell = tableView.dequeueReusableCell(withIdentifier: CellID)
        if protoCell == nil {
            let style: UITableViewCell.CellStyle = (indexPath.section == 0) ? .subtitle : .default
            protoCell = UITableViewCell(style: style, reuseIdentifier: CellID)
        }
        let cell = protoCell!
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "San Francisco"
                cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", kSanFranciscoCoordinate.latitude, kSanFranciscoCoordinate.longitude)
                
            case 1:
                cell.textLabel!.text = "Current Location"
                if CLLocationCoordinate2DIsValid(currentUserCoordinate) {
                    cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", currentUserCoordinate.latitude, currentUserCoordinate.longitude)
                } else {
                    let status = CLLocationManager.authorizationStatus()
                    if status == .denied ||
                        status == .restricted
                    {
                        cell.detailTextLabel!.text = "Location Services Disabled"
                    } else {
                        cell.detailTextLabel!.text = "<unknown>"
                    }
                }
            default:
                break
            }
            cell.selectionStyle = .none
            
            let accessoryType: UITableViewCell.AccessoryType =
            (selectedRow == indexPath.row) ? .checkmark : .none
            cell.accessoryType = accessoryType
        } else {
            cell.textLabel!.text = "Geocode Coordinate"
            cell.textLabel!.textAlignment = .center
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        
        if indexPath.section == 1 && indexPath.row == 0 {
            // perform the Geocode
            self.performCoordinateGeocode(self)
        } else {
            let whichCellRow = (indexPath.row == 0) ? 1 : 0
            
            var cell = self.tableView.cellForRow(at: IndexPath(row: whichCellRow, section: 0))
            cell!.accessoryType = .none
            
            cell = self.tableView.cellForRow(at: indexPath)
            cell!.accessoryType = .checkmark
            
            if indexPath.row == 1 {
                self.startUpdatingCurrentLocation()
            }
            
            selectedRow = indexPath.row
        }
    }
    
    
    //MARK: - CLLocationManagerDelegate
    
    private func startUpdatingCurrentLocation() {
        // if location services are restricted do nothing
        let status = CLLocationManager.authorizationStatus()
        if status == .denied ||
            status == .restricted
        {
            return
        }
        
        // if locationManager does not currently exist, create it
        if self.locationManager == nil {
            locationManager = CLLocationManager()
            self.locationManager!.delegate = self
            self.locationManager!.distanceFilter = 10.0 // we don't need to be any more accurate than 10m
        }
        
        // for iOS 8 and later, specific user level permission is required,
        // "when-in-use" authorization grants access to the user's location
        //
        // important: be sure to include NSLocationWhenInUseUsageDescription along with its
        // explanation string in your Info.plist or startUpdatingLocation will not work.
        //
        self.locationManager!.requestWhenInUseAuthorization()
        
        self.locationManager!.startUpdatingLocation()
        
        self.showCurrentLocationSpinner(true)
    }
    
    private func stopUpdatingCurrentLocation() {
        self.locationManager?.stopUpdatingLocation()
        
        self.showCurrentLocationSpinner(false)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//    func locationManager(_ manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        guard !locations.isEmpty else {
            return
        }
        let newLocation = locations[0]
        
        // if the location is older than 30s ignore
        if abs(newLocation.timestamp.timeIntervalSince(Date())) > 30 {
            return
        }
        
        currentUserCoordinate = newLocation.coordinate
        selectedRow = 1
        
        // update the current location cells detail label with these coords
        let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0))!
        cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", currentUserCoordinate.latitude, currentUserCoordinate.longitude)
        
        // after recieving a location, stop updating
        self.stopUpdatingCurrentLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog(error.localizedDescription)
        
        // stop updating
        self.stopUpdatingCurrentLocation()
        
        // since we got an error, set selected location to invalid location
        currentUserCoordinate = kCLLocationCoordinate2DInvalid
        
        // show the error alert
        let alertController =
        UIAlertController(title: "Error updating location",
            message: error.localizedDescription,
            preferredStyle: .alert)
        let ok =
        UIAlertAction(title: "OK",
            style: .default,
            handler: {action in
                // do some thing here
        })
        alertController.addAction(ok)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - Actions
    
    @IBAction func performCoordinateGeocode(_: AnyObject) {
        self.lockUI(true)
        
        let geocoder = CLGeocoder()
        
        let coord = (selectedRow == 0) ? kSanFranciscoCoordinate : currentUserCoordinate
        
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        
        geocoder.reverseGeocodeLocation(location) {placemarks, error in
            if let error = error {
                NSLog("Geocode failed with error: \(error)")
                self.displayError(error as NSError)
                return
            }
            
            //NSLog(@"Received placemarks: %@", placemarks);
            self.displayPlacemarks(placemarks!)
        }
    }
    
}

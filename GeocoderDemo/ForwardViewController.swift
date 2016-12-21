//
//  ForwardViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/3.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller in charge of forward geocoding.
 */

import UIKit
import MapKit

@objc(ForwardViewController)
class ForwardViewController: UITableViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager? // location manager for current location
    
    @IBOutlet private weak var searchStringCell: UITableViewCell!
    @IBOutlet private weak var searchStringTextField: UITextField!
    
    private var searchHintSwitch: UISwitch?
    
    @IBOutlet private /*####weak*/ var searchRadiusCell: UITableViewCell!
    @IBOutlet private /*###weak*/ var searchRadiusLabel: UILabel!
    @IBOutlet private /*###weak*/ var searchRadiusSlider: UISlider!
    
    private var selectedCoordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    private weak var spinner: UIActivityIndicatorView?
    private weak var currentLocationActivityIndicatorView: UIActivityIndicatorView?
    
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedCoordinate = kCLLocationCoordinate2DInvalid
        
        // load our custom table view cells from our nib
        Bundle.main.loadNibNamed("ForwardViewControllerCells", owner: self, options: nil)
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
        if currentLocationActivityIndicatorView == nil {
            // add the spinner to the table cell
            let curLocSpinner =
            UIActivityIndicatorView(activityIndicatorStyle: .gray)
            curLocSpinner.startAnimating()
            curLocSpinner.frame = CGRect(x: 200.0, y: 0.0, width: 22.0, height: 22.0)
            curLocSpinner.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            
            let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1))
            assert(cell != nil)
            if cell != nil {
                cell!.accessoryView = curLocSpinner
            }
            
            currentLocationActivityIndicatorView = curLocSpinner // keep a weak ref around for later
        }
        
        self.showSpinner(currentLocationActivityIndicatorView!, withShowState: show)
    }
    
    private func showSpinner(_ show: Bool) {
        if spinner == nil {
            // add the spinner to the table's footer view
            let containerView = UIView(frame:
                CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.width, height: 22.0))
            let spinner =
            UIActivityIndicatorView(activityIndicatorStyle: .gray)
            
            // size and center the spinner
            spinner.frame = CGRect.zero
            spinner.sizeToFit()
            var frame = spinner.frame
            frame.origin.x = (self.tableView.frame.width - frame.width) / 2.0
            spinner.frame = frame
            spinner.startAnimating()
            
            containerView.addSubview(spinner)
            self.tableView.tableFooterView = containerView
            self.spinner = spinner // keep a weak ref around for later
        }
        
        self.showSpinner(self.spinner!, withShowState: show)
    }
    
    private func lockUI(_ lock: Bool) {
        // prevent user interaction while we are processing the forward geocoding
        self.tableView.allowsSelection = !lock
        self.searchHintSwitch?.isEnabled = !lock
        self.searchRadiusSlider.isEnabled = !lock
        
        self.showSpinner(lock)
    }
    
    
    //MARK: - Display Results
    
    // display the results
    private func displayPlacemarks(_ placemarks: [CLPlacemark]) {
        DispatchQueue.main.async {
            self.lockUI(false)
            
            let plvc = PlacemarksListViewController(placemarks: placemarks)
            self.navigationController?.pushViewController(plvc, animated: true)
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
            default:
                message = error.description
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
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        if section == 1 {
            return self.searchHintSwitch?.isOn ?? false ? 3 : 1
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ----- interface builder generated cells -----
        //
        // search string cell
        if indexPath.section == 0 {
            return self.searchStringCell
        }
        
        // search radius cell
        if indexPath.section == 1 && indexPath.row == 2 {
            return self.searchRadiusCell
        }
        
        // ----- non interface builder generated cells -----
        //
        // search hint cell
        if indexPath.section == 1 && indexPath.row == 0 {
            var protoCell = tableView.dequeueReusableCell(withIdentifier: "radiusToggleCell")
            if protoCell == nil {
                protoCell = UITableViewCell(style: .subtitle, reuseIdentifier: "radiusToggleCell")
            }
            let cell = protoCell!
            cell.selectionStyle = .none
            
            searchHintSwitch = UISwitch(frame: CGRect.zero)
            self.searchHintSwitch!.sizeToFit()
            self.searchHintSwitch!.addTarget(self, action: #selector(ForwardViewController.hintSwitchChanged(_:)), for: .touchUpInside)
            cell.accessoryView = self.searchHintSwitch
            
            cell.textLabel!.text = "Include Hint Region"
            return cell
        }
        
        // current location cell
        if indexPath.section == 1 && indexPath.row == 1 {
            var protoCell = tableView.dequeueReusableCell(withIdentifier: "radiusCell")
            if protoCell == nil {
                protoCell = UITableViewCell(style: .subtitle, reuseIdentifier: "radiusCell")
            }
            let cell = protoCell!
            
            cell.textLabel!.text = "Current Location"
            
            let status = CLLocationManager.authorizationStatus()
            if status == .denied || status == .restricted {
                cell.detailTextLabel!.text = "Location Services Disabled"
            } else {
                cell.detailTextLabel!.text = "<unknown>"
            }
            cell.selectionStyle = .none
            return cell
        }
        
        // basic cell
        var protoCell = tableView.dequeueReusableCell(withIdentifier: "basicCell")
        if protoCell == nil {
            protoCell = UITableViewCell(style: .default, reuseIdentifier: "basicCell")
        }
        let cell = protoCell!
        
        // geocode button
        if indexPath.section == 2 && indexPath.row == 0 {
            cell.textLabel!.text = "Geocode String"
            cell.textLabel!.textAlignment = .center
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        
        if indexPath.section == 2 && indexPath.row == 0 {
            // perform the Geocode
            self.performStringGeocode(self)
        }
    }
    
    
    //MARK: - UITextFieldDelegate
    
    // dismiss the keyboard for the textfields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - UIScrollViewDelegate
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // dismiss the keyboard upon a scroll
        self.searchStringTextField.resignFirstResponder()
    }
    
    
    //MARK: - CLLocationManagerDelegate
    
    private func startUpdatingCurrentLocation() {
        // if location services are restricted do nothing
        let status = CLLocationManager.authorizationStatus()
        if status == .denied || status == .restricted {
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
        self.locationManager!.requestAlwaysAuthorization()
        
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
        
        selectedCoordinate = newLocation.coordinate
        
        // update the current location cells detail label with these coords
        let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1))!
        cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", selectedCoordinate.latitude, selectedCoordinate.longitude)
        
        // after recieving a location, stop updating
        self.stopUpdatingCurrentLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog(error.localizedDescription)
        
        // stop updating
        self.stopUpdatingCurrentLocation()
        
        // since we got an error, set selected location to invalid location
        selectedCoordinate = kCLLocationCoordinate2DInvalid
        
        // show the error alert
        let alertController =
        UIAlertController(title: "Error obtaining location",
            message: error.localizedDescription,
            preferredStyle: .alert)
        let ok =
        UIAlertAction(title: "OK", style: .default,
            handler: {action in
                // do some thing here
        })
        alertController.addAction(ok)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - Actions
    
    @IBAction func hintSwitchChanged(_: AnyObject) {
        // show or hide the region hint cells
        let indexes = [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)]
        
        if self.searchHintSwitch?.isOn ?? false {
            self.tableView.insertRows(at: indexes, with: .automatic)
            
            // start searching for our location coordinates
            self.startUpdatingCurrentLocation()
        } else {
            self.tableView.deleteRows(at: indexes, with: .automatic)
        }
    }
    
    @IBAction func radiusChanged(_: AnyObject) {
        self.searchRadiusLabel.text = String(format: "%1.1f km", Double(self.searchRadiusSlider.value/1000.0))
    }
    
    @IBAction func performStringGeocode(_: AnyObject) {
        // dismiss the keyboard if it's currently open
        if self.searchStringTextField.isFirstResponder {
            self.searchStringTextField.resignFirstResponder()
        }
        
        self.lockUI(true)
        
        let geocoder = CLGeocoder()
        
        // if we are going to includer region hint
        if self.searchHintSwitch?.isOn ?? false {
            // use hint region
            let dist = self.searchRadiusSlider.value // 50,000m (50km)
            let point = selectedCoordinate
            let region = CLCircularRegion(center: point,
                radius: CLLocationDistance(dist),
                identifier: "Hint Region")
            
            geocoder.geocodeAddressString(self.searchStringTextField.text ?? "", in: region) {placemarks, error in
                if error != nil {
                    NSLog("Geocode failed with error: \(error!)")
                    self.displayError(error! as NSError)
                    return
                    
                }
                
                //NSLog(@"Received placemarks: %@", placemarks);
                self.displayPlacemarks(placemarks!)
            }
        } else {
            // don't use a hint region
            geocoder.geocodeAddressString(self.searchStringTextField.text ?? "") {placemarks, error in
                if error != nil {
                    NSLog("Geocode failed with error: \(error!)")
                    self.displayError(error! as NSError)
                    return
                }
                
                //NSLog(@"Received placemarks: %@", placemarks);
                self.displayPlacemarks(placemarks!)
            }
        }
    }
    
}

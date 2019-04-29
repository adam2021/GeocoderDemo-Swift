//
//  CoordinateSelectorTableViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/4.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 UITableViewController that allows for the selection of a CLCoordinate2D.
 */

import UIKit
import CoreLocation
// pull this in so we can use CNMutablePostalAddress
import Contacts

enum CoordinateSelectorLastSelectedType: Int {
    case search = 1
    case current
    case undefined
}

// this class contains a list of names and associated Coordinates as well as allowing
// for the selection of a custom Coordinate it vends the users selection through
// the 4 selected properties..
//
@objc(CoordinateSelectorTableViewController)
class CoordinateSelectorTableViewController: UITableViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    private(set) var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    private(set) var selectedType: CoordinateSelectorLastSelectedType = .undefined
    private(set) var selectedName: String = ""
    
    private var searchPlacemarksCache: [CLPlacemark]?
    
    private var locationManager: CLLocationManager?
    
    private var checkedIndexPath: IndexPath?
    
    @IBOutlet private weak var searchCell: UITableViewCell!
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var searchSpinner: UIActivityIndicatorView!
    
    @IBOutlet private weak var currentLocationCell: UITableViewCell!
    @IBOutlet private weak var currentLocationLabel: UILabel!
    @IBOutlet private weak var currentLocationActivityIndicatorView: UIActivityIndicatorView!
    
    private var selectedIndex: Int = 0
    
    
    //MARK: -
    
    init() {
        // do some default variables setup
        selectedCoordinate = kCLLocationCoordinate2DInvalid
        selectedType = .undefined
        super.init(style: .grouped)
        self.updateSelectedName()
        self.updateSelectedCoordinate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Select a Place"
        self.clearsSelectionOnViewWillAppear = false
        
        // load our custom table view cells from our nib
        Bundle.main.loadNibNamed("CoordinateSelectorTableViewCells", owner: self, options: nil)
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.updateSelectedCoordinate()
        
        // stop updating, we don't care no more…
        if self.selectedType == .current {
            self.stopUpdatingCurrentLocation()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start updating, we might care again
        if self.selectedType == .current {
            self.startUpdatingCurrentLocation()
        }
    }
    
    
    //MARK: - Utilities
    
    private func postalAddressFromPlacemark(_ placemark: CLPlacemark?) -> String {
        // use the Contacts framework to create a readable formatter address
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = placemark?.thoroughfare ?? ""
        postalAddress.city = placemark?.locality ?? ""
        postalAddress.state = placemark?.administrativeArea ?? ""
        postalAddress.postalCode = placemark?.postalCode ?? ""
        postalAddress.country = placemark?.country ?? ""
        postalAddress.isoCountryCode = placemark?.isoCountryCode ?? ""
        
        return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil
        if section == 1 {
            title = "OR"
        }
        return title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        if section == 0 {
            return 1 + (self.searchPlacemarksCache?.count ?? 0)
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        
        var protoCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if protoCell == nil {
            protoCell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }
        var cell = protoCell!
        
        // configure the cell...
        let section = indexPath.section
        if section == 1 {
            // Current location
            //
            // load the custom cell from the Nib
            cell = currentLocationCell
            cell.selectionStyle = .none
            
            let status = CLLocationManager.authorizationStatus()
            if status == .denied ||
                status == .restricted
            {
                currentLocationLabel.text = "Location Services Disabled"
            }
            
        } else if section == 0 {
            // Search
            if indexPath.row == 0 {
                return searchCell
            }
            
            // otherwise display the list of results
            let placemark = self.searchPlacemarksCache?[indexPath.row - 1]
            
            cell.textLabel!.lineBreakMode = .byWordWrapping
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.font = UIFont.systemFont(ofSize: 16.0)
            cell.textLabel!.text = self.postalAddressFromPlacemark(placemark)
            
            cell.detailTextLabel!.lineBreakMode = .byWordWrapping
            cell.detailTextLabel!.font = UIFont.boldSystemFont(ofSize: 16.0)
            let latitude = placemark?.location?.coordinate.latitude ?? 0.0
            let longitude = placemark?.location?.coordinate.longitude ?? 0.0
            cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", latitude, longitude)
        }
        
        // show a check next to the selected option / cell
        if self.checkedIndexPath == indexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    
    //MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // set the selected type
        let section = indexPath.section
        
        if section == 1 {
            selectedType = .current
        } else if section == 0 {
            selectedType = .search
        }
        
        // deselect the cell
        self.tableView.cellForRow(at: indexPath)?.isSelected = false
        
        // if this is the search cell itself do nothing
        if selectedType == .search && indexPath.row == 0 {
            return
        }
        
        // if location services are restricted do nothing
        if selectedType == .current {
            let status = CLLocationManager.authorizationStatus()
            if status == .denied ||
                status == .restricted
            {
                return
            }
        }
        
        // set the selected row index
        selectedIndex = indexPath.row
        
        // move the checkmark from the previous to the new cell
        if checkedIndexPath != nil {
            self.tableView.cellForRow(at: self.checkedIndexPath!)?.accessoryType = .none
        }
        self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        // set this row to be checked on next reload
        if self.checkedIndexPath != indexPath {
            checkedIndexPath = indexPath
        }
        
        // set the selected name based on the selected type
        self.updateSelectedName()
        
        // set the selected coordinates based on the selected type and index
        self.updateSelectedCoordinate()
        
        // if current location has been selected, start updating current location
        if selectedType == .current {
            self.startUpdatingCurrentLocation()
        }
        
        // if regular or search, pop back to previous level
        if selectedType == .search {
            self.navigationController!.popViewController(animated: true)
        }
    }
    
    
    //MARK: - update selected cell
    
    // keys off selectedType and selectedCoordinates
    private func updateSelectedName() {
        switch selectedType {
        case .current:
            selectedName = "Current Location"
            
        case .search:
            let placemark = self.searchPlacemarksCache?[selectedIndex - 1] // take into account the first 'search' cell
            selectedName = self.postalAddressFromPlacemark(placemark)
            
        case .undefined:
            selectedName = "Select a Place"
        }
    }
    
    // keys off selectedType and selectedCoordinates
    private func updateSelectedCoordinate() {
        switch selectedType {
        case .search:
            // allow for the selection of search results,
            // take into account the first 'search' cell
            let placemark = self.searchPlacemarksCache?[selectedIndex - 1]
            selectedCoordinate = placemark?.location?.coordinate ?? kCLLocationCoordinate2DInvalid
            
        case .undefined:
            selectedCoordinate = kCLLocationCoordinate2DInvalid
            
        case .current:
            break // no need to update for current location (CL delegate callback sets it)
        }
    }
    
    
    //MARK: - current location
    
    private func startUpdatingCurrentLocation() {
        // if location services are restricted do nothing
        let status = CLLocationManager.authorizationStatus()
        if status == .denied ||
            status == .restricted
        {
            return
        }
        
        // if locationManager does not currently exist, create it.
        if self.locationManager == nil {
            locationManager = CLLocationManager()
            self.locationManager!.delegate = self
            self.locationManager!.distanceFilter = 10.0 //we don't need to be any more accurate than 10m
        }
        
        // for iOS 8 and later, specific user level permission is required,
        // "when-in-use" authorization grants access to the user's location
        //
        // important: be sure to include NSLocationWhenInUseUsageDescription along with its
        // explanation string in your Info.plist or startUpdatingLocation will not work.
        //
        self.locationManager!.requestWhenInUseAuthorization()
        
        self.locationManager!.startUpdatingLocation()
        self.currentLocationActivityIndicatorView.startAnimating()
    }
    
    private func stopUpdatingCurrentLocation() {
        self.locationManager?.stopUpdatingLocation()
        self.currentLocationActivityIndicatorView.stopAnimating()
    }
    
    
    //MARK: - CLLocationManagerDelegate - Location updates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//    func locationManager(_ manager: CLLocationManager,
//        didUpdateToLocation newLocation: CLLocation,
//        fromLocation oldLocation: CLLocation)
//    {
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
        currentLocationLabel.text = String(format: "φ:%.4F, λ:%.4F", selectedCoordinate.latitude, selectedCoordinate.longitude)
        
        // after recieving a location, stop updating
        self.stopUpdatingCurrentLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog(error.localizedDescription)
        
        // stop updating
        self.stopUpdatingCurrentLocation()
        
        // set selected location to invalid location
        selectedType = .undefined
        selectedCoordinate = kCLLocationCoordinate2DInvalid
        selectedName = "Select a Location"
        currentLocationLabel.text = "Error updating location"
        
        // remove the check from the current Location cell
        currentLocationCell.accessoryType = .none
        
        // show an alert
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
    
    // invoked when the authorization status changes for this application
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    
    //MARK: - placemarks search
    
    private func lockSearch(_ lock: Bool) {
        self.searchTextField.isEnabled = !lock
        self.searchSpinner.isHidden = !lock
    }
    
    private func performPlacemarksSearch() {
        self.lockSearch(true)
        
        // perform geocode
        let geocoder = CLGeocoder()
        
        
        geocoder.geocodeAddressString(self.searchTextField.text ?? "") {placemarks, error in
            // There is no guarantee that the CLGeocodeCompletionHandler will be invoked on the main thread.
            // So we use a dispatch_async(dispatch_get_main_queue(),^{}) call to ensure that UI updates are always
            // performed from the main thread.
            //
            DispatchQueue.main.async {
                if (self.checkedIndexPath?.section ?? 0) == 0 {
                    // clear any current selections if they are search result selections
                    self.checkedIndexPath = nil
                }
                
                self.searchPlacemarksCache = placemarks; // might be nil
                self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
                self.lockSearch(false)
                
                if placemarks?.count ?? 0 == 0 {
                    // show an alert if no results were found
                    let alertController =
                    UIAlertController(title: "No places were found",
                        message: nil,
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
            }
        }
    }
    
    
    //MARK: - UITextFieldDelegate
    
    // dismiss the keyboard for the textfields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        
        // initiate a search
        self.performPlacemarksSearch()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateSelectedCoordinate()
    }
    
}

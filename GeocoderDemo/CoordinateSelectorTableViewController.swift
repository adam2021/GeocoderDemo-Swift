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
    case Search = 1
    case Current
    case Undefined
}

// this class contains a list of names and associated Coordinates as well as allowing
// for the selection of a custom Coordinate it vends the users selection through
// the 4 selected properties..
//
@objc(CoordinateSelectorTableViewController)
class CoordinateSelectorTableViewController: UITableViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    private(set) var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    private(set) var selectedType: CoordinateSelectorLastSelectedType = .Undefined
    private(set) var selectedName: String = ""
    
    private var searchPlacemarksCache: [CLPlacemark]?
    
    private var locationManager: CLLocationManager?
    
    private var checkedIndexPath: NSIndexPath?
    
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
        selectedType = .Undefined
        super.init(style: .Grouped)
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
        NSBundle.mainBundle().loadNibNamed("CoordinateSelectorTableViewCells", owner: self, options: nil)
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.updateSelectedCoordinate()
        
        // stop updating, we don't care no more…
        if self.selectedType == .Current {
            self.stopUpdatingCurrentLocation()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // start updating, we might care again
        if self.selectedType == .Current {
            self.startUpdatingCurrentLocation()
        }
    }
    
    
    //MARK: - Utilities
    
    private func postalAddressFromPlacemark(placemark: CLPlacemark?) -> String {
        // use the Contacts framework to create a readable formatter address
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = placemark?.thoroughfare ?? ""
        postalAddress.city = placemark?.locality ?? ""
        postalAddress.state = placemark?.administrativeArea ?? ""
        postalAddress.postalCode = placemark?.postalCode ?? ""
        postalAddress.country = placemark?.country ?? ""
        postalAddress.ISOCountryCode = placemark?.ISOcountryCode ?? ""
        
        return CNPostalAddressFormatter.stringFromPostalAddress(postalAddress, style: .MailingAddress)
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil
        if section == 1 {
            title = "OR"
        }
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        if section == 0 {
            return 1 + (self.searchPlacemarksCache?.count ?? 0)
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        
        var protoCell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if protoCell == nil {
            protoCell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        }
        var cell = protoCell!
        
        // configure the cell...
        let section = indexPath.section
        if section == 1 {
            // Current location
            //
            // load the custom cell from the Nib
            cell = currentLocationCell
            cell.selectionStyle = .None
            
            let status = CLLocationManager.authorizationStatus()
            if status == .Denied ||
                status == .Restricted
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
            
            cell.textLabel!.lineBreakMode = .ByWordWrapping
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.font = UIFont.systemFontOfSize(16.0)
            cell.textLabel!.text = self.postalAddressFromPlacemark(placemark)
            
            cell.detailTextLabel!.lineBreakMode = .ByWordWrapping
            cell.detailTextLabel!.font = UIFont.boldSystemFontOfSize(16.0)
            let latitude = placemark?.location?.coordinate.latitude ?? 0.0
            let longitude = placemark?.location?.coordinate.longitude ?? 0.0
            cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", latitude, longitude)
        }
        
        // show a check next to the selected option / cell
        if self.checkedIndexPath == indexPath {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    
    //MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // set the selected type
        let section = indexPath.section
        
        if section == 1 {
            selectedType = .Current
        } else if section == 0 {
            selectedType = .Search
        }
        
        // deselect the cell
        self.tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        
        // if this is the search cell itself do nothing
        if selectedType == .Search && indexPath.row == 0 {
            return
        }
        
        // if location services are restricted do nothing
        if selectedType == .Current {
            let status = CLLocationManager.authorizationStatus()
            if status == .Denied ||
                status == .Restricted
            {
                return
            }
        }
        
        // set the selected row index
        selectedIndex = indexPath.row
        
        // move the checkmark from the previous to the new cell
        if checkedIndexPath != nil {
            self.tableView.cellForRowAtIndexPath(self.checkedIndexPath!)?.accessoryType = .None
        }
        self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        
        // set this row to be checked on next reload
        if self.checkedIndexPath != indexPath {
            checkedIndexPath = indexPath
        }
        
        // set the selected name based on the selected type
        self.updateSelectedName()
        
        // set the selected coordinates based on the selected type and index
        self.updateSelectedCoordinate()
        
        // if current location has been selected, start updating current location
        if selectedType == .Current {
            self.startUpdatingCurrentLocation()
        }
        
        // if regular or search, pop back to previous level
        if selectedType == .Search {
            self.navigationController!.popViewControllerAnimated(true)
        }
    }
    
    
    //MARK: - update selected cell
    
    // keys off selectedType and selectedCoordinates
    private func updateSelectedName() {
        switch selectedType {
        case .Current:
            selectedName = "Current Location"
            
        case .Search:
            let placemark = self.searchPlacemarksCache?[selectedIndex - 1] // take into account the first 'search' cell
            selectedName = self.postalAddressFromPlacemark(placemark)
            
        case .Undefined:
            selectedName = "Select a Place"
        }
    }
    
    // keys off selectedType and selectedCoordinates
    private func updateSelectedCoordinate() {
        switch selectedType {
        case .Search:
            // allow for the selection of search results,
            // take into account the first 'search' cell
            let placemark = self.searchPlacemarksCache?[selectedIndex - 1]
            selectedCoordinate = placemark?.location?.coordinate ?? kCLLocationCoordinate2DInvalid
            
        case .Undefined:
            selectedCoordinate = kCLLocationCoordinate2DInvalid
            
        case .Current:
            break // no need to update for current location (CL delegate callback sets it)
        }
    }
    
    
    //MARK: - current location
    
    private func startUpdatingCurrentLocation() {
        // if location services are restricted do nothing
        let status = CLLocationManager.authorizationStatus()
        if status == .Denied ||
            status == .Restricted
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
    
    func locationManager(manager: CLLocationManager,
        didUpdateToLocation newLocation: CLLocation,
        fromLocation oldLocation: CLLocation)
    {
        // if the location is older than 30s ignore
        if abs(newLocation.timestamp.timeIntervalSinceDate(NSDate())) > 30 {
            return
        }
        
        selectedCoordinate = newLocation.coordinate
        
        // update the current location cells detail label with these coords
        currentLocationLabel.text = String(format: "φ:%.4F, λ:%.4F", selectedCoordinate.latitude, selectedCoordinate.longitude)
        
        // after recieving a location, stop updating
        self.stopUpdatingCurrentLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("%@", error)
        
        // stop updating
        self.stopUpdatingCurrentLocation()
        
        // set selected location to invalid location
        selectedType = .Undefined
        selectedCoordinate = kCLLocationCoordinate2DInvalid
        selectedName = "Select a Location"
        currentLocationLabel.text = "Error updating location"
        
        // remove the check from the current Location cell
        currentLocationCell.accessoryType = .None
        
        // show an alert
        let alertController =
        UIAlertController(title: "Error updating location",
            message: error.localizedDescription,
            preferredStyle: .Alert)
        let ok =
        UIAlertAction(title: "OK",
            style: .Default,
            handler: {action in
                // do some thing here
        })
        alertController.addAction(ok)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // invoked when the authorization status changes for this application
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    }
    
    
    //MARK: - placemarks search
    
    private func lockSearch(lock: Bool) {
        self.searchTextField.enabled = !lock
        self.searchSpinner.hidden = !lock
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
            dispatch_async(dispatch_get_main_queue()) {
                if (self.checkedIndexPath?.section ?? 0) == 0 {
                    // clear any current selections if they are search result selections
                    self.checkedIndexPath = nil
                }
                
                self.searchPlacemarksCache = placemarks; // might be nil
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
                self.lockSearch(false)
                
                if placemarks?.count ?? 0 == 0 {
                    // show an alert if no results were found
                    let alertController =
                    UIAlertController(title: "No places were found",
                        message: nil,
                        preferredStyle: .Alert)
                    let ok =
                    UIAlertAction(title: "OK",
                        style: .Default,
                        handler: {action in
                            // do some thing here
                    })
                    alertController.addAction(ok)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    //MARK: - UITextFieldDelegate
    
    // dismiss the keyboard for the textfields
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        
        // initiate a search
        self.performPlacemarksSearch()
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.updateSelectedCoordinate()
    }
    
}
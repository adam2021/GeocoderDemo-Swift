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
    
    private func showSpinner(whichSpinner: UIActivityIndicatorView, withShowState show: Bool) {
        whichSpinner.hidden = !show
        if show {
            whichSpinner.startAnimating()
        } else {
            whichSpinner.stopAnimating()
        }
    }
    
    private func showCurrentLocationSpinner(show: Bool) {
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!
        
        if self.currentLocationActivityIndicatorView == nil {
            // add the spinner to the table cell
            let curLocSpinner =
            UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            curLocSpinner.startAnimating()
            curLocSpinner.frame = CGRectMake(200.0, 0.0, 22.0, 22.0)
            curLocSpinner.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
            
            currentLocationActivityIndicatorView = curLocSpinner // keep a weak ref around for later
            cell.accessoryView = currentLocationActivityIndicatorView
        }
        
        if !show && selectedRow == 1 {
            cell.accessoryView = nil
            cell.accessoryType = .Checkmark
        }
    }
    
    private func showSpinner(show: Bool) {
        if self.spinner == nil {
            // add the spinner to the table's footer view
            let containerView = UIView(frame:
                CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 22.0))
            let spinner =
            UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            
            // size and center the spinner
            spinner.frame = CGRectZero
            spinner.sizeToFit()
            var frame = spinner.frame
            frame.origin.x = (CGRectGetWidth(self.tableView.frame) - CGRectGetWidth(frame)) / 2.0
            spinner.frame = frame
            spinner.startAnimating()
            
            containerView.addSubview(spinner)
            self.tableView.tableFooterView = containerView
            self.spinner = spinner; // keep a weak ref around for later
        }
        
        self.showSpinner(self.spinner!, withShowState: show)
    }
    
    private func lockUI(lock: Bool) {
        // prevent user interaction while we are processing the forward geocoding
        self.tableView.allowsSelection = !lock
        self.showSpinner(lock)
    }
    
    
    //MARK: - Display Results
    
    // display the results
    private func displayPlacemarks(placemarks: [CLPlacemark]) {
        dispatch_async(dispatch_get_main_queue()) {
            self.lockUI(false)
            
            let plvc = PlacemarksListViewController(placemarks: placemarks)
            self.navigationController!.pushViewController(plvc, animated: true)
        }
    }
    
    // display a given NSError in an UIAlertView
    private func displayError(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            self.lockUI(false)
            
            let message: String
            switch error.code {
            case CLError.GeocodeFoundNoResult.rawValue:
                message = "kCLErrorGeocodeFoundNoResult"
            case CLError.GeocodeCanceled.rawValue:
                message = "kCLErrorGeocodeCanceled"
            case CLError.GeocodeFoundPartialResult.rawValue:
                message = "kCLErrorGeocodeFoundNoResult"
            default: message = error.description
            }
            
            let alertController =
            UIAlertController(title: "An error occurred.",
                message: message,
                preferredStyle: .Alert)
            let ok =
            UIAlertAction(title: "OK", style: .Default,
                handler: {action in
                    // do some thing here
            })
            alertController.addAction(ok)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Choose a location:"
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellID = (indexPath.section == 0) ? "SubtitleCell" : "DefaultCell"
        var protoCell = tableView.dequeueReusableCellWithIdentifier(CellID)
        if protoCell == nil {
            let style: UITableViewCellStyle = (indexPath.section == 0) ? .Subtitle : .Default
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
                    if status == .Denied ||
                        status == .Restricted
                    {
                        cell.detailTextLabel!.text = "Location Services Disabled"
                    } else {
                        cell.detailTextLabel!.text = "<unknown>"
                    }
                }
            default:
                break
            }
            cell.selectionStyle = .None
            
            let accessoryType: UITableViewCellAccessoryType =
            (selectedRow == indexPath.row) ? .Checkmark : .None
            cell.accessoryType = accessoryType
        } else {
            cell.textLabel!.text = "Geocode Coordinate"
            cell.textLabel!.textAlignment = .Center
            cell.accessoryType = .DisclosureIndicator
        }
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        
        if indexPath.section == 1 && indexPath.row == 0 {
            // perform the Geocode
            self.performCoordinateGeocode(self)
        } else {
            let whichCellRow = (indexPath.row == 0) ? 1 : 0
            
            var cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: whichCellRow, inSection: 0))
            cell!.accessoryType = .None
            
            cell = self.tableView.cellForRowAtIndexPath(indexPath)
            cell!.accessoryType = .Checkmark
            
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
        if status == .Denied ||
            status == .Restricted
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
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        // if the location is older than 30s ignore
        if abs(newLocation.timestamp.timeIntervalSinceDate(NSDate())) > 30 {
            return
        }
        
        currentUserCoordinate = newLocation.coordinate
        selectedRow = 1
        
        // update the current location cells detail label with these coords
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!
        cell.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", currentUserCoordinate.latitude, currentUserCoordinate.longitude)
        
        // after recieving a location, stop updating
        self.stopUpdatingCurrentLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("%@", error)
        
        // stop updating
        self.stopUpdatingCurrentLocation()
        
        // since we got an error, set selected location to invalid location
        currentUserCoordinate = kCLLocationCoordinate2DInvalid
        
        // show the error alert
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
    
    
    //MARK: - Actions
    
    @IBAction func performCoordinateGeocode(_: AnyObject) {
        self.lockUI(true)
        
        let geocoder = CLGeocoder()
        
        let coord = (selectedRow == 0) ? kSanFranciscoCoordinate : currentUserCoordinate
        
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        
        geocoder.reverseGeocodeLocation(location) {placemarks, error in
            if let error = error {
                NSLog("Geocode failed with error: %@", error)
                self.displayError(error)
                return
            }
            
            //NSLog(@"Received placemarks: %@", placemarks);
            self.displayPlacemarks(placemarks!)
        }
    }
    
}
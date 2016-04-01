//
//  PlacemarkViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/3.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 UITableViewController that displays the propeties of a CLPlacemark.
 */

import UIKit
import MapKit

// custom table view cell for holding the placemark's map
@objc(MapTableViewCell)
class MapTableViewCell: UITableViewCell {
    @IBOutlet weak var mapView: MKMapView!
}


//MARK: -
private let AddressDictionaryKeys = [
    "name",
    "thoroughfare",
    "subThoroughfare",
    "locality",
    "subLocality",
    "administrativeArea",
    "subAdministrativeArea",
    "postalCode",
    "ISOcountryCode",
    "country"]
private let LocationKeys = [
    "coordinate.latitude",
    "coordinate.longitude",
    "altitude",
    "horizontalAccuracy",
    "verticalAccuracy",
    "course",
    "speed",
    "timestamp"]
private let RegionKeys = [
    "center.latitude",
    "center.longitude",
    "radius",
    "identifier"]

@objc(PlacemarkViewController)
class PlacemarkViewController: UITableViewController, MKAnnotation {
    
    private var placemark: CLPlacemark?
    @IBOutlet private var mapCell: MapTableViewCell!   // points to a custom cell in "MapCell.xib"
    
    
    //MARK: -
    
    private let PlacemarkViewControllerSections: [(count: Int, title: String)] = [
        (AddressDictionaryKeys.count, "addressDictionary - (NSDictionary)"),    // dict
        (RegionKeys.count, "region - (CLCircularRegion)"),                   // region
        (LocationKeys.count, "location - (CLLocation)"),               // location
        ( 1, "Map"),                                   // map
        ( 1, ""),                                      // map url
    ]
    
    init(placemark: CLPlacemark?) {
        self.placemark = placemark
        super.init(style: .Grouped)
    }
    
    convenience override init(style: UITableViewStyle) {
        self.init(placemark: nil)
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init(placemark: nil)
    }
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.init(placemark: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "CLPlacemark Details"
        
        // load our custom map cell from 'MapCell.xib' (connects our IBOutlet to that cell)
        NSBundle.mainBundle().loadNibNamed("MapCell", owner: self, options: nil)
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return PlacemarkViewControllerSections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return PlacemarkViewControllerSections[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return PlacemarkViewControllerSections[section].title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return self.cellForAddressDictionaryIndex(indexPath.row)
        case 1: return self.cellForRegionIndex(indexPath.row)
        case 2: return self.cellForLocationIndex(indexPath.row)
        case 3:
            // point the map to our placemark
            let region = MKCoordinateRegionMakeWithDistance(self.placemark?.location?.coordinate ?? CLLocationCoordinate2D(), 200, 200)
            self.mapCell.mapView.region = region
            
            // add a pin using self as the object implementing the MKAnnotation protocol
            self.mapCell.mapView.addAnnotation(self)
            
            return self.mapCell
        default: return self.cellForMapURL() //### case 4:
        }
        
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let mapSection = 3
        if indexPath.section == mapSection {
            return 240.0 // map cell height
        }
        return self.tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // if it's the map url cell, open the location in Google maps
        //
        if indexPath.section == 4 { // map url is always last section
            let ll = String(format: "%f,%f",
                self.placemark?.location?.coordinate.latitude ?? 0.0,
                self.placemark?.location?.coordinate.longitude ?? 0.0)
                .stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let url = "http://maps.apple.com/?q=\(ll)"
            UIApplication.sharedApplication().openURL(NSURL(string: url)!)
            
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
    
    //MARK: - Cell Generators
    
    private func blankCell() -> UITableViewCell {
        let cellID = "BlankCell"
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: cellID)
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }
    
    private func cellForAddressDictionaryIndex(_index: Int) -> UITableViewCell {
        let keys = AddressDictionaryKeys
        
        var index = _index
        if index >= keys.count {
            index = keys.count - 1
        }
        
        let cell = self.blankCell()
        
        // setup
        let key = keys[index]
        let ivar = self.placemark?.valueForKey(key) as? String
        if let dict = self.placemark?.addressDictionary?.filter({dictKey,_ in dictKey.description.lowercaseString == key.lowercaseString}).first?.1 as? String {
            // assert that ivar and dict values are the same
            assert(ivar == dict, "value from ivar accessor and from addressDictionary should always be the same! \(ivar) != \(dict)")
        }
        
        // set cell attributes
        cell.textLabel!.text = key
        cell.detailTextLabel!.text = ivar
        
        return cell
    }
    
    private func cellForLocationIndex(_index: Int) -> UITableViewCell {
        let keys = LocationKeys
        
        var index = _index
        if index >= keys.count {
            index = keys.count - 1
        }
        
        let cell = self.blankCell()
        
        // setup
        let key = keys[index]
        var ivar = ""
        
        // look up the values, special case lat and long and timestamp but first, special case placemark being nil.
        block: do {
            guard let location = self.placemark?.location else {
                ivar = "location is nil."
                break block
            }
            switch key {
            case "coordinate.latitude":
                ivar = location.horizontalAccuracy < 0
                    ? "N/A"
                    : self.displayStringForDouble(location.coordinate.latitude)
            case "coordinate.longitude":
                ivar = location.horizontalAccuracy < 0
                    ? "N/A"
                    : self.displayStringForDouble(location.coordinate.longitude)
            case "timestamp":
                ivar = location.timestamp.description
            case "altitude":
                ivar = location.verticalAccuracy < 0 ? "N/A" : displayStringForDouble(location.altitude)
            default:
                let val = self.doubleForObject(self.placemark?.location, andKey: key)
                ivar = self.displayStringForDoubleWithInvalid(val)
            }
        }
        
        // set cell attributes
        cell.textLabel!.text = key
        cell.detailTextLabel!.text = ivar
        
        return cell
    }
    
    private func cellForRegionIndex(_index: Int) -> UITableViewCell {
        let keys = RegionKeys
        
        var index = _index
        if index >= keys.count {
            index = keys.count - 1
        }
        
        let cell = self.blankCell()
        
        // setup
        let key = keys[index]
        var ivar: String
        
        // look up the values, special case lat and long and timestamp but first special case region being nil
        block: do {
            guard let region = self.placemark?.region as? CLCircularRegion else {
                ivar = "region is nil."
                break block
            }
            switch key {
            case "center.latitude":
                ivar = self.displayStringForDouble(region.center.latitude)
            case "center.longitude":
                ivar = self.displayStringForDouble(region.center.longitude)
            case "identifier":
                ivar = self.placemark!.region!.identifier
            default:
                let val = self.doubleForObject(region, andKey: key)
                ivar = self.displayStringForDouble(val)
            }
        } //###block
        
        // set cell attributes
        cell.textLabel!.text = key
        cell.detailTextLabel!.text = ivar
        
        return cell
    }
    
    private func cellForMapURL() -> UITableViewCell {
        let cellID = "MapURLCell"
        let cell = UITableViewCell(style: .Default, reuseIdentifier: cellID)
        
        cell.textLabel!.text = "View in Maps"
        cell.textLabel!.textAlignment = NSTextAlignment.Center
        
        return cell
    }
    
    
    //MARK: - Display Utilities
    
    // performSelector is only for objects
    private func doubleForObject(object: NSObject?, andKey key: String) -> Double {
        
        let result = object?.valueForKey(key) as? Double ?? 0.0
        
        return result
    }
    
    // don't try and print any NaNs. these throw exceptions in strings
    private func displayStringForDouble(aDouble: Double) -> String {
        if aDouble.isNaN {
            return "N/A"
        } else {
            return String(format: "%f", aDouble)
        }
    }
    private func displayStringForDoubleWithInvalid(aDouble: Double) -> String {
        if aDouble.isNaN {
            return "N/A"
        } else if aDouble < 0 {
            return "Invalid"
        } else {
            return String(format: "%f", aDouble)
        }
    }
    
    
    //MARK: - MKAnnotation Protocol (for map pin)
    
    var coordinate: CLLocationCoordinate2D {
        return self.placemark?.location?.coordinate ?? CLLocationCoordinate2D()
    }
    
    dynamic override var title: String? {
        get {
            return self.placemark?.thoroughfare
        }
        set {
            //ignored
        }
    }
    
}
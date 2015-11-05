//
//  PlacemarksListViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/3.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 UITableViewController that Displays a list of CLPlacemarks.
 */

import UIKit
import Contacts
import MapKit

@objc(PlacemarksListViewController)
class PlacemarksListViewController: UITableViewController {
    
    private let CellIdentifier = "Cell"
    
    private var placemarks: [CLPlacemark] = []
    
    
    //MARK: -
    
    override convenience init(style: UITableViewStyle) {
        self.init(placemarks: [])
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(placemarks: [])
    }
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.init(placemarks: [])
    }
    
    init(placemarks: [CLPlacemark]) {
        self.placemarks = placemarks
        super.init(style: .Grouped)
    }
    
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "CLPlacemarks"
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section.
        if self.placemarks.isEmpty {
            return 1
        }
        
        return self.placemarks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var protoCell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if protoCell == nil {
            protoCell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        }
        let cell = protoCell!
        
        if self.placemarks.isEmpty {
            // show a zero results cell
            cell.textLabel!.text = "No Placemarks.."
        } else {
            let placemark = self.placemarks[indexPath.row]
            
            // use the Contacts framework to create a readable formatter address
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = placemark.thoroughfare ?? ""
            postalAddress.city = placemark.locality ?? ""
            postalAddress.state = placemark.administrativeArea ?? ""
            postalAddress.postalCode = placemark.postalCode ?? ""
            postalAddress.country = placemark.country ?? ""
            postalAddress.ISOCountryCode = placemark.ISOcountryCode ?? ""
            
            let addressString = CNPostalAddressFormatter.stringFromPostalAddress(postalAddress, style: .MailingAddress)
            
            let latitude = placemark.location?.coordinate.latitude ?? 0.0
            let longitude = placemark.location?.coordinate.longitude ?? 0.0
            let coordString = String(format: "φ:%.4F, λ:%.4F", latitude, longitude)
            
            // strip out any empty lines in the address
            var finalAttrString = ""
            let arrSplit = addressString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            for subStr in arrSplit {
                if !subStr.isEmpty {
                    if !finalAttrString.isEmpty {
                        finalAttrString += "\n"
                    }
                    finalAttrString += subStr
                }
            }
            
            cell.textLabel!.lineBreakMode = .ByWordWrapping
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.font = UIFont.systemFontOfSize(16.0)
            cell.textLabel!.text = finalAttrString
            
            cell.detailTextLabel!.lineBreakMode = .ByWordWrapping
            cell.detailTextLabel!.numberOfLines = 0
            cell.detailTextLabel!.font = UIFont.boldSystemFontOfSize(16.0)
            cell.detailTextLabel!.text = coordString
            
            cell.accessoryType = .DisclosureIndicator
        }
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let placemark = self.placemarks[indexPath.row]
        let pvc = PlacemarkViewController(placemark: placemark)
        self.navigationController!.pushViewController(pvc, animated: true)
    }
    
}
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
    
    override convenience init(style: UITableView.Style) {
        self.init(placemarks: [])
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(placemarks: [])
    }
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(placemarks: [])
    }
    
    init(placemarks: [CLPlacemark]) {
        self.placemarks = placemarks
        super.init(style: .grouped)
    }
    
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "CLPlacemarks"
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section.
        if self.placemarks.isEmpty {
            return 1
        }
        
        return self.placemarks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var protoCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if protoCell == nil {
            protoCell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
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
            postalAddress.isoCountryCode = placemark.isoCountryCode ?? ""
            
            let addressString = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
            
            let latitude = placemark.location?.coordinate.latitude ?? 0.0
            let longitude = placemark.location?.coordinate.longitude ?? 0.0
            let coordString = String(format: "φ:%.4F, λ:%.4F", latitude, longitude)
            
            // strip out any empty lines in the address
            var finalAttrString = ""
            let arrSplit = addressString.components(separatedBy: CharacterSet.newlines)
            for subStr in arrSplit {
                if !subStr.isEmpty {
                    if !finalAttrString.isEmpty {
                        finalAttrString += "\n"
                    }
                    finalAttrString += subStr
                }
            }
            
            cell.textLabel!.lineBreakMode = .byWordWrapping
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.font = UIFont.systemFont(ofSize: 16.0)
            cell.textLabel!.text = finalAttrString
            
            cell.detailTextLabel!.lineBreakMode = .byWordWrapping
            cell.detailTextLabel!.numberOfLines = 0
            cell.detailTextLabel!.font = UIFont.boldSystemFont(ofSize: 16.0)
            cell.detailTextLabel!.text = coordString
            
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let placemark = self.placemarks[indexPath.row]
        let pvc = PlacemarkViewController(placemark: placemark)
        self.navigationController!.pushViewController(pvc, animated: true)
    }
    
}

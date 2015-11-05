//
//  DistanceViewController.swift
//  GeocoderDemo
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/11/4.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 View controller in charge of measuring distance between 2 locations.
 */

import UIKit
import CoreLocation

@objc(DistanceViewController)
class DistanceViewController: UITableViewController {
    
    
    private var toCoordinateSelector: CoordinateSelectorTableViewController!
    private var fromCoordinateSelector: CoordinateSelectorTableViewController!
    
    
    //MARK: -
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toCoordinateSelector = CoordinateSelectorTableViewController()
        fromCoordinateSelector = CoordinateSelectorTableViewController()
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    
    //MARK: - Distance Calculation
    
    private var distanceBetweenCoordinates: Double {
        
        var latitude = self.toCoordinateSelector!.selectedCoordinate.latitude
        var longitude = self.toCoordinateSelector.selectedCoordinate.longitude
        let to = CLLocation(latitude: latitude, longitude: longitude)
        
        latitude = self.fromCoordinateSelector.selectedCoordinate.latitude
        longitude = self.fromCoordinateSelector.selectedCoordinate.longitude
        let from = CLLocation(latitude: latitude, longitude: longitude)
        
        let distance = to.distanceFromLocation(from)
        
        return distance
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        // to and from cells
        if indexPath.section == 0 || indexPath.section == 1 {
            cell = tableView.dequeueReusableCellWithIdentifier("selectorCell")
            if cell == nil {
                cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "selectorCell")
                cell!.accessoryType = .DisclosureIndicator
            }
            
            var selector: CoordinateSelectorTableViewController!
            switch indexPath.section {
            case 0:
                selector = self.toCoordinateSelector
            case 1:
                selector = self.fromCoordinateSelector
            default:
                break
            }
            
            if selector.selectedType != .Undefined {
                cell!.accessoryType = .DisclosureIndicator
                cell!.textLabel!.lineBreakMode = .ByWordWrapping
                cell!.textLabel!.numberOfLines = 0
                cell!.textLabel!.font = UIFont.systemFontOfSize(16.0)
                cell!.textLabel!.text = selector.selectedName
                
                if CLLocationCoordinate2DIsValid(selector.selectedCoordinate) {
                    cell!.detailTextLabel!.lineBreakMode = .ByWordWrapping
                    cell!.detailTextLabel!.numberOfLines = 0
                    cell!.detailTextLabel!.font = UIFont.boldSystemFontOfSize(16.0)
                    
                    cell!.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", selector.selectedCoordinate.latitude, selector.selectedCoordinate.longitude)
                }
            } else {
                cell!.textLabel!.text = "Select a Place"
                cell!.detailTextLabel!.text = ""
            }
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            if self.toCoordinateSelector.selectedType != .Undefined &&
                self.fromCoordinateSelector.selectedType != .Undefined
            {
                return String(format: "%.1f km\n(as the crow flies)", self.distanceBetweenCoordinates / 1000)
            } else {
                return "- km"
            }
        }
        return nil
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        
        if indexPath.section == 0 {
            self.navigationController!.pushViewController(self.toCoordinateSelector, animated: true)
        } else if indexPath.section == 1 {
            self.navigationController!.pushViewController(self.fromCoordinateSelector, animated: true)
        }
    }
    
}
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
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        let distance = to.distance(from: from)
        
        return distance
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the section
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        // to and from cells
        if indexPath.section == 0 || indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "selectorCell")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "selectorCell")
                cell!.accessoryType = .disclosureIndicator
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
            
            if selector.selectedType != .undefined {
                cell!.accessoryType = .disclosureIndicator
                cell!.textLabel!.lineBreakMode = .byWordWrapping
                cell!.textLabel!.numberOfLines = 0
                cell!.textLabel!.font = UIFont.systemFont(ofSize: 16.0)
                cell!.textLabel!.text = selector.selectedName
                
                if CLLocationCoordinate2DIsValid(selector.selectedCoordinate) {
                    cell!.detailTextLabel!.lineBreakMode = .byWordWrapping
                    cell!.detailTextLabel!.numberOfLines = 0
                    cell!.detailTextLabel!.font = UIFont.boldSystemFont(ofSize: 16.0)
                    
                    cell!.detailTextLabel!.text = String(format: "φ:%.4F, λ:%.4F", selector.selectedCoordinate.latitude, selector.selectedCoordinate.longitude)
                }
            } else {
                cell!.textLabel!.text = "Select a Place"
                cell!.detailTextLabel!.text = ""
            }
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            if self.toCoordinateSelector.selectedType != .undefined &&
                self.fromCoordinateSelector.selectedType != .undefined
            {
                return String(format: "%.1f km\n(as the crow flies)", self.distanceBetweenCoordinates / 1000)
            } else {
                return "- km"
            }
        }
        return nil
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        
        if indexPath.section == 0 {
            self.navigationController!.pushViewController(self.toCoordinateSelector, animated: true)
        } else if indexPath.section == 1 {
            self.navigationController!.pushViewController(self.fromCoordinateSelector, animated: true)
        }
    }
    
}

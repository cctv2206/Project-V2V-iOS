//
//  ViewController.swift
//  V2V-Beta0.1
//
//  Created by Kang Kai on 15/9/10.
//  Copyright (c) 2015 Kang Kai. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreLocation
import MapKit

class ViewController: UIViewController, MPCManagerDelegate, CLLocationManagerDelegate, MKMapViewDelegate
{
    var isAdvertising: Bool!
    
    var LocationManager:CLLocationManager!
    var info = [String:String]()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var myLocations: [CLLocation] = []
    
    // the map
    @IBOutlet weak var theMap: MKMapView!
    
    // my labels
    @IBOutlet weak var LabelName: UILabel!
    @IBOutlet weak var LabelLati: UILabel!
    @IBOutlet weak var LabelLong: UILabel!
    @IBOutlet weak var LabelSpeed: UILabel!
    
    // label array
    @IBOutlet var DevicesLabels: [UILabel]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        LabelName.text = UIDevice.currentDevice().name
        
        //Setup Location Manager
        LocationManager = CLLocationManager()
        LocationManager.delegate = self
        LocationManager.desiredAccuracy = kCLLocationAccuracyBest
        LocationManager.requestAlwaysAuthorization()
        LocationManager.startUpdatingLocation()
        //----------
        
        //Setup our Map View
        theMap.delegate = self
        theMap.mapType = MKMapType.Standard
        theMap.showsUserLocation = true
        
        appDelegate.mpcManager.delegate = self
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        
        // start advertising
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
        
        isAdvertising = true
        
        
        // init all the labels
        for index in 0 ... DevicesLabels.count - 1 {
            DevicesLabels[index].text = nil
        }
        
        
    }
    
    //update the location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        appDelegate.mpcManager.advertiser.stopAdvertisingPeer() // stop the advertiser
        
        let speed = manager.location.speed
        //let speed = 3.0
        let latitude = manager.location.coordinate.latitude
        let longitude = manager.location.coordinate.longitude
        let theTime = manager.location.timestamp
        
        
        LabelLati.text = "\(latitude)"
        LabelLong.text = "\(longitude)"
        LabelSpeed.text = "\(speed)"
        
        // draw some line on the map
        let newLocation = locations[0] as! CLLocation
        myLocations.append(newLocation)
        
        let spanX = 0.00007
        let spanY = 0.00007
        var newRegion = MKCoordinateRegion(center: theMap.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        theMap.setRegion(newRegion, animated: true)
        
        if (myLocations.count > 1){
            var sourceIndex = myLocations.count - 1
            var destinationIndex = myLocations.count - 2
            
            let c1 = myLocations[sourceIndex].coordinate
            let c2 = myLocations[destinationIndex].coordinate
            var a = [c1, c2]
            var polyline = MKPolyline(coordinates: &a, count: a.count)
            theMap.addOverlay(polyline)
        }
        // -----------
        
        self.info = [String:String]()
        self.info = ["Name":UIDevice.currentDevice().name, "Speed":"\(speed)", "Lati":"\(latitude)", "Long":"\(longitude)"]
        
        appDelegate.mpcManager.updateLocationInfo(info)
    }
    
    // map function
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 4
            return polylineRenderer
        }
        return nil
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MPCManagerDelegate protocol
    
    func foundPeer() // update the UI
    {
        //NSLog("found a new one!")
        
        if let NearbyInfo = appDelegate.mpcManager.DisInfo as? [String:String] { // if not nil
            if NearbyInfo["Name"] != UIDevice.currentDevice().name { // not my self
                NSLog(NearbyInfo["Speed"]!)
                //check if we need an alert, check the speed
                var theSpeed: Double? = nil
                if (NearbyInfo["Speed"] != nil) {
                    theSpeed = (NearbyInfo["Speed"]! as NSString).doubleValue
                }
                
                NSLog("Speed: \(theSpeed)")
                if theSpeed > 5 {
                    // show the alert
                    let theName = NearbyInfo["Name"]
                    var alert: UIAlertView = UIAlertView(title: "Someone is here", message: "\(theName!) is driving at \(theSpeed!) m/s", delegate: nil, cancelButtonTitle: "OK")
                    
                    alert.show()
                    
                    // Delay the dismissal by 2 seconds
                    let delay = 5.0 * Double(NSEC_PER_SEC)
                    var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                    dispatch_after(time, dispatch_get_main_queue(), {
                        alert.dismissWithClickedButtonIndex(-1, animated: true)
                    })
                }
                
                // check here for each label in the label array. change the text to new peers name
                var AlreadyHere = false
                for index in 0 ... DevicesLabels.count - 1 {
                    if NearbyInfo["Name"] == DevicesLabels[index].text { // it is already here
                        AlreadyHere = true
                        break
                    }
                }
                
                if !AlreadyHere {
                    for index in 0 ... DevicesLabels.count - 1 {
                        if DevicesLabels[index].text == nil {
                            DevicesLabels[index].text = NearbyInfo["Name"]
                            NSLog(NearbyInfo["Name"]!)
                            break
                        }
                    }
                }
            }
        }
    }
    
    func lostPeer() {
    }
    
    func invitationWasReceived(fromPeer: String) {
    }
    
    func connectedWithPeer(peerID: MCPeerID) {
    }
    
}

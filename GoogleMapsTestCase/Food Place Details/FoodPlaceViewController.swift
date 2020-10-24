//
//  FoodPlaceViewController.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 19.10.2020.
//

import UIKit
import GoogleMaps

class FoodPlaceViewController: UIViewController {

    @IBOutlet weak var mapLayerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    var place: FoodPlace?
    var locationManager: CLLocationManager?
    private var mapView: GMSMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = place?.name
        
        nameLabel.text = place?.name
        addressLabel.text = place?.address
        phoneLabel.text = place?.phone
        
        if let location = locationManager?.location {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: 14)
            mapView = GMSMapView.map(withFrame: mapLayerView.bounds, camera: camera)
            
            if let mapView = mapView {
                mapLayerView.addSubview(mapView)

                mapView.animate(to: camera)
                
                if let position = place?.coordinate() {
                    let marker = GMSMarker(position: position)
                    marker.title = place?.name
                    marker.map = mapView
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

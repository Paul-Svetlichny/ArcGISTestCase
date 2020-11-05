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
    
    var place: FoodPlace
    private var mapView: GMSMapView?

    init?(coder: NSCoder, place: FoodPlace) {
        self.place = place
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("You must create this view controller with a place.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupMapView()
    }
    
    private func setupUI() {
        self.title = place.name
        
        nameLabel.text = place.name
        addressLabel.text = place.address
        phoneLabel.text = place.phone
    }
    
    private func setupMapView() {
        let coordinate = place.coordinate()
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude,
                                              longitude: coordinate.longitude,
                                              zoom: Settings.preciseLocationZoomLevel)
        mapView = GMSMapView.map(withFrame: mapLayerView.bounds, camera: camera)
        
        if let mapView = mapView {
            mapLayerView.addSubview(mapView)

            mapView.animate(to: camera)
            
            let position = place.coordinate()
            let marker = GMSMarker(position: position)
            marker.title = place.name
            marker.map = mapView
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

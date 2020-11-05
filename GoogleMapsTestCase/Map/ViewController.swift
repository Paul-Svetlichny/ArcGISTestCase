//
//  ViewController.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 17.10.2020.
//

import UIKit
import GoogleMaps
import ArcGIS
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var mapLayerView: UIView!
    @IBOutlet weak var tableView: UITableView!
        
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var mapView: GMSMapView?

    var coreDataManager = CoreDataManager()
    var coordinator: ArcGISCoordinator?

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    var markers = [String: GMSMarker]()
    var selectedMarker: GMSMarker?
    
    var isInitialLoad = true
    
    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: FoodPlace.entityName)
        let placeName = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [placeName]
        
        let moc = coreDataManager.persistentContainer.viewContext
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            NotificationPresenter.init().show(.alert, in: self, title: "Setup Error", message: error.localizedDescription, actions: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeFetchedResultsController()
        coordinator = ArcGISCoordinator(coreDataManager: coreDataManager)
        
        initLocationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
        
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
    
    func add(places: [FoodPlace]?, to mapView: GMSMapView) {
        if let places = places {
            for place in places {
                let marker = GMSMarker(position: place.coordinate())
                marker.title = place.name
                marker.map = mapView
            }
        }
    }
}

//  MARK: - GMSMapView Delegate
extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
        if !isInitialLoad {
            self.coreDataManager.removeAll(excluding: selectedMarker?.title)

            coordinator?.findPlaces(at: cameraPosition.target) { [weak self] (places, error) in
                self?.coreDataManager.saveContext()
            }
        } else {
            if let places = self.coreDataManager.initialData(), places.count > 0 {
                for place in places {
                    self.addToMap(place: place)
                }
            } else {
                coordinator?.findPlaces(at: cameraPosition.target) { [weak self] (places, error) in
                    self?.coreDataManager.saveContext()
                }
            }
            
            isInitialLoad = false
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let place = coreDataManager.place(with: marker.title) {
            openDetailsViewController(with: place)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.selectedMarker = marker
        
        return false
    }
}

//  MARK: - UITableView Delegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = self.fetchedResultsController?.object(at: indexPath) as? FoodPlace else {
            return
        }

        self.openDetailsViewController(with: place)
    }
}

//  MARK: - UITableView Data Source
extension ViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
        
        guard let place = self.fetchedResultsController?.object(at: indexPath) as? FoodPlace else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = place.name
        cell.detailTextLabel?.text = place.address
        
        return cell
    }
}

//  MARK: - CLLocation Manager Delegate
extension ViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = locations.last else {
            return
        }
        
        let zoomLevel = Settings.preciseLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView == nil {
            mapView = GMSMapView.map(withFrame: mapLayerView.frame, camera: camera)
            mapView?.delegate = self
            mapLayerView.addSubview(mapView!)
        }

        mapView?.animate(to: camera)
    }

    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            NotificationPresenter.init().show(.alert, in: self, title: "Location Services Error", message: "Location access was restricted", actions: nil)
            mapView?.isHidden = false
        case .denied:
            NotificationPresenter.init().show(.alert, in: self, title: "Location Services Error", message: "Location permissions were declined", actions: nil)
            mapView?.isHidden = false
        case .notDetermined:
            NotificationPresenter.init().show(.alert, in: self, title: "Location Services Error", message: "Location status not determined", actions: nil)
            mapView?.isHidden = false
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            NotificationPresenter.init().show(.alert, in: self, title: "Location Services Error", message: "Undetermined error", actions: nil)
            mapView?.isHidden = false
        }
    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        NotificationPresenter.init().show(.alert, in: self, title: "Location Services Error", message: error.localizedDescription, actions: nil)
    }
}

//  MARK: - NSFetched Results Controller Delegate
extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard
            let newIndexPath = newIndexPath,
            let indexPath = indexPath
        else {
            return
        }
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath], with: .fade)
            if let place = anObject as? FoodPlace {
                addToMap(place: place)
            }
        case .delete:
            tableView.deleteRows(at: [indexPath], with: .fade)
            if let place = anObject as? FoodPlace {
                removeFromMap(place: place)
            }
        case .update:
            tableView.reloadRows(at: [indexPath], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath, to: newIndexPath)
        @unknown default:
            break
        }
    }
         
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

//  MARK: - Additional Map Methods (Markers)
extension ViewController {
    func addToMap(place: FoodPlace) {
        guard let name = place.name else {
            return
        }
        
        let marker = GMSMarker(position: place.coordinate())
        marker.title = name
        marker.map = mapView
        markers[name] = marker
    }
    
    func removeFromMap(place: FoodPlace) {
        guard let name = place.name else {
            return
        }
        
        if let marker = markers[name] {
            if marker != selectedMarker {
                marker.map = nil
            }
        }
    }
}

//  MARK: - Navigation
extension ViewController {
    func openDetailsViewController(with place: FoodPlace) {
        let storyboard = UIStoryboard(name: "FoodPlace", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "FoodPlaceViewController", creator: { coder in
            return FoodPlaceViewController(coder: coder, place: place)
        })
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

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
    var preciseLocationZoomLevel: Float = 14.0
    var approximateLocationZoomLevel: Float = 14.0

    var coreDataManager = CoreDataManager()
    var coordinator: ArcGISCoordinator?

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    var markers = [String: GMSMarker]()
    
    var isInitialLoad = true
    
    func initializeFetchedResultsController() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FoodPlace")
        let placeName = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [placeName]
        
        let moc = coreDataManager.persistentContainer.viewContext
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeFetchedResultsController()
        coordinator = ArcGISCoordinator(coreDataManager: coreDataManager)
        
        initLocationManager()
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
            self.coreDataManager.removeAll()

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
//        Move to details
    }
}

//  MARK: - UITableView Delegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        Move to Food Place details
    }
}

//  MARK: - UITableView Data Source
extension ViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
        
        guard let place = self.fetchedResultsController?.object(at: indexPath) as? FoodPlace else {
            fatalError("Attempt to configure cell without a managed object")
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
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        if mapView == nil {
            mapView = GMSMapView.map(withFrame: mapLayerView.frame, camera: camera)
            mapView!.delegate = self
            mapLayerView.addSubview(mapView!)
        }

        mapView?.animate(to: camera)
    }

    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      // Check accuracy authorization
        let accuracy = manager.accuracyAuthorization
        switch accuracy {
        case .fullAccuracy:
            print("Location accuracy is precise.")
        case .reducedAccuracy:
            print("Location accuracy is not precise.")
        @unknown default:
            fatalError()
        }

      // Handle authorization status
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView?.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
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
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            if let place = anObject as? FoodPlace {
                addToMap(place: place)
            }
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            if let place = anObject as? FoodPlace {
                removeFromMap(place: place)
            }
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
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
            marker.map = nil
        }
    }
}

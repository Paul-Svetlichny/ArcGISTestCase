//
//  ArcGISCoordinator.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 18.10.2020.
//

import ArcGIS

class ArcGISCoordinator {
    static let locator = URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!
    
    private var fetcher: ArcGISFetcher
    private let locatorTask = AGSLocatorTask(url: locator)
    private var coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
        self.fetcher = ArcGISFetcher(locatorTask: locatorTask)
    }
    
    func findPlaces(at location: CLLocationCoordinate2D, completion: @escaping ([FoodPlace]?, Error?) -> Void) {
        let centerCoordinate = MapTypesConverter.point(from: location)
        fetcher.findPlaces(at: centerCoordinate) { result in
            if case .error(let error) = result {
                completion(nil, error)
                return
            }
            
            if case .success(let places) = result {
                let coordinates = places?.compactMap { MapTypesConverter.foodPlace(from: $0, in: self.coreDataManager.persistentContainer.viewContext) }
                completion(coordinates, nil)
            }
        }
    }
}

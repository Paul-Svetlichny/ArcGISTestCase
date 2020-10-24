//
//  MapTypesConverter.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 18.10.2020.
//

import ArcGIS
import CoreData

class MapTypesConverter {
    static func point(from: CLLocationCoordinate2D) -> AGSPoint {
        return AGSPoint(clLocationCoordinate2D: from)
    }
    
    static func foodPlace(from: AGSGeocodeResult, in context: NSManagedObjectContext) -> FoodPlace? {
        let name = from.label
        
        guard let address = from.attributes?["Place_addr"] as? String else {
            return nil
        }
        
        guard let coordinate = from.displayLocation?.toCLLocationCoordinate2D() else {
            return nil
        }
        
        let place = NSEntityDescription.insertNewObject(forEntityName: "FoodPlace", into: context) as! FoodPlace

        place.address = address
        place.name = name
        place.latitude = coordinate.latitude
        place.longitude = coordinate.longitude

        if let phone = from.attributes?["Phone"] as? String {
            place.phone = phone
        }

        return place
    }
}

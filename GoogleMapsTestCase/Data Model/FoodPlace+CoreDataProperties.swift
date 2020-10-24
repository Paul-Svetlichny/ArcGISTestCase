//
//  FoodPlace+CoreDataProperties.swift
//  
//
//  Created by Paul Svetlichny on 18.10.2020.
//
//

import CoreData
import CoreLocation

@objc(FoodPlace)
public class FoodPlace: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodPlace> {
        return NSFetchRequest<FoodPlace>(entityName: "FoodPlace")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var phone: String?

    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude:self.latitude, longitude:self.longitude)
    }
    
}

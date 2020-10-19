//
//  ArcGISFetcher.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 18.10.2020.
//

import ArcGIS

enum Result<T> {
    case success(T)
    case error(Error?)
    case empty
}

class ArcGISFetcher {
    private let locatorTask: AGSLocatorTask
    private var currentSearch: AGSCancelable?
    
    init(locatorTask: AGSLocatorTask) {
        self.locatorTask = locatorTask
    }
    
    func findPlaces(at centerPoint: AGSPoint, completion: @escaping (Result<[AGSGeocodeResult]?>) -> Void) {
        currentSearch?.cancel()

        let parameters: AGSGeocodeParameters = {
            let geocodeParameters = AGSGeocodeParameters()
            geocodeParameters.maxResults = 20
            geocodeParameters.resultAttributeNames.append(contentsOf: ["Place_addr", "PlaceName"])
            geocodeParameters.preferredSearchLocation = centerPoint
            geocodeParameters.categories = ["food"]
            return geocodeParameters
        }()

        currentSearch = locatorTask.geocode(withSearchText: "", parameters: parameters) { (results, error) in
            guard error == nil else {
                completion(.error(error))
                return
            }

            completion(.success(results))
        }
    }

}

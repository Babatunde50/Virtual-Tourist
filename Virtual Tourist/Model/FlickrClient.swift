//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Tunde Ola on 12/12/20.
//

import Foundation

class FlickrClient {
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=bb1b9cd4d5b2d0cad1ac7439d93f8cbd&format=json&nojsoncallback=1&extras=url_sq%2C&per_page=20"
        
        case getPhotos(lat: Double, lon: Double,page: Int)
        
        var stringValue: String {
            switch self {
                case .getPhotos(let lat, let lon, let page):
                    return "\(Endpoints.base)&lat=\(lat)&lon=\(lon)&page=\(page)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getGeoPhotos(lat: Double, lon: Double, page: Int = 1, completion: @escaping ([PhotoResponse]?, Error? ) -> Void) {
        let task = URLSession.shared.dataTask(with: FlickrClient.Endpoints.getPhotos(lat: lat, lon: lon, page: page).url) { data, response, error in
            
            print("Data gotten!!!")
            
            guard let data = data else {
                completion(nil, error)
                print(error)
                return
            }
            
            do {
                let responseObject = try JSONDecoder().decode(FlikrResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject.photos!.photo, nil )
                }
            } catch {
                DispatchQueue.main.async {
                    print(error)
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    
}



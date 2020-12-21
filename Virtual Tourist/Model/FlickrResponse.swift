//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Tunde Ola on 12/12/20.
//

import Foundation

struct PhotoResponse: Codable {
    let id : String?
    let owner : String?
    let secret : String?
    let server : String?
    let farm : Int?
    let title : String?
    let ispublic : Int?
    let isfriend : Int?
    let isfamily : Int?
    let urlSq : String?
    let heightSq : Int?
    let widthSq : Int?

    enum CodingKeys: String, CodingKey {

        case id = "id"
        case owner = "owner"
        case secret = "secret"
        case server = "server"
        case farm = "farm"
        case title = "title"
        case ispublic = "ispublic"
        case isfriend = "isfriend"
        case isfamily = "isfamily"
        case urlSq = "url_sq"
        case heightSq = "height_sq"
        case widthSq = "width_sq"
    }

}

struct PhotosResponse: Codable {
    let page : Int?
    let pages : Int?
    let perpage : Int?
    let total : String?
    let photo : [PhotoResponse]?
}

struct FlikrResponse : Codable {
    let photos : PhotosResponse?
    let stat : String?
}

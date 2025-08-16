//
//  PhotoPickerUtils.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/17/25.
//

import Photos
import CoreLocation
import PhotosUI

struct PhotoPickerUtils {
    static func extractLocation(
        from pickerResults: [PHPickerResult],
        completion: @escaping ([CLLocationCoordinate2D?]) -> Void
    ) {
        var coords: [CLLocationCoordinate2D?] = Array(repeating: nil, count: pickerResults.count)
        let dispatchGroup = DispatchGroup()
        
        for (index, result) in pickerResults.enumerated() {
            if let assetId = result.assetIdentifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                if let asset = assets.firstObject {
                    dispatchGroup.enter()
                    coords[index] = asset.location?.coordinate
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(coords)
        }
    }
}

import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Saga
import SagaImageReader
import SagaPathKit
import SwiftDotenv

private let mapsFolder: Path = "content/static/maps"

extension Item where M == ImageMetadata {
  var coordinates: (latitude: Double, longitude: Double)? {
    guard let latitude = metadata.gpsLatitude.flatMap(Double.init),
          let longitude = metadata.gpsLongitude.flatMap(Double.init)
    else {
      return nil
    }

    // EXIF stores the coordinates unsigned, with the hemisphere in the ref
    return (
      metadata.gpsLatitudeRef == "S" ? -latitude : latitude,
      metadata.gpsLongitudeRef == "W" ? -longitude : longitude
    )
  }

  /// Rounded to two decimals (about a kilometer), which is plenty for a zoomed-out map and lets
  /// nearby photos share one map image
  var mapLocation: (latitude: String, longitude: String)? {
    coordinates.map { (String(format: "%.2f", $0.latitude), String(format: "%.2f", $0.longitude)) }
  }

  var mapURL: String? {
    mapLocation.map { "/static/maps/\($0.latitude)_\($0.longitude).png" }
  }
}

/// Downloads the map for a photo's location into content/static/maps.
/// Does nothing when the photo has no location or we already have the map on disk.
@Sendable func downloadMap(photo: Item<ImageMetadata>) async {
  guard let location = photo.mapLocation else { return }

  let destination = mapsFolder + "\(location.latitude)_\(location.longitude).png"
  guard !destination.exists else { return }

  guard let token = Dotenv["MAPBOX_TOKEN"]?.stringValue else {
    print("⚠️ MAPBOX_TOKEN is not set, skipping map downloads")
    return
  }

  // The logo and attribution are left off the image, the legal notice page credits Mapbox and OSM
  let center = "\(location.longitude),\(location.latitude)"
  let url = URL(string: "https://api.mapbox.com/styles/v1/kevinrenskers/cmvjyum7e00n401s5hyu35ftm/static/pin-s+2b2b2b(\(center))/\(center),6.5/220x220@2x?attribution=false&logo=false&access_token=\(token)")!

  do {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      print("⚠️ Failed to download map for \(photo.relativeSource)")
      return
    }

    try mapsFolder.mkpath()
    try destination.write(data)
  } catch {
    print("⚠️ Failed to download map for \(photo.relativeSource): \(error)")
  }
}

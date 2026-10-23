import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Saga
import SagaPathKit
import SwiftCSV

private let postersFolder: Path = "content/static/posters/albums"

/// iTunes hands back a 100x100 thumbnail, but the same URL serves whatever size we ask for.
private let artworkSize = "600x600bb.jpg"

private struct LookupResponse: Decodable {
  struct Result: Decodable {
    let collectionId: Int?
    let artworkUrl100: String?
  }

  let results: [Result]
}

private func posterPath(id: String) -> Path {
  postersFolder + "\(id).jpg"
}

/// Looks up the artwork for every album in a single request. The ids come from the Dutch
/// store, and an album is only found in the storefronts it was released in.
private func fetchArtworkURLs(ids: [String]) async -> [String: String] {
  guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else { return [:] }
  components.queryItems = [
    URLQueryItem(name: "id", value: ids.joined(separator: ",")),
    URLQueryItem(name: "country", value: "NL"),
  ]
  guard let url = components.url else { return [:] }

  do {
    let (data, _) = try await URLSession.shared.data(from: url)
    let results = try JSONDecoder().decode(LookupResponse.self, from: data).results

    return results.reduce(into: [:]) { urls, result in
      guard let id = result.collectionId, let artwork = result.artworkUrl100 else { return }
      urls["\(id)"] = artwork.replacingOccurrences(of: "100x100bb.jpg", with: artworkSize)
    }
  } catch {
    print("⚠️ Failed to look up albums on iTunes: \(error)")
    return [:]
  }
}

/// Downloads an album's artwork into content/static/posters/albums.
/// Does nothing when we already have the image on disk, which is also how the albums that
/// aren't on Apple Music get their art: drop the file in yourself.
private func downloadArtwork(id: String, artworkURL: String?) async {
  let destination = posterPath(id: id)
  guard !destination.exists else { return }

  guard let artworkURL, let url = URL(string: artworkURL) else {
    print("⚠️ No artwork for \(id), add \(destination) by hand")
    return
  }

  do {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      print("⚠️ No artwork for \(id), add \(destination) by hand")
      return
    }

    try postersFolder.mkpath()
    try destination.write(data)
  } catch {
    print("⚠️ Failed to download artwork for \(id): \(error)")
  }
}

func fetchAlbums() async throws -> [Item<AlbumMetadata>] {
  let csvFile = try loadCSV(named: "albums")

  let items = compactMapRows(csvFile) { position, row in
    let metadata = try AlbumMetadata(
      position: position,
      id: row.required("Id"),
      artist: row.required("Artist"),
      title: row.required("Title"),
      year: row.requiredInt("Year"),
      url: row["URL"]?.nonEmpty
    )
    return Item(title: metadata.title, metadata: metadata)
  }

  // Only ask iTunes about albums we don't already have art for, so a rebuild does no networking
  let missing = items.map(\.metadata.id).filter { !posterPath(id: $0).exists }
  let onAppleMusic = missing.filter { Int($0) != nil }
  let artworkURLs = onAppleMusic.isEmpty ? [:] : await fetchArtworkURLs(ids: onAppleMusic)

  for id in missing {
    // Albums that aren't on Apple Music have a slug instead of a collection id, so there's
    // nothing to look up
    guard Int(id) != nil else {
      print("⚠️ \(id) isn't on Apple Music, add \(posterPath(id: id)) by hand")
      continue
    }

    await downloadArtwork(id: id, artworkURL: artworkURLs[id])
  }

  return items
}

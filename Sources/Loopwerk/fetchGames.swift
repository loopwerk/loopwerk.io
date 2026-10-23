import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Saga
import SagaPathKit
import SwiftCSV

private let postersFolder: Path = "content/static/posters/games"
private let assetBaseURL = "https://shared.cloudflare.steamstatic.com/store_item_assets/"

/// Steam's store API knows the per-asset hashes that newer games hide their art behind,
/// which can't be derived from the appid.
private struct StoreItemsResponse: Decodable {
  struct Body: Decodable {
    let storeItems: [StoreItem]

    enum CodingKeys: String, CodingKey {
      case storeItems = "store_items"
    }
  }

  let response: Body
}

private struct StoreItem: Decodable {
  struct Assets: Decodable {
    let urlFormat: String?
    let libraryCapsule2x: String?
    let libraryCapsule: String?
    let mainCapsule2x: String?
    let header2x: String?
    let libraryHero: String?

    enum CodingKeys: String, CodingKey {
      case urlFormat = "asset_url_format"
      case libraryCapsule2x = "library_capsule_2x"
      case libraryCapsule = "library_capsule"
      case mainCapsule2x = "main_capsule_2x"
      case header2x = "header_2x"
      case libraryHero = "library_hero"
    }

    /// The 2:3 portrait art first, then the wide images the template crops down to 2:3.
    var bestURL: String? {
      guard let urlFormat,
            let filename = libraryCapsule2x ?? libraryCapsule ?? mainCapsule2x ?? header2x ?? libraryHero
      else { return nil }

      return assetBaseURL + urlFormat.replacingOccurrences(of: "${FILENAME}", with: filename)
    }
  }

  let appid: Int
  let assets: Assets?
}

/// The old predictable URLs, still the only option for delisted games that the store API
/// returns nothing for.
private let legacyCoverArtSources = [
  "library_600x900_2x.jpg",
  "capsule_616x353.jpg",
  "header.jpg",
  "library_hero.jpg",
]

private func posterPath(id: String) -> Path {
  postersFolder + "\(id).jpg"
}

/// Looks up the best cover art URL for each game in a single request.
private func fetchAssetURLs(ids: [String]) async -> [String: String] {
  let payload: [String: Any] = [
    "ids": ids.compactMap(Int.init).map { ["appid": $0] },
    "context": ["language": "english", "country_code": "US"],
    "data_request": ["include_assets": true],
  ]

  guard let json = try? JSONSerialization.data(withJSONObject: payload),
        let jsonString = String(data: json, encoding: .utf8),
        var components = URLComponents(string: "https://api.steampowered.com/IStoreBrowseService/GetItems/v1/")
  else { return [:] }

  components.queryItems = [URLQueryItem(name: "input_json", value: jsonString)]
  guard let url = components.url else { return [:] }

  do {
    let (data, _) = try await URLSession.shared.data(from: url)
    let items = try JSONDecoder().decode(StoreItemsResponse.self, from: data).response.storeItems

    return items.reduce(into: [:]) { urls, item in
      urls["\(item.appid)"] = item.assets?.bestURL
    }
  } catch {
    print("⚠️ Failed to load Steam asset manifests: \(error)")
    return [:]
  }
}

/// Downloads a game's cover art into content/static/posters.
/// Does nothing when we already have the image on disk; delete it to try Steam again.
private func downloadCoverArt(id: String, assetURL: String?) async {
  let destination = posterPath(id: id)
  guard !destination.exists else { return }

  let candidates = [assetURL].compactMap(\.self)
    + legacyCoverArtSources.map { "https://cdn.cloudflare.steamstatic.com/steam/apps/\(id)/\($0)" }

  for candidate in candidates {
    guard let url = URL(string: candidate) else { continue }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

      try postersFolder.mkpath()
      try destination.write(data)
      return
    } catch {
      print("⚠️ Failed to download \(candidate) for \(id): \(error)")
    }
  }

  print("⚠️ No cover art for \(id)")
}

func fetchGames() async throws -> [Item<GameMetadata>] {
  let csvFile = try loadCSV(named: "games")

  let items = compactMapRows(csvFile) { position, row in
    let metadata = try GameMetadata(
      position: position,
      id: row.required("Id"),
      title: row.required("Title"),
      url: row["URL"]?.nonEmpty
    )
    return Item(title: metadata.title, metadata: metadata)
  }

  // Only ask Steam about games we don't already have art for, so a rebuild does no networking
  let missing = items.map(\.metadata.id).filter { !posterPath(id: $0).exists }
  let onSteam = missing.filter { Int($0) != nil }
  let assetURLs = onSteam.isEmpty ? [:] : await fetchAssetURLs(ids: onSteam)

  for id in missing {
    // Games that aren't on Steam have a slug instead of an appid, so there's nothing to ask for
    guard Int(id) != nil else {
      print("⚠️ \(id) isn't on Steam, add \(posterPath(id: id)) by hand")
      continue
    }

    await downloadCoverArt(id: id, assetURL: assetURLs[id])
  }

  return items
}

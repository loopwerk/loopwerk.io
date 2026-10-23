import Foundation
import SagaPathKit
import SwiftCSV

private let csvFolder: Path = "Sources/Loopwerk/csv"

/// Reads a CSV straight from the source folder instead of the SwiftPM resource bundle.
///
/// The bundle copy is only refreshed when the package recompiles, but editing a .csv doesn't
/// trigger a recompile — only a site rebuild. Reading the file directly means CSV edits show up
/// on the very next rebuild.
func loadCSV(named name: String) throws -> CSV<Named> {
  try CSV<Named>(url: (csvFolder + "\(name).csv").url)
}

extension String {
  /// Optional csv columns come back as an empty string, both when the field is empty and when
  /// the row doesn't have it at all.
  var nonEmpty: String? {
    isEmpty ? nil : self
  }
}

/// A row that isn't filled in yet, thrown while turning it into metadata so the row can be
/// skipped instead of taking the whole build down.
struct IncompleteRow: Error, CustomStringConvertible {
  let column: String

  var description: String {
    "\(column) is missing"
  }
}

extension [String: String] {
  /// A column that a row can't do without. Throws when the field is empty or isn't there at all.
  func required(_ column: String) throws -> String {
    guard let value = self[column]?.nonEmpty else { throw IncompleteRow(column: column) }
    return value
  }

  /// A required column that has to hold a number.
  func requiredInt(_ column: String) throws -> Int {
    guard let value = try Int(required(column)) else { throw IncompleteRow(column: column) }
    return value
  }
}

/// Turns csv rows into items, skipping the rows that aren't filled in yet — editing a csv by
/// hand shouldn't crash the dev server halfway through typing a line.
///
/// The position handed to `transform` only counts the rows that made it through, so a skipped
/// row doesn't leave a hole in the numbering.
func compactMapRows<T>(_ csvFile: CSV<Named>, _ transform: (Int, [String: String]) throws -> T) -> [T] {
  var position = 0

  return csvFile.rows.compactMap { row in
    do {
      let value = try transform(position + 1, row)
      position += 1
      return value
    } catch {
      print("⚠️ Skipping csv row, \(error): \(row)")
      return nil
    }
  }
}

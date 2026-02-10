#if canImport(SwiftData)
  import DebugSnapshots
  import Foundation
  import SwiftData
  import Testing

  @Test func swiftData() throws {
    let schema = Schema([BucketListItem.self, LivingAccommodation.self, Trip.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let context = ModelContext(container)

    let trip = Trip(
      name: "Outer Borough Trip #1",
      destination: "Brooklyn, NY",
      startDate: Date(timeIntervalSinceReferenceDate: 0),
      endDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 7)
    )
    context.insert(trip)

    let bucketListItem = BucketListItem(
      title: "Brooklyn Bridge Park",
      details: """
        Explore the sweeping vistas, rich ecology, expansive piers, and vibrant programming of \
        this special waterfront park
        """,
      hasReservation: false,
      isInPlan: false
    )
    context.insert(bucketListItem)

    let livingAccommodation = LivingAccommodation(
      address: """
        60 Furman St
        Brooklyn, NY 11201
        """,
      placeName: "1 Hotel Brooklyn Bridge"
    )
    context.insert(livingAccommodation)
    trip.livingAccommodation = livingAccommodation

    withKnownIssue {
      expect(trip) {
        trip.bucketList.append(bucketListItem)
        trip.livingAccommodation = nil
      } changes: { _ in
      }
    } matching: {
      $0.description.hasSuffix(
        #"""
        Expected changes do not match: ...

          \#u{2007} #1 Trip.DebugSnapshot(
          \#u{2007}   name: "Outer Borough Trip #1",
          \#u{2007}   destination: "Brooklyn, NY",
          \#u{2007}   startDate: Date(2001-01-01T00:00:00.000Z),
          \#u{2007}   endDate: Date(2001-01-08T00:00:00.000Z),
          \#u{2007}   bucketList: [
          \#u{002B}     [0]: #1 BucketListItem.DebugSnapshot(
          \#u{002B}       title: "Brooklyn Bridge Park",
          \#u{002B}       details: "Explore the sweeping vistas, rich ecology, expansive piers, and vibrant programming of this special waterfront park",
          \#u{002B}       hasReservation: false,
          \#u{002B}       isInPlan: false
          \#u{002B}     )
          \#u{2007}   ],
          \#u{2212}   livingAccommodation: #1 LivingAccommodation.DebugSnapshot(
          \#u{2212}     address: """
          \#u{2212}       60 Furman St
          \#u{2212}       Brooklyn, NY 11201
          \#u{2212}       """,
          \#u{2212}     placeName: "1 Hotel Brooklyn Bridge"
          \#u{2212}   )
          \#u{002B}   livingAccommodation: nil
          \#u{2007} )

        (Expected: \#u{2212}, Actual: \#u{002B})
        """#
      )
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @DebugSnapshot
  @Model final class BucketListItem {
    var title: String
    var details: String
    var hasReservation: Bool
    var isInPlan: Bool
    @DebugSnapshotIgnored var trip: Trip?

    init(title: String, details: String, hasReservation: Bool, isInPlan: Bool) {
      self.title = title
      self.details = details
      self.hasReservation = hasReservation
      self.isInPlan = isInPlan
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @DebugSnapshot
  @Model final class LivingAccommodation {
    var address: String
    var placeName: String
    @DebugSnapshotIgnored var trip: Trip?

    init(address: String, placeName: String) {
      self.address = address
      self.placeName = placeName
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @DebugSnapshot
  @Model final class Trip {
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date

    @DebugSnapshotConvertible
    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem] = [BucketListItem]()

    @DebugSnapshotConvertible
    @Relationship(deleteRule: .cascade, inverse: \LivingAccommodation.trip)
    var livingAccommodation: LivingAccommodation?

    init(
      name: String,
      destination: String,
      startDate: Date = .now,
      endDate: Date = .distantFuture
    ) {
      self.name = name
      self.destination = destination
      self.startDate = startDate
      self.endDate = endDate
    }
  }
#endif

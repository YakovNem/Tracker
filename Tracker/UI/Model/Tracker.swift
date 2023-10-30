import UIKit

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: [WeekDay]?
    let type: TrackerType
    let isPinned: Bool
}

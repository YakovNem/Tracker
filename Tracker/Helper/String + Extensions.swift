import Foundation
extension Array where Element == WeekDay {
    func toString() -> String {
        return self.map { "\($0.rawValue)" }.joined(separator: ",")
    }
}

extension String {
    func toWeekDays() -> [WeekDay]? {
        let intArray = self.split(separator: ",").compactMap { Int($0) }
        return intArray.compactMap(WeekDay.init)
    }
}

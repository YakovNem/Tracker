import Foundation

extension Array where Element == Int {
    func sortedDaysOfWeek() -> [Int] {
        self.sorted { (day1, day2) -> Bool in
            switch (day1, day2) {
            case (1, 7):
                return false
            case (7, 1):
                return true
            default:
                return day1 < day2
            }
        }
    }
}

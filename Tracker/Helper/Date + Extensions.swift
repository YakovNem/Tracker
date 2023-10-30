import Foundation

extension Date {
    func dayOfWeek() -> Int? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        
        if weekday == 1 {
            return 7
        } else {
            return weekday - 1
        }
    }
}

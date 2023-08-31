//
//  Date+Extensions.swift
//  Tracker
//
//  Created by Yakov Nemychenkov on 27.08.2023.
//

import Foundation
extension Date {
    func dayOfWeek() -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        
        if weekday == 1 {
            return 7
        } else {
            return weekday - 1
        }
    }
}

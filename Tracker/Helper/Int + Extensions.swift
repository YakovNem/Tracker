import Foundation

extension Int {
    func daysEnding() -> String {
        let formatString = NSLocalizedString("days", comment: "days format")
        return String.localizedStringWithFormat(formatString, self)
    }
}

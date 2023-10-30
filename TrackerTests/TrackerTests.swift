import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackerTests: XCTestCase {

    func testViewController() {
        let vc = TrackersViewController()
        let navigationController = UINavigationController(rootViewController: vc)
        
        assertSnapshots(matching: navigationController, as: [.image])
    }
    
    func testViewControllerOnDifferentDevices() {
        let vc = TrackersViewController()
        assertSnapshots(matching: vc, as: [.image(on: .iPhone8), .image(on: .iPhoneX)])
    }
}

import XCTest
import Fate

final class FateTests: XCTestCase {
    func someFuture() -> Future<Void, Error> {
        let promise = Promise<Void, Error>()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
            try! promise.resolve(with: ())
        }
        return promise
    }

    func testCancel() {
        let future = someFuture()
        future.observe { (result) in
            fatalError("Oh, man the observe got executed and it shouldn't have")
        }
        future.cancel()

        sleep(5)
    }

    func testWait() {
        let future = someFuture()
        let result = future.wait()
        switch result {
        case .success(_):
            print("Wait worked")
        case .failure(_):
            fatalError("Crap, this should have worked")
        }
    }

    static var allTests = [
        ("testCancel", testCancel),
    ]
}

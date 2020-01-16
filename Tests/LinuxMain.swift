import XCTest

import FateTests

var tests = [XCTestCaseEntry]()
tests += FateTests.allTests()
XCTMain(tests)

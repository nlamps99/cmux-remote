import XCTest
@testable import SharedKit

final class PairingPayloadTests: XCTestCase {
    private let payload = PairingPayload(
        serverURL: "https://relay.example.com/cmux-remote",
        relayId: "home-mac",
        pairingCode: "deadbeef0123456789abcdef"
    )

    func testRoundTripsThroughURL() throws {
        let decoded = try PairingPayload(urlString: try payload.urlString())
        XCTAssertEqual(decoded, payload)
    }

    /// A base64/hex pairing code can contain `+`, `/` and `=`, which are all
    /// URL-significant. They must survive the round trip untouched.
    func testPreservesURLSignificantCharactersInTheCode() throws {
        let tricky = PairingPayload(
            serverURL: "https://relay.example.com",
            relayId: "home-mac",
            pairingCode: "a+b/c=d&e?f"
        )
        let decoded = try PairingPayload(urlString: try tricky.urlString())
        XCTAssertEqual(decoded.pairingCode, "a+b/c=d&e?f")
    }

    func testPreservesPathInServerURL() throws {
        let decoded = try PairingPayload(urlString: try payload.urlString())
        XCTAssertEqual(decoded.serverURL, "https://relay.example.com/cmux-remote")
    }

    func testRejectsForeignSchemes() {
        XCTAssertThrowsError(
            try PairingPayload(urlString: "https://pair?server=a&relay=b&code=c")
        ) { error in
            XCTAssertEqual(error as? PairingPayload.DecodeError, .notAPairingURL)
        }
    }

    func testRejectsOtherCmuxDeepLinks() {
        XCTAssertThrowsError(
            try PairingPayload(urlString: "cmux://surface/SF-1")
        ) { error in
            XCTAssertEqual(error as? PairingPayload.DecodeError, .notAPairingURL)
        }
    }

    func testRejectsMissingAndEmptyFields() {
        XCTAssertThrowsError(
            try PairingPayload(urlString: "cmux://pair?server=a&relay=b")
        ) { error in
            XCTAssertEqual(error as? PairingPayload.DecodeError, .missingField("code"))
        }
        XCTAssertThrowsError(
            try PairingPayload(urlString: "cmux://pair?server=a&relay=&code=c")
        ) { error in
            XCTAssertEqual(error as? PairingPayload.DecodeError, .missingField("relay"))
        }
    }
}

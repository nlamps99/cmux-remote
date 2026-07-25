import Foundation

/// The connection details a phone needs to pair with a broker-mode relay.
///
/// Encoded as a `cmux://pair?...` URL so it can be carried by a QR code. The
/// custom scheme is deliberate: it is not a tappable https link, so a screenshot
/// posted somewhere is less likely to be opened by a browser, and iOS routes it
/// straight back into the app.
///
/// This payload contains the pairing code in the clear. That is inherent to any
/// scan-to-pair flow — treat the QR code itself as a secret, the same way as the
/// code it carries.
public struct PairingPayload: Equatable, Sendable {
    public var serverURL: String
    public var relayId: String
    public var pairingCode: String

    public init(serverURL: String, relayId: String, pairingCode: String) {
        self.serverURL = serverURL
        self.relayId = relayId
        self.pairingCode = pairingCode
    }

    public enum DecodeError: Error, Equatable {
        case notAPairingURL
        case missingField(String)
    }

    public static let scheme = "cmux"
    public static let host = "pair"

    /// Percent-encodes every field, so a pairing code containing URL-significant
    /// characters survives the round trip.
    public func url() -> URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [
            URLQueryItem(name: "server", value: serverURL),
            URLQueryItem(name: "relay", value: relayId),
            URLQueryItem(name: "code", value: pairingCode),
        ]
        return components.url
    }

    public func urlString() throws -> String {
        guard let string = url()?.absoluteString else {
            throw DecodeError.notAPairingURL
        }
        return string
    }

    public init(url: URL) throws {
        guard url.scheme?.lowercased() == Self.scheme,
              url.host?.lowercased() == Self.host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { throw DecodeError.notAPairingURL }

        func value(_ name: String) throws -> String {
            guard let raw = components.queryItems?.first(where: { $0.name == name })?.value,
                  !raw.isEmpty
            else { throw DecodeError.missingField(name) }
            return raw
        }

        self.serverURL = try value("server")
        self.relayId = try value("relay")
        self.pairingCode = try value("code")
    }

    public init(urlString: String) throws {
        guard let url = URL(string: urlString) else { throw DecodeError.notAPairingURL }
        try self.init(url: url)
    }
}

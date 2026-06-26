import Foundation

public struct ContainerReleaseVersion: Sendable, Equatable, Hashable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prereleaseIdentifiers: [Identifier]?

    public var description: String {
        var value = "\(major).\(minor).\(patch)"
        if let prerelease = prereleaseIdentifiers, !prerelease.isEmpty {
            value += "-" + prerelease.map { $0.renderedValue }.joined(separator: ".")
        }
        return value
    }

    public init?(rawValue: String) {
        let normal = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split(separator: "+", omittingEmptySubsequences: false)
            .first

        guard let normal else { return nil }

        let parts = normal.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let core = String(parts[0])
        let prereleaseText = parts.count == 2 ? String(parts[1]) : nil

        let coreParts = core.split(separator: ".", omittingEmptySubsequences: false)
        guard coreParts.count == 2 || coreParts.count == 3 else { return nil }
        let major = Int(coreParts[0])
        let minor = Int(coreParts[1])
        let patch = Int(coreParts.count == 3 ? coreParts[2] : "0")

        guard let major, let minor, let patch else { return nil }

        let prereleaseIdentifiers: [Identifier]? = prereleaseText.flatMap { raw in
            let split = raw.split(separator: ".", omittingEmptySubsequences: false)
            let identifiers = split.compactMap { Identifier(rawValue: String($0)) }
            return identifiers.isEmpty ? nil : identifiers
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
    }

    public static func < (lhs: ContainerReleaseVersion, rhs: ContainerReleaseVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        switch (lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case let (lhsParts?, rhsParts?):
            return lhsParts.lexicographicallyPrecedes(rhsParts) { $0 < $1 }
        }
    }

    public enum Identifier: Sendable, Equatable, Hashable, Comparable {
        case numeric(Int)
        case textual(String)

        public static func < (lhs: Identifier, rhs: Identifier) -> Bool {
            switch (lhs, rhs) {
            case let (.numeric(l), .numeric(r)):
                return l < r
            case let (.textual(l), .textual(r)):
                return l < r
            case (.numeric, .textual):
                return true
            case (.textual, .numeric):
                return false
            }
        }

        public init?(rawValue: String) {
            if let numeric = Int(rawValue) {
                self = .numeric(numeric)
            } else if !rawValue.isEmpty {
                self = .textual(rawValue)
            } else {
                return nil
            }
        }

        public var renderedValue: String {
            switch self {
            case let .numeric(value):
                return String(value)
            case let .textual(value):
                return value
            }
        }
    }
}

public struct ContainerVersionParser: Sendable {
    private static let pattern = #"\b[vV]?\d+\.\d+(?:\.\d+)?(?:-[0-9A-Za-z.-]+)?\b"#
    private let expression: NSRegularExpression

    public init() {
        self.expression = try! NSRegularExpression(pattern: Self.pattern)
    }

    public func parse(from text: String) -> ContainerReleaseVersion? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = expression.firstMatch(in: text, range: range) else {
            return nil
        }

        guard let matchedRange = Range(match.range, in: text) else {
            return nil
        }

        let versionText = String(text[matchedRange]).trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        return ContainerReleaseVersion(rawValue: versionText)
    }
}

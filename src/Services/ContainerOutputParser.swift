import Foundation

public enum ContainerOutputKind {
    case container
    case image
    case volume
    case network
}

public struct ContainerOutputParser {
    private static let ansiPattern = #"\u{001B}\[[0-9;]*[mK]"#

    public init() {}

    public func parseContainers(from text: String) -> [ContainerStateRow] {
        parseRows(from: text, kind: .container).compactMap { row in
            guard let id = row["id"] ?? row["containerid"] ?? row["container"] else { return nil }
            return ContainerStateRow(
                id: id,
                image: row["image"],
                name: row["name"],
                command: row["command"],
                state: row["state"],
                status: row["status"],
                created: row["created"],
                ports: splitPorts(row["ports"])
            )
        }
    }

    public func parseImages(from text: String) -> [ContainerImageRow] {
        parseRows(from: text, kind: .image).compactMap { row in
            guard let id = row["id"] ?? row["imageid"] else { return nil }
            return ContainerImageRow(
                id: id,
                repository: row["repository"] ?? row["repo"],
                tag: row["tag"],
                digest: row["digest"] ?? row["imageid"]?.description,
                size: row["size"],
                created: row["created"]
            )
        }
    }

    public func parseVolumes(from text: String) -> [ContainerVolumeRow] {
        parseRows(from: text, kind: .volume).compactMap { row in
            guard let id = row["id"] ?? row["volume"] ?? row["name"] else { return nil }
            return ContainerVolumeRow(
                id: id,
                name: row["name"] ?? row["volume"],
                driver: row["driver"],
                scope: row["scope"],
                mountpoint: row["mountpoint"] ?? row["mount"]
            )
        }
    }

    public func parseNetworks(from text: String) -> [ContainerNetworkRow] {
        parseRows(from: text, kind: .network).compactMap { row in
            guard let id = row["id"] ?? row["networkid"] ?? row["name"] else { return nil }
            return ContainerNetworkRow(
                id: id,
                name: row["name"],
                driver: row["driver"],
                scope: row["scope"],
                internal: row["internal"],
                attachable: row["attachable"]
            )
        }
    }

    private func parseRows(from text: String, kind: ContainerOutputKind) -> [[String: String]] {
        let sanitized = sanitize(text)
        guard let jsonRows = parseJSONRows(from: sanitized) else {
            return parseTableRows(from: sanitized, kind: kind)
        }
        return jsonRows
    }

    private func parseJSONRows(from text: String) -> [[String: String]]? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard
            let root = try? JSONSerialization.jsonObject(with: data),
            let list = root as? [[String: Any]]
        else { return nil }
        return list.compactMap { dictionary in
            var normalized: [String: String] = [:]
            for (key, value) in dictionary {
                guard let text = valueText(value) else { continue }
                normalized[key.normalizedKey()] = text
            }
            return normalized
        }
    }

    private func parseTableRows(from text: String, kind: ContainerOutputKind) -> [[String: String]] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let headerIndex = lines.firstIndex(where: { hasHeader($0, kind: kind) }) else {
            return []
        }

        let headerLine = lines[headerIndex]
        let headerColumns = headerColumns(from: headerLine)
        let starts = headerColumns.map(\.start)
        let rows = Array(lines[(headerIndex + 1)...])

        let meaningful = rows.filter { row in
            !row.contains("----") && !row.hasPrefix("----")
        }

        return meaningful.compactMap { row in
            var parsed: [String: String] = [:]
            for index in headerColumns.indices {
                let start = starts[index]
                let end = index + 1 < headerColumns.count ? starts[index + 1] : row.utf16.count
                let tokenRange = start..<min(end, row.utf16.count)
                let raw = token(from: row, range: tokenRange).trimmingCharacters(in: .whitespaces)
                if !raw.isEmpty {
                    parsed[headerColumns[index].name] = raw
                }
            }
            return parsed
        }
    }

    private func hasHeader(_ line: String, kind: ContainerOutputKind) -> Bool {
        let keys = requiredHeaderAliases(for: kind).flatMap { $0 }
        let lower = line.lowercased()
        let tokenized = Set(lower.split { $0.isWhitespace }.map(String.init).map { $0.normalizedKey() })
        let matches = keys.filter { tokenized.contains($0) }
        return matches.count >= 1 && tokenized.count >= 2
    }

    private func splitPorts(_ value: String?) -> [String] {
        guard let value else { return [] }
        let separatorSet = CharacterSet(charactersIn: ",")
        return value
            .split(whereSeparator: separatorSet.contains)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func sanitize(_ text: String) -> String {
        text.replacingOccurrences(
            of: Self.ansiPattern,
            with: "",
            options: .regularExpression
        )
    }

    private func parseJSONRows(from text: String) -> [[String: String]]? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard
            let container = try? JSONSerialization.jsonObject(with: data),
            let list = container as? [[String: Any]]
        else {
            return nil
        }
        return list.compactMap { dictionary in
            var normalized: [String: String] = [:]
            for (key, value) in dictionary {
                if let stringValue = valueText(value) {
                    normalized[key.normalizedKey()] = stringValue
                }
            }
            return normalized
        }
    }

    private func valueText(_ value: Any) -> String? {
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func headerColumns(from headerLine: String) -> [(name: String, start: Int)] {
        let normalized = headerLine
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).normalizedKey() }

        var ranges: [String: Int] = [:]
        let ns = headerLine as NSString
        var anchors: [Int] = []
        for column in normalized {
            if let match = ns.range(of: column, options: .caseInsensitive, range: NSRange(location: 0, length: ns.length))?.location,
               match != NSNotFound {
                ranges[column] = match
            }
        }

        return zip(normalized, normalized.compactMap { ranges[$0] })
            .map { name, start in (name: name, start: start) }
    }

    private func requiredHeaderAliases(for kind: ContainerOutputKind) -> [[String]] {
        switch kind {
        case .container:
            return [["id", "containerid"], ["name"], ["image"], ["status"], ["state"], ["ports"], ["created"], ["command"]]
        case .image:
            return [["imageid", "id"], ["repository", "repo", "image"], ["tag"], ["size"], ["created"]]
        case .volume:
            return [["name", "volume", "volumeid"], ["driver"], ["scope"], ["mountpoint", "mount"]]
        case .network:
            return [["name", "network"], ["driver"], ["scope"], ["internal"], ["attachable"]]
        }
    }

    private func token(from row: String, range: Range<Int>) -> String {
        guard let start = row.utf16.index(row.utf16.startIndex, offsetBy: range.lowerBound, limitedBy: row.utf16.endIndex),
              let end = row.utf16.index(row.utf16.startIndex, offsetBy: range.upperBound, limitedBy: row.utf16.endIndex),
              let stringRange = Range(start..<end, in: row) else {
            return ""
        }
        return String(row[stringRange])
    }
}

private extension String {
    func normalizedKey() -> String {
        return lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }
}

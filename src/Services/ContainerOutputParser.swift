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
            guard let id = row["id"] ?? row["imageid"] ?? row["digest"] else { return nil }
            return ContainerImageRow(
                id: id,
                repository: row["repository"] ?? row["repo"] ?? row["image"],
                tag: row["tag"],
                digest: row["digest"] ?? row["imageid"],
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
                isInternal: row["internal"],
                attachable: row["attachable"]
            )
        }
    }

    private func parseRows(from text: String, kind: ContainerOutputKind) -> [[String: String]] {
        let sanitized = sanitize(text)
        if let jsonRows = parseJSONRows(from: sanitized) {
            return jsonRows
        }
        if let pipeRows = parsePipeRows(from: sanitized, kind: kind) {
            return pipeRows
        }
        return parseFixedWidthRows(from: sanitized, kind: kind)
    }

    private func parseJSONRows(from text: String) -> [[String: String]]? {
        guard let data = text.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data)
        else { return nil }

        if let rows = root as? [[String: Any]] {
            return rows.compactMap(normalizeJSONObject)
        }

        if let wrapper = root as? [String: Any] {
            if let items = wrapper["containers"] as? [[String: Any]] {
                return items.compactMap(normalizeJSONObject)
            }
            if let items = wrapper["images"] as? [[String: Any]] {
                return items.compactMap(normalizeJSONObject)
            }
            if let items = wrapper["volumes"] as? [[String: Any]] {
                return items.compactMap(normalizeJSONObject)
            }
            if let items = wrapper["networks"] as? [[String: Any]] {
                return items.compactMap(normalizeJSONObject)
            }
        }
        return nil
    }

    private func parsePipeRows(from text: String, kind: ContainerOutputKind) -> [[String: String]]? {
        let lines = normalizedLines(from: text)
        guard let headerIndex = lines.firstIndex(where: { hasHeader($0, kind: kind) && $0.contains("|") }) else {
            return nil
        }

        let header = splitPipeLine(lines[headerIndex]).map { $0.normalizedKey() }
        if header.isEmpty { return nil }

        let rawRows = lines[(headerIndex + 1)...].filter { !$0.isEmpty && !$0.hasPrefix("---") }
        var parsedRows: [[String: String]] = []

        for row in rawRows {
            let values = splitPipeLine(row)
            guard !values.isEmpty else { continue }
            if values.count == 1 && values[0].isEmpty { continue }

            var parsed: [String: String] = [:]
            for index in values.indices where index < header.count {
                let value = values[index].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    parsed[header[index]] = value
                }
            }
            if !parsed.isEmpty { parsedRows.append(parsed) }
        }

        return parsedRows
    }

    private func parseFixedWidthRows(from text: String, kind: ContainerOutputKind) -> [[String: String]] {
        let lines = normalizedLines(from: text)
        guard let headerIndex = lines.firstIndex(where: { hasHeader($0, kind: kind) }) else {
            return []
        }

        let columns = headerColumns(from: lines[headerIndex])
        if columns.isEmpty { return [] }
        let starts = columns.map(\.start)
        let body = lines[(headerIndex + 1)...].filter { !$0.hasPrefix("---") && !$0.isEmpty }

        return body.compactMap { line in
            var parsed: [String: String] = [:]
            for index in columns.indices {
                let start = starts[index]
                if start >= line.utf16.count { continue }
                let end = index + 1 < columns.count ? starts[index + 1] : line.utf16.count
                let value = substring(line, from: start, to: min(end, line.utf16.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    parsed[columns[index].name] = value
                }
            }
            return parsed.isEmpty ? nil : parsed
        }
    }

    private func hasHeader(_ line: String, kind: ContainerOutputKind) -> Bool {
        let aliases = Set(requiredHeaderAliases(for: kind).flatMap { $0 })
        let tokenized = Set(
            line
                .lowercased()
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
                .map { $0.normalizedKey() }
        )
        return !aliases.intersection(tokenized).isEmpty
    }

    private func normalizedLines(from text: String) -> [String] {
        sanitize(text)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.allSatisfy { $0 == "-" } }
    }

    private func splitPipeLine(_ line: String) -> [String] {
        line
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func splitPorts(_ value: String?) -> [String] {
        guard let value else { return [] }
        return value
            .split(separator: ",")
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

    private func normalizeJSONObject(_ item: [String: Any]) -> [String: String]? {
        var normalized: [String: String] = [:]
        for (key, value) in item {
            guard let stringValue = valueText(value) else { continue }
            normalized[key.normalizedKey()] = stringValue
        }
        return normalized.isEmpty ? nil : normalized
    }

    private func valueText(_ value: Any) -> String? {
        if let text = value as? String {
            return text
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func headerColumns(from headerLine: String) -> [(name: String, start: Int)] {
        guard let regex = try? NSRegularExpression(pattern: "\\S+") else { return [] }
        let matches = regex.matches(
            in: headerLine,
            range: NSRange(location: 0, length: headerLine.utf16.count)
        )

        let tokens = matches.compactMap { match -> (String, Int)? in
            guard let range = Range(match.range, in: headerLine) else { return nil }
            let token = String(headerLine[range]).normalizedKey()
            return (token, match.range.location)
        }
        if tokens.isEmpty { return [] }

        let twoWordMerges: Set<String> = ["containerid", "imageid", "networkid", "volumeid"]
        var columns: [(String, Int)] = []
        var index = 0
        while index < tokens.count {
            if index + 1 < tokens.count {
                let pair = tokens[index].0 + tokens[index + 1].0
                if twoWordMerges.contains(pair) {
                    columns.append((pair, tokens[index].1))
                    index += 2
                    continue
                }
            }
            columns.append(tokens[index])
            index += 1
        }

        return columns
    }

    private func requiredHeaderAliases(for kind: ContainerOutputKind) -> [[String]] {
        switch kind {
        case .container:
            return [["container", "containerid", "id"], ["name"], ["image"], ["status"], ["state"], ["ports"], ["created"], ["command"]]
        case .image:
            return [["imageid", "id"], ["repository", "repo", "image"], ["tag"], ["size"], ["created"]]
        case .volume:
            return [["volume", "name", "volumeid"], ["driver"], ["scope"], ["mountpoint", "mount"]]
        case .network:
            return [["name", "network", "networkid"], ["driver"], ["scope"], ["internal"], ["attachable"]]
        }
    }

    private func substring(_ line: String, from start: Int, to end: Int) -> String {
        guard
            let start16 = line.utf16.index(
                line.utf16.startIndex,
                offsetBy: start,
                limitedBy: line.utf16.endIndex
            ),
            let end16 = line.utf16.index(
                line.utf16.startIndex,
                offsetBy: end,
                limitedBy: line.utf16.endIndex
            ),
            let startIndex = start16.samePosition(in: line),
            let endIndex = end16.samePosition(in: line),
            startIndex <= endIndex
        else { return "" }
        return String(line[startIndex..<endIndex])
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

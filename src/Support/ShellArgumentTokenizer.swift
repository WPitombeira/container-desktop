import Foundation

enum ShellArgumentTokenizationError: Error, LocalizedError {
    case unbalancedQuotes

    var errorDescription: String? {
        "Command contained an unbalanced quote."
    }
}

struct ShellArgumentTokenizer {
    private enum Quote {
        case none
        case single
        case double
    }

    func tokenize(_ input: String) throws -> [String] {
        var tokens: [String] = []
        var buffer = ""
        var state: Quote = .none
        var escaped = false

        for scalar in input.unicodeScalars {
            let character = String(scalar)

            if escaped {
                buffer.append(contentsOf: escapedValue(for: scalar))
                escaped = false
                continue
            }

            if character == "\\" && state != .single {
                escaped = true
                continue
            }

            if state == .none && character == "'" {
                state = .single
                continue
            }

            if state == .none && character == "\"" {
                state = .double
                continue
            }

            if state == .single && character == "'" {
                state = .none
                continue
            }

            if state == .double && character == "\"" {
                state = .none
                continue
            }

            if state == .none && character == " " {
                if !buffer.isEmpty {
                    tokens.append(buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
                continue
            }

            buffer.append(contentsOf: character)
        }

        if escaped || state != .none {
            throw ShellArgumentTokenizationError.unbalancedQuotes
        }

        if !buffer.isEmpty {
            tokens.append(buffer)
        }
        return tokens
    }

    private func escapedValue(for scalar: UnicodeScalar) -> String {
        if scalar == "n" { return "\n" }
        if scalar == "t" { return "\t" }
        if scalar == "\\" { return "\\" }
        if scalar == "\"" { return "\"" }
        if scalar == "'" { return "'" }
        return String(scalar)
    }
}

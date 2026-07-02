import AuraMCPKit
import Foundation

@main
struct AuraMCPMain {
    static func main() async {
        if CommandLine.arguments.contains("--help") {
            print("""
            AuraMCP

            Stdio MCP server for Container Desktop agent tooling.

            Usage:
              swift run --package-path <container-desktop-path> AuraMCP

            The server reads newline-delimited JSON-RPC messages from stdin and writes responses to stdout.
            """)
            return
        }

        await StdioMCPServer().run()
    }
}

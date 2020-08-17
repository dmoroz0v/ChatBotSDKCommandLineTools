import Foundation

@discardableResult
func shell(_ args: [String]) -> [String] {
    var result : [String] = []
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = args
    let standardOutput = Pipe()
    process.standardOutput = standardOutput
    process.launch()
    let resultdata = standardOutput.fileHandleForReading.readDataToEndOfFile()
    if var stringValue = String(data: resultdata, encoding: .utf8) {
        stringValue = stringValue.trimmingCharacters(in: .newlines)
        result = stringValue.components(separatedBy: "\n")
    }
    process.waitUntilExit()
    return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
}

struct Exeption: Error {

}

func clone(tag: String, repository: String, path: String) {
    shell(["git", "clone", "--depth", "1", "--branch", tag, repository, path])
}

func replace(
    replacingPathComponents: [String],
    destinationUrl: URL,
    botname: String,
    sdkTag: String,
    tgTag: String,
    version: String
) throws {
    for pathComponent in replacingPathComponents {
        let url = destinationUrl.appendingPathComponent(pathComponent)
        let data = try Data(contentsOf: url)
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "__BOTNAME__", with: botname)
            string = string.replacingOccurrences(of: "__sdkTAG__", with: sdkTag)
            string = string.replacingOccurrences(of: "__tgTAG__", with: tgTag)
            string = string.replacingOccurrences(of: "__VERSION__", with: version)
            if let data = string.data(using: .utf8) {
                try data.write(to: url)
            } else {
                throw Exeption()
            }
        } else {
            throw Exeption()
        }
    }
}

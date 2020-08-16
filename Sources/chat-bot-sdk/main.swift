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

struct Urls {

    struct PathComponent {
        var component: String
        var subComponents: [PathComponent]
    }

    var sourceUrl: URL
    var destinationUrl: URL

    var copyPathComponents: [String] {
        return [
            ".cbproject",
            "config.json",
            "__BOTNAME__Project",
            "__BOTNAME__",
        ]
    }

    var replacingPathComponents: [String] {
        return [
            ".cbproject",
            "__BOTNAME__Project/Bot/main.swift",
            "__BOTNAME__Project/BotDependencies/Package.swift",
            "__BOTNAME__/Package.swift",
        ]
    }

    var renamingPathComponents: [PathComponent] {
        return [
            PathComponent(component: "__BOTNAME__Project", subComponents: []),
            PathComponent(
                component: "__BOTNAME__",
                subComponents: [
                    PathComponent(
                        component: "Sources/__BOTNAME__",
                        subComponents: [
                            PathComponent( component: "__BOTNAME__.swift", subComponents: []),
                        ]
                    ),
                ]
            ),
        ]
    }

}

var command = CommandLine.arguments[1]

if command != "create" {
    throw Exeption()
}

let baseUrl = URL(fileURLWithPath: shell(["pwd"]).first!)
var botname = CommandLine.arguments[2]

var botUrl = baseUrl.appendingPathComponent(botname)
var tag = "0.0.1"
var repository = "https://github.com/dmoroz0v/ChatBotTemplate.git"

var urls = Urls(
    sourceUrl: botUrl.appendingPathComponent(".tmp/template"),
    destinationUrl: botUrl.appendingPathComponent(".tmp/bot")
)

do {
    // создание корневой директории проекта-бота
    try FileManager.default.createDirectory(
        at: botUrl,
        withIntermediateDirectories: true,
        attributes: nil
    )

    // клонирование шаблона проекта

    shell(["git", "clone", "--depth", "1", "--branch", tag, repository, urls.sourceUrl.path])

    // заполнение папки .tmp/bot

    try FileManager.default.createDirectory(
        at: urls.destinationUrl,
        withIntermediateDirectories: true,
        attributes: nil
    )

    for copyPathComponent in urls.copyPathComponents {
        try FileManager.default.copyItem(
            at: urls.sourceUrl.appendingPathComponent(copyPathComponent),
            to: urls.destinationUrl.appendingPathComponent(copyPathComponent)
        )
    }

    // замена __BOTNAME__ на botname

    for pathComponent in urls.replacingPathComponents {
        let url = urls.destinationUrl.appendingPathComponent(pathComponent)
        let data = try Data(contentsOf: url)
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "__BOTNAME__", with: botname)
            if let data = string.data(using: .utf8) {
                try data.write(to: url)
            } else {
                throw Exeption()
            }
        } else {
            throw Exeption()
        }
    }

    // переименование директорий и файлов

    func rename(url: URL, renamePathComponents: [Urls.PathComponent]) throws {
        for renamePathComponent in renamePathComponents {
            let atUrl = url.appendingPathComponent(renamePathComponent.component)
            let toUrl = url.appendingPathComponent(
                renamePathComponent.component.replacingOccurrences(of: "__BOTNAME__", with: botname)
            )
            try FileManager.default.moveItem(at: atUrl, to: toUrl)
            try rename(url: toUrl, renamePathComponents: renamePathComponent.subComponents)
        }
    }

    try rename(url: urls.destinationUrl, renamePathComponents: urls.renamingPathComponents)

    // копирование готового проекта из папки .tmp в папку проекта-бота

    let contents = try FileManager.default.contentsOfDirectory(
        at: urls.destinationUrl,
        includingPropertiesForKeys: nil,
        options: [])

    for content in contents {
        try FileManager.default.copyItem(
            at: content,
            to: botUrl.appendingPathComponent(content.lastPathComponent)
        )
    }

}
catch let e {
    print(e)
}


try? FileManager.default.removeItem(at: urls.destinationUrl)

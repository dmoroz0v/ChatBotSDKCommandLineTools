import Foundation

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

func homeDir() -> URL {
    if #available(macOS 10.12, *) {
        return FileManager.default.homeDirectoryForCurrentUser
    } else {
        fatalError("update mac OS to 10.12")
    }
}

func upReleases(cacheUrl: URL, releasesUrl: URL) throws {

    if !FileManager.default.fileExists(atPath: cacheUrl.path) {
        try FileManager.default.createDirectory(
            at: cacheUrl,
            withIntermediateDirectories: true,
            attributes: nil)
    }

    if !FileManager.default.fileExists(atPath: releasesUrl.path) {
        shell(["git", "clone", "https://github.com/dmoroz0v/ChatBotSDK-releases.git", releasesUrl.path])
        shell(["git", "-C", releasesUrl.path, "checkout", "master"])
    } else {
        shell(["git", "-C", releasesUrl.path, "fetch"])
        shell(["git", "-C", releasesUrl.path, "pull"])
    }

}

struct ReleaseSpec: Decodable {

    struct SDK: Decodable {
        var version: String
    }

    struct Template: Decodable {
        var repository: String
        var version: String
    }

    struct Tg: Decodable {
        var version: String
    }

    struct DockerTemplate: Decodable {
        var repository: String
        var version: String
    }

    var version: String
    var template: Template
    var sdk: SDK
    var tg: Tg
    var dockerTemplate: DockerTemplate
}

func create(baseUrl: URL, botname: String, tag: String) throws {
    let botUrl = baseUrl.appendingPathComponent(botname)

    let urls = Urls(
        sourceUrl: botUrl.appendingPathComponent(".tmp/template"),
        destinationUrl: botUrl.appendingPathComponent(".tmp/bot")
    )

    do {
        let homeUrl = homeDir()
        let cacheUrl = homeUrl.appendingPathComponent(".cbcache")
        let releasesUrl = cacheUrl.appendingPathComponent("releases")

        try upReleases(cacheUrl: cacheUrl, releasesUrl: releasesUrl)

        let data = try Data(contentsOf: releasesUrl.appendingPathComponent(tag).appendingPathExtension("json"))

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let releaseSpec = try decoder.decode(ReleaseSpec.self, from: data)

        // создание корневой директории проекта-бота
        try FileManager.default.createDirectory(
            at: botUrl,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // клонирование шаблона проекта

        clone(tag: releaseSpec.template.version, repository: releaseSpec.template.repository, path: urls.sourceUrl.path)

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

        // замена __BOTNAME__ на botname и __sdkTAG__ и __tgSDK__

        try replace(
            replacingPathComponents: urls.replacingPathComponents,
            destinationUrl: urls.destinationUrl,
            botname: botname,
            sdkTag: releaseSpec.sdk.version,
            tgTag: releaseSpec.tg.version,
            version: String(data: data, encoding: .utf8)!
        )

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
}

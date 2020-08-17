import Foundation

struct Project: Decodable {
    var name: String
    var version: ReleaseSpec
}

func build(botUrl: URL) throws {
    let projectUrl = botUrl.appendingPathComponent(".cbproject")
    let project = try JSONDecoder().decode(Project.self, from: try Data(contentsOf: projectUrl))
    let botname = project.name
    let version = project.version

    let dockerUrl = botUrl.appendingPathComponent(".docker")
    clone(tag: version.dockerTemplate.version, repository: version.dockerTemplate.repository, path: dockerUrl.path)

    if FileManager.default.fileExists(atPath: dockerUrl.path) {
        try FileManager.default.removeItem(at: dockerUrl)
    }

    try FileManager.default.copyItem(
        at: botUrl.appendingPathComponent(botname),
        to: dockerUrl.appendingPathComponent("logic").appendingPathComponent(botname)
    )

    try FileManager.default.copyItem(
        at: botUrl.appendingPathComponent("config.json"),
        to: dockerUrl.appendingPathComponent("logic").appendingPathComponent("config.json")
    )

    let replacingPathComponents: [String] = [
        "logic/App/Package.swift",
        "logic/App/Sources/App/main.swift",
    ]

    try replace(
        replacingPathComponents: replacingPathComponents,
        destinationUrl: dockerUrl,
        botname: botname,
        sdkTag: version.sdk.version,
        tgTag: version.tg.version,
        version: ""
    )

    shell(["docker-compose", "-f", "./.docker/docker-compose.yml", "build"])
}

func up() throws {
    shell(["docker-compose", "-f", "./.docker/docker-compose.yml", "up", "--no-start"])
}

func start() throws {
    shell(["docker-compose", "-f", "./.docker/docker-compose.yml", "start"])
}

func stop() throws {
    shell(["docker-compose", "-f", "./.docker/docker-compose.yml", "stop"])
}

func down() throws {
    shell(["docker-compose", "-f", "./.docker/docker-compose.yml", "down"])
}

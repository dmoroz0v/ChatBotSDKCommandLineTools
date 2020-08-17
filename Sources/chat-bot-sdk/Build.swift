import Foundation

struct Project: Decodable {
    var name: String
    var version: ReleaseSpec
}

func build(botUrl: URL, verbose: Bool) throws {
    let projectUrl = botUrl.appendingPathComponent(".cbproject")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let project = try decoder.decode(Project.self, from: try Data(contentsOf: projectUrl))
    let botname = project.name
    let version = project.version

    let dockerUrl = botUrl.appendingPathComponent(".docker")

    if FileManager.default.fileExists(atPath: dockerUrl.path) {
        if verbose { print("Deleting '\(dockerUrl)'") }
        try FileManager.default.removeItem(at: dockerUrl)
    }

    clone(tag: version.dockerTemplate.version, repository: version.dockerTemplate.repository, path: dockerUrl.path)

    if verbose { print("Copying '\(botUrl.appendingPathComponent(botname).path)' to '\(dockerUrl.appendingPathComponent("logic").appendingPathComponent(botname).path)'") }
    try FileManager.default.copyItem(
        at: botUrl.appendingPathComponent(botname),
        to: dockerUrl.appendingPathComponent("logic").appendingPathComponent(botname)
    )

    if verbose { print("Copying '\(botUrl.appendingPathComponent("config.json").path)' to '\(dockerUrl.appendingPathComponent("logic").appendingPathComponent("config.json").path)'") }
    try FileManager.default.copyItem(
        at: botUrl.appendingPathComponent("config.json"),
        to: dockerUrl.appendingPathComponent("logic").appendingPathComponent("config.json")
    )

    let replacingPathComponents: [String] = [
        "logic/App/Package.swift",
        "logic/App/Sources/App/main.swift",
    ]

    if verbose { print("Replacing content in template") }
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

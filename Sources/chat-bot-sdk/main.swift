import Foundation

let command = CommandLine.arguments[1]

if command == "create" {
    let baseUrl = URL(fileURLWithPath: shell(["pwd"]).first!)
    let botname = CommandLine.arguments[2]
    let tag = CommandLine.arguments[3]
    try create(baseUrl: baseUrl, botname: botname, tag: tag)
} else if command == "run" {
    let botUrl = URL(fileURLWithPath: shell(["pwd"]).first!)
    try run(botUrl: botUrl)
} else {
    throw Exeption()
}

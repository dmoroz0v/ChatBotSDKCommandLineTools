import Foundation

let command = CommandLine.arguments[1]

func hasVerbose(args: [String]) -> Bool {
    return nil != CommandLine.arguments.first(where: {
        $0 == "-v"
    })
}

do {
    if command == "help" {
        print("commands:")
        print("create <project_name> <version_of_tg_bot> - создать директория с проектом")
        print("build - собрать образы")
        print("up - собрать контейнеры")
        print("start - запустить контейнеры")
        print("stop - остановить контейнеры")
        print("down - остановить и удалить контейнеры")
    } else if command == "create" {
        let baseUrl = URL(fileURLWithPath: shell(["pwd"]).first!)
        let arguments = CommandLine.arguments.filter { !$0.hasPrefix("-") }
        let botname = arguments[2]
        let tag = arguments[3]
        try create(baseUrl: baseUrl, botname: botname, tag: tag)
    } else if command == "build" {
        let botUrl = URL(fileURLWithPath: shell(["pwd"]).first!)
        try build(botUrl: botUrl, verbose: hasVerbose(args: CommandLine.arguments))
    } else if command == "up" {
        try up()
    } else if command == "start" {
        try start()
    } else if command == "stop" {
        try stop()
    } else if command == "down" {
        try down()
    } else {
        throw Exeption()
    }
} catch let e {
    print(e)
}


@testable import HTMLKit

protocol HTMLTestable: ViewBuildable {
    static var expextedOutput: String { get }
}


struct SimpleView: StaticTemplate, HTMLTestable {

    static var expextedOutput: String = "<div><p>Text</p></div>"

    static func build() -> Mappable {
        return
            div(
                p("Text")
            )
    }
}

struct BaseView: ViewTemplate {

    struct Context {
        let title: String
    }

    struct ViewContext {
        let body: Mappable
    }

    static func build(with context: BaseView.ViewContext) -> Mappable {
        return
            html(
                head(
                    title(variable(at: \.title))
                ),
                body(context.body)
        )
    }
}

struct StringView: Template {

    struct Context {
        let string: String
    }

    static func build() -> Mappable {
        return
            p(variable(at: \.string))
    }

}

struct SomeView: Template {

    struct Context {
        let name: String
        let baseContext: BaseView.Context

        static func contentWith(name: String, title: String) -> Context {
            return .init(name: name, baseContext: .init(title: title))
        }
    }

    static func build() -> Mappable {
        return
            embed(
                BaseView.self,
                with: .init(
                    body: p("Hello ", variable(at: \.name), "!")
                ),
                contextPath: \.baseContext
            )
    }
}

struct ForEachView: Template {

    struct Context {
        let array: [StringView.Context]

        static func content(from array: [String]) -> Context {
            array.enumerated().map { $0.element }
            return .init(array: array.map { .init(string: $0) })
        }
    }

    static func build() -> Mappable {
        return
            div(attr: [.id("array")],
                forEach(in: \.array, render: StringView.self)
        )
    }
}


struct IFView: Template {

    struct Context {
        let name: String
        let age: Int
        let nullable: String?
        let bool: Bool
    }

    static func build() -> Mappable {
        return
            div(
                renderIf(\.name == "Mats", view:
                    p("My name is: ", variable(at: \.name), "!")
                ),
                renderIf(\.age < 20, view:
                    "I am a child"
                ).elseIf(\.age > 20, render:
                    "I am older"
                ).else(render:
                    "I am growing"
                ),
                renderIf(notNull: \.nullable, view:
                    b("Only if nullable exists")
                ).elseIf(\.bool, render:
                    p("Simple bool")
                )
            )
    }
}

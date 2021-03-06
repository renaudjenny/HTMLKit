//
//  ForEach.swift
//  HTMLKit
//
//  Created by Mats Mollestad on 02/03/2019.
//

/// A struct making it possible to have a for each loop in the template
public struct ForEach<Values> where Values: Sequence {

    public let context: TemplateValue<Values>

    let content: HTML

    let localFormula: HTMLRenderer.Formula

    let condition: Conditionable
    var isEnumerated: Bool = false

    public init(in context: TemplateValue<Values>, @HTMLBuilder content: (TemplateValue<Values.Element>) -> HTML) {

        self.condition = true
        self.context = context
        switch context {
        case .constant(let values): self.content = values.reduce(into: "") { $0 += content(.constant($1)) }
        case .dynamic(let variable): self.content = content(.dynamic(.root(Values.Element.self, rootId: "\(variable.pathId)-loop")))
        }
        localFormula = .init()
    }

    public init(in context: TemplateValue<Values?>, @HTMLBuilder content: (TemplateValue<Values.Element>) -> HTML) {

        self.context = context.unsafelyUnwrapped
        switch context {
        case .constant(let values):
            if let values = values {
                self.content = values.reduce(into: "") { $0 += content(.constant($1)) }
            } else {
                self.content = ""
            }
        case .dynamic(let variable):
            self.content = content(.dynamic(.root(Values.Element.self, rootId: variable.unsafelyUnwrapped.pathId + "-loop")))
        }
        self.condition = context.isDefined
        localFormula = .init()
    }

    public init(enumerated context: TemplateValue<Values>, @HTMLBuilder content: ((element: TemplateValue<Values.Element>, index: TemplateValue<Int>)) -> HTML) {

        self.condition = true
        self.context = context
        switch context {
        case .constant(let values): self.content = values.enumerated().reduce(into: "") { $0 += content((.constant($1.element), .constant($1.offset))) }
        case .dynamic(let variable): self.content = content(
            (
                .dynamic(.root(Values.Element.self, rootId: "\(variable.pathId)-loop")),
                .dynamic(.root(Int.self, rootId: "\(variable.pathId)-loop-index"))
            ))
        }
        localFormula = .init()
        self.isEnumerated = true
    }
}

extension ForEach {
    public init(enumerated context: Values, @HTMLBuilder content: ((element: TemplateValue<Values.Element>, index: TemplateValue<Int>)) -> HTML) {
        self.init(enumerated: .constant(context), content: content)
    }
}

extension ForEach {
    public init(in values: Values, @HTMLBuilder content: (TemplateValue<Values.Element>) -> HTML) {
        self.init(in: .constant(values), content: content)
    }
}

extension ForEach: HTML {

    public func prerender(_ formula: HTMLRenderer.Formula) throws {
        formula.add(mappable: self)
        try content.prerender(localFormula)
    }

    public func render<T>(with manager: HTMLRenderer.ContextManager<T>) throws -> String {
        switch context {
        case .constant(_):
            return try localFormula.render(with: manager)
        case .dynamic(let variable):
            guard try condition.evaluate(with: manager) else { return "" }
            var rendering = ""
            let elements = try manager.value(for: variable)
            if isEnumerated {
                for (index, element) in elements.enumerated() {
                    manager.set(index, for: .root(Int.self, rootId: variable.pathId + "-loop-index"))
                    manager.set(element, for: .root(Values.Element.self, rootId: variable.pathId + "-loop"))
                    rendering += try localFormula.render(with: manager)
                }
            } else {
                for element in elements {
                    manager.set(element, for: .root(Values.Element.self, rootId: variable.pathId + "-loop"))
                    rendering += try localFormula.render(with: manager)
                }
            }

            return rendering
        }
    }
}

extension TemplateValue where Value: Sequence {

    func forEach(@HTMLBuilder content: (TemplateValue<Value.Element>) -> HTML) -> HTML {
        ForEach(in: self, content: content)
    }
}

extension Sequence {
    public func htmlForEach(@HTMLBuilder content: (TemplateValue<Element>) -> HTML) -> HTML {
        ForEach(in: .constant(self), content: content)
    }
}

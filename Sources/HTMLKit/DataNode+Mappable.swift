/// Makes the node renderable
extension HTML.DataNode: Mappable {

    public func map<T>(for type: T.Type, with context: T.Context) throws -> String where T : Template {
        return try "<\(nodeName)" + attributes.reduce("") { try $0 + " \($1.map(for: type, with: context))" } + "/>"
    }

    public func brew<T>(_ formula: HTML.Renderer.Formula<T>) throws where T: Template {
        formula.add(string: "<\(nodeName)")
        try attributes.forEach {
            formula.add(string: " ")
            try $0.brew(formula)
        }
        formula.add(string: "/>")
    }
}

import SwiftUI
import Foundation

struct TurtleSegment: Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let heading: Double
    let color: Color
    let lineWidth: CGFloat
    let turtleID: String
}

struct LogoExecutionResult {
    let segments: [TurtleSegment]
    let bounds: CGRect
    let initialStates: [String: TurtleState]
    let finalStates: [String: TurtleState]
    let turtleOrder: [String]
}

struct TurtleState {
    var position: CGPoint = .zero
    var heading: Double = 0 // Degrees; 0 means pointing up
    var penDown: Bool = true
    var penColor: Color = .blue
    var lineWidth: CGFloat = 2
}

enum LogoInterpreterError: LocalizedError, Identifiable {
    case unexpectedEndOfInput
    case unexpectedToken(String)
    case invalidNumber(String)
    case invalidRepeatCount(String)
    case missingBlock
    case missingEnd(String)
    case missingIdentifier(String)
    case recursionLimitReached
    case undefinedVariable(String)
    case invalidExpression(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .unexpectedEndOfInput:
            return "Unexpected end of input."
        case .unexpectedToken(let token):
            return "Unexpected token: \(token)."
        case .invalidNumber(let token):
            return "Invalid number: \(token)."
        case .invalidRepeatCount(let token):
            return "Invalid repeat count: \(token)."
        case .missingBlock:
            return "Missing block after REPEAT."
        case .missingEnd(let name):
            return "Missing END for procedure \(name)."
        case .missingIdentifier(let keyword):
            return "Missing identifier after \(keyword)."
        case .recursionLimitReached:
            return "Maximum procedure call depth exceeded."
        case .undefinedVariable(let name):
            return "Undefined variable: \(name)."
        case .invalidExpression(let token):
            return "Unable to evaluate expression starting with \(token)."
        }
    }
}

struct BoundsTracker {
    private(set) var minX: CGFloat = 0
    private(set) var maxX: CGFloat = 0
    private(set) var minY: CGFloat = 0
    private(set) var maxY: CGFloat = 0
    private var initialized = false

    mutating func register(_ point: CGPoint) {
        if !initialized {
            minX = point.x
            maxX = point.x
            minY = point.y
            maxY = point.y
            initialized = true
        } else {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
    }

    var rect: CGRect {
        if !initialized {
            return CGRect(x: -50, y: -50, width: 100, height: 100)
        }
        return CGRect(x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
    }
}

final class LogoInterpreter {
    private struct Procedure {
        let name: String
        let body: [String]
        let parameters: [String]
    }

    private struct ProcedureParseResult {
        let tokens: [String]
        let procedures: [String: Procedure]
    }

    private let defaultTurtleID = "MAIN"
    private let maxCallDepth = 32

    func run(script: String) throws -> LogoExecutionResult {
        var turtles: [String: TurtleState] = [:]
        var initialStates: [String: TurtleState] = [:]
        var turtleOrder: [String] = []
        var activeTurtleID = defaultTurtleID
        ensureTurtleExists(id: defaultTurtleID, turtles: &turtles, initialStates: &initialStates, turtleOrder: &turtleOrder)
        var segments: [TurtleSegment] = []
        let tokens = tokenize(script)
        let parsed = try parseProcedures(tokens)
        let executableTokens = parsed.tokens
        var bounds = BoundsTracker()
        for state in turtles.values {
            bounds.register(state.position)
        }
        var index = 0
        var variableStack: [[String: Double]] = [[:]]
        try execute(tokens: executableTokens,
                    index: &index,
                    turtles: &turtles,
                    initialStates: &initialStates,
                    activeTurtleID: &activeTurtleID,
                    segments: &segments,
                    bounds: &bounds,
                    procedures: parsed.procedures,
                    turtleOrder: &turtleOrder,
                    variableStack: &variableStack,
                    callDepth: 0)
        return LogoExecutionResult(
            segments: segments,
            bounds: bounds.rect,
            initialStates: initialStates,
            finalStates: turtles,
            turtleOrder: turtleOrder
        )
    }

    private func tokenize(_ script: String) -> [String] {
        script
            .replacingOccurrences(of: "[", with: " [ ")
            .replacingOccurrences(of: "]", with: " ] ")
            .split { $0.isWhitespace }
            .map { String($0) }
    }

    private func execute(tokens: [String],
                         index: inout Int,
                         turtles: inout [String: TurtleState],
                         initialStates: inout [String: TurtleState],
                         activeTurtleID: inout String,
                         segments: inout [TurtleSegment],
                         bounds: inout BoundsTracker,
                         procedures: [String: Procedure],
                         turtleOrder: inout [String],
                         variableStack: inout [[String: Double]],
                         callDepth: Int) throws {
        if callDepth > maxCallDepth {
            throw LogoInterpreterError.recursionLimitReached
        }

        while index < tokens.count {
            let token = tokens[index]
            index += 1
            let keyword = token.uppercased()

            switch keyword {
            case "FD", "FORWARD":
                let distance = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                try move(by: CGFloat(distance),
                         turtles: &turtles,
                         activeTurtleID: activeTurtleID,
                         segments: &segments,
                         bounds: &bounds)
            case "BK", "BACK":
                let distance = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                try move(by: CGFloat(-distance),
                         turtles: &turtles,
                         activeTurtleID: activeTurtleID,
                         segments: &segments,
                         bounds: &bounds)
            case "RT", "RIGHT":
                let angle = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.heading -= angle
                turtles[activeTurtleID] = state
            case "LT", "LEFT":
                let angle = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.heading += angle
                turtles[activeTurtleID] = state
            case "PU", "PENUP":
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.penDown = false
                turtles[activeTurtleID] = state
            case "PD", "PENDOWN":
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.penDown = true
                turtles[activeTurtleID] = state
            case "HOME":
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.position = .zero
                state.heading = 0
                turtles[activeTurtleID] = state
                bounds.register(state.position)
            case "CLEAR":
                segments.removeAll()
                bounds = BoundsTracker()
                for key in turtles.keys {
                    if var state = turtles[key] {
                        state.position = .zero
                        state.heading = 0
                        turtles[key] = state
                        initialStates[key] = state
                        bounds.register(state.position)
                    }
                }
            case "COLOR":
                let r = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let g = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let b = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.penColor = Color(red: clampColor(r / 255), green: clampColor(g / 255), blue: clampColor(b / 255))
                turtles[activeTurtleID] = state
            case "SETXY":
                let x = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let y = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.position = CGPoint(x: x, y: y)
                turtles[activeTurtleID] = state
                bounds.register(state.position)
            case "SETHEADING":
                let angle = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                var state = turtles[activeTurtleID] ?? TurtleState()
                state.heading = angle
                turtles[activeTurtleID] = state
            case "REPEAT":
                let countValue = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let count = Int(countValue.rounded())
                if count < 0 {
                    throw LogoInterpreterError.invalidRepeatCount("\(countValue)")
                }
                let blockTokens = try readBlock(tokens: tokens, index: &index)
                for _ in 0..<count {
                    var blockIndex = 0
                    try execute(tokens: blockTokens,
                                index: &blockIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth)
                }
            case "TURTLE":
                let identifier = try readIdentifier(tokens: tokens, index: &index, keyword: "TURTLE")
                let turtleID = identifier.uppercased()
                activeTurtleID = turtleID
                let created = ensureTurtleExists(id: turtleID,
                                                turtles: &turtles,
                                                initialStates: &initialStates,
                                                turtleOrder: &turtleOrder)
                if created, let state = turtles[turtleID] {
                    bounds.register(state.position)
                }
            case "MAKE":
                let name = try readVariableName(tokens: tokens, index: &index)
                let value = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                setVariable(name: name, value: value, variableStack: &variableStack)
            case "IF":
                let condition = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let trueBlock = try readBlock(tokens: tokens, index: &index)
                let elseBlock: [String]?
                if index < tokens.count, tokens[index] == "[" {
                    elseBlock = try readBlock(tokens: tokens, index: &index)
                } else {
                    elseBlock = nil
                }
                if condition != 0 {
                    var blockIndex = 0
                    try execute(tokens: trueBlock,
                                index: &blockIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth)
                } else if let elseBlock {
                    var elseIndex = 0
                    try execute(tokens: elseBlock,
                                index: &elseIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth)
                }
            case "IFELSE":
                let condition = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                let trueBlock = try readBlock(tokens: tokens, index: &index)
                let falseBlock = try readBlock(tokens: tokens, index: &index)
                if condition != 0 {
                    var trueIndex = 0
                    try execute(tokens: trueBlock,
                                index: &trueIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth)
                } else {
                    var falseIndex = 0
                    try execute(tokens: falseBlock,
                                index: &falseIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth)
                }
            case "]":
                throw LogoInterpreterError.unexpectedToken("]")
            case "[":
                throw LogoInterpreterError.unexpectedToken("[")
            default:
                if let procedure = procedures[keyword] {
                    var arguments: [Double] = []
                    for parameter in procedure.parameters {
                        _ = parameter // retain order
                        let value = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
                        arguments.append(value)
                    }
                    variableStack.append(Dictionary(uniqueKeysWithValues: zip(procedure.parameters, arguments)))
                    var procedureIndex = 0
                    try execute(tokens: procedure.body,
                                index: &procedureIndex,
                                turtles: &turtles,
                                initialStates: &initialStates,
                                activeTurtleID: &activeTurtleID,
                                segments: &segments,
                                bounds: &bounds,
                                procedures: procedures,
                                turtleOrder: &turtleOrder,
                                variableStack: &variableStack,
                                callDepth: callDepth + 1)
                    _ = variableStack.popLast()
                    continue
                }
                if let number = Double(token) {
                    throw LogoInterpreterError.unexpectedToken("\(number)")
                } else {
                    throw LogoInterpreterError.unexpectedToken(token)
                }
            }
        }
    }

    private func move(by distance: CGFloat,
                      turtles: inout [String: TurtleState],
                      activeTurtleID: String,
                      segments: inout [TurtleSegment],
                      bounds: inout BoundsTracker) throws {
        guard var state = turtles[activeTurtleID] else {
            return
        }
        let radians = state.heading * .pi / 180
        let dx = sin(radians) * distance
        let dy = cos(radians) * distance
        let start = state.position
        let end = CGPoint(x: start.x + dx, y: start.y + dy)
        if state.penDown {
            let segment = TurtleSegment(start: start,
                                        end: end,
                                        heading: state.heading,
                                        color: state.penColor,
                                        lineWidth: state.lineWidth,
                                        turtleID: activeTurtleID)
            segments.append(segment)
            bounds.register(start)
            bounds.register(end)
        }
        state.position = end
        turtles[activeTurtleID] = state
        bounds.register(state.position)
    }

    private func readNumber(tokens: [String], index: inout Int, variableStack: [[String: Double]]) throws -> Double {
        guard index < tokens.count else {
            throw LogoInterpreterError.unexpectedEndOfInput
        }
        let token = tokens[index]
        index += 1
        if token.hasPrefix(":") {
            let name = String(token.dropFirst()).uppercased()
            for scope in variableStack.reversed() {
                if let value = scope[name] {
                    return value
                }
            }
            throw LogoInterpreterError.undefinedVariable(name)
        }
        let keyword = token.uppercased()
        switch keyword {
        case "SUM":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return lhs + rhs
        case "DIFFERENCE":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return lhs - rhs
        case "PRODUCT":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return lhs * rhs
        case "QUOTIENT":
            let numerator = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let denominator = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return denominator == 0 ? 0 : numerator / denominator
        case "REMAINDER":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return rhs == 0 ? 0 : lhs.truncatingRemainder(dividingBy: rhs)
        case "MIN":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return min(lhs, rhs)
        case "MAX":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return max(lhs, rhs)
        case "ABS":
            let value = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return abs(value)
        case "NEG":
            let value = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return -value
        case "POWER":
            let base = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let exponent = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return pow(base, exponent)
        case "LESS":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return lhs < rhs ? 1 : 0
        case "GREATER":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return lhs > rhs ? 1 : 0
        case "EQUAL":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return abs(lhs - rhs) < 0.0001 ? 1 : 0
        case "NOTEQUAL":
            let lhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let rhs = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            return abs(lhs - rhs) >= 0.0001 ? 1 : 0
        case "RANDOM":
            let upperBound = try readNumber(tokens: tokens, index: &index, variableStack: variableStack)
            let clamped = max(upperBound, 0)
            return clamped == 0 ? 0 : Double.random(in: 0..<clamped)
        case "PI":
            return Double.pi
        case "E":
            return M_E
        default:
            break
        }
        guard let value = Double(token) else {
            throw LogoInterpreterError.invalidNumber(token)
        }
        return value
    }

    private func readBlock(tokens: [String], index: inout Int) throws -> [String] {
        guard index < tokens.count else {
            throw LogoInterpreterError.missingBlock
        }
        guard tokens[index] == "[" else {
            throw LogoInterpreterError.missingBlock
        }
        index += 1
        var depth = 1
        var block: [String] = []
        while index < tokens.count {
            let token = tokens[index]
            index += 1
            if token == "[" {
                depth += 1
            } else if token == "]" {
                depth -= 1
                if depth == 0 {
                    return block
                }
            }
            block.append(token)
        }
        throw LogoInterpreterError.missingBlock
    }

    private func parseProcedures(_ tokens: [String]) throws -> ProcedureParseResult {
        var index = 0
        var executable: [String] = []
        var procedures: [String: Procedure] = [:]

        while index < tokens.count {
            let token = tokens[index]
            if token.uppercased() == "TO" {
                index += 1
                guard index < tokens.count else {
                    throw LogoInterpreterError.unexpectedEndOfInput
                }
                let nameToken = tokens[index]
                index += 1
                let procedureName = nameToken.uppercased()
                var parameters: [String] = []
                while index < tokens.count {
                    let candidate = tokens[index]
                    if candidate.hasPrefix(":") {
                        index += 1
                        let parameterName = String(candidate.dropFirst()).uppercased()
                        parameters.append(parameterName)
                    } else {
                        break
                    }
                }
                var body: [String] = []
                var foundEnd = false
                while index < tokens.count {
                    let current = tokens[index]
                    if current.uppercased() == "END" {
                        foundEnd = true
                        index += 1
                        break
                    }
                    body.append(current)
                    index += 1
                }
                guard foundEnd else {
                    throw LogoInterpreterError.missingEnd(procedureName)
                }
                procedures[procedureName] = Procedure(name: procedureName, body: body, parameters: parameters)
            } else {
                executable.append(token)
                index += 1
            }
        }

        return ProcedureParseResult(tokens: executable, procedures: procedures)
    }

    @discardableResult
    private func ensureTurtleExists(id: String,
                                    turtles: inout [String: TurtleState],
                                    initialStates: inout [String: TurtleState],
                                    turtleOrder: inout [String]) -> Bool {
        if turtles[id] == nil {
            let state = TurtleState()
            turtles[id] = state
            if initialStates[id] == nil {
                initialStates[id] = state
            }
            if !turtleOrder.contains(id) {
                turtleOrder.append(id)
            }
            return true
        }

        if initialStates[id] == nil, let state = turtles[id] {
            initialStates[id] = state
        }

        if !turtleOrder.contains(id) {
            turtleOrder.append(id)
        }

        return false
    }

    private func readIdentifier(tokens: [String], index: inout Int, keyword: String) throws -> String {
        guard index < tokens.count else {
            throw LogoInterpreterError.missingIdentifier(keyword)
        }
        let token = tokens[index]
        index += 1
        if token == "[" || token == "]" {
            throw LogoInterpreterError.missingIdentifier(keyword)
        }
        return token
    }

    private func readVariableName(tokens: [String], index: inout Int) throws -> String {
        guard index < tokens.count else {
            throw LogoInterpreterError.unexpectedEndOfInput
        }
        let token = tokens[index]
        index += 1
        if token.hasPrefix(":") {
            return String(token.dropFirst()).uppercased()
        }
        if token.hasPrefix("\"") {
            let name = String(token.dropFirst()).uppercased()
            if name.isEmpty {
                throw LogoInterpreterError.unexpectedToken(token)
            }
            return name
        }
        return token.uppercased()
    }

    private func setVariable(name: String, value: Double, variableStack: inout [[String: Double]]) {
        for scopeIndex in stride(from: variableStack.count - 1, through: 0, by: -1) {
            if variableStack[scopeIndex][name] != nil {
                variableStack[scopeIndex][name] = value
                return
            }
        }
        if variableStack.isEmpty {
            variableStack.append([name: value])
        } else {
            variableStack[0][name] = value
        }
    }

    private func clampColor(_ value: Double) -> Double {
        return max(0, min(1, value))
    }
}

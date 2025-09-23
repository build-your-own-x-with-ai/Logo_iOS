import SwiftUI

struct TurtleSegment: Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let heading: Double
    let color: Color
    let lineWidth: CGFloat
}

struct LogoExecutionResult {
    let segments: [TurtleSegment]
    let bounds: CGRect
    let finalState: TurtleState
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
    func run(script: String) throws -> LogoExecutionResult {
        var state = TurtleState()
        var segments: [TurtleSegment] = []
        let tokens = tokenize(script)
        var index = 0
        var bounds = BoundsTracker()
        bounds.register(state.position)
        try execute(tokens: tokens, index: &index, state: &state, segments: &segments, bounds: &bounds)
        return LogoExecutionResult(segments: segments, bounds: bounds.rect, finalState: state)
    }

    private func tokenize(_ script: String) -> [String] {
        script
            .replacingOccurrences(of: "[", with: " [ ")
            .replacingOccurrences(of: "]", with: " ] ")
            .split { $0.isWhitespace }
            .map { String($0) }
    }

    private func execute(tokens: [String], index: inout Int, state: inout TurtleState, segments: inout [TurtleSegment], bounds: inout BoundsTracker) throws {
        while index < tokens.count {
            let token = tokens[index]
            index += 1
            let keyword = token.uppercased()

            switch keyword {
            case "FD", "FORWARD":
                let distance = try readNumber(tokens: tokens, index: &index)
                try move(by: CGFloat(distance), state: &state, segments: &segments, bounds: &bounds)
            case "BK", "BACK":
                let distance = try readNumber(tokens: tokens, index: &index)
                try move(by: CGFloat(-distance), state: &state, segments: &segments, bounds: &bounds)
            case "RT", "RIGHT":
                let angle = try readNumber(tokens: tokens, index: &index)
                state.heading -= angle
            case "LT", "LEFT":
                let angle = try readNumber(tokens: tokens, index: &index)
                state.heading += angle
            case "PU", "PENUP":
                state.penDown = false
            case "PD", "PENDOWN":
                state.penDown = true
            case "HOME":
                state.position = .zero
                state.heading = 0
                bounds.register(state.position)
            case "CLEAR":
                segments.removeAll()
                state.position = .zero
                state.heading = 0
                bounds = BoundsTracker()
                bounds.register(state.position)
            case "COLOR":
                let r = try readNumber(tokens: tokens, index: &index)
                let g = try readNumber(tokens: tokens, index: &index)
                let b = try readNumber(tokens: tokens, index: &index)
                state.penColor = Color(red: clampColor(r / 255), green: clampColor(g / 255), blue: clampColor(b / 255))
            case "SETXY":
                let x = try readNumber(tokens: tokens, index: &index)
                let y = try readNumber(tokens: tokens, index: &index)
                state.position = CGPoint(x: x, y: y)
                bounds.register(state.position)
            case "SETHEADING":
                let angle = try readNumber(tokens: tokens, index: &index)
                state.heading = angle
            case "REPEAT":
                let countValue = try readNumber(tokens: tokens, index: &index)
                let count = Int(countValue.rounded())
                if count < 0 {
                    throw LogoInterpreterError.invalidRepeatCount("\(countValue)")
                }
                let blockTokens = try readBlock(tokens: tokens, index: &index)
                for _ in 0..<count {
                    var blockIndex = 0
                    try execute(tokens: blockTokens, index: &blockIndex, state: &state, segments: &segments, bounds: &bounds)
                }
            case "]":
                throw LogoInterpreterError.unexpectedToken("]")
            case "[":
                throw LogoInterpreterError.unexpectedToken("[")
            default:
                if let number = Double(token) {
                    throw LogoInterpreterError.unexpectedToken("\(number)")
                } else {
                    throw LogoInterpreterError.unexpectedToken(token)
                }
            }
        }
    }

    private func move(by distance: CGFloat, state: inout TurtleState, segments: inout [TurtleSegment], bounds: inout BoundsTracker) throws {
        let radians = state.heading * .pi / 180
        let dx = sin(radians) * distance
        let dy = cos(radians) * distance
        let start = state.position
        let end = CGPoint(x: start.x + dx, y: start.y + dy)
        if state.penDown {
            let segment = TurtleSegment(start: start, end: end, heading: state.heading, color: state.penColor, lineWidth: state.lineWidth)
            segments.append(segment)
            bounds.register(start)
            bounds.register(end)
        }
        state.position = end
        bounds.register(state.position)
    }

    private func readNumber(tokens: [String], index: inout Int) throws -> Double {
        guard index < tokens.count else {
            throw LogoInterpreterError.unexpectedEndOfInput
        }
        let token = tokens[index]
        index += 1
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

    private func clampColor(_ value: Double) -> Double {
        return max(0, min(1, value))
    }
}

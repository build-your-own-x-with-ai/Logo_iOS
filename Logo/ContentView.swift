import SwiftUI

struct ContentView: View {
    @State private var script: String = ContentView.defaultScript
    @State private var result: LogoExecutionResult? = try? LogoInterpreter().run(script: ContentView.defaultScript)
    @State private var errorMessage: String?
    @State private var isInterpreting = false
    @State private var animationProgress: CGFloat = 1
    @State private var isAnimating = false
    @State private var showInfo = false
    @State private var animationToken = UUID()

    private let interpreter = LogoInterpreter()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                LogoCanvas(result: result, progress: animationProgress)
                    .frame(minHeight: 300)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                if let message = errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Logo Script")
                            .font(.headline)
                        Spacer()
                        Menu("Samples") {
                            Button("Square") { loadSample(ContentView.squareSample) }
                            Button("Polygon Star") { loadSample(ContentView.starSample) }
                            Button("Spiral") { loadSample(ContentView.spiralSample) }
                        }
                    }

                    TextEditor(text: $script)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                HStack(spacing: 12) {
                    Button("Run", action: interpret)
                        .buttonStyle(.borderedProminent)
                        .disabled(isInterpreting || isAnimating)
                    Button("Reset") {
                        script = ContentView.defaultScript
                        interpret()
                    }
                    .buttonStyle(.bordered)
                    if isAnimating {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .navigationTitle("Logo Runner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Usage Information")
                }
            }
        }
        .task { interpret() }
        .sheet(isPresented: $showInfo) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to Logo Runner")
                            .font(.title3)
                        Text("Supported Commands:")
                            .font(.headline)
                        Group {
                            Text("`FORWARD n` / `FD n` – Move turtle forward n points")
                            Text("`BACK n` / `BK n` – Move turtle back n points")
                            Text("`LEFT angle` / `LT angle` – Turn left")
                            Text("`RIGHT angle` / `RT angle` – Turn right")
                            Text("`PENUP` / `PU` – Lift pen (no drawing)")
                            Text("`PENDOWN` / `PD` – Lower pen (resume drawing)")
                            Text("`COLOR r g b` – Set pen color using 0–255 RGB")
                            Text("`SETXY x y` – Move without drawing")
                            Text("`SETHEADING angle` – Set turtle direction")
                            Text("`REPEAT count [ ... ]` – Repeat block of commands")
                            Text("`HOME` – Return to origin (0, 0)")
                            Text("`CLEAR` – Clear drawing and reset state")
                        }
                        .font(.body)
                        Text("Tap Run to animate the drawing. Animation speed adapts to the total path length; you can rerun anytime after it completes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("How to Use")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showInfo = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func loadSample(_ sample: String) {
        script = sample
        interpret()
    }

    private func interpret() {
        isInterpreting = true
        defer { isInterpreting = false }
        do {
            let execution = try interpreter.run(script: script)
            result = execution
            errorMessage = nil
            startAnimation(for: execution)
        } catch {
            result = nil
            errorMessage = error.localizedDescription
            stopAnimation()
        }
    }

    private func startAnimation(for execution: LogoExecutionResult) {
        let totalLength = pathLength(for: execution)
        guard totalLength > 0 else {
            animationProgress = 1
            isAnimating = false
            return
        }

        let token = UUID()
        animationToken = token
        let speed: CGFloat = 140
        let duration = Double(min(max(totalLength / speed, 0.6), 10))
        animationProgress = 0
        isAnimating = true

        withAnimation(.linear(duration: duration)) {
            animationProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if animationToken == token {
                isAnimating = false
            }
        }
    }

    private func stopAnimation() {
        animationProgress = 1
        isAnimating = false
    }

    private func pathLength(for execution: LogoExecutionResult) -> CGFloat {
        execution.segments.reduce(0) { partialResult, segment in
            let dx = segment.end.x - segment.start.x
            let dy = segment.end.y - segment.start.y
            return partialResult + CGFloat(hypot(dx, dy))
        }
    }
}

struct LogoCanvas: View {
    let result: LogoExecutionResult?
    let progress: CGFloat

    var body: some View {
        Canvas { context, size in
            guard let result = result else { return }
            let bounds = result.bounds
            let widthScale = size.width / bounds.width
            let heightScale = size.height / bounds.height
            let scale = min(widthScale, heightScale) * 0.85
            let center = CGPoint(x: bounds.midX, y: bounds.midY)

            func project(_ point: CGPoint) -> CGPoint {
                let shiftedX = (point.x - center.x) * scale
                let shiftedY = (point.y - center.y) * scale
                let x = size.width / 2 + shiftedX
                let y = size.height / 2 - shiftedY
                return CGPoint(x: x, y: y)
            }

            guard !result.segments.isEmpty else {
                drawTurtle(context: &context, project: project, position: result.finalState.position, heading: result.finalState.heading, scale: scale)
                return
            }

            let clampedProgress = max(0, min(1, progress))
            let lengths = result.segments.map { segment -> CGFloat in
                let dx = segment.end.x - segment.start.x
                let dy = segment.end.y - segment.start.y
                return CGFloat(hypot(dx, dy))
            }
            let totalLength = lengths.reduce(0, +)
            let targetLength = clampedProgress * totalLength
            var drawnLength: CGFloat = 0
            var turtlePosition = result.segments.first?.start ?? result.finalState.position
            var turtleHeading = result.segments.first?.heading ?? result.finalState.heading

            for (index, segment) in result.segments.enumerated() {
                let segmentLength = lengths[index]
                let projectedWidth = max(0.5, segment.lineWidth * scale)

                if targetLength >= drawnLength + segmentLength {
                    var path = Path()
                    path.move(to: project(segment.start))
                    path.addLine(to: project(segment.end))
                    context.stroke(path, with: .color(segment.color), lineWidth: projectedWidth)
                    drawnLength += segmentLength
                    turtlePosition = segment.end
                    turtleHeading = segment.heading
                } else if targetLength > drawnLength {
                    let remaining = targetLength - drawnLength
                    let ratio = max(0, min(1, segmentLength.isZero ? 0 : remaining / segmentLength))
                    let partialPoint = CGPoint(
                        x: segment.start.x + (segment.end.x - segment.start.x) * ratio,
                        y: segment.start.y + (segment.end.y - segment.start.y) * ratio
                    )
                    var path = Path()
                    path.move(to: project(segment.start))
                    path.addLine(to: project(partialPoint))
                    context.stroke(path, with: .color(segment.color), lineWidth: projectedWidth)
                    turtlePosition = partialPoint
                    turtleHeading = segment.heading
                    break
                } else {
                    break
                }
            }

            if clampedProgress >= 0.999 || totalLength.isZero {
                turtlePosition = result.finalState.position
                turtleHeading = result.finalState.heading
            }

            drawTurtle(context: &context, project: project, position: turtlePosition, heading: turtleHeading, scale: scale)
        }
    }

    private func drawTurtle(context: inout GraphicsContext, project: (CGPoint) -> CGPoint, position: CGPoint, heading: Double, scale: CGFloat) {
        let normalizedScale = max(scale, 0.001)
        let bodyLength: CGFloat = 12 / normalizedScale
        let bodyWidth: CGFloat = bodyLength * 0.6

        func offsetPoint(angleOffset: Double, distance: CGFloat) -> CGPoint {
            let radians = (heading + angleOffset) * .pi / 180
            let dx = sin(radians) * distance
            let dy = cos(radians) * distance
            return CGPoint(x: position.x + dx, y: position.y + dy)
        }

        let tip = offsetPoint(angleOffset: 0, distance: bodyLength)
        let left = offsetPoint(angleOffset: 150, distance: bodyWidth)
        let right = offsetPoint(angleOffset: -150, distance: bodyWidth)

        var path = Path()
        path.move(to: project(tip))
        path.addLine(to: project(left))
        path.addLine(to: project(right))
        path.closeSubpath()

        context.fill(path, with: .color(.orange.opacity(0.85)))
        context.stroke(path, with: .color(.orange.opacity(0.9)), lineWidth: max(0.5, 1.5 / normalizedScale))
    }
}

private extension ContentView {
    static let defaultScript = """
    REPEAT 4 [
        FORWARD 100
        RIGHT 90
    ]
    """

    static let squareSample = defaultScript

    static let starSample = """
    REPEAT 5 [
        FORWARD 150
        RIGHT 144
    ]
    """

    static let spiralSample = """
    REPEAT 60 [
        FORWARD 5
        RIGHT 15
        FORWARD 5
        RIGHT 5
    ]
    """
}

#Preview {
    ContentView()
}

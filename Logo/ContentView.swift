import SwiftUI

struct ContentView: View {
    @State private var script: String
    @State private var result: LogoExecutionResult?
    @State private var errorMessage: String?
    @State private var isInterpreting = false
    @State private var animationProgress: CGFloat = 1
    @State private var isAnimating = false
    @State private var showInfo = false
    @State private var animationToken = UUID()
    @State private var selectedSampleCategory: SampleCategory = .featured
    @State private var isCanvasCollapsed = false
    @State private var isEditorCollapsed = false
    @State private var showSaveSheet = false
    @State private var showLoadSheet = false
    @State private var savedScripts: [UserScript]
    @State private var scriptName = ""
    @State private var playbackSpeed: Double = 1
    @State private var playbackMode: PlaybackMode = .auto
    @State private var manualProgress: CGFloat = 0
    @State private var segmentBoundaries: [CGFloat] = [0, 1]
    @State private var currentStepIndex: Int = 0
    @State private var canvasScale: CGFloat = 1
    @State private var canvasOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1
    @GestureState private var dragTranslation: CGSize = .zero
    @FocusState private var isEditorFocused: Bool

    private let interpreter: LogoInterpreter
    private let store: ScriptStore

    init() {
        let store = ScriptStore.shared
        let interpreter = LogoInterpreter()
        let initialScript = store.loadLastScript() ?? ContentView.defaultScript
        _script = State(initialValue: initialScript)
        _result = State(initialValue: try? interpreter.run(script: initialScript))
        _savedScripts = State(initialValue: store.loadScripts())
        self.store = store
        self.interpreter = interpreter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if !isCanvasCollapsed {
                    let magnification = MagnificationGesture()
                        .updating($pinchScale) { value, state, _ in
                            state = value
                        }
                        .onEnded { finalValue in
                            let updated = clampScale(canvasScale * finalValue)
                            canvasScale = updated
                        }

                    let drag = DragGesture()
                        .updating($dragTranslation) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            canvasOffset.width += value.translation.width
                            canvasOffset.height += value.translation.height
                        }

                    LogoCanvas(result: result, progress: animationProgress)
                        .scaleEffect(canvasScale * pinchScale)
                        .offset(x: canvasOffset.width + dragTranslation.width,
                                y: canvasOffset.height + dragTranslation.height)
                        .frame(minHeight: 300)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .gesture(drag.simultaneously(with: magnification))
                        .onTapGesture(count: 2) {
                            resetZoom()
                        }
                        .transition(.opacity.combined(with: .scale))

                    ZoomControl(scale: $canvasScale, onReset: resetZoom)
                }

                if let message = errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !isEditorCollapsed {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Logo Script")
                                .font(.headline)
                            Spacer()
                            Menu("Samples") {
                                ForEach(SampleCategory.allCases, id: \.self) { category in
                                    Button(category.title) {
                                        selectedSampleCategory = category
                                    }
                                }
                            }
                            .menuStyle(.borderlessButton)
                            Menu("Scripts") {
                                Button("Save Current...") {
                                    scriptName = ""
                                    showSaveSheet = true
                                }
                                Button("Load Saved...") {
                                    savedScripts = store.loadScripts()
                                    showLoadSheet = true
                                }
                            }
                        }

                        SampleCarousel(category: selectedSampleCategory) { sample in
                            loadSample(sample)
                        }
                        .frame(height: 160)

                        TextEditor(text: $script)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .focused($isEditorFocused)
                    }
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
                    Spacer()
                    IconToggleButton(isOn: $isCanvasCollapsed, systemName: isCanvasCollapsed ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
                    IconToggleButton(isOn: $isEditorCollapsed, systemName: isEditorCollapsed ? "square.grid.3x3.fill" : "square.grid.3x3")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                SlidableSpeedControl(speed: $playbackSpeed)

                Picker("播放模式", selection: $playbackMode) {
                    ForEach(PlaybackMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: playbackMode) { _ in
                    handlePlaybackModeChange()
                }

                if playbackMode == .manual {
                    ManualPlaybackControls(
                        progress: $manualProgress,
                        onStepBackward: stepBackward,
                        onStepForward: stepForward,
                        label: manualStepLabel
                    )
                    .onChange(of: manualProgress) { _ in
                        updateManualProgress()
                    }
                }
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
                ToolbarItemGroup(placement: .keyboard) {
                    KeywordToolbar(script: $script)
                }
            }
        }
        .task { interpret() }
        .onChange(of: script) { newValue in
            store.saveLastScript(newValue)
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveScriptSheet(name: $scriptName, isPresented: $showSaveSheet) { name in
                let scriptToSave = UserScript(name: name, content: script)
                store.saveScript(scriptToSave)
                savedScripts = store.loadScripts()
            }
        }
        .sheet(isPresented: $showLoadSheet) {
            LoadScriptSheet(isPresented: $showLoadSheet, scripts: savedScripts) { selected in
                script = selected.content
                interpret()
            } onUpdate: { updated in
                savedScripts = updated
            }
        }
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

    private func loadSample(_ sample: LogoSample) {
        script = sample.script
        interpret()
    }

    private func interpret() {
        isInterpreting = true
        defer { isInterpreting = false }
        do {
            let execution = try interpreter.run(script: script)
            preparePlaybackMetadata(for: execution)
            if playbackMode == .manual {
                isAnimating = false
                manualProgress = segmentBoundaries.first ?? 0
                animationProgress = manualProgress
            } else {
                animationProgress = 0
            }
            result = execution
            errorMessage = nil
            if playbackMode == .auto {
                startAnimation(for: execution)
            }
            store.saveLastScript(script)
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
        let baseSpeed: CGFloat = 140
        let speedMultiplier = max(0.1, CGFloat(playbackSpeed))
        let adjustedSpeed = baseSpeed * speedMultiplier
        let rawDuration = Double(totalLength / adjustedSpeed)
        let minimumDuration = max(0.2, 0.4 / max(playbackSpeed, 0.1))
        let duration = min(max(rawDuration, minimumDuration), 25)
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

struct LogoCanvas: View, Animatable {
    let result: LogoExecutionResult?
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

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

            var turtlePositions = Dictionary(uniqueKeysWithValues: result.initialStates.map { ($0.key, $0.value.position) })
            var turtleHeadings = Dictionary(uniqueKeysWithValues: result.initialStates.map { ($0.key, $0.value.heading) })
            var turtleColors = Dictionary(uniqueKeysWithValues: result.initialStates.map { ($0.key, $0.value.penColor) })

            for (id, state) in result.finalStates where turtlePositions[id] == nil {
                turtlePositions[id] = state.position
                turtleHeadings[id] = state.heading
                turtleColors[id] = state.penColor
            }

            guard !result.segments.isEmpty else {
                drawTurtles(context: &context, project: project, scale: scale, positions: turtlePositions, headings: turtleHeadings, colors: turtleColors, order: result.turtleOrder)
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

            for (index, segment) in result.segments.enumerated() {
                let segmentLength = lengths[index]
                let projectedWidth = max(0.5, segment.lineWidth * scale)

                if targetLength >= drawnLength + segmentLength {
                    var path = Path()
                    path.move(to: project(segment.start))
                    path.addLine(to: project(segment.end))
                    context.stroke(path, with: .color(segment.color), lineWidth: projectedWidth)
                    drawnLength += segmentLength
                    turtlePositions[segment.turtleID] = segment.end
                    turtleHeadings[segment.turtleID] = segment.heading
                    turtleColors[segment.turtleID] = segment.color
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
                    turtlePositions[segment.turtleID] = partialPoint
                    turtleHeadings[segment.turtleID] = segment.heading
                    turtleColors[segment.turtleID] = segment.color
                    break
                } else {
                    break
                }
            }

            if clampedProgress >= 0.999 || totalLength.isZero {
                for (id, state) in result.finalStates {
                    turtlePositions[id] = state.position
                    turtleHeadings[id] = state.heading
                    turtleColors[id] = state.penColor
                }
            }

            drawTurtles(context: &context,
                        project: project,
                        scale: scale,
                        positions: turtlePositions,
                        headings: turtleHeadings,
                        colors: turtleColors,
                        order: result.turtleOrder)
        }
    }

    private func drawTurtles(context: inout GraphicsContext,
                             project: (CGPoint) -> CGPoint,
                             scale: CGFloat,
                             positions: [String: CGPoint],
                             headings: [String: Double],
                             colors: [String: Color],
                             order: [String]) {
        let orderedIDs = order.isEmpty ? Array(positions.keys) : order
        for id in orderedIDs {
            let position = positions[id] ?? .zero
            let heading = headings[id] ?? 0
            let tint = colors[id] ?? .orange
            drawTurtle(context: &context,
                       project: project,
                       position: position,
                       heading: heading,
                       scale: scale,
                       tint: tint)
        }
    }

    private func drawTurtle(context: inout GraphicsContext,
                            project: (CGPoint) -> CGPoint,
                            position: CGPoint,
                            heading: Double,
                            scale: CGFloat,
                            tint: Color) {
        let projected = project(position)
        let normalizedScale = max(scale, 0.001)
        let shellRadius: CGFloat = 16 / normalizedScale
        let headLength: CGFloat = shellRadius * 0.95
        let limbRadius: CGFloat = shellRadius * 0.55
        let orientation = Angle(degrees: heading).radians

        context.drawLayer { layer in
            layer.translateBy(x: projected.x, y: projected.y)
            layer.rotate(by: .radians(orientation))

            let shellRect = CGRect(x: -shellRadius, y: -shellRadius, width: shellRadius * 2, height: shellRadius * 2)
            let shellPath = Path(ellipseIn: shellRect)
            layer.fill(shellPath, with: .color(tint.opacity(0.85)))
            layer.stroke(shellPath, with: .color(tint.opacity(0.9)), lineWidth: max(0.8, 1.6 / normalizedScale))

            let patternPath = Path { path in
                path.addLines([
                    CGPoint(x: -shellRadius * 0.6, y: 0),
                    CGPoint(x: shellRadius * 0.6, y: 0)
                ])
                path.move(to: CGPoint(x: 0, y: -shellRadius * 0.6))
                path.addLine(to: CGPoint(x: 0, y: shellRadius * 0.6))
            }
            layer.stroke(patternPath, with: .color(tint.opacity(0.6)), lineWidth: max(0.6, 1.2 / normalizedScale))

            let headRect = CGRect(x: -headLength * 0.45, y: -shellRadius - headLength * 0.9, width: headLength * 0.9, height: headLength)
            let headPath = Path(ellipseIn: headRect)
            layer.fill(headPath, with: .color(tint))

            let tailRect = CGRect(x: -headLength * 0.25, y: shellRadius - headLength * 0.2, width: headLength * 0.5, height: headLength * 0.65)
            let tailPath = Path(ellipseIn: tailRect)
            layer.fill(tailPath, with: .color(tint.opacity(0.75)))

            let limbOffsets = [
                CGPoint(x: -shellRadius * 0.9, y: -shellRadius * 0.5),
                CGPoint(x: shellRadius * 0.9, y: -shellRadius * 0.5),
                CGPoint(x: -shellRadius * 0.9, y: shellRadius * 0.5),
                CGPoint(x: shellRadius * 0.9, y: shellRadius * 0.5)
            ]
            for offset in limbOffsets {
                let limbRect = CGRect(x: offset.x - limbRadius * 0.5,
                                      y: offset.y - limbRadius * 0.5,
                                      width: limbRadius,
                                      height: limbRadius)
                let limbPath = Path(ellipseIn: limbRect)
                layer.fill(limbPath, with: .color(tint.opacity(0.9)))
            }
        }
    }
}

private extension ContentView {
    static let defaultScript = """
    CLEAR
    COLOR 30 144 255
    REPEAT 4 [
        FORWARD 120
        RIGHT 90
    ]
    """
}

private extension ContentView {
    func preparePlaybackMetadata(for execution: LogoExecutionResult) {
        let lengths = execution.segments.map { segment -> CGFloat in
            let dx = segment.end.x - segment.start.x
            let dy = segment.end.y - segment.start.y
            return CGFloat(hypot(dx, dy))
        }
        let total = lengths.reduce(0, +)
        if total.isZero {
            segmentBoundaries = [0, 1]
        } else {
            var cumulative: [CGFloat] = [0]
            var running: CGFloat = 0
            for length in lengths {
                running += length
                cumulative.append(min(1, max(0, running / total)))
            }
            if let last = cumulative.last, abs(last - 1) > 0.0001 {
                cumulative[cumulative.count - 1] = 1
            }
            segmentBoundaries = cumulative
        }
        currentStepIndex = 0
        manualProgress = segmentBoundaries.first ?? 0
    }

    func stepForward() {
        guard currentStepIndex + 1 < segmentBoundaries.count else { return }
        currentStepIndex += 1
        manualProgress = segmentBoundaries[currentStepIndex]
        animationProgress = manualProgress
    }

    func stepBackward() {
        guard currentStepIndex > 0 else {
            manualProgress = segmentBoundaries.first ?? 0
            animationProgress = manualProgress
            return
        }
        currentStepIndex -= 1
        manualProgress = segmentBoundaries[currentStepIndex]
        animationProgress = manualProgress
    }

    func updateManualProgress() {
        guard playbackMode == .manual else { return }
        animationProgress = manualProgress
        if let closestIndex = segmentBoundaries.enumerated().min(by: { abs($0.element - manualProgress) < abs($1.element - manualProgress) })?.offset {
            currentStepIndex = closestIndex
        }
    }

    func handlePlaybackModeChange() {
        switch playbackMode {
        case .auto:
            interpret()
        case .manual:
            isAnimating = false
            manualProgress = segmentBoundaries[min(currentStepIndex, segmentBoundaries.count - 1)]
            animationProgress = manualProgress
        }
    }

    func resetZoom() {
        canvasScale = 1
        canvasOffset = .zero
    }

    func clampScale(_ value: CGFloat) -> CGFloat {
        max(0.3, min(4, value))
    }

    var manualStepLabel: String {
        guard segmentBoundaries.count > 1 else { return "0 / 0" }
        return "\(currentStepIndex) / \(segmentBoundaries.count - 1)"
    }
}

private enum PlaybackMode: String, CaseIterable, Identifiable {
    case auto
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "自动"
        case .manual: return "逐步"
        }
    }
}

#Preview {
    ContentView()
}

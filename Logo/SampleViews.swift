import SwiftUI

struct SampleCarousel: View {
    let category: SampleCategory
    let onSelect: (LogoSample) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(category.samples) { sample in
                    SampleCard(sample: sample) {
                        onSelect(sample)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct SampleCard: View {
    let sample: LogoSample
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(sample.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(sample.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(sample.accent.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(sample.accent.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("加载示例：\(sample.title)")
    }
}

struct IconToggleButton: View {
    @Binding var isOn: Bool
    let systemName: String

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isOn.toggle()
            }
        } label: {
            Image(systemName: systemName)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "展开" : "收起")
    }
}

struct SlidableSpeedControl: View {
    @Binding var speed: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("运行速度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2fx", speed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Image(systemName: "tortoise")
                    .foregroundStyle(.secondary)
                Slider(value: $speed, in: 0.25...3, step: 0.05)
                Image(systemName: "hare")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }
}

struct SaveScriptSheet: View {
    @Binding var name: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("为脚本命名", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("保存脚本")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ManualPlaybackControls: View {
    @Binding var progress: CGFloat
    let onStepBackward: () -> Void
    let onStepForward: () -> Void
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("当前步骤")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button {
                    onStepBackward()
                } label: {
                    Image(systemName: "backward.frame")
                }
                .buttonStyle(.bordered)

                Slider(value: Binding(
                    get: { Double(progress) },
                    set: { progress = CGFloat($0) }
                ), in: 0...1)

                Button {
                    onStepForward()
                } label: {
                    Image(systemName: "forward.frame")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 4)
    }
}

struct ZoomControl: View {
    @Binding var scale: CGFloat
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "minus.magnifyingglass")
                .foregroundStyle(.secondary)
            Slider(value: Binding(
                get: { Double(scale) },
                set: { newValue in
                    let value = CGFloat(newValue)
                    scale = max(0.3, min(4, value))
                }
            ), in: 0.3...4, step: 0.05)
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.secondary)
            Button("重置") {
                onReset()
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 4)
    }
}

struct LoadScriptSheet: View {
    @Binding var isPresented: Bool
    let onSelect: (UserScript) -> Void
    let onUpdate: ([UserScript]) -> Void
    @State private var workingScripts: [UserScript]

    init(isPresented: Binding<Bool>, scripts: [UserScript], onSelect: @escaping (UserScript) -> Void, onUpdate: @escaping ([UserScript]) -> Void) {
        _isPresented = isPresented
        _workingScripts = State(initialValue: scripts)
        self.onSelect = onSelect
        self.onUpdate = onUpdate
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(workingScripts) { script in
                    Button {
                        onSelect(script)
                        isPresented = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(script.name)
                                .font(.headline)
                            Text(script.updatedAt.formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indices in
                    var updated = workingScripts
                    for index in indices {
                        ScriptStore.shared.deleteScript(updated[index])
                    }
                    updated.remove(atOffsets: indices)
                    workingScripts = updated
                }
            }
            .navigationTitle("加载脚本")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { isPresented = false }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("刷新") {
                        workingScripts = ScriptStore.shared.loadScripts()
                    }
                }
            }
            .onChange(of: workingScripts) { newValue in
                onUpdate(newValue)
            }
        }
    }
}

struct KeywordToolbar: View {
    @Binding var script: String

    private let tokens: [String] = [
        "FORWARD", "BACK", "LEFT", "RIGHT",
        "PENUP", "PENDOWN", "COLOR", "SETXY",
        "SETHEADING", "REPEAT", "[", "]",
        "MAKE", "TURTLE", "TO", "END",
        "IF", "IFELSE", "SUM", "DIFFERENCE",
        "PRODUCT", "QUOTIENT", "LESS", "GREATER",
        "EQUAL", "NOTEQUAL", "ABS", "RANDOM"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tokens, id: \.self) { token in
                    Button(token) {
                        insert(token: token)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func insert(token: String) {
        let needsSpace = !script.isEmpty && !(script.last?.isWhitespace ?? true)
        if needsSpace {
            script.append(" ")
        }
        script.append(token)
        if token == "[" || token == "]" || token == "TO" || token == "END" {
            script.append("\n")
        } else {
            script.append(" ")
        }
    }
}

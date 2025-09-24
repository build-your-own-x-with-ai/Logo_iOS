import Foundation

struct UserScript: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var content: String
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, content: String, updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.content = content
        self.updatedAt = updatedAt
    }
}

final class ScriptStore {
    static let shared = ScriptStore()

    private let scriptsKey = "logo.savedScripts.v1"
    private let lastScriptKey = "logo.lastScript.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func loadScripts() -> [UserScript] {
        guard let data = UserDefaults.standard.data(forKey: scriptsKey),
              let scripts = try? decoder.decode([UserScript].self, from: data) else {
            return []
        }
        return scripts.sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveScript(_ script: UserScript) {
        var scripts = loadScripts()
        var entry = script
        entry.updatedAt = Date()
        if let index = scripts.firstIndex(where: { $0.id == entry.id }) {
            scripts[index] = entry
        } else if let index = scripts.firstIndex(where: { $0.name.caseInsensitiveCompare(entry.name) == .orderedSame }) {
            entry.id = scripts[index].id
            scripts[index] = entry
        } else {
            scripts.append(entry)
        }
        persist(scripts)
        saveLastScript(entry.content)
    }

    func deleteScript(_ script: UserScript) {
        var scripts = loadScripts()
        scripts.removeAll { $0.id == script.id }
        persist(scripts)
    }

    func loadLastScript() -> String? {
        UserDefaults.standard.string(forKey: lastScriptKey)
    }

    func saveLastScript(_ script: String) {
        UserDefaults.standard.set(script, forKey: lastScriptKey)
    }

    private func persist(_ scripts: [UserScript]) {
        if let data = try? encoder.encode(scripts) {
            UserDefaults.standard.set(data, forKey: scriptsKey)
        }
    }
}

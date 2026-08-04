import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Property values

/// A single telemetry property. Deliberately only flat scalars: the ingestion
/// endpoint drops nested values, so the type system refuses to build them.
public enum TelemetryProp: Equatable, Sendable,
                           ExpressibleByStringLiteral,
                           ExpressibleByIntegerLiteral,
                           ExpressibleByFloatLiteral,
                           ExpressibleByBooleanLiteral {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }

    var json: Any {
        switch self {
        case .string(let s): return String(s.prefix(Telemetry.maxPropChars))
        case .int(let i): return i
        case .double(let d):
            // NaN and infinity make JSONSerialization throw, which would kill
            // the whole batch rather than this one property.
            let safe: Double = d.isFinite ? d : 0
            return safe
        case .bool(let b): return b
        }
    }
}

// MARK: - App codes

/// Permanent per-title codes. These are identifiers, **not** product names:
/// Ghost Deck was renamed Curse Deck and the code deliberately did not follow,
/// because changing it would split every retention query at the rename date.
/// Adding a title here means adding it to the server's allowlist too.
public enum TelemetryApp {
    public static let ghostWanderer = "gw"
    public static let curseDeck = "gd"
}

// MARK: - Public surface

/// Anonymous, opt-out gameplay telemetry shared by every RaoBot game.
///
/// What it sends: a per-install UUID, an event name from a short list, and a
/// handful of flat numbers. What it never sends: names, e-mail, device or
/// advertising identifiers, IDFA, contacts, or location. The multiplayer
/// display name is explicitly filtered out here rather than trusted not to
/// arrive — the ingestion endpoint stores whatever it is given, so the client
/// is the guard.
///
/// **The ingest key is not baked into this file.** RaoBotKit is a public
/// repository; each app passes its key in at `start(app:key:)` from its own
/// private source. The key is spam control, not a secret — it ships inside
/// every binary regardless — but it does not belong in public git history.
///
/// ## Moving the server later without shipping new app versions
///
/// The host is reached by name, never by IP, and the path is fixed at
/// `/api/game/events`. Two escape hatches, in order of preference:
///
/// 1. **Re-point DNS.** `stats.raobot.ai` can move to any machine. Installed
///    apps follow on their next flush with no code change at all.
/// 2. **Serve a redirect.** Redirects are followed automatically, so the old
///    host can hand off to an entirely different domain. It must be a **307 or
///    308** — a 301/302 would downgrade the POST to a GET and silently discard
///    every event.
///
/// Because of this, never hardcode a different host at a call site: change DNS
/// instead, and old versions keep reporting.
public enum Telemetry {

    // Limits mirror the server's (app/schema.py) so we trim before sending
    // rather than having rows silently truncated on arrival.
    static let maxPropChars = 120
    static let maxProps = 12
    static let maxEventsPerBatch = 50
    static let maxQueued = 500
    /// Flush once this many are waiting, rather than on every single event.
    static let flushThreshold = 12
    /// A gap this long in the background counts as a new session.
    static let sessionGap: TimeInterval = 5 * 60

    /// Keys that must never leave the device, whatever a call site passes.
    /// Matched case-insensitively against a substring of the key.
    static let bannedKeyFragments = ["name", "email", "mail", "phone", "address",
                                     "user", "idfa", "udid", "token", "code"]

    static let core = TelemetryCore()

    /// Begin reporting. Safe to call more than once; later calls are ignored.
    ///
    /// - Parameters:
    ///   - app: the permanent app code (`"gd"`, `"gw"`) — **not** a product
    ///     name. Curse Deck stays `"gd"` after the rename, or every query
    ///     splits in two at the rename date.
    ///   - key: the ingest key, supplied by the app from a private source.
    ///   - host: override only for local testing.
    public static func start(app: String, key: String, host: String = "stats.raobot.ai") {
        Task { await core.start(app: app, key: key, host: host) }
    }

    /// Record an event. Fire-and-forget: returns immediately, never throws,
    /// never blocks the caller, and does nothing at all when opted out.
    public static func log(_ event: String, _ props: [String: TelemetryProp] = [:]) {
        Task { await core.log(event, props) }
    }

    /// Player-facing opt-out. Defaults to on.
    public static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.enabled) as? Bool ?? true
    }

    /// Turning it off sends one final `analytics_off` event so the opt-out is
    /// itself recorded, then discards anything still queued.
    public static func setEnabled(_ on: Bool) {
        let was = isEnabled
        guard was != on else { return }
        UserDefaults.standard.set(on, forKey: Keys.enabled)
        Task { await core.setEnabled(on) }
    }

    /// The anonymous per-install identifier, created on first use.
    ///
    /// Surfaced so the player can quote it in a deletion request — it is the
    /// only handle that exists for their rows, since nothing else about them
    /// is stored.
    public static var anonymousID: String {
        if let existing = UserDefaults.standard.string(forKey: Keys.playerID),
           existing.count == 36 {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: Keys.playerID)
        return fresh
    }

    /// A short form of `anonymousID` for showing in a settings screen.
    public static var anonymousIDShort: String {
        String(anonymousID.prefix(8)).lowercased()
    }

    /// Send anything queued now. Called automatically on backgrounding.
    public static func flush() {
        Task { await core.flush() }
    }

    enum Keys {
        static let enabled = "rb.telemetry.enabled"
        static let playerID = "rb.telemetry.playerID"
        static let lastActive = "rb.telemetry.lastActive"
    }

    // MARK: Internal helpers (exercised directly by the tests)

    /// Trim props to what the server will accept, and drop anything that looks
    /// like it identifies a person.
    static func sanitise(_ props: [String: TelemetryProp]) -> [String: Any] {
        var out: [String: Any] = [:]
        for key in props.keys.sorted() {
            guard out.count < maxProps else { break }
            guard key.count <= 32 else { continue }
            let lowered = key.lowercased()
            guard !bannedKeyFragments.contains(where: { lowered.contains($0) }) else { continue }
            out[key] = props[key]!.json
        }
        return out
    }
}

// MARK: - The worker

/// Serialises all state behind an actor so `log` can be called from anywhere,
/// including mid-animation on the main thread, without locking.
actor TelemetryCore {
    private var app = ""
    private var key = ""
    private var endpoint: URL?
    private var started = false
    private var queue: [Event] = []
    private var sending = false
    /// Consecutive network failures — used to back off rather than hammer.
    private var failures = 0
    /// Tests point this at a scratch directory so they never share a queue
    /// file with each other or with a real install.
    private let storeDirectory: URL?

    init(storeDirectory: URL? = nil) {
        self.storeDirectory = storeDirectory
    }

    /// Test-only view of what is still waiting to be sent.
    var pending: [Event] { queue }

    struct Event: Codable, Equatable {
        var e: String
        var p: String
        var t: Int          // milliseconds since epoch
        var d: [String: CodableValue]
    }

    /// Minimal Codable box so the on-disk queue survives a relaunch.
    enum CodableValue: Codable, Equatable {
        case string(String), int(Int), double(Double), bool(Bool)

        init?(_ any: Any) {
            switch any {
            case let b as Bool: self = .bool(b)
            case let i as Int: self = .int(i)
            case let d as Double: self = .double(d)
            case let s as String: self = .string(s)
            default: return nil
            }
        }

        var json: Any {
            switch self {
            case .string(let s): return s
            case .int(let i): return i
            case .double(let d): return d
            case .bool(let b): return b
            }
        }
    }

    func start(app: String, key: String, host: String) async {
        guard !started else { return }
        started = true
        self.app = app
        self.key = key
        self.endpoint = URL(string: "https://\(host)/api/game/events")
        loadQueue()
        observeLifecycle()

        guard Telemetry.isEnabled else { return }
        // A launch, or a return after a long absence, counts as a session.
        let last = UserDefaults.standard.double(forKey: Telemetry.Keys.lastActive)
        let now = Date().timeIntervalSince1970
        if last == 0 || now - last > Telemetry.sessionGap {
            enqueue("session_start", [:])
        }
        UserDefaults.standard.set(now, forKey: Telemetry.Keys.lastActive)
        // Also delivers whatever the previous run left behind.
        await flush()
    }

    func log(_ event: String, _ props: [String: TelemetryProp]) {
        guard started, Telemetry.isEnabled else { return }
        enqueue(event, props)
        if queue.count >= Telemetry.flushThreshold { Task { await flush() } }
    }

    func setEnabled(_ on: Bool) async {
        if on {
            // Re-opting-in starts a fresh session rather than back-dating one.
            UserDefaults.standard.set(Date().timeIntervalSince1970,
                                      forKey: Telemetry.Keys.lastActive)
            enqueue("session_start", [:])
            await flush()
        } else {
            // Say goodbye, then forget everything else that was waiting.
            queue.removeAll()
            enqueue("analytics_off", [:])
            let farewell = queue
            queue.removeAll()
            saveQueue()
            await send(farewell, isFarewell: true)
        }
    }

    private func enqueue(_ event: String, _ props: [String: TelemetryProp]) {
        let cleaned = Telemetry.sanitise(props)
        var boxed: [String: CodableValue] = [:]
        for (k, v) in cleaned { boxed[k] = CodableValue(v) }
        queue.append(Event(e: event,
                           p: Telemetry.anonymousID,
                           t: Int(Date().timeIntervalSince1970 * 1000),
                           d: boxed))
        // Drop the oldest rather than growing without bound: a player who is
        // offline for a week should not accumulate a megabyte of JSON.
        if queue.count > Telemetry.maxQueued {
            queue.removeFirst(queue.count - Telemetry.maxQueued)
        }
        saveQueue()
    }

    func flush() async {
        guard started, Telemetry.isEnabled, !sending, !queue.isEmpty else { return }
        let batch = Array(queue.prefix(Telemetry.maxEventsPerBatch))
        await send(batch, isFarewell: false)
    }

    private func send(_ batch: [Event], isFarewell: Bool) async {
        guard let endpoint, !batch.isEmpty, !key.isEmpty else { return }
        sending = true
        defer { sending = false }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        // Telemetry must never compete with gameplay traffic for the radio.
        request.networkServiceType = .background

        let body: [String: Any] = [
            "k": key,
            "v": 2,
            "app": app,
            "events": batch.map { ["e": $0.e, "p": $0.p, "t": $0.t,
                                   "d": $0.d.mapValues(\.json)] },
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = data

        do {
            let (_, response) = try await Telemetry.session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if (200..<300).contains(status) {
                failures = 0
                if !isFarewell { drop(batch) }
            } else if status == 403 || status == 413 || status == 422 {
                // Permanently unacceptable — retrying can only ever fail again.
                failures = 0
                if !isFarewell { drop(batch) }
            } else {
                failures += 1     // 5xx or 503: keep them, try later
            }
        } catch {
            failures += 1         // offline: keep them, try later
        }
    }

    private func drop(_ batch: [Event]) {
        let sent = Set(batch.map(\.stableKey))
        queue.removeAll { sent.contains($0.stableKey) }
        saveQueue()
    }

    // MARK: Disk

    /// Events outlive the process, so a run that ends just before the player
    /// force-quits is still reported on next launch.
    private var fileURL: URL? {
        guard let dir = storeDirectory
                ?? (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
        else { return nil }
        let folder = dir.appendingPathComponent("RaoBotTelemetry", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("queue.json")
    }

    private func loadQueue() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([Event].self, from: data) else { return }
        queue = Array(saved.suffix(Telemetry.maxQueued))
    }

    private func saveQueue() {
        guard let fileURL else { return }
        guard !queue.isEmpty else { try? FileManager.default.removeItem(at: fileURL); return }
        guard let data = try? JSONEncoder().encode(queue) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: Lifecycle

    private func observeLifecycle() {
        #if canImport(UIKit)
        let centre = NotificationCenter.default
        for name in [UIApplication.didEnterBackgroundNotification,
                     UIApplication.willResignActiveNotification] {
            centre.addObserver(forName: name, object: nil, queue: nil) { _ in
                Task { await Telemetry.flushFromNotification() }
            }
        }
        centre.addObserver(forName: UIApplication.didBecomeActiveNotification,
                           object: nil, queue: nil) { _ in
            Task { await Telemetry.noteForegroundFromNotification() }
        }
        #endif
    }

    func noteForeground() {
        guard started, Telemetry.isEnabled else { return }
        let last = UserDefaults.standard.double(forKey: Telemetry.Keys.lastActive)
        let now = Date().timeIntervalSince1970
        if now - last > Telemetry.sessionGap { enqueue("session_start", [:]) }
        UserDefaults.standard.set(now, forKey: Telemetry.Keys.lastActive)
        Task { await flush() }
    }
}

extension TelemetryCore.Event {
    /// Identifies an event well enough to remove it once acknowledged. Two
    /// genuinely identical events in the same millisecond are indistinguishable,
    /// and dropping both is the right answer anyway.
    var stableKey: String { "\(t)|\(e)|\(d.count)" }
}

extension Telemetry {
    /// Overridable so tests can intercept without a live server.
    nonisolated(unsafe) static var session: URLSession = .shared

    static func flushFromNotification() async { await core.flush() }
    static func noteForegroundFromNotification() async { await core.noteForeground() }
}

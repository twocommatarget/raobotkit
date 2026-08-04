import Foundation
import Testing
@testable import RaoBotKit

/// These share one `URLSession` seam and one `UserDefaults`, so they run one
/// at a time.
@Suite(.serialized)
struct TelemetryTests {

    // MARK: - Sanitising (the client is the guard, not the server)

    @Test func keepsFlatScalars() {
        let out = Telemetry.sanitise(["turns": 12, "dur_s": 8.5, "won": true, "mode": "ai"])
        #expect(out["turns"] as? Int == 12)
        #expect(out["dur_s"] as? Double == 8.5)
        #expect(out["won"] as? Bool == true)
        #expect(out["mode"] as? String == "ai")
    }

    /// The ingestion endpoint stores whatever it is handed — its own test suite
    /// says so explicitly. This is where a display name is actually stopped.
    @Test(arguments: ["name", "playerName", "display_name", "email", "e_mail",
                      "phone", "address", "username", "idfa", "udid",
                      "authToken", "table_code"])
    func dropsAnythingIdentifying(_ key: String) {
        let out = Telemetry.sanitise([key: "Alice", "turns": 3])
        #expect(out[key] == nil, "\(key) must never leave the device")
        #expect(out["turns"] as? Int == 3, "the rest of the event survives")
    }

    @Test func truncatesLongStringsRatherThanDroppingThem() {
        let out = Telemetry.sanitise(["cause": .string(String(repeating: "x", count: 500))])
        #expect((out["cause"] as? String)?.count == Telemetry.maxPropChars)
    }

    @Test func capsThePropertyCount() {
        var props: [String: TelemetryProp] = [:]
        for i in 0..<50 { props["k\(i)"] = .int(i) }
        #expect(Telemetry.sanitise(props).count == Telemetry.maxProps)
    }

    @Test func dropsAbsurdlyLongKeys() {
        let out = Telemetry.sanitise([String(repeating: "k", count: 40): 1, "ok": 2])
        #expect(out.count == 1)
        #expect(out["ok"] as? Int == 2)
    }

    @Test func nonFiniteDoublesBecomeZeroRatherThanBreakingJSON() {
        // JSONSerialization throws on NaN/infinity, which would silently kill
        // the whole batch rather than one property.
        let out = Telemetry.sanitise(["a": .double(.nan), "b": .double(.infinity)])
        #expect(out["a"] as? Double == 0)
        #expect(out["b"] as? Double == 0)
        #expect(JSONSerialization.isValidJSONObject(out))
    }

    // MARK: - Identity

    @Test func anonymousIDIsAStableUUID() {
        UserDefaults.standard.removeObject(forKey: Telemetry.Keys.playerID)
        let first = Telemetry.anonymousID
        #expect(UUID(uuidString: first) != nil)
        #expect(Telemetry.anonymousID == first, "must not churn between calls")
        #expect(Telemetry.anonymousIDShort.count == 8)
    }

    @Test func defaultsToOn() {
        UserDefaults.standard.removeObject(forKey: Telemetry.Keys.enabled)
        #expect(Telemetry.isEnabled, "opt-out, not opt-in — agreed with the owner")
    }

    // MARK: - Wire format

    @Test func postsTheShapeTheServerExpects() async throws {
        let harness = try Harness(status: 200)
        defer { harness.tearDown() }

        await harness.core.start(app: "gd", key: "test-key", host: "stats.example.com")
        await harness.core.log("match_end", ["mode": "ai", "turns": 14])
        await harness.core.flush()

        let body = try #require(harness.lastBody())
        #expect(body["k"] as? String == "test-key")
        #expect(body["v"] as? Int == 2)
        #expect(body["app"] as? String == "gd")

        let events = harness.allEvents()
        #expect(events.first?["e"] as? String == "session_start",
                "a launch opens a session before anything else")
        let match = try #require(events.first { $0["e"] as? String == "match_end" })
        #expect(UUID(uuidString: match["p"] as? String ?? "") != nil)
        #expect((match["t"] as? Int ?? 0) > 1_700_000_000_000, "milliseconds, not seconds")
        let props = try #require(match["d"] as? [String: Any])
        #expect(props["turns"] as? Int == 14)

        let url = try #require(harness.lastURL())
        #expect(url.absoluteString == "https://stats.example.com/api/game/events")
    }

    @Test func acceptedEventsLeaveTheQueue() async throws {
        let harness = try Harness(status: 200)
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "k", host: "h")
        await harness.core.log("run_end", ["score": 5])
        await harness.core.flush()
        #expect(await harness.core.pending.isEmpty)
    }

    @Test func aServerErrorKeepsEventsForTheNextAttempt() async throws {
        let harness = try Harness(status: 503)
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "k", host: "h")
        await harness.core.log("run_end", ["score": 5])
        await harness.core.flush()
        let pending = await harness.core.pending
        #expect(pending.contains { $0.e == "run_end" }, "a 503 must not lose data")
    }

    @Test func offlineKeepsEventsForTheNextAttempt() async throws {
        let harness = try Harness(status: nil)   // throws a URLError
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "k", host: "h")
        await harness.core.log("run_end", ["score": 5])
        await harness.core.flush()
        #expect(await !harness.core.pending.isEmpty)
    }

    /// A rejected key or an unknown app can never succeed on a retry, so
    /// holding the events forever would just wedge the queue.
    @Test(arguments: [403, 422, 413])
    func permanentRejectionsAreDiscarded(_ status: Int) async throws {
        let harness = try Harness(status: status)
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "bad", host: "h")
        await harness.core.log("run_end", ["score": 5])
        await harness.core.flush()
        #expect(await harness.core.pending.isEmpty)
    }

    // MARK: - Opting out

    @Test func optingOutSendsAFarewellAndDiscardsTheRest() async throws {
        let harness = try Harness(status: 200)
        defer { harness.tearDown() }
        await harness.core.start(app: "gd", key: "k", host: "h")
        await harness.core.log("table_created", [:])
        await harness.core.setEnabled(false)

        let body = try #require(harness.lastBody())
        let events = try #require(body["events"] as? [[String: Any]])
        #expect(events.count == 1)
        #expect(events.first?["e"] as? String == "analytics_off")
        #expect(await harness.core.pending.isEmpty, "nothing lingers after opting out")
    }

    @Test func nothingIsRecordedWhileOptedOut() async throws {
        let harness = try Harness(status: 200)
        defer { harness.tearDown() }
        UserDefaults.standard.set(false, forKey: Telemetry.Keys.enabled)
        await harness.core.start(app: "gd", key: "k", host: "h")
        await harness.core.log("match_end", ["turns": 3])
        #expect(await harness.core.pending.isEmpty)
        UserDefaults.standard.set(true, forKey: Telemetry.Keys.enabled)
    }

    // MARK: - Survival

    /// A run that ends seconds before the player force-quits still counts.
    @Test func theQueueSurvivesRelaunch() async throws {
        let harness = try Harness(status: 503)
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "k", host: "h")
        await harness.core.log("run_end", ["score": 9])
        await harness.core.flush()

        let reborn = TelemetryCore(storeDirectory: harness.directory)
        await reborn.start(app: "gw", key: "k", host: "h")
        #expect(await reborn.pending.contains { $0.e == "run_end" })
    }

    @Test func theQueueCannotGrowWithoutBound() async throws {
        let harness = try Harness(status: nil)
        defer { harness.tearDown() }
        await harness.core.start(app: "gw", key: "k", host: "h")
        for i in 0..<(Telemetry.maxQueued + 120) {
            await harness.core.log("reset", ["n": .int(i)])
        }
        #expect(await harness.core.pending.count <= Telemetry.maxQueued)
    }

    // MARK: - Contract with the server

    @Test func appCodesAreStableAcrossRenames() {
        // Mirrors the server's own test: Ghost Deck became Curse Deck, but the
        // code must stay "gd" or every query splits at the rename date.
        #expect(TelemetryApp.curseDeck == "gd")
        #expect(TelemetryApp.ghostWanderer == "gw")
    }
}

// MARK: - Harness

/// Wires a `TelemetryCore` to a scratch directory and a stubbed transport.
private struct Harness {
    let core: TelemetryCore
    let directory: URL
    private let previousSession: URLSession

    init(status: Int?) throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("telemetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        core = TelemetryCore(storeDirectory: directory)

        UserDefaults.standard.set(true, forKey: Telemetry.Keys.enabled)
        UserDefaults.standard.removeObject(forKey: Telemetry.Keys.lastActive)

        StubProtocol.reset(status: status)
        previousSession = Telemetry.session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        Telemetry.session = URLSession(configuration: config)
    }

    func lastBody() -> [String: Any]? {
        guard let data = StubProtocol.bodies.last else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// Every event across every batch — assertions then don't depend on how
    /// the flushes happened to divide up.
    func allEvents() -> [[String: Any]] {
        StubProtocol.bodies.compactMap {
            try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
        }.flatMap { ($0["events"] as? [[String: Any]]) ?? [] }
    }

    func batchCount() -> Int { StubProtocol.bodies.count }

    func lastURL() -> URL? { StubProtocol.lastURL }

    func tearDown() {
        Telemetry.session = previousSession
        try? FileManager.default.removeItem(at: directory)
        UserDefaults.standard.removeObject(forKey: Telemetry.Keys.lastActive)
    }
}

private final class StubProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status: Int?
    nonisolated(unsafe) static var bodies: [Data] = []
    nonisolated(unsafe) static var lastURL: URL?

    static func reset(status: Int?) {
        self.status = status
        bodies = []
        lastURL = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubProtocol.lastURL = request.url
        // URLSession moves the body to a stream, so `httpBody` is nil here.
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            stream.close()
            StubProtocol.bodies.append(data)
        } else if let body = request.httpBody {
            StubProtocol.bodies.append(body)
        }

        guard let status = StubProtocol.status else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                       httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{\"ok\":true}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

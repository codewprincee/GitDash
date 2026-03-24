import Foundation

@Observable
final class PollingManager {
    private var timers: [String: DispatchSourceTimer] = [:]

    func startPolling(id: String, interval: TimeInterval, action: @escaping () async -> Void) {
        stopPolling(id: id)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler {
            Task { await action() }
        }
        timer.resume()
        timers[id] = timer
    }

    func stopPolling(id: String) {
        timers[id]?.cancel()
        timers.removeValue(forKey: id)
    }

    func stopAll() {
        for (_, timer) in timers { timer.cancel() }
        timers.removeAll()
    }

    deinit {
        stopAll()
    }
}

import Foundation

@MainActor
protocol AutoCollapseTiming: AnyObject {
    func start(interval: TimeInterval, action: @escaping () -> Void)
    func stop()
}

@MainActor
final class AutoCollapseTimer: AutoCollapseTiming {
    private var timer: Timer?

    func start(interval: TimeInterval, action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            action()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}

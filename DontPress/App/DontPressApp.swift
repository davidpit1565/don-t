import SwiftUI

@main
struct DontPressApp: App {
    /// Created once per process: a cold launch always starts a fresh current run, while
    /// backgrounding or presenting the share sheet keeps this same instance alive.
    @State private var model: HomeViewModel

    init() {
        let configuration = LaunchConfiguration()
        let service = PressService(store: configuration.makeStore())
        _model = State(initialValue: HomeViewModel(service: service, haptics: UIKitHaptics()))
    }

    var body: some Scene {
        WindowGroup {
            HomeView(model: model)
        }
    }
}

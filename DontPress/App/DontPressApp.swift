import SwiftUI

@main
struct DontPressApp: App {
    /// Created once per process: a cold launch always starts a fresh current run, while
    /// backgrounding or presenting the share sheet keeps this same instance alive.
    @State private var model: HomeViewModel
    @State private var proStore: ProStore

    init() {
        let configuration = LaunchConfiguration()
        let service = PressService(store: configuration.makeStore())
        let model = HomeViewModel(service: service, haptics: UIKitHaptics())
        let proStore = ProStore(cachedIsPro: service.savedIsPro)
        proStore.onChange = { [weak model] isPro in model?.setPro(isPro) }
        _model = State(initialValue: model)
        _proStore = State(initialValue: proStore)
    }

    var body: some Scene {
        WindowGroup {
            HomeView(model: model, proStore: proStore)
                .task { await proStore.start() }
        }
    }
}

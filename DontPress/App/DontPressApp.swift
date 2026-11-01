import SwiftUI

@main
struct DontPressApp: App {
    /// Created once per process: a cold launch always starts a fresh current run, while
    /// backgrounding or presenting the share sheet keeps this same instance alive.
    @State private var model: HomeViewModel
    @State private var proStore: ProStore
    /// UI tests only (DEBUG): Pro is pre-set, so StoreKit must not overwrite it.
    private let skipStoreKit: Bool

    init() {
        let configuration = LaunchConfiguration()
        skipStoreKit = configuration.forcePro
        let store = configuration.makeStore()
        let service = PressService(store: store)
        // feat-nudges: soft Pro prompts; off in UI-test mode so cards never cover tested controls.
        let nudges: ProNudgeScheduler? = configuration.isUITestMode ? nil : ProNudgeScheduler(store: store)
        nudges?.registerLaunch()
        let model = HomeViewModel(service: service, haptics: UIKitHaptics(), sounds: AudioEngineSounds(),
                                  daily: DailyTracker(store: store), nudges: nudges)
        let proStore = ProStore(cachedIsPro: service.savedIsPro)
        proStore.onChange = { [weak model] isPro in
            model?.setPro(isPro)
            // After a refund/revocation the alternate icons are Pro-only again: restore the classic icon.
            if !isPro, UIApplication.shared.alternateIconName != nil {
                UIApplication.shared.setAlternateIconName(nil) { _ in }
            }
        }
        _model = State(initialValue: model)
        _proStore = State(initialValue: proStore)
    }

    var body: some Scene {
        WindowGroup {
            HomeView(model: model, proStore: proStore)
                .task { if !skipStoreKit { await proStore.start() } }
        }
    }
}

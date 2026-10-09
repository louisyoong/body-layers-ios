import SwiftUI

enum StudyCategory: Hashable {
    case human, animal
}

/// Root: the study-category picker, then the chosen atlas. Both atlas view models
/// live here so their loaded geometry survives switching back and forth.
struct ContentView: View {
    @StateObject private var humanViewModel = AnatomyViewModel()
    @StateObject private var animalViewModel = AnimalAtlasViewModel()
    @State private var category: StudyCategory?
    @State private var showSplash = true

    var body: some View {
        ZStack {
            content
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
        }
    }

    private var content: some View {
        ZStack {
            switch category {
            case nil:
                StudyPickerView { category = $0 }
                    .transition(.opacity)
            case .human:
                HumanAtlasView(viewModel: humanViewModel) { category = nil }
                    .transition(.move(edge: .trailing))
            case .animal:
                AnimalAtlasView(viewModel: animalViewModel) { category = nil }
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: category)
    }
}

#Preview {
    ContentView()
}

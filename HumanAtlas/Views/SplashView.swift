import SwiftUI

/// Shown over the study picker on launch. Its background matches the
/// `LaunchBackground` color the system launch screen uses, so the hand-off from
/// the OS launch screen to this view is seamless.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 31, style: .continuous))
                    .shadow(color: .cyan.opacity(0.25), radius: 24)
                    .scaleEffect(appeared ? 1 : 0.85)
                Text("Body Layers")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("3D Human & Animal Anatomy")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }
}

#Preview {
    SplashView()
}

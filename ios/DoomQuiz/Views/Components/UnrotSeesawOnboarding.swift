import SwiftUI
import UIKit
import CoreHaptics

struct UnrotSeesawOnboarding: View {
    var onAnimationComplete: (() -> Void)? = nil

    @State private var isBalanced = false
    @State private var boxScale: CGFloat = 1.0
    @State private var brainScale: CGFloat = 1.0
    @State private var tiltAngle: Double = -18 // Initial tilt towards social media
    @State private var floatingIcons = false
    @State private var brainBreathing = false
    
    // Core Haptics Engine
    @State private var hapticEngine: CHHapticEngine?
    
    // BOX SIZE
    private let boxWidth: CGFloat = 162
    private let boxHeight: CGFloat = 113.85
    
    // LOGO SIZES
    private let baseLogoSize: CGFloat = 31
    private let youtubeLogoSize: CGFloat = 64.4
    private let snapchatLogoSize: CGFloat = 53.1
    private let redditLogoSize: CGFloat = 35
    private let facebookLogoSize: CGFloat = 39.6

    var body: some View {
        ZStack {
            // Background - Clean and Minimal
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Text Header
                VStack(spacing: 12) {
                    Text("Let's balance it")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text("Study to earn scroll time — or scroll less and keep learning.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.36, green: 0.38, blue: 0.42))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Seesaw Animation Area
                ZStack(alignment: .bottom) {
                    // Pivot (The Triangle)
                    Triangle()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .frame(width: 60, height: 50)
                        .offset(y: 10)

                    // The Seesaw Plank
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .frame(width: 320, height: 12)

                        // LEFT SIDE: The Cardboard Box with Logos layered inside
                        ZStack {
                            // Back layer of the box
                            Image("box_back_layer")
                                .resizable()
                                .scaledToFit()
                                .frame(width: boxWidth, height: boxHeight)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)

                            // Social Media Logos
                            Group {
                                Image("reddit_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: redditLogoSize, height: redditLogoSize)
                                    .rotationEffect(.degrees(-10))
                                    .offset(x: -boxWidth * 0.1, y: floatingIcons ? -boxHeight * 0.4 : -boxHeight * 0.3)
                                
                                Image("tiktok_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: baseLogoSize, height: baseLogoSize)
                                    .rotationEffect(.degrees(15))
                                    .offset(x: boxWidth * 0.15, y: floatingIcons ? -boxHeight * 0.35 : -boxHeight * 0.25)

                                Image("instagram_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: baseLogoSize, height: baseLogoSize)
                                    .rotationEffect(.degrees(-20))
                                    .offset(x: boxWidth * 0.25, y: floatingIcons ? -boxHeight * 0.5 : -boxHeight * 0.4)
                                
                                Image("x_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: baseLogoSize * 0.9, height: baseLogoSize * 0.9)
                                    .rotationEffect(.degrees(25))
                                    .offset(x: -boxWidth * 0.25, y: floatingIcons ? -boxHeight * 0.45 : -boxHeight * 0.35)

                                Image("facebook_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: facebookLogoSize, height: facebookLogoSize)
                                    .rotationEffect(.degrees(-12))
                                    .offset(x: boxWidth * 0.05 + 16.5 - 1.98, y: floatingIcons ? -boxHeight * 0.6 - 24.75 + 3.96 : -boxHeight * 0.5 - 24.75 + 3.96)

                                Image("youtube_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: youtubeLogoSize, height: youtubeLogoSize)
                                    .rotationEffect(.degrees(-5))
                                    .offset(x: 5, y: floatingIcons ? -boxHeight * 0.55 : -boxHeight * 0.45)
                                
                                Image("snapchat_logo_clean")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: snapchatLogoSize, height: snapchatLogoSize)
                                    .rotationEffect(.degrees(10))
                                    .offset(x: -boxWidth * 0.1, y: floatingIcons ? -boxHeight * 0.65 : -boxHeight * 0.55)
                            }
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: floatingIcons)

                            // Front layer of the box
                            Image("box_front_layer")
                                .resizable()
                                .scaledToFit()
                                .frame(width: boxWidth, height: boxHeight)
                        }
                        .scaleEffect(boxScale)
                        .offset(x: -84.5, y: -50)

                        // RIGHT SIDE: The Brain Character
                        Image("brain_character")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 112.5, height: 87.5)
                            .offset(y: brainBreathing ? -60 : -50)
                            .scaleEffect(brainScale)
                            .offset(x: 110)
                    }
                    .rotationEffect(.degrees(tiltAngle), anchor: .center)
                    .animation(.spring(response: 2.8, dampingFraction: 0.75, blendDuration: 0.2), value: tiltAngle) // Slower response (2.2 -> 2.8)
                }
                .frame(height: 200)

                Spacer()

                // Progress Indicators
                HStack(spacing: 8) {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                    Capsule().fill(Color.black).frame(width: 24, height: 8)
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            prepareHaptics()
            startAutomaticAnimation()
        }
    }

    // MARK: - Haptics Logic
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic Engine Error: \(error.localizedDescription)")
        }
    }

    private func playContinuousBalancingHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        // Slower haptic pattern (2.5s duration)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
        
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 2.5)
        
        // Impact at the balance point (adjusted for slower timing)
        let impactIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let impactSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        let impactEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [impactIntensity, impactSharpness], relativeTime: 1.2)

        do {
            let pattern = try CHHapticPattern(events: [event, impactEvent], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }

    private func startAutomaticAnimation() {
        // Initial state
        tiltAngle = -18
        boxScale = 1.0
        brainScale = 1.0
        brainBreathing = false
        floatingIcons = true

        // Sequence: Pause for 0.7s, then start animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            playContinuousBalancingHaptic()
            
            withAnimation(.spring(response: 2.8, dampingFraction: 0.75, blendDuration: 0.2)) {
                tiltAngle = 15
                brainScale = 1.5
            }
            
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                brainBreathing = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onAnimationComplete?()
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    UnrotSeesawOnboarding()
}

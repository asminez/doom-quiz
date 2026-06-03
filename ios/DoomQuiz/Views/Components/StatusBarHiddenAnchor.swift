import SwiftUI
import UIKit

/// Ensures the hosting window prefers a hidden status bar (SwiftUI can ignore Info.plist alone).
struct StatusBarHiddenAnchor: UIViewControllerRepresentable {
  final class Controller: UIViewController {
    override var prefersStatusBarHidden: Bool { true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      setNeedsStatusBarAppearanceUpdate()
      parent?.setNeedsStatusBarAppearanceUpdate()
    }
  }

  func makeUIViewController(context: Context) -> Controller {
    Controller()
  }

  func updateUIViewController(_ uiViewController: Controller, context: Context) {}
}

extension View {
  func prefersHiddenStatusBar() -> some View {
    background(StatusBarHiddenAnchor().frame(width: 0, height: 0))
      .statusBarHidden(true)
  }
}

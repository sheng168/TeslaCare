//
//  CarPhotoFullScreenView.swift
//  TeslaCare
//

import SwiftUI

/// A full-screen, dismissable image viewer that supports pinch-to-zoom, pan, and
/// double-tap-to-zoom. Presented when a thumbnail in `CarPhotoStrip` is tapped.
struct CarPhotoFullScreenView: View {
    let image: UIImage
    var caption: String?

    @Environment(\.dismiss) private var dismiss

    /// Committed zoom scale, persisted between gestures.
    @State private var scale: CGFloat = 1
    /// Committed pan offset, persisted between gestures.
    @State private var offset: CGSize = .zero
    /// Live pinch magnification applied on top of `scale` while pinching.
    @GestureState private var gestureScale: CGFloat = 1
    /// Live drag translation applied on top of `offset` while panning.
    @GestureState private var gestureOffset: CGSize = .zero

    /// Zoom level used when double-tapping to magnify.
    private let doubleTapScale: CGFloat = 2.5
    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5

    private var effectiveScale: CGFloat {
        scale * gestureScale
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(effectiveScale)
                    .offset(x: offset.width + gestureOffset.width,
                            y: offset.height + gestureOffset.height)
                    .gesture(magnification)
                    .simultaneousGesture(pan(in: proxy.size))
                    .onTapGesture(count: 2) { toggleZoom() }
            }
        }
        .overlay(alignment: .topTrailing) { topControls }
        .overlay(alignment: .bottom) { captionLabel }
        .statusBarHidden()
    }

    // MARK: - Gestures

    private var magnification: some Gesture {
        MagnifyGesture()
            .updating($gestureScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                scale = (scale * value.magnification).clamped(to: minScale...maxScale)
                if scale == minScale {
                    withAnimation(.spring) { offset = .zero }
                }
            }
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                // Only pan once zoomed in; otherwise the image stays put.
                state = scale > minScale ? value.translation : .zero
            }
            .onEnded { value in
                guard scale > minScale else { return }
                offset = clampedOffset(
                    CGSize(width: offset.width + value.translation.width,
                           height: offset.height + value.translation.height),
                    in: size
                )
            }
    }

    private func toggleZoom() {
        withAnimation(.spring) {
            if scale > minScale {
                scale = minScale
                offset = .zero
            } else {
                scale = doubleTapScale
            }
        }
    }

    /// Keeps the panned image from drifting entirely off screen by limiting the
    /// offset to the slack created by the current zoom scale.
    private func clampedOffset(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let maxX = max(0, (size.width * effectiveScale - size.width) / 2)
        let maxY = max(0, (size.height * effectiveScale - size.height) / 2)
        return CGSize(
            width: proposed.width.clamped(to: -maxX...maxX),
            height: proposed.height.clamped(to: -maxY...maxY)
        )
    }

    // MARK: - Overlays

    private var topControls: some View {
        HStack(spacing: 16) {
            ShareLink(item: shareImage, preview: sharePreview) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.4))
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
        }
        .padding()
    }

    /// The image to share, exposed as a `Transferable` SwiftUI `Image`.
    private var shareImage: Image {
        Image(uiImage: image)
    }

    private var sharePreview: SharePreview<Image, Never> {
        SharePreview(caption?.isEmpty == false ? caption! : "Car Photo",
                     image: shareImage)
    }

    @ViewBuilder
    private var captionLabel: some View {
        if let caption, !caption.isEmpty {
            Text(caption)
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.4), in: Capsule())
                .padding(.bottom, 32)
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    CarPhotoFullScreenView(
        image: UIImage(systemName: "car.fill") ?? UIImage(),
        caption: "Front Bumper • Front Left"
    )
}

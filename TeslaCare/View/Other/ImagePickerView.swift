//
//  ImagePickerView.swift
//  TeslaCare
//

import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        if sourceType == .camera {
            let overlay = UIHostingController(rootView: TireCameraOverlay())
            if let screenBounds = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds {
                overlay.view.frame = screenBounds
            }
            overlay.view.backgroundColor = .clear
            overlay.view.isUserInteractionEnabled = false
            overlay.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            picker.cameraOverlayView = overlay.view
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                if picker.sourceType == .camera {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct TireCameraOverlay: View {
    var body: some View {
        GeometryReader { geo in
            // Always portrait: UIImagePickerController is portrait-only on iPhone.
            // Viewfinder is 4:3 at the top; shutter controls fill the remainder.
            let cx = geo.size.width / 2
            let cy = geo.size.width * 2.0 / 3.0
            let diameter = geo.size.width * 0.82
            let r = diameter / 2

            ZStack {
                // Dashed circle — rim guide
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2.5, dash: [12, 7]))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: diameter, height: diameter)
                    .position(x: cx, y: cy)

                // Valve stem body
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(.white.opacity(0.85))
                    .frame(width: 7, height: 18)
                    .position(x: cx, y: cy + r + 9)

                // Valve stem cap
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.85))
                    .frame(width: 11, height: 5)
                    .position(x: cx, y: cy + r + 19)

                // Hint
                Text("Align rim with circle")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.5), in: Capsule())
                    .position(x: cx, y: cy + r + 46)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Camera Overlay") {
    TireCameraOverlay()
        .background(Color(.darkGray))
}

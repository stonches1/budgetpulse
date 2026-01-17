//
//  ReceiptImageView.swift
//  BudgetPulse
//

import SwiftUI
import PhotosUI

struct ReceiptImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        selectedImage = nil
                        selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .red)
                    }
                    .padding(8)
                }
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Label(
                    selectedImage == nil ? L("attach_receipt") : L("change_receipt"),
                    systemImage: "camera.fill"
                )
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
}

struct ReceiptImageViewer: View {
    let filename: String
    @State private var image: UIImage?
    @State private var showingFullScreen = false

    var body: some View {
        Group {
            if let image = image {
                Button {
                    showingFullScreen = true
                } label: {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(L("view_receipt"))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .fullScreenCover(isPresented: $showingFullScreen) {
                    ReceiptFullScreenView(image: image)
                }
            } else {
                HStack {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, height: 60)

                    Text(L("receipt_not_found"))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }
        }
        .task {
            image = ImageStorageManager.shared.loadImage(filename: filename)
        }
    }
}

struct ReceiptFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, min(value, 4.0))
                                }
                        )
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .gray)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ReceiptImagePicker(selectedImage: .constant(nil))
}

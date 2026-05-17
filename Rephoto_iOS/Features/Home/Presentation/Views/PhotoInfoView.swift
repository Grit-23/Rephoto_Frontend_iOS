//
//  PhotoInfoView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import NukeUI

struct PhotoInfoView: View {
    let photo: Photo
    @State private var vm: PhotoInfoViewModel
    @State private var showDeleteConfirmation = false
    @State private var showInfoSheet = false
    @State private var showAddTag = false
    @State private var newTagName = ""
    @Environment(\.dismiss) private var dismiss

    init(photo: Photo, provider: HomeUseCaseProviderProtocol) {
        self.photo = photo
        self._vm = State(initialValue: PhotoInfoViewModel(provider: provider))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyImage(url: photo.imageUrl) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(height: 300)
                    }
                }

                // Tags Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("태그")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(vm.tags) { tag in
                            TagChipView(tag: tag) { newName in
                                Task {
                                    await vm.updateTag(photoTagId: tag.photoTagId, newTagName: newName)
                                }
                            }
                        }

                        if vm.tags.count < 3 {
                            Button {
                                showAddTag = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        showInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }

                    ShareLink(item: photo.imageUrl)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog("사진을 삭제하시겠습니까?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                Task {
                    await vm.deletePhoto(photoId: photo.photoId)
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            PhotoDetailSheet(photo: photo, description: vm.description)
        }
        .task {
            await vm.fetchTags(photoId: photo.photoId)
            await vm.getDescription(photoId: photo.photoId)
        }
        .onChange(of: vm.isDeleted) { _, isDeleted in
            if isDeleted { dismiss() }
        }
        .alert("태그 추가", isPresented: $showAddTag) {
            TextField("태그 이름", text: $newTagName)
            Button("추가") {
                let name = newTagName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                Task { await vm.addTag(photoId: photo.photoId, tagName: name) }
                newTagName = ""
            }
            Button("취소", role: .cancel) { newTagName = "" }
        }
    }
}

// MARK: - PhotoDetailSheet

private struct PhotoDetailSheet: View {
    let photo: Photo
    let description: String

    var body: some View {
        NavigationStack {
            List {
                Section("파일 정보") {
                    LabeledContent("파일명", value: photo.fileName)
                    LabeledContent("생성일", value: photo.createdAt.formatted())
                }
                Section("위치") {
                    LabeledContent("위도", value: String(format: "%.6f", photo.latitude))
                    LabeledContent("경도", value: String(format: "%.6f", photo.longitude))
                }
                if !description.isEmpty {
                    Section("설명") {
                        Text(description)
                    }
                }
            }
            .navigationTitle("상세 정보")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - TagChipView

private struct TagChipView: View {
    let tag: PhotoTag
    let onUpdate: (String) -> Void
    @State private var isEditing = false
    @State private var editText: String

    init(tag: PhotoTag, onUpdate: @escaping (String) -> Void) {
        self.tag = tag
        self.onUpdate = onUpdate
        self._editText = State(initialValue: tag.tagName)
    }

    var body: some View {
        if isEditing {
            TextField("태그", text: $editText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onSubmit {
                    onUpdate(editText)
                    isEditing = false
                }
        } else {
            Text(tag.tagName)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .onTapGesture {
                    isEditing = true
                }
        }
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + rowHeight), positions)
    }
}

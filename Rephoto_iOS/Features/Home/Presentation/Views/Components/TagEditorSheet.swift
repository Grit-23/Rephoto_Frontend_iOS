//
//  TagEditorSheet.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI

// MARK: - TagSheetMode

/// 태그 편집 시트의 모드 (추가/수정). id는 줌 전환 sourceID와도 공유됨
enum TagSheetMode: Identifiable {
    case add
    case edit(PhotoTag)

    var id: Int {
        switch self {
        case .add: -1
        case .edit(let tag): tag.photoTagId
        }
    }

    var title: String {
        switch self {
        case .add: "태그 추가"
        case .edit: "태그 수정"
        }
    }
}

// MARK: - TagEditorSheet

/// 태그 추가/수정 시트. 수정 모드에서는 삭제 버튼도 제공
struct TagEditorSheet: View {
    let mode: TagSheetMode
    let onSave: (String) -> Void
    let onDelete: () -> Void
    @State private var name: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(mode: TagSheetMode, onSave: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete
        // sheet(item:)은 표시마다 새 identity를 만드므로 초기값 주입이 안전함
        if case .edit(let tag) = mode {
            self._name = State(initialValue: tag.tagName)
        } else {
            self._name = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("태그 이름", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(save)

                CTAButton(title: "저장", isLoading: false, action: save)

                if case .edit = mode {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Text("태그 삭제")
                            .font(.subheadline.weight(.medium))
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(280)])
        .onAppear { isFocused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}

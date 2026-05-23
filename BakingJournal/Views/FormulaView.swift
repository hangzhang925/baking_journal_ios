import SwiftUI
import UniformTypeIdentifiers

struct FormulaView: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var expandedItemId: UUID?
    @State private var exportDocument = RecipeBackupDocument(data: Data())
    @State private var fileError: String?
    @State private var importingRecipe = false
    @State private var previewOpen = false
    @State private var showingExporter = false
    @State private var previewItemIDsByCategory: [ItemCategory: [UUID]] = [:]
    @State private var activeItemID: UUID?
    @State private var activeItemCategory: ItemCategory?
    @State private var activeItemFrame: CGRect?
    @State private var activeItemGrabOffset: CGSize = .zero
    @State private var activeItemLocation: CGPoint?
    @State private var itemRowFrames: [UUID: CGRect] = [:]
    @State private var openSwipeItemID: UUID?
    @State private var inlineControlItemID: UUID?
    @State private var showingToolbarActions = false
    @StateObject private var dropdownPresenter = DropdownPresenter()
    @FocusState private var isRecipeNameFocused: Bool

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    recipeHeader
                        .padding(.horizontal, 14)
                        .padding(.top, 6)

                    ForEach(displayCategories) { category in
                        categorySection(category)
                    }
                }
                .padding(.bottom, 178)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.brandBackground)

            if let menu = dropdownPresenter.menu {
                dropdownOverlay(menu)
                    .zIndex(20)
            }

            if let activeItem {
                FormulaItemCard(
                    item: activeItem,
                    isExpanded: false,
                    canRemove: canRemove(activeItem)
                ) {}
                .frame(width: activeItemFrame?.width)
                .reorderLiftedAppearance()
                .offset(activeItemOverlayOffset)
                .allowsHitTesting(false)
                .zIndex(30)
            }
        }
        .coordinateSpace(name: "formulaDropdownSpace")
        .environmentObject(dropdownPresenter)
        .onPreferenceChange(ReorderRowFramePreferenceKey.self) { frames in
            itemRowFrames = frames
        }
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarActionsButton
                }
            }
        }
        .sheet(isPresented: $previewOpen) {
            NavigationStack {
                RecipePreviewView(showsDoneButton: true)
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result {
                fileError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $importingRecipe,
            allowedContentTypes: [.json]
        ) { result in
            importRecipe(result)
        }
        .alert("文件操作失败", isPresented: Binding(
            get: { fileError != nil },
            set: { if !$0 { fileError = nil } }
        )) {
            Button("好", role: .cancel) { fileError = nil }
        } message: {
            Text(fileError ?? "")
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                dropdownPresenter.dismiss()
                dismissActiveKeyboard()
            }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    dismissActiveKeyboard()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "keyboard.chevron.compact.down",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .subheadline.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("完成")
            }
        }
    }

    private var toolbarActionsButton: some View {
        Button {
            showingToolbarActions = true
        } label: {
            BakingSystemIconButtonLabel(
                systemImage: "ellipsis",
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .subheadline.weight(.semibold)
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel("更多")
        .popover(isPresented: $showingToolbarActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingDropdownPopover(width: 188) {
                Button {
                    showingToolbarActions = false
                    store.saveCurrentRecipe()
                } label: {
                    BakingDropdownRow(title: "保存到我的配方") {
                        Image(systemName: "bookmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingToolbarActions = false
                    exportRecipe()
                } label: {
                    BakingDropdownRow(title: "导出 JSON") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingToolbarActions = false
                    importingRecipe = true
                } label: {
                    BakingDropdownRow(title: "导入 JSON") {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recipeHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer()

                headerActionButton(icon: "doc.text.magnifyingglass", label: "预览流程") {
                    previewOpen = true
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("配方名称")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandSecondaryText)

                HStack(spacing: 8) {
                    BakingSystemIconButtonLabel(
                        systemImage: "pencil",
                        tint: isRecipeNameFocused ? .white : .brandPrimary,
                        background: isRecipeNameFocused ? .brandPrimary : Color.brandPrimary.opacity(0.11),
                        visualSize: BakingTouchTarget.secondaryActionVisual
                    )

                    TextField("配方名称", text: $store.recipeName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                        .textFieldStyle(.plain)
                        .focused($isRecipeNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isRecipeNameFocused = false
                        }

                    if !store.recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("可编辑")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isRecipeNameFocused ? Color.brandPrimary : Color.brandSecondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isRecipeNameFocused ? Color.brandPrimary.opacity(0.12) : Color.brandBackground.opacity(0.9))
                            )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .bakingFieldSurface(
                    background: isRecipeNameFocused ? Color.brandPrimary.opacity(0.12) : Color.brandBackground.opacity(0.88),
                    stroke: isRecipeNameFocused ? Color.brandPrimary.opacity(0.32) : Color.brandPrimary.opacity(0.14),
                    radius: BakingRadius.card
                )
                .contentShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
                .onTapGesture {
                    isRecipeNameFocused = true
                }
            }

            CompactRecipeMetrics(summary: store.summary)
        }
        .padding(10)
        .bakingCard()
    }

    private func categorySection(_ category: ItemCategory) -> some View {
        VStack(spacing: BakingSpace.sm) {
            let categoryItems = displayedItems(for: category)
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(category.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if category == .basic {
                        BakerPercentageInfoButton()
                    }
                }
                Spacer()
                AddItemControl(category: category)
            }
            .padding(.horizontal, 18)

            if categoryItems.isEmpty {
                Text("还没有材料")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.brandSurface.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 14)
            } else {
                ForEach(categoryItems) { item in
                    formulaItemRow(item, in: category)
                        .opacity(activeItemID == item.id ? ReorderMotion.previewOpacity : 1)
                        .background(ReorderFrameReader(id: item.id, coordinateSpace: "formulaDropdownSpace"))
                        .padding(.horizontal, 14)
                        .animation(ReorderMotion.animation, value: categoryItems.map(\.id))
                }
            }
        }
    }

    private var displayCategories: [ItemCategory] {
        [.flour, .basic]
    }

    private func items(for category: ItemCategory) -> [RecipeItem] {
        switch category {
        case .flour:
            return store.items.filter { $0.category == .flour || $0.category == .starter }
        case .basic:
            return store.items.filter { $0.category == .basic || $0.category == .other }
        default:
            return store.items.filter { $0.category == category }
        }
    }

    private func displayedItems(for category: ItemCategory) -> [RecipeItem] {
        let categoryItems = items(for: category)
        guard let previewIDs = previewItemIDsByCategory[category] else { return categoryItems }

        let itemsByID = Dictionary(uniqueKeysWithValues: categoryItems.map { ($0.id, $0) })
        let previewItems = previewIDs.compactMap { itemsByID[$0] }
        let previewIDSet = Set(previewIDs)
        return previewItems + categoryItems.filter { !previewIDSet.contains($0.id) }
    }

    private var activeItem: RecipeItem? {
        guard let activeItemID else { return nil }
        return store.items.first { $0.id == activeItemID }
    }

    private var activeItemOverlayOffset: CGSize {
        guard let frame = activeItemFrame else { return .zero }
        let location = activeItemLocation ?? CGPoint(
            x: frame.midX,
            y: frame.midY
        )
        return CGSize(
            width: location.x - activeItemGrabOffset.width,
            height: location.y - activeItemGrabOffset.height
        )
    }

    private func canRemove(_ item: RecipeItem) -> Bool {
        item.category != .flour || store.items.filter { $0.category == .flour }.count > 1
    }

    private func formulaItemRow(_ item: RecipeItem, in category: ItemCategory) -> some View {
        BakingSwipeToDeleteRow(canDelete: activeItemID == nil && inlineControlItemID == nil && canRemove(item)) {
            store.removeItem(item)
        } onOpenChanged: { isOpen in
            updateOpenSwipeItem(item.id, isOpen: isOpen)
        } content: {
            FormulaItemCard(
                item: item,
                isExpanded: expandedItemId == item.id,
                canRemove: canRemove(item),
                reorderCoordinateSpace: canStartItemReorder(item) ? "formulaDropdownSpace" : nil
            ) {
                guard item.requiresAdvancedFormulaEditor else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedItemId = expandedItemId == item.id ? nil : item.id
                }
            } onInlineInteractionChanged: { isActive in
                updateInlineControlItem(item.id, isActive: isActive)
            } onReorderChanged: { drag in
                beginItemReorderIfNeeded(item, category: category, drag: drag)
                updateItemReorder(in: category, with: drag.location)
            } onReorderEnded: { drag in
                guard let drag else {
                    cancelItemReorder()
                    return
                }
                updateItemReorder(in: category, with: drag.location)
                commitItemReorder()
            }
        }
    }

    private func canStartItemReorder(_ item: RecipeItem) -> Bool {
        openSwipeItemID == nil
            && inlineControlItemID == nil
            && expandedItemId != item.id
            && activeItemID == nil
    }

    private func updateOpenSwipeItem(_ itemID: UUID, isOpen: Bool) {
        if isOpen {
            openSwipeItemID = itemID
        } else if openSwipeItemID == itemID {
            openSwipeItemID = nil
        }
    }

    private func updateInlineControlItem(_ itemID: UUID, isActive: Bool) {
        if isActive {
            inlineControlItemID = itemID
        } else if inlineControlItemID == itemID {
            inlineControlItemID = nil
        }
    }

    private func beginItemReorderIfNeeded(_ item: RecipeItem, category: ItemCategory, drag: DragGesture.Value) {
        guard activeItemID == nil else { return }
        let frame = itemRowFrames[item.id]
        activeItemID = item.id
        setHistorySwipeSuppressed(true)
        activeItemCategory = category
        activeItemFrame = frame
        activeItemLocation = drag.location
        if let frame {
            activeItemGrabOffset = CGSize(
                width: drag.startLocation.x - frame.minX,
                height: drag.startLocation.y - frame.minY
            )
        }
        previewItemIDsByCategory[category] = items(for: category).map(\.id)
    }

    private func updateItemReorder(in category: ItemCategory, with location: CGPoint) {
        activeItemLocation = location
        guard let activeItemID,
              activeItemCategory == category,
              let currentIDs = previewItemIDsByCategory[category] else { return }

        var remainingIDs = currentIDs.filter { $0 != activeItemID }
        let destination = remainingIDs.firstIndex { itemID in
            guard let frame = itemRowFrames[itemID] else { return false }
            return location.y < frame.midY
        } ?? remainingIDs.count
        remainingIDs.insert(activeItemID, at: destination)

        guard remainingIDs != currentIDs else { return }
        withAnimation(ReorderMotion.animation) {
            previewItemIDsByCategory[category] = remainingIDs
        }
    }

    private func commitItemReorder() {
        if let activeItemCategory,
           let previewIDs = previewItemIDsByCategory[activeItemCategory],
           previewIDs != items(for: activeItemCategory).map(\.id) {
            store.reorderItems(in: activeItemCategory, orderedIDs: previewIDs)
        }
        cancelItemReorder()
    }

    private func cancelItemReorder() {
        withAnimation(ReorderMotion.animation) {
            activeItemID = nil
            activeItemCategory = nil
            activeItemFrame = nil
            activeItemLocation = nil
            activeItemGrabOffset = .zero
            previewItemIDsByCategory.removeAll()
            setHistorySwipeSuppressed(false)
        }
    }

    private func headerActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            BakingSystemIconButtonLabel(
                systemImage: icon,
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .subheadline.weight(.semibold)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var exportFilename: String {
        let safeName = store.recipeName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
        return safeName.isEmpty ? "烘焙手帐配方" : safeName
    }

    private func exportRecipe() {
        do {
            exportDocument = RecipeBackupDocument(data: try store.exportRecipeData())
            showingExporter = true
        } catch {
            fileError = error.localizedDescription
        }
    }

    private func importRecipe(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            try store.importRecipeData(data)
        } catch {
            fileError = error.localizedDescription
        }
    }

    @ViewBuilder
    private func dropdownOverlay(_ menu: ActiveDropdownMenu) -> some View {
        GeometryReader { proxy in
            let layout = dropdownLayout(for: menu, in: proxy.size)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dropdownPresenter.dismiss()
                }

            BakingDropdownPopover(width: menu.width) {
                ForEach(menu.items) { item in
                    Button {
                        dropdownPresenter.dismiss()
                        item.action()
                    } label: {
                        BakingDropdownRow(title: item.title, isSelected: item.isSelected) {
                            if let icon = item.icon {
                                BakingIconView(icon: icon, size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                            } else {
                                Color.clear
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .position(
                x: layout.origin.x + menu.width / 2,
                y: layout.origin.y + layout.height / 2
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
        }
    }

    private func dropdownLayout(for menu: ActiveDropdownMenu, in containerSize: CGSize) -> (origin: CGPoint, height: CGFloat) {
        let rowHeight: CGFloat = 44
        let verticalPadding: CGFloat = 16
        let menuHeight = CGFloat(menu.items.count) * rowHeight + verticalPadding
        let horizontalInset: CGFloat = 8
        let verticalGap: CGFloat = 2
        let rawX = menu.alignment == .trailing ? (menu.frame.maxX - menu.width) : menu.frame.minX
        let x = min(max(horizontalInset, rawX), containerSize.width - menu.width - horizontalInset)

        let availableBelow = containerSize.height - menu.frame.maxY
        let showAbove = availableBelow < menuHeight + 20 && menu.frame.minY > menuHeight + 20
        let y = showAbove
            ? max(8, menu.frame.minY - menuHeight - verticalGap)
            : min(containerSize.height - menuHeight - 8, menu.frame.maxY + verticalGap)

        return (CGPoint(x: x, y: y), menuHeight)
    }
}

private struct BakerPercentageInfoButton: View {
    @State private var showingInfo = false

    var body: some View {
        Button {
            showingInfo = true
        } label: {
            Image(systemName: "exclamationmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("百分比说明")
        .popover(isPresented: $showingInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakerPercentageTooltip()
                .presentationCompactAdaptation(.popover)
        }
    }
}

private struct BakerPercentageTooltip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "percent")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 22, height: 22)
                    .background(Color.brandPrimary.opacity(0.10))
                    .clipShape(Circle())

                Text("基于总面粉")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandText)
            }

            Text("包含直接添加的面粉，也包含种面里的面粉。")
                .font(.caption)
                .foregroundStyle(Color.brandSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                .fill(Color.brandSurface.opacity(0.98))
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(0.07), radius: 18, x: 0, y: 8)
        )
    }
}

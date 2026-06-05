import SwiftUI
import UIKit
import UniformTypeIdentifiers
import OSLog

struct FormulaView: View {
    private static let reorderLog = Logger(subsystem: "com.hang.BakingJournal", category: "FormulaReorder")

    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var exportDocument = RecipeBackupDocument(data: Data())
    @State private var fileError: String?
    @State private var importingRecipe = false
    @State private var showingExporter = false
    @State private var showingToolbarActions = false
    @State private var previewItemsByCategory: [ItemCategory: [RecipeItem]] = [:]
    @State private var isItemListEditing = false
    @State private var activeItemID: UUID?
    @State private var activeItemCategory: ItemCategory?
    @State private var activeItemFrame: CGRect?
    @State private var activeItemGrabOffset: CGSize = .zero
    @State private var activeItemLocation: CGPoint?
    @State private var itemRowFrames: [UUID: CGRect] = [:]
    @State private var suppressNextItemTap = false
    @State private var pendingDeleteItem: RecipeItem?
    @State private var showingDeleteConfirmation = false
    @State private var editingItemID: UUID?
    @State private var itemEditorMeasuredContentHeight: CGFloat = 0
    @StateObject private var dropdownPresenter = DropdownPresenter()

    private let reorderCoordinateSpace = "formulaReorderSpace"

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
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: BakingSpace.lg) {
                        RecipeMetricsOverviewCard(
                            summary: store.summary,
                            items: store.items,
                            flourContribution: store.flourContribution,
                            waterContribution: store.waterContribution
                        )

                        ForEach(displayCategories) { category in
                            categorySection(category)
                        }
                    }
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingLayout.contentTopInset)
                    .padding(.bottom, 178)
                }
                .onPreferenceChange(ReorderRowFramePreferenceKey.self) { frames in
                    itemRowFrames = frames
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.brandBackground)

            if let activeItem {
                FormulaItemDisplayRow(item: activeItem)
                    .frame(width: activeItemFrame?.width)
                    .reorderLiftedAppearance()
                    .offset(activeItemOverlayOffset)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    .allowsHitTesting(false)
                    .zIndex(10)
            }

            if let menu = dropdownPresenter.menu {
                dropdownOverlay(menu)
                    .zIndex(20)
            }

        }
        .overlay {
            if showingDeleteConfirmation {
                BakingConfirmationDialog(
                    title: BakingTerms.formulaDeleteMaterialConfirmationTitle,
                    message: BakingTerms.formulaDeleteMaterialConfirmationMessage,
                    confirmTitle: BakingTerms.delete,
                    cancelTitle: BakingTerms.cancel,
                    confirmTint: .brandPrimary,
                    onConfirm: confirmPendingDelete,
                    onCancel: cancelPendingDelete
                )
                .zIndex(40)
            }
        }
        .animation(BakingMotion.standard, value: showingDeleteConfirmation)
        .coordinateSpace(name: "formulaDropdownSpace")
        .coordinateSpace(name: reorderCoordinateSpace)
        .environmentObject(dropdownPresenter)
        .sheet(isPresented: Binding(
            get: { editingItemID != nil },
            set: { if !$0 { editingItemID = nil } }
        )) {
            itemEditorSheet
        }
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarActionsButton
                }
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
        .alert(BakingTerms.formulaFileOperationFailed, isPresented: Binding(
            get: { fileError != nil },
            set: { if !$0 { fileError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) { fileError = nil }
        } message: {
            Text(fileError ?? "")
        }
        .onDisappear {
            resetItemReorderState(reason: "formula disappear")
        }
        .onChange(of: editingItemID) { _, newValue in
            if newValue != nil {
                resetItemReorderState(reason: "item editor sheet presented")
            }
        }
        .onChange(of: showingDeleteConfirmation) { _, newValue in
            if newValue {
                resetItemReorderState(keepEditingMode: true, reason: "delete confirmation presented")
            }
        }
        .onChange(of: store.items.map(\.id)) { _, itemIDs in
            if let activeItemID, !itemIDs.contains(activeItemID) {
                resetItemReorderState(reason: "active item removed")
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                dropdownPresenter.dismiss()
                guard !showingDeleteConfirmation, pendingDeleteItem == nil else { return }
                closeItemListEditingIfNeeded()
            }
        )
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
        .accessibilityLabel(BakingTerms.moreActions)
        .popover(isPresented: $showingToolbarActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingDropdownPopover(width: 188) {
                Button {
                    showingToolbarActions = false
                    exportRecipe()
                } label: {
                    BakingDropdownRow(title: BakingTerms.formulaExportJSON) {
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
                    BakingDropdownRow(title: BakingTerms.formulaImportJSON) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func categorySection(_ category: ItemCategory) -> some View {
        VStack(spacing: 0) {
            let categoryItems = displayedItems(for: category)
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(category.label)
                        .bakingLabelStyle(.sectionHeader)
                    if category == .basic {
                        BakerPercentageInfoButton()
                    }
                }
                Spacer()
                HStack(spacing: BakingSpace.xs) {
                    BakingSectionEditButton(accessibilityLabel: BakingTerms.formulaEditMaterials) {
                        enterItemListEditing()
                    }

                    AddItemControl(category: category, onOpenEditor: presentItemEditor)
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.top, BakingSpace.md)
            .padding(.bottom, categoryItems.isEmpty ? 0 : BakingSpace.xs)

            if categoryItems.isEmpty {
                Text(BakingTerms.formulaEmptyMaterials)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.vertical, BakingSpace.xl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(categoryItems.enumerated()), id: \.element.id) { index, item in
                        formulaItemRow(item, in: category)
                            .opacity(activeItemID == item.id ? ReorderMotion.previewOpacity : 1)
                            .background(ReorderFrameReader(id: item.id, coordinateSpace: reorderCoordinateSpace))
                            .animation(ReorderMotion.animation, value: categoryItems.map(\.id))

                        if index < categoryItems.count - 1 {
                            Divider()
                                .overlay(BakingSurfaceTheme.separator)
                                .padding(.leading, FormulaItemDisplayRow.separatorLeadingInset)
                        }
                    }
                }
            }
        }
        .bakingCard()
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
        previewItemsByCategory[category] ?? items(for: category)
    }

    private func canRemove(_ item: RecipeItem) -> Bool {
        item.category != .flour || store.items.filter { $0.category == .flour }.count > 1
    }

    @ViewBuilder
    private func formulaItemRow(_ item: RecipeItem, in category: ItemCategory) -> some View {
        let row = FormulaItemDisplayRow(
            item: item,
            isEditing: isItemListEditing,
            canDelete: canRemove(item),
            onReorderBegan: { drag in
                beginItemReorderIfNeeded(item, in: category, drag: drag)
            },
            onReorderChanged: { drag in
                updateItemReorder(in: category, with: drag)
            },
            onReorderEnded: { drag in
                if let drag {
                    Self.reorderLog.info("row long-press drag ended item=\(item.id.uuidString, privacy: .public) active=\(activeItemID?.uuidString ?? "nil", privacy: .public) location=(\(drag.location.x, privacy: .public), \(drag.location.y, privacy: .public))")
                    updateItemReorder(in: category, with: drag)
                    commitItemReorder()
                } else {
                    Self.reorderLog.info("row long-press drag cancelled item=\(item.id.uuidString, privacy: .public) active=\(activeItemID?.uuidString ?? "nil", privacy: .public)")
                    cancelItemReorder()
                }
            },
            onTap: {
                if suppressNextItemTap || isItemListEditing {
                    suppressNextItemTap = false
                    return
                }
                presentItemEditor(item)
            },
            onDelete: {
                requestDeleteItem(item)
            }
        )
        .contentShape(Rectangle())
        row
    }

    private var activeItem: RecipeItem? {
        guard let activeItemID else { return nil }
        if let activeItemCategory,
           let previewItem = previewItemsByCategory[activeItemCategory]?.first(where: { $0.id == activeItemID }) {
            return previewItem
        }
        return store.items.first { $0.id == activeItemID }
    }

    private var activeItemOverlayOffset: CGSize {
        guard let frame = activeItemFrame else { return .zero }
        let location = activeItemLocation ?? CGPoint(x: frame.midX, y: frame.midY)
        return CGSize(
            width: location.x - activeItemGrabOffset.width,
            height: location.y - activeItemGrabOffset.height
        )
    }

    private func canStartItemReorder(_ item: RecipeItem) -> Bool {
        activeItemID == nil
            && store.items.contains(where: { $0.id == item.id })
    }

    private func beginItemReorderIfNeeded(_ item: RecipeItem, in category: ItemCategory, drag: FormulaRowReorderValue) {
        guard canStartItemReorder(item) || activeItemID == item.id else {
            Self.reorderLog.debug("handle drag ignored item=\(item.id.uuidString, privacy: .public) active=\(activeItemID?.uuidString ?? "nil", privacy: .public)")
            return
        }
        guard activeItemID == nil else { return }
        guard let frame = itemRowFrames[item.id] else {
            Self.reorderLog.error("begin failed missing frame item=\(item.id.uuidString, privacy: .public) category=\(category.rawValue, privacy: .public) knownFrames=\(itemRowFrames.count, privacy: .public)")
            return
        }
        activeItemID = item.id
        activeItemCategory = category
        activeItemFrame = frame
        activeItemLocation = initialReorderLocation(for: drag)
        isItemListEditing = true
        suppressNextItemTap = true
        setHistorySwipeSuppressed(true)
        activeItemGrabOffset = CGSize(width: drag.startLocation.x, height: drag.startLocation.y)
        previewItemsByCategory[category] = items(for: category)
        Self.reorderLog.info("begin item=\(item.id.uuidString, privacy: .public) name=\(item.name, privacy: .public) category=\(category.rawValue, privacy: .public) frame=(\(frame.minX, privacy: .public), \(frame.minY, privacy: .public), \(frame.width, privacy: .public), \(frame.height, privacy: .public)) start=(\(drag.startLocation.x, privacy: .public), \(drag.startLocation.y, privacy: .public))")
        scheduleReorderWatchdog(for: item.id)
    }

    private func updateItemReorder(in category: ItemCategory, with drag: FormulaRowReorderValue) {
        guard let activeItemID,
              let globalLocation = activeReorderLocation(for: drag) else {
            Self.reorderLog.error("update failed missing active location active=\(activeItemID?.uuidString ?? "nil", privacy: .public) category=\(category.rawValue, privacy: .public)")
            return
        }
        withTransaction(Transaction(animation: nil)) {
            activeItemLocation = globalLocation
        }
        guard let currentItems = previewItemsByCategory[category],
              let movingItem = currentItems.first(where: { $0.id == activeItemID }) else {
            Self.reorderLog.error("update failed active=\(activeItemID.uuidString, privacy: .public) category=\(category.rawValue, privacy: .public) previewCount=\(previewItemsByCategory[category]?.count ?? -1, privacy: .public)")
            return
        }

        var remainingItems = currentItems.filter { $0.id != activeItemID }
        let destination = insertionIndex(for: activeItemCenterY(for: drag), among: remainingItems)
        remainingItems.insert(movingItem, at: destination)

        guard remainingItems.map(\.id) != currentItems.map(\.id) else { return }
        withAnimation(ReorderMotion.animation) {
            previewItemsByCategory[category] = remainingItems
        }
        Self.reorderLog.info("move active=\(activeItemID.uuidString, privacy: .public) category=\(category.rawValue, privacy: .public) destination=\(destination, privacy: .public) order=\(remainingItems.map { $0.name }.joined(separator: ","), privacy: .public)")
    }

    private func reorderLocation(for item: RecipeItem, localLocation: CGPoint) -> CGPoint? {
        reorderLocation(for: item.id, localLocation: localLocation)
    }

    private func reorderLocation(for itemID: UUID, localLocation: CGPoint) -> CGPoint? {
        guard let frame = itemRowFrames[itemID] else { return nil }
        return CGPoint(x: frame.minX + localLocation.x, y: frame.minY + localLocation.y)
    }

    private func initialReorderLocation(for drag: FormulaRowReorderValue) -> CGPoint? {
        guard let activeItemFrame else { return nil }
        return CGPoint(
            x: activeItemFrame.minX + drag.startLocation.x,
            y: activeItemFrame.minY + drag.startLocation.y
        )
    }

    private func activeReorderLocation(for drag: FormulaRowReorderValue) -> CGPoint? {
        guard let initialLocation = initialReorderLocation(for: drag) else { return nil }
        return CGPoint(
            x: initialLocation.x + drag.translation.width,
            y: initialLocation.y + drag.translation.height
        )
    }

    private func insertionIndex(for yLocation: CGFloat, among remainingItems: [RecipeItem]) -> Int {
        remainingItems.firstIndex { item in
            guard let frame = itemRowFrames[item.id] else { return false }
            return yLocation < frame.midY
        } ?? remainingItems.count
    }

    private func activeItemCenterY(for drag: FormulaRowReorderValue) -> CGFloat {
        guard let activeItemFrame else { return drag.location.y }
        return activeItemFrame.midY + drag.translation.height
    }

    private func commitItemReorder() {
        Self.reorderLog.info("commit active=\(activeItemID?.uuidString ?? "nil", privacy: .public) category=\(activeItemCategory?.rawValue ?? "nil", privacy: .public)")
        if let activeItemCategory,
           let previewItems = previewItemsByCategory[activeItemCategory],
           previewItems.map(\.id) != items(for: activeItemCategory).map(\.id) {
            store.reorderItems(in: activeItemCategory, orderedIDs: previewItems.map(\.id))
        }
        cancelItemReorder()
    }

    private func cancelItemReorder() {
        withAnimation(ReorderMotion.animation) {
            resetItemReorderState(keepEditingMode: true, reason: "gesture cancel")
        }
    }

    private func resetItemReorderState(keepEditingMode: Bool = false, reason: String) {
        Self.reorderLog.info("reset reason=\(reason, privacy: .public) keepEditing=\(keepEditingMode, privacy: .public) active=\(activeItemID?.uuidString ?? "nil", privacy: .public) category=\(activeItemCategory?.rawValue ?? "nil", privacy: .public) previewCategories=\(previewItemsByCategory.count, privacy: .public)")
        activeItemID = nil
        activeItemCategory = nil
        activeItemFrame = nil
        activeItemLocation = nil
        activeItemGrabOffset = .zero
        previewItemsByCategory = [:]
        setHistorySwipeSuppressed(false)
        if !keepEditingMode {
            isItemListEditing = false
        }
    }

    private func removeItemFromList(_ item: RecipeItem) {
        withAnimation(ReorderMotion.animation) {
            store.removeItem(item)
        }
    }

    private func enterItemListEditing() {
        withAnimation(ReorderMotion.animation) {
            isItemListEditing = true
        }
    }

    private func presentItemEditor(_ item: RecipeItem) {
        Self.reorderLog.info("present editor item=\(item.id.uuidString, privacy: .public) active=\(activeItemID?.uuidString ?? "nil", privacy: .public) editing=\(isItemListEditing, privacy: .public)")
        editingItemID = item.id
    }

    private func scheduleReorderWatchdog(for itemID: UUID) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard activeItemID == itemID else { return }
            Self.reorderLog.fault("watchdog resetting stuck reorder item=\(itemID.uuidString, privacy: .public) category=\(activeItemCategory?.rawValue ?? "nil", privacy: .public) location=(\(activeItemLocation?.x ?? -1, privacy: .public), \(activeItemLocation?.y ?? -1, privacy: .public))")
            withAnimation(ReorderMotion.animation) {
                resetItemReorderState(keepEditingMode: true, reason: "watchdog stuck active drag")
            }
        }
    }

    @ViewBuilder
    private var itemEditorSheet: some View {
        if let editingItem {
            ItemEditorSheetView(item: editingItem) {
                editingItemID = nil
            } onContentHeightChange: { height in
                itemEditorMeasuredContentHeight = height
            }
            .id(editingItem.id)
            .environmentObject(store)
            .presentationDetents([.height(itemEditorSheetHeight(for: editingItem))])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.brandBackground)
            .onAppear {
                itemEditorMeasuredContentHeight = 0
            }
            .onChange(of: editingItem.id) { _, _ in
                itemEditorMeasuredContentHeight = 0
            }
        } else {
            BakingEmptyState(title: BakingTerms.formulaItemMissing, systemImage: "exclamationmark.triangle")
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.brandBackground)
        }
    }

    private var editingItem: RecipeItem? {
        guard let editingItemID else { return nil }
        return store.items.first { $0.id == editingItemID }
    }

    private func itemEditorSheetHeight(for item: RecipeItem) -> CGFloat {
        BakingPopupSheetMetrics.detentHeight(
            for: itemEditorSheetSize(for: item),
            measuredContentHeight: itemEditorMeasuredContentHeight,
            screenHeight: itemEditorScreenHeight
        )
    }

    private func itemEditorSheetSize(for item: RecipeItem) -> BakingPopupSheetSize {
        item.category == .starter || item.tag == .egg ? .expanded : .compact
    }

    private var itemEditorScreenHeight: CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first
    }

    private func requestDeleteItem(_ item: RecipeItem) {
        guard canRemove(item) else { return }
        isItemListEditing = true
        pendingDeleteItem = item
        showingDeleteConfirmation = true
    }

    private func confirmPendingDelete() {
        guard let pendingDeleteItem else {
            cancelPendingDelete()
            return
        }
        showingDeleteConfirmation = false
        removeItemFromList(pendingDeleteItem)
        self.pendingDeleteItem = nil
    }

    private func cancelPendingDelete() {
        showingDeleteConfirmation = false
        pendingDeleteItem = nil
    }

    private func closeItemListEditingIfNeeded() {
        guard isItemListEditing else { return }
        withAnimation(ReorderMotion.animation) {
            resetItemReorderState(reason: "tap outside edit mode")
        }
        suppressNextItemTap = false
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
                        if menu.reservesLeadingIconSlot {
                            BakingDropdownRow(title: item.title, isSelected: item.isSelected) {
                                if let icon = item.icon {
                                    BakingIconView(icon: icon, size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                                } else {
                                    Color.clear
                                }
                            }
                        } else {
                            BakingDropdownTextRow(title: item.title, isSelected: item.isSelected)
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
        .accessibilityLabel(BakingTerms.formulaBakerPercentageInfoAccessibility)
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
                    .background(BakingSurfaceTheme.theme(for: .selected).background)
                    .clipShape(Circle())

                Text(BakingTerms.formulaBakerPercentageInfoTitle)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
            }

            Text(BakingTerms.formulaBakerPercentageInfoBody)
                .font(BakingTypography.appSecondaryText)
                .foregroundStyle(Color.brandSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .bakingPopoverSurface(width: BakingComponentMetrics.popoverCompactWidth)
    }
}

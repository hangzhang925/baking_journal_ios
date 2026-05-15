import SwiftUI
import UniformTypeIdentifiers

struct FormulaView: View {
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var expandedItemId: UUID?
    @State private var draggedItemID: UUID?
    @State private var exportDocument = RecipeBackupDocument(data: Data())
    @State private var fileError: String?
    @State private var importingRecipe = false
    @State private var previewOpen = false
    @State private var showingExporter = false
    @State private var selectedTemplate: RecipeStore.RecipeTemplate = .toast
    @State private var showingTemplateOptions = false
    @StateObject private var dropdownPresenter = DropdownPresenter()

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
        }
        .coordinateSpace(name: "formulaDropdownSpace")
        .environmentObject(dropdownPresenter)
        .navigationTitle("配方编辑")
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.saveCurrentRecipe()
                        } label: {
                            Label("保存到我的配方", systemImage: "bookmark")
                        }

                        Button {
                            exportRecipe()
                        } label: {
                            Label("导出 JSON", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            importingRecipe = true
                        } label: {
                            Label("导入 JSON", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("更多")
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
        .onAppear {
            selectedTemplate = inferredTemplate
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
                Button("完成") {
                    dismissActiveKeyboard()
                }
            }
        }
    }

    private var recipeHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    showingTemplateOptions = true
                } label: {
                    BakingDropdownTrigger(title: selectedTemplate.label)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingTemplateOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    BakingDropdownPopover(width: 166) {
                        ForEach(RecipeStore.RecipeTemplate.allCases) { template in
                            Button {
                                selectedTemplate = template
                                store.applyTemplate(template)
                                expandedItemId = nil
                                showingTemplateOptions = false
                            } label: {
                                BakingDropdownRow(title: template.label, isSelected: selectedTemplate == template) {
                                    BakingIconView(icon: .recipe, size: 16, color: .brandPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                headerActionButton(icon: "doc.text.magnifyingglass", label: "预览流程") {
                    previewOpen = true
                }
            }

            TextField("配方名称", text: $store.recipeName)
                .font(.title3.weight(.semibold))
                .textFieldStyle(.plain)
                .padding(.top, 1)

            CompactRecipeMetrics(summary: store.summary)
        }
        .padding(10)
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func categorySection(_ category: ItemCategory) -> some View {
        VStack(spacing: 6) {
            let categoryItems = items(for: category)
            HStack {
                Text(category.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
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
                let flourItemCount = store.items.filter { $0.category == .flour }.count
                ForEach(categoryItems) { item in
                    let canRemove = item.category != .flour || flourItemCount > 1
                    DraggableFormulaRow(
                        item: item,
                        draggedItemID: $draggedItemID
                    ) {
                        SwipeToDeleteRow(canDelete: canRemove) {
                            store.removeItem(item)
                        } content: {
                            FormulaItemCard(
                                item: item,
                                isExpanded: expandedItemId == item.id,
                                canRemove: canRemove
                            ) {
                                guard item.requiresAdvancedFormulaEditor else { return }
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    expandedItemId = expandedItemId == item.id ? nil : item.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, -4)
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

    private func headerActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 34, height: 34)
                .background(Color.brandPrimary.opacity(0.10))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var inferredTemplate: RecipeStore.RecipeTemplate {
        let name = store.recipeName
        if name.contains("戚风") {
            return .chiffon
        }
        if name.contains("欧包") {
            return .countryBread
        }
        return .toast
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
                                BakingIconView(icon: icon, size: 16, color: .brandPrimary)
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

private struct DraggableFormulaRow<Content: View>: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    @Binding var draggedItemID: UUID?
    @ViewBuilder let content: () -> Content
    @State private var isDropTargeted = false

    var body: some View {
        content()
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDropTargeted ? Color.brandPrimary.opacity(0.34) : .clear, lineWidth: 1.2)
            }
            .scaleEffect(isDropTargeted ? 1.01 : 1)
            .opacity(draggedItemID == item.id ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.16), value: isDropTargeted)
            .dropDestination(for: String.self) { items, _ in
                guard let raw = items.first,
                      let draggedId = UUID(uuidString: raw) else { return false }
                store.moveItem(draggedId, before: item.id)
                draggedItemID = nil
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.16)) {
                    isDropTargeted = targeted && draggedItemID != item.id
                }
            }
            .onDrag {
                draggedItemID = item.id
                return NSItemProvider(object: item.id.uuidString as NSString)
            }
    }
}

struct RecipeBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct AddItemControl: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    let category: ItemCategory
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Group {
            switch category {
            case .flour:
                Button {
                    dropdownPresenter.present(
                        ActiveDropdownMenu(
                            frame: triggerFrame,
                            width: 170,
                            alignment: .trailing,
                            items: flourMenuItems
                        )
                    )
                } label: {
                    plusIcon
                }

            case .basic:
                Button {
                    dropdownPresenter.present(
                        ActiveDropdownMenu(
                            frame: triggerFrame,
                            width: 158,
                            alignment: .trailing,
                            items: basicMenuItems
                        )
                    )
                } label: {
                    plusIcon
                }

            default:
                Button {
                    store.addItem(category: category)
                } label: {
                    plusIcon
                }
            }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("添加\(category.label)")
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        triggerFrame = proxy.frame(in: .named("formulaDropdownSpace"))
                    }
                    .onChange(of: proxy.frame(in: .named("formulaDropdownSpace"))) { _, newValue in
                        triggerFrame = newValue
                    }
            }
        )
    }

    private var plusIcon: some View {
        Image(systemName: "plus.circle.fill")
            .imageScale(.medium)
            .foregroundStyle(Color.brandPrimary)
    }

    private func icon(for tag: ItemTag) -> BakingIcon {
        switch tag {
        case .water: .water
        case .salt: .salt
        case .butter: .butter
        case .yeast: .yeast
        case .egg: .egg
        case .sugar: .sugar
        case .flour: .flour
        case .starter: .starter
        case .other: .other
        }
    }

    private var flourMenuItems: [DropdownMenuItem] {
        [
            DropdownMenuItem(title: "面粉", icon: .flour) {
                store.addItem(category: .flour)
            },
            DropdownMenuItem(title: "种面", icon: .starter) {
                store.addItem(category: .starter)
            }
        ]
    }

    private var basicMenuItems: [DropdownMenuItem] {
        [ItemTag.water, .salt, .butter, .yeast, .egg, .sugar, .other].map { tag in
            DropdownMenuItem(title: tag.label, icon: icon(for: tag)) {
                store.addItem(category: tag == .other ? .other : .basic, tag: tag)
            }
        }
    }
}

private struct SwipeToDeleteRow<Content: View>: View {
    let canDelete: Bool
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0

    private let actionWidth: CGFloat = 58
    private let buttonSize = CGSize(width: 52, height: 52)

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && offset != 0 {
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        offset = 0
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: buttonSize.width, height: buttonSize.height)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("删除")
                .padding(.trailing, 3)
            }

            content()
                .offset(x: offset)
                .contentShape(Rectangle())
                .allowsHitTesting(offset == 0)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 14, coordinateSpace: .local)
                .onChanged { value in
                    guard canDelete, abs(value.translation.width) > abs(value.translation.height) else { return }
                    let nextOffset: CGFloat
                    if offset == 0 {
                        nextOffset = value.translation.width
                    } else {
                        nextOffset = value.translation.width - actionWidth
                    }
                    offset = min(0, max(-actionWidth, nextOffset))
                }
                .onEnded { value in
                    guard canDelete else { return }
                    let projectedOffset: CGFloat
                    if offset == 0 {
                        projectedOffset = value.translation.width
                    } else {
                        projectedOffset = value.translation.width - actionWidth
                    }

                    withAnimation(.easeInOut(duration: 0.18)) {
                        if projectedOffset < -actionWidth / 2 {
                            offset = -actionWidth
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            guard offset != 0 else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                offset = 0
            }
        }
    }
}

private struct FormulaItemCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let isExpanded: Bool
    let canRemove: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Button {
                    if currentItem.requiresAdvancedFormulaEditor {
                        toggle()
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottomTrailing) {
                            BakingIconView(icon: BakingIcon.material(for: currentItem), size: 22, color: itemTint)
                                .frame(width: 30, height: 30)
                                .background(iconBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                            if currentItem.requiresAdvancedFormulaEditor {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.brandPrimary)
                                    .frame(width: 14, height: 14)
                                    .background(Color.brandSurface)
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                    .offset(x: 3, y: 3)
                            }
                        }
                        .frame(width: 30, height: 30)

                        if let iconCaptionText {
                            Text(iconCaptionText)
                                .font(.caption2)
                                .foregroundStyle(Color.brandSecondaryText)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 44)
                }
                .buttonStyle(.plain)
                .disabled(!currentItem.requiresAdvancedFormulaEditor)
                .accessibilityLabel(currentItem.requiresAdvancedFormulaEditor ? (isExpanded ? "收起材料设置" : "展开材料设置") : currentItem.name)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        InlineNameField(
                            text: itemTextBinding(\.name),
                            placeholder: currentItem.category.label,
                            font: .callout.weight(.semibold),
                            isWaterStyle: isPureWaterItem
                        )
                        if hasWaterContent {
                            Image(systemName: "drop.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.waterText.opacity(0.88))
                                .frame(width: 20, height: 18)
                                .background(Color.waterSurface.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        if !hasWaterContent {
                            Color.clear
                                .frame(width: 20, height: 18)
                        }
                    }
                    if let detailText {
                        Text(detailText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0)

                HStack(alignment: .top, spacing: 6) {
                    if currentItem.tag == .egg && isWholeEgg {
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(percent, precision: 0),
                            unit: "%",
                            font: .callout,
                            color: isPureWaterItem ? .waterText : .brandPrimary,
                            totalWidth: 58,
                            isWaterStyle: isPureWaterItem
                        )
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(currentItem.weight, precision: 0),
                            unit: "g",
                            font: .callout,
                            color: isPureWaterItem ? .waterText : .primary,
                            totalWidth: 76,
                            isWaterStyle: isPureWaterItem
                        )
                    } else {
                        if currentItem.category != .flour {
                            InlineNumberField(value: Binding(
                                get: { percent },
                                set: { store.updateItemPercent(currentItem, percent: $0) }
                            ), unit: "%", font: .callout, color: isPureWaterItem ? .waterText : .brandPrimary, fieldWidth: 30, totalWidth: 58, isWaterStyle: isPureWaterItem)
                        } else {
                            Color.clear
                                .frame(width: 58, height: 1)
                        }

                        InlineNumberField(value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        ), unit: "g", font: .callout, color: isPureWaterItem ? .waterText : .primary, fieldWidth: 48, totalWidth: 76, isWaterStyle: isPureWaterItem)
                    }
                }
                .layoutPriority(2)
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            if isExpanded && currentItem.requiresAdvancedFormulaEditor {
                Divider().padding(.horizontal, 12)

                if currentItem.category == .starter {
                    StarterMiniRecipeEditor(
                        item: currentItem,
                        canRemove: canRemove
                    )
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                } else if currentItem.tag == .egg {
                    EggMiniRecipeEditor(
                        item: currentItem,
                        canRemove: canRemove,
                        name: itemTextBinding(\.name)
                    )
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                } else {
                    VStack(spacing: 8) {
                        CompactTextRow(title: "名称", text: itemTextBinding(\.name))

                        itemSpecificEditor

                        if canRemove {
                            Button(role: .destructive) {
                                store.removeItem(currentItem)
                            } label: {
                                Label("删除材料", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(cardStroke, lineWidth: 0.6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder private var itemSpecificEditor: some View {
        if currentItem.tag == .yeast {
            CompactMenuRow(
                title: "酵母类型",
                value: currentItem.yeastType ?? "干酵母",
                options: RecipeStore.yeastOptions
            ) { value in
                var next = currentItem
                next.yeastType = value
                next.name = value
                store.updateItem(next)
            }
        }
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var hasWaterContent: Bool {
        store.hasWaterContent(currentItem)
    }

    private var isPureWaterItem: Bool {
        currentItem.tag == .water
    }

    private var itemTint: Color {
        currentItem.materialPalette.tint
    }

    private var iconBackground: Color {
        currentItem.materialPalette.iconSurface
    }

    private var cardBackground: Color {
        currentItem.materialPalette.surface
    }

    private var cardStroke: Color {
        currentItem.materialPalette.stroke
    }

    private var percent: Double {
        store.summary.doughWeight > 0 ? currentItem.weight / store.summary.doughWeight * 100 : 0
    }

    private var detailText: String? {
        if currentItem.category == .starter {
            return "面粉 \(BakingFormat.weight(store.flourContribution(currentItem))) / 水 \(BakingFormat.weight(store.starterBaseWater(currentItem)))"
        }
        if currentItem.tag == .egg {
            return nil
        }
        return nil
    }

    private var iconCaptionText: String? {
        if currentItem.category == .starter {
            return "种面"
        }
        return currentItem.tag.label
    }

    private var isWholeEgg: Bool {
        (currentItem.eggType ?? "鸡蛋") == "鸡蛋"
    }

    private func itemTextBinding(_ keyPath: WritableKeyPath<RecipeItem, String>) -> Binding<String> {
        Binding(
            get: { currentItem[keyPath: keyPath] },
            set: {
                var next = currentItem
                next[keyPath: keyPath] = $0
                store.updateItem(next)
            }
        )
    }

    private func itemNumberBinding(_ keyPath: WritableKeyPath<RecipeItem, Double?>, fallback: Double) -> Binding<Double> {
        Binding(
            get: { currentItem[keyPath: keyPath] ?? fallback },
            set: {
                var next = currentItem
                next[keyPath: keyPath] = max(0, $0)
                store.updateItem(next)
            }
        )
    }

    private func updateEgg(count: Double, unitWeight: Double) {
        var next = currentItem
        next.eggCount = max(0, count)
        next.eggUnitWeight = max(0, unitWeight)
        next.weight = (next.eggCount ?? 0) * (next.eggUnitWeight ?? 45)
        store.updateItem(next)
    }
}

private struct StarterMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StarterTypePicker(
                    selection: Binding(
                        get: { currentStarterType },
                        set: { store.applyStarterType($0, to: currentItem) }
                    )
                )

                CompactSummaryPill(title: "总重", value: BakingFormat.number(currentItem.weight, precision: 0) + "g")
                CompactSummaryPill(title: "含水", value: "\(BakingFormat.number(starterHydration, precision: 0))%", isWater: true)

                Spacer(minLength: 0)
            }

            StarterPartsRow(
                flour: Binding(
                    get: { store.flourContribution(currentItem) },
                    set: { store.updateStarterParts(currentItem, flour: $0) }
                ),
                water: Binding(
                    get: { store.starterBaseWater(currentItem) },
                    set: { store.updateStarterParts(currentItem, water: $0) }
                )
            )

            StarterTapAddInRow(
                title: "酵母",
                enabled: Binding(
                    get: { currentItem.starterYeastWeight != nil },
                    set: {
                        store.updateStarterYeast(currentItem, weight: $0 ? max(1, currentItem.starterYeastWeight ?? 1) : nil)
                    }
                ),
                value: Binding(
                    get: { currentItem.starterYeastWeight ?? 1 },
                    set: { store.updateStarterYeast(currentItem, weight: $0) }
                )
            )

            StarterTapAddInRow(
                title: "鸡蛋",
                enabled: Binding(
                    get: { currentItem.starterEggCount != nil },
                    set: {
                        store.updateStarterEgg(currentItem, count: $0 ? 1 : nil)
                    }
                ),
                value: Binding(
                    get: { store.starterEggWeight(currentItem) },
                    set: { store.updateStarterEgg(currentItem, count: $0 > 0 ? 1 : 0, unitWeight: $0) }
                ),
                isWaterBearing: currentItem.starterEggCount != nil,
                waterText: BakingFormat.weight(store.starterEggWater(currentItem))
            )
        }
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var currentStarterType: String {
        currentItem.starterType ?? "鲁邦种"
    }

    private var starterHydration: Double {
        let flour = store.flourContribution(currentItem)
        guard flour > 0 else { return 0 }
        return store.starterBaseWater(currentItem) / flour * 100
    }
}

private struct StarterPartsRow: View {
    @Binding var flour: Double
    @Binding var water: Double

    var body: some View {
        HStack(spacing: 8) {
            StarterPartEntry(title: "面粉", value: $flour)
            StarterPartEntry(title: "水", value: $water, isWater: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StarterPartEntry: View {
    let title: String
    @Binding var value: Double
    var isWater = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isWater ? Color.waterText.opacity(0.86) : Color.brandText)
                .lineLimit(1)

            NumericInlineTextField(
                value: $value,
                fractionDigits: 0...0,
                color: UIColor(isWater ? Color.waterText : Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold),
                adjustsFontSizeToFitWidth: false
            )
            .frame(width: 48)

            Text("g")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 136, alignment: .leading)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandPrimary.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isWater ? Color.brandSea.opacity(0.16) : Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
        }
    }
}

private struct StarterTapAddInRow: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var value: Double
    var isWaterBearing = false
    var waterText: String?

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    enabled.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                    Text(title)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(enabled ? Color.brandPrimary : Color.brandSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background((enabled ? Color.brandPrimary.opacity(0.08) : Color.brandBackground.opacity(0.5)))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            if enabled {
                InlineNumberField(
                    value: $value,
                    unit: "g",
                    font: .caption,
                    color: isWaterBearing ? .waterText : .primary,
                    fieldWidth: 26,
                    totalWidth: 58,
                    isWaterStyle: isWaterBearing,
                    height: 32
                )

                if isWaterBearing, let waterText {
                    CompactInfoBadge(icon: "drop.fill", text: waterText, isWater: true, compact: true)
                }

                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brandBackground.opacity(enabled ? 0.68 : 0.52))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(enabled ? 1 : 0.85)
    }
}

private struct StarterTypePicker: View {
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    @Binding var selection: String
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Button {
            dropdownPresenter.present(
                ActiveDropdownMenu(
                    frame: triggerFrame,
                    width: 156,
                    alignment: .leading,
                    items: RecipeStore.starterOptions.map { option in
                        DropdownMenuItem(title: option, icon: .starter, isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(title: selection)
        }
        .buttonStyle(.plain)
        .zIndex(3)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        triggerFrame = proxy.frame(in: .named("formulaDropdownSpace"))
                    }
                    .onChange(of: proxy.frame(in: .named("formulaDropdownSpace"))) { _, newValue in
                        triggerFrame = newValue
                    }
            }
        )
    }
}

private struct EggMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool
    @Binding var name: String

    private let wholeEggUnitWeight = 50.0
    private let eggTypeWaterContent: [String: Double] = [
        "鸡蛋": 75,
        "全蛋液": 75,
        "蛋黄": 48,
        "蛋白": 88
    ]

    var body: some View {
        HStack(spacing: 10) {
            EggTypePicker(
                selection: Binding(
                    get: { currentEggType },
                    set: { updateEggType($0) }
                )
            )

            if isWholeEgg {
                EggCountSelector(
                    count: Binding(
                        get: { max(0, currentItem.eggCount ?? wholeEggCountFallback) },
                        set: { updateWholeEggCount($0) }
                    )
                )

                Spacer(minLength: 0)

                CompactInfoBadge(icon: "scalemass", text: BakingFormat.weight(currentItem.weight))
                CompactInfoBadge(icon: "drop.fill", text: BakingFormat.weight(store.waterContribution(currentItem)), isWater: true)
            } else {
                Spacer(minLength: 0)

                InlineNumberField(
                    value: Binding(
                        get: { currentItem.weight },
                        set: { updateLiquidEggWeight($0) }
                    ),
                    unit: "g",
                    font: .subheadline,
                    color: .primary,
                    fieldWidth: 42,
                    totalWidth: 78,
                    height: 36
                )

                HStack(spacing: 5) {
                    Image(systemName: "drop.fill")
                        .font(.caption2.weight(.semibold))
                    Text(BakingFormat.weight(store.waterContribution(currentItem)))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                .foregroundStyle(Color.waterText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 92, alignment: .leading)
                .background(Color.waterSurfaceStrong.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private func updateEgg(count: Double, unitWeight: Double) {
        var next = currentItem
        next.eggCount = max(0, count)
        next.eggUnitWeight = max(0, unitWeight)
        next.weight = (next.eggCount ?? 0) * (next.eggUnitWeight ?? 45)
        store.updateItem(next)
    }

    private func updateWholeEggCount(_ count: Double) {
        var next = currentItem
        let roundedCount = max(0, count.rounded())
        next.eggType = "鸡蛋"
        next.waterContentPct = eggTypeWaterContent["鸡蛋"]
        next.eggCount = roundedCount
        next.eggUnitWeight = wholeEggUnitWeight
        next.weight = roundedCount * wholeEggUnitWeight
        store.updateItem(next)
    }

    private var displayWaterPercent: Double {
        currentItem.waterContentPct ?? 75
    }

    private var currentEggType: String {
        currentItem.eggType ?? "鸡蛋"
    }

    private var isWholeEgg: Bool {
        currentEggType == "鸡蛋"
    }

    private var wholeEggCountFallback: Double {
        let unitWeight = currentItem.eggUnitWeight ?? wholeEggUnitWeight
        guard unitWeight > 0 else { return 1 }
        return max(1, (currentItem.weight / unitWeight).rounded())
    }

    private func updateLiquidEggWeight(_ weight: Double) {
        var next = currentItem
        next.weight = max(0, weight)
        next.eggCount = nil
        next.eggUnitWeight = nil
        store.updateItem(next)
    }

    private func updateEggType(_ type: String) {
        var next = currentItem
        next.eggType = type
        next.name = type
        next.waterContentPct = eggTypeWaterContent[type] ?? 75

        if type == "鸡蛋" {
            let count = next.eggCount ?? max(1, (next.weight / wholeEggUnitWeight).rounded())
            next.eggCount = count
            next.eggUnitWeight = wholeEggUnitWeight
            next.weight = count * wholeEggUnitWeight
        } else {
            next.eggCount = nil
            next.eggUnitWeight = nil
            if next.weight == 0 {
                next.weight = 50
            }
        }

        store.updateItem(next)
    }
}

private struct EggTypePicker: View {
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    @Binding var selection: String
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Button {
            dropdownPresenter.present(
                ActiveDropdownMenu(
                    frame: triggerFrame,
                    width: 148,
                    alignment: .leading,
                    items: RecipeStore.eggOptions.map { option in
                        DropdownMenuItem(title: option, isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(title: selection)
        }
        .buttonStyle(.plain)
        .zIndex(3)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        triggerFrame = proxy.frame(in: .named("formulaDropdownSpace"))
                    }
                    .onChange(of: proxy.frame(in: .named("formulaDropdownSpace"))) { _, newValue in
                        triggerFrame = newValue
                    }
            }
        )
    }
}

private struct WholeEggCountRow: View {
    @Binding var count: Double
    let totalWeightText: String
    let waterText: String

    var body: some View {
        HStack(spacing: 10) {
            EggCountSelector(
                count: Binding(
                    get: { count },
                    set: { count = max(0, $0.rounded()) }
                )
            )

            Spacer(minLength: 0)

            CompactInfoBadge(icon: "scalemass", text: totalWeightText)
            CompactInfoBadge(icon: "drop.fill", text: waterText, isWater: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct EggCountSelector: View {
    @Binding var count: Double
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 0) {
                Text("\(Int(count.rounded()))")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.brandText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 44, alignment: .center)
            .background(Color.brandPrimary.opacity(0.075))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            EggCountWheelPopover(count: $count)
        }
    }
}

private struct EggCountWheelPopover: View {
    @Binding var count: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }

            Picker("鸡蛋个数", selection: Binding(
                get: { Int(max(1, count.rounded())) },
                set: { count = Double($0) }
            )) {
                ForEach(1...10, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 88, height: 120)
        }
        .padding(12)
        .presentationCompactAdaptation(.popover)
        .background(Color.brandSurface)
    }
}

private struct LiquidEggWeightRow: View {
    @Binding var weight: Double
    let waterText: String

    var body: some View {
        HStack(spacing: 10) {
            Text("克数")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            InlineNumberField(
                value: $weight,
                unit: "g",
                font: .subheadline,
                color: .primary,
                fieldWidth: 42,
                totalWidth: 78,
                height: 36
            )

            HStack(spacing: 5) {
                Image(systemName: "drop.fill")
                    .font(.caption2.weight(.semibold))
                Text(waterText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            .foregroundStyle(Color.waterText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minWidth: 92, alignment: .leading)
            .background(Color.waterSurfaceStrong.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct RectangularDropdownTrigger: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.brandText)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(width: 96, alignment: .leading)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
        }
    }
}

private struct CompactInfoBadge: View {
    let icon: String
    let text: String
    var isWater = false
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font((compact ? Font.caption2 : Font.caption2).weight(.semibold))
            Text(text)
                .font((compact ? Font.caption : Font.subheadline).monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isWater ? Color.waterText : Color.brandText)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .frame(minWidth: compact ? 68 : 84)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandPrimary.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

@MainActor
private final class DropdownPresenter: ObservableObject {
    @Published var menu: ActiveDropdownMenu?

    func present(_ menu: ActiveDropdownMenu) {
        withAnimation(.easeInOut(duration: 0.18)) {
            self.menu = menu
        }
    }

    func dismiss() {
        guard menu != nil else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            menu = nil
        }
    }
}

private struct ActiveDropdownMenu: Identifiable {
    let id = UUID()
    let frame: CGRect
    let width: CGFloat
    let alignment: DropdownMenuAlignment
    let items: [DropdownMenuItem]
}

private enum DropdownMenuAlignment {
    case leading
    case trailing
}

private struct DropdownMenuItem: Identifiable {
    let id = UUID()
    let title: String
    var icon: BakingIcon? = nil
    var isSelected = false
    let action: () -> Void
}

private struct StarterMetricPill: View {
    let title: String
    let value: String
    var isWater = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(isWater ? Color.waterText.opacity(0.75) : .secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(isWater ? Color.waterText : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.55) : Color.brandBackground.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CompactSummaryRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            content()
        }
    }
}

private struct CompactSummaryPill: View {
    let title: String
    let value: String
    var isWater = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isWater ? Color.waterText.opacity(0.82) : Color.brandSecondaryText)
            Text(value)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(isWater ? Color.waterText : Color.brandText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StarterIngredientField: View {
    let title: String
    @Binding var value: Double
    var unit = "g"
    var isWater = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 4)
            InlineNumberField(value: $value, unit: unit, font: .subheadline, color: isWater ? .waterText : .primary, isWaterStyle: isWater)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StarterAddInRow: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var value: Double
    var isWaterBearing = false
    var waterText: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Toggle("", isOn: $enabled)
                .toggleStyle(.switch)
                .labelsHidden()

            Spacer(minLength: 4)
            if enabled {
                if isWaterBearing, let waterText {
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                        Text(waterText)
                    }
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.brandSurface.opacity(0.75))
                    .clipShape(Capsule())
                }
                InlineNumberField(value: $value, unit: "g", font: .subheadline, color: isWaterBearing ? .waterText : .primary, isWaterStyle: isWaterBearing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 52)
        .background(Color.brandBackground.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CompactToggleConfigRow<Content: View>: View {
    let title: String
    @Binding var enabled: Bool
    var isWaterBearing = false
    var waterText: String?
    var summary: String?
    @Binding var showingConfig: Bool
    @ViewBuilder let config: () -> Content

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Toggle("", isOn: $enabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: enabled) { _, newValue in
                        if !newValue {
                            showingConfig = false
                        } else if summary != nil {
                            showingConfig = true
                        }
                    }

                Spacer(minLength: 4)

                if enabled, let summary {
                    Text(summary)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(isWaterBearing ? Color.waterText : Color.brandText)
                }

                if enabled, isWaterBearing, let waterText {
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                        Text(waterText)
                    }
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.waterText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.waterSurfaceStrong.opacity(0.48))
                    .clipShape(Capsule())
                }

                if enabled {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showingConfig.toggle()
                        }
                    } label: {
                        Image(systemName: showingConfig ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isWaterBearing && enabled ? Color.waterSurface.opacity(0.72) : Color.brandBackground.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if enabled && showingConfig {
                config()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct CompactTextRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
            Spacer()
            TextField(title, text: $text)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

struct CompactNumberRow: View {
    let title: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
            Spacer()
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                .frame(minWidth: 70)
            Text(unit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct InlineNameField: View {
    @Binding var text: String
    let placeholder: String
    var font: Font = .body.weight(.semibold)
    var isWaterStyle = false
    var fieldWidth: CGFloat = 132

    var body: some View {
        TextField(placeholder, text: $text)
            .font(font)
            .foregroundStyle(.primary)
            .textFieldStyle(.plain)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(width: fieldWidth, alignment: .leading)
            .background(editableFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
            }
    }

    private var editableFieldBackground: Color {
        isWaterStyle ? Color.waterSurfaceStrong.opacity(0.25) : Color.brandPrimary.opacity(0.075)
    }
}

struct InlineNumberField: View {
    @Binding var value: Double
    let unit: String
    var font: Font = .subheadline
    var color: Color = .primary
    var fieldWidth: CGFloat = 64
    var totalWidth: CGFloat? = nil
    var isWaterStyle = false
    var fractionDigits: ClosedRange<Int> = 0...0
    var height: CGFloat = 40

    var body: some View {
        HStack(spacing: 4) {
            NumericInlineTextField(
                value: $value,
                fractionDigits: fractionDigits,
                color: UIColor(color),
                font: uiFont
            )
                .frame(width: fieldWidth)
            Text(unit)
                .font(font)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(width: totalWidth, alignment: .trailing)
        .frame(height: height)
        .background(editableFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(fieldStroke, lineWidth: 0.5)
        }
    }

    private var editableFieldBackground: Color {
        if isWaterStyle {
            return Color.waterSurfaceStrong.opacity(0.42)
        }
        return Color.brandPrimary.opacity(0.075)
    }

    private var fieldStroke: Color {
        if isWaterStyle {
            return Color.brandSea.opacity(0.16)
        }
        return Color.brandPrimary.opacity(0.10)
    }

    private var uiFont: UIFont {
        switch font {
        case .subheadline:
            return .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        case .callout:
            return .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        default:
            return .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        }
    }
}

struct ReadOnlyInlineMetric: View {
    let value: String
    let unit: String
    var font: Font = .subheadline
    var color: Color = .primary
    var totalWidth: CGFloat? = nil
    var isWaterStyle = false
    var height: CGFloat = 40

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(displayFont)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(unit)
                .font(font)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(width: totalWidth, alignment: .trailing)
        .frame(height: height)
        .background(editableFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(fieldStroke, lineWidth: 0.5)
        }
    }

    private var displayFont: Font {
        switch font {
        case .callout:
            return .callout.monospacedDigit().weight(.semibold)
        default:
            return .subheadline.monospacedDigit().weight(.semibold)
        }
    }

    private var editableFieldBackground: Color {
        if isWaterStyle {
            return Color.waterSurfaceStrong.opacity(0.42)
        }
        return Color.brandPrimary.opacity(0.075)
    }

    private var fieldStroke: Color {
        if isWaterStyle {
            return Color.brandSea.opacity(0.16)
        }
        return Color.brandPrimary.opacity(0.10)
    }
}

private struct NumericInlineTextField: UIViewRepresentable {
    @Binding var value: Double
    let fractionDigits: ClosedRange<Int>
    let color: UIColor
    let font: UIFont
    var adjustsFontSizeToFitWidth = true

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, fractionDigits: fractionDigits)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = fractionDigits.upperBound > 0 ? .decimalPad : .numberPad
        textField.textAlignment = .right
        textField.textColor = color
        textField.font = font
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.text = context.coordinator.formatted(value)
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        textField.minimumFontSize = 12
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.inputAccessoryView = context.coordinator.makeAccessoryToolbar()
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.textColor = color
        uiView.font = font
        uiView.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth

        let next = context.coordinator.formatted(value)
        if !uiView.isFirstResponder, uiView.text != next {
            uiView.text = next
        }
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumericInlineTextField
        private let formatter = NumberFormatter()

        init(value: Binding<Double>, fractionDigits: ClosedRange<Int>) {
            self.parent = NumericInlineTextField(
                value: value,
                fractionDigits: fractionDigits,
                color: .label,
                font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
            )
            super.init()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = false
            formatter.minimumFractionDigits = fractionDigits.lowerBound
            formatter.maximumFractionDigits = fractionDigits.upperBound
            formatter.decimalSeparator = "."
        }

        func makeAccessoryToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let flex = UIBarButtonItem(systemItem: .flexibleSpace)
            let done = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(doneTapped))
            toolbar.items = [flex, done]
            return toolbar
        }

        func formatted(_ value: Double) -> String {
            formatter.string(from: NSNumber(value: value)) ?? "0"
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            moveCaretToEnd(of: textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            textField.text = formatted(parent.value)
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? formatted(parent.value)
            guard let stringRange = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: stringRange, with: string)

            if next.isEmpty {
                parent.value = 0
                textField.text = "0"
                moveCaretToEnd(of: textField)
                return false
            }

            if !isValid(next) {
                return false
            }

            let normalized = normalizedInput(next)

            if normalized != next {
                if let number = Double(normalized) {
                    parent.value = number
                }
                textField.text = normalized
                moveCaretToEnd(of: textField)
                return false
            }

            if let number = Double(normalized) {
                parent.value = number
            }
            return true
        }

        private func isValid(_ text: String) -> Bool {
            let allowed = CharacterSet(charactersIn: "0123456789.")
            guard text.rangeOfCharacter(from: allowed.inverted) == nil else { return false }

            let parts = text.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count <= 2 else { return false }

            if parent.fractionDigits.upperBound == 0 {
                return !text.contains(".")
            }

            if parts.count == 2 {
                return parts[1].count <= parent.fractionDigits.upperBound
            }

            return true
        }

        private func normalizedInput(_ text: String) -> String {
            guard text.count > 1 else { return text }

            if text.hasPrefix("0"), !text.hasPrefix("0.") {
                let trimmed = text.drop { $0 == "0" }
                return trimmed.isEmpty ? "0" : String(trimmed)
            }

            return text
        }

        private func moveCaretToEnd(of textField: UITextField) {
            if let end = textField.endOfDocument as UITextPosition?,
               let range = textField.textRange(from: end, to: end) {
                textField.selectedTextRange = range
            }
        }

        @objc private func doneTapped() {
            dismissActiveKeyboard()
        }
    }
}

struct CompactReadOnlyRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct CompactMenuRow: View {
    let title: String
    let value: String
    let options: [String]
    let onSelect: (String) -> Void
    @State private var showingOptions = false

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
            Spacer()
            Button {
                showingOptions = true
            } label: {
                BakingDropdownTrigger(
                    title: value,
                    tint: .brandPrimary,
                    background: Color.brandPrimary.opacity(0.075)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                BakingDropdownPopover(width: 156) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onSelect(option)
                            showingOptions = false
                        } label: {
                            BakingDropdownRow(title: option, isSelected: option == value) {
                                Color.clear
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private extension RecipeItem {
    var requiresAdvancedFormulaEditor: Bool {
        category == .starter || tag == .egg
    }
}

private struct CompactRecipeMetrics: View {
    let summary: RecipeSummary

    var body: some View {
        HStack(spacing: 8) {
            CompactMetricCell(title: "面团", value: BakingFormat.weight(summary.doughWeight))
            CompactMetricCell(title: "面粉", value: BakingFormat.weight(summary.flourWeight))
            CompactMetricCell(
                title: "含水",
                value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                accent: .waterText,
                background: .waterSurface
            )
        }
    }
}

private struct CompactMetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandPrimary
    var background: Color = Color.brandBackground.opacity(0.75)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

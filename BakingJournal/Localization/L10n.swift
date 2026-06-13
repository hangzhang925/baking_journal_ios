import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    private static let storageKey = "baking-journal-ios:app-language"

    var id: String { rawValue }

    var localizationIdentifier: String {
        rawValue
    }

    var locale: Locale {
        return Locale(identifier: localizationIdentifier)
    }

    var displayName: String {
        switch self {
        case .english:
            return BakingTerms.settingsLanguageEnglishOption
        case .simplifiedChinese:
            return BakingTerms.settingsLanguageSimplifiedChineseOption
        }
    }

    static func saved(in defaults: UserDefaults = .standard) -> AppLanguage {
        guard let rawValue = defaults.string(forKey: storageKey),
              let language = AppLanguage(rawValue: rawValue) else {
            return defaultLanguage()
        }
        return language
    }

    static func defaultLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard let preferredLanguage = preferredLanguages.first else {
            return .english
        }

        let normalizedLanguage = preferredLanguage
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        return normalizedLanguage == "zh" || normalizedLanguage.hasPrefix("zh-")
            ? .simplifiedChinese
            : .english
    }

    func save(in defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.storageKey)
    }
}

final class AppLanguageSettings: ObservableObject {
    @Published private(set) var selectedLanguage: AppLanguage

    init() {
        selectedLanguage = AppLanguage.saved()
    }

    var locale: Locale {
        selectedLanguage.locale
    }

    func select(_ language: AppLanguage) {
        language.save()
        guard language != selectedLanguage else { return }
        selectedLanguage = language
    }
}

enum L10n {
    private static var localizedBundle: Bundle {
        let identifier = AppLanguage.saved().localizationIdentifier
        guard let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    static var locale: Locale {
        AppLanguage.saved().locale
    }

    static func tr(_ key: String, default defaultValue: String) -> String {
        localizedBundle.localizedString(forKey: key, value: defaultValue, table: nil)
    }

    static func format(_ key: String, default defaultValue: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key, default: defaultValue), locale: locale, arguments: arguments)
    }
}

enum BakingTerms {
    static let levainStarter = "鲁邦种"
    static let liquidStarter = "液种"
    static let tangzhongStarter = "汤种"
    static let scaldedStarter = "烫种"
    static let poolishStarter = "波兰种"

    static let dryYeast = "干酵母"
    static let freshYeast = "鲜酵母"
    static let liquidYeast = "酵液"

    static let wholeEgg = "鸡蛋"
    static let beatenEgg = "全蛋液"
    static let yolk = "蛋黄"
    static let white = "蛋白"

    static func starterDisplayName(_ rawValue: String) -> String {
        switch rawValue {
        case levainStarter:
            return L10n.tr("starter.levain", default: levainStarter)
        case liquidStarter:
            return L10n.tr("starter.liquid", default: liquidStarter)
        case tangzhongStarter:
            return L10n.tr("starter.tangzhong", default: tangzhongStarter)
        case scaldedStarter:
            return L10n.tr("starter.scalded", default: scaldedStarter)
        case poolishStarter:
            return L10n.tr("starter.poolish", default: poolishStarter)
        default:
            return rawValue
        }
    }

    static func yeastDisplayName(_ rawValue: String) -> String {
        switch rawValue {
        case dryYeast:
            return L10n.tr("yeast.dry", default: dryYeast)
        case freshYeast:
            return L10n.tr("yeast.fresh", default: freshYeast)
        case liquidYeast:
            return L10n.tr("yeast.liquid", default: liquidYeast)
        default:
            return rawValue
        }
    }

    static func eggDisplayName(_ rawValue: String) -> String {
        switch rawValue {
        case wholeEgg:
            return L10n.tr("egg.whole", default: wholeEgg)
        case beatenEgg:
            return L10n.tr("egg.beaten", default: beatenEgg)
        case yolk:
            return L10n.tr("egg.yolk", default: yolk)
        case white:
            return L10n.tr("egg.white", default: white)
        default:
            return rawValue
        }
    }

    static var flour: String { L10n.tr("ingredient.flour", default: "面粉") }
    static var water: String { L10n.tr("ingredient.water", default: "水") }
    static var salt: String { L10n.tr("ingredient.salt", default: "盐") }
    static var sugar: String { L10n.tr("ingredient.sugar", default: "糖") }
    static var butter: String { L10n.tr("ingredient.butter", default: "黄油") }
    static var cream: String { L10n.tr("ingredient.cream", default: "奶油") }
    static var yeast: String { L10n.tr("ingredient.yeast", default: "酵母") }
    static var egg: String { L10n.tr("ingredient.egg", default: wholeEgg) }
    static var custom: String { L10n.tr("ingredient.custom", default: "其他") }
    static var lowGlutenFlour: String { L10n.tr("ingredient.low_gluten_flour", default: "低粉") }
    static var granulatedSugar: String { L10n.tr("ingredient.granulated_sugar", default: "细砂糖") }
    static var milk: String { L10n.tr("ingredient.milk", default: "牛奶") }
    static var cornOil: String { L10n.tr("ingredient.corn_oil", default: "玉米油") }
    static var highGlutenFlour: String { L10n.tr("ingredient.high_gluten_flour", default: "高粉") }
    static var wholeWheatFlour: String { L10n.tr("ingredient.whole_wheat_flour", default: "全麦粉") }
    static var oliveOil: String { L10n.tr("ingredient.olive_oil", default: "橄榄油") }

    static var defaultRecipeName: String { L10n.tr("recipe.default_new", default: "新配方") }
    static var unnamedRecipe: String { L10n.tr("recipe.unnamed", default: "未命名配方") }
    static var unknownRecipe: String { L10n.tr("recipe.unknown", default: "未知配方") }
    static var recipeNameLabel: String { L10n.tr("recipe.field.name", default: "配方名称") }
    static var recipeNamePromptLabel: String { L10n.tr("recipe.field.name_prompt", default: "名称") }
    static var toastRecipeName: String { L10n.tr("recipe.toast.name", default: "吐司配方") }
    static var chiffonRecipeName: String { L10n.tr("recipe.chiffon.name", default: "蛋糕") }
    static var countryBreadRecipeName: String { L10n.tr("recipe.country_bread.name", default: "欧包配方") }
    static var toastTemplateLabel: String { L10n.tr("recipe.toast.template", default: "日式吐司") }
    static var chiffonTemplateLabel: String { L10n.tr("recipe.chiffon.template", default: "蛋糕") }
    static var countryBreadTemplateLabel: String { L10n.tr("recipe.country_bread.template", default: "欧包") }
    static var recipeKindToast: String { L10n.tr("recipe.kind.toast", default: "吐司") }
    static var recipeKindChiffon: String { L10n.tr("recipe.kind.chiffon", default: "蛋糕") }
    static var recipeKindCountryBread: String { L10n.tr("recipe.kind.country_bread", default: "欧包") }
    static var recipeKindCustom: String { L10n.tr("recipe.kind.custom", default: "配方") }
    static func recipeKindPinnedAccessibility(_ kind: String) -> String {
        L10n.format("recipe.kind.pinned_accessibility", default: "配方类型：%@", kind)
    }
    static var done: String { L10n.tr("common.done", default: "完成") }
    static var save: String { L10n.tr("common.save", default: "保存") }
    static var saved: String { L10n.tr("common.saved", default: "已保存") }
    static var back: String { L10n.tr("common.back", default: "返回") }
    static var share: String { L10n.tr("common.share", default: "分享") }
    static var edit: String { L10n.tr("common.edit", default: "编辑") }
    static var copy: String { L10n.tr("common.copy", default: "复制") }
    static var copiedToClipboard: String { L10n.tr("common.copied_to_clipboard", default: "已复制") }
    static var delete: String { L10n.tr("common.delete", default: "删除") }
    static var cancel: String { L10n.tr("common.cancel", default: "取消") }
    static var ok: String { L10n.tr("common.ok", default: "好") }
    static var start: String { L10n.tr("common.start", default: "开始") }
    static var end: String { L10n.tr("common.end", default: "结束") }
    static var time: String { L10n.tr("common.time", default: "时间") }
    static var percentage: String { L10n.tr("common.percentage", default: "百分比") }
    static var unitGram: String { L10n.tr("common.unit.gram", default: "g") }
    static var unitDay: String { L10n.tr("common.unit.day", default: "天") }
    static var unitPiece: String { L10n.tr("common.unit.piece", default: "个") }
    static var moreActions: String { L10n.tr("common.more_actions", default: "更多操作") }
    static var continueAction: String { L10n.tr("common.continue", default: "继续") }
    static var pause: String { L10n.tr("common.pause", default: "暂停") }
    static var resume: String { L10n.tr("common.resume", default: "继续") }
    static var stop: String { L10n.tr("common.stop", default: "停止") }
    static var reset: String { L10n.tr("common.reset", default: "重置") }
    static var recipeTabTitle: String { L10n.tr("home.tab.recipes", default: "配方") }
    static var bakeHistoryTabTitle: String { L10n.tr("home.tab.history", default: "记录") }
    static var settingsTabTitle: String { L10n.tr("home.tab.settings", default: "设置") }
    static var bakeHistoryTitle: String { L10n.tr("home.title.history", default: "烘焙记录") }
    static var continueBake: String { L10n.tr("home.action.continue_bake", default: "继续制作") }
    static var addRecipe: String { L10n.tr("home.action.add_recipe", default: "添加配方") }
    static var copyRecipe: String { L10n.tr("home.action.copy_recipe", default: "复制配方") }
    static var editRecipe: String { L10n.tr("home.action.edit_recipe", default: "编辑配方") }
    static var startBake: String { L10n.tr("home.action.start_bake", default: "开始制作") }
    static var viewIncompleteSteps: String { L10n.tr("home.action.view_incomplete_steps", default: "查看未完成步骤") }
    static var exportLongImage: String { L10n.tr("home.action.export_long_image", default: "导出长图") }
    static var saveLongImage: String { L10n.tr("home.action.save_long_image", default: "保存长图") }
    static var saveAsImage: String { L10n.tr("home.action.save_as_image", default: "保存为图片") }
    static var generateTextTutorial: String { L10n.tr("home.action.generate_text_tutorial", default: "生成文字教程") }
    static var bakeAction: String { L10n.tr("home.action.bake", default: "烘焙") }
    static var activeBakeSection: String { L10n.tr("home.section.active_bake", default: "正在制作") }
    static var bakeRecordOngoing: String { L10n.tr("bake_record.status.ongoing", default: "正在制作") }
    static var bakeRecordStartedAt: String { L10n.tr("bake_record.started_at", default: "开始时间") }
    static var bakeRecordCompletedAt: String { L10n.tr("bake_record.completed_at", default: "完成时间") }
    static var bakeRecordStepTimingSection: String { L10n.tr("bake_record.section.step_timing", default: "步骤时间") }
    static var bakeRecordStepColumn: String { L10n.tr("bake_record.column.step", default: "步骤") }
    static var bakeRecordOpenRecipe: String { L10n.tr("bake_record.action.open_recipe", default: "打开配方") }
    static var bakeRecordEditReviewNotes: String { L10n.tr("bake_record.action.edit_review_notes", default: "编辑复盘备注") }
    static var bakeRecordNoReviewNotes: String { L10n.tr("bake_record.empty.review_notes", default: "还没有复盘备注") }
    static var bakeRecordDeleteConfirmationTitle: String { L10n.tr("bake_record.confirm.delete.title", default: "删除这条记录？") }
    static var bakeRecordDeleteConfirmationButton: String { L10n.tr("bake_record.confirm.delete.button", default: "删除记录") }
    static func bakeRecordDeleteConfirmationMessage(_ name: String) -> String {
        L10n.format("bake_record.confirm.delete.message", default: "“%@” 会从烘焙记录中移除。", name)
    }
    static var noRecipes: String { L10n.tr("home.empty.no_recipes", default: "暂无配方") }
    static var noMatchingRecipes: String { L10n.tr("home.empty.no_matching_recipes", default: "没有匹配的配方") }
    static var recipeSearchPrompt: String { L10n.tr("home.search.recipes", default: "搜索配方名称") }
    static var recipeStatusFilter: String { L10n.tr("home.filter.recipe_status", default: "配方状态筛选") }
    static var recipeStatusFilterAll: String { L10n.tr("home.filter.recipe_status.all", default: "全部") }
    static var recipeSortModified: String { L10n.tr("home.filter.modified_sort", default: "修改时间排序") }
    static var recipeSortModifiedNewest: String { L10n.tr("home.filter.modified_sort.newest", default: "最近修改优先") }
    static var recipeSortModifiedOldest: String { L10n.tr("home.filter.modified_sort.oldest", default: "最早修改优先") }
    static var recipeUpdatedAt: String { L10n.tr("home.recipe.updated_at", default: "更新时间") }
    static var recipeCreatedAt: String { L10n.tr("home.recipe.created_at", default: "创建时间") }
    static var recipeBakeCount: String { L10n.tr("home.recipe.bake_count", default: "制作次数") }
    static func recipeMetadataLine(_ title: String, _ value: String) -> String {
        L10n.format("home.recipe.metadata_line", default: "%@：%@", title, value)
    }
    static var clearRecipeSearch: String { L10n.tr("home.search.clear", default: "清除配方搜索") }
    static var bakeSearchPrompt: String { L10n.tr("bake_library.search.prompt", default: "搜索烘焙记录") }
    static var clearBakeSearch: String { L10n.tr("bake_library.search.clear", default: "清除烘焙记录搜索") }
    static var bakeSortStarted: String { L10n.tr("bake_library.filter.started_sort", default: "开始时间排序") }
    static var bakeSortStartedNewest: String { L10n.tr("bake_library.filter.started_sort.newest", default: "最近开始优先") }
    static var bakeSortStartedOldest: String { L10n.tr("bake_library.filter.started_sort.oldest", default: "最早开始优先") }
    static var noMatchingBakeRecords: String { L10n.tr("bake_library.empty.no_matching_records", default: "没有匹配的烘焙记录") }
    static var settingsSectionTools: String { L10n.tr("settings.section.tools", default: "工具") }
    static var settingsLanguageTitle: String { L10n.tr("settings.language.title", default: "语言 Language") }
    static var settingsLanguageOpenAccessibility: String {
        L10n.tr("settings.language.action.open", default: "选择语言")
    }
    static var settingsLanguagePickerTitle: String {
        L10n.tr("settings.language.picker.title", default: "选择语言")
    }
    static var settingsLanguageSystemOption: String {
        L10n.tr("settings.language.option.system", default: "跟随系统")
    }
    static var settingsLanguageEnglishOption: String {
        L10n.tr("settings.language.option.english", default: "英文 English")
    }
    static var settingsLanguageSimplifiedChineseOption: String {
        L10n.tr("settings.language.option.zh_hans", default: "中文 Chinese")
    }
    static var settingsTimerDetail: String { L10n.tr("settings.timer.detail", default: "独立计时器，适合烘烤、发酵和醒发提醒") }
    static var settingsTutorialTitle: String { L10n.tr("settings.tutorial.title", default: "新手教程") }
    static var settingsTutorialOpenAccessibility: String {
        L10n.tr("settings.tutorial.action.open", default: "打开新手教程")
    }
    static var settingsAboutTitle: String { L10n.tr("settings.about.title", default: "关于 Toastmark") }
    static var settingsAboutOpenAccessibility: String { L10n.tr("settings.about.action.open", default: "打开关于 Toastmark") }
    static var settingsAboutFeedbackMessage: String {
        L10n.tr("settings.about.feedback_message", default: "欢迎提交 feedback，帮助我们把 Toastmark 做得更好。")
    }
    static var settingsAboutLocalDataMessage: String {
        L10n.tr("settings.about.local_data_message", default: "目前，你在 Toastmark 中记录的配方、烘焙记录和酵种等数据都保存在本地，不会上传到我们的服务器。")
    }
    static var settingsAboutVersion: String { L10n.tr("settings.about.version", default: "版本") }
    static var settingsAboutVersionUnavailable: String {
        L10n.tr("settings.about.version.unavailable", default: "未知")
    }
    static var settingsAboutContactEmail: String { L10n.tr("settings.about.channel.contact_email", default: "联系邮箱") }
    static var settingsAboutXiaohongshu: String { L10n.tr("settings.about.channel.xiaohongshu", default: "小红书") }
    static var settingsAboutInstagram: String { L10n.tr("settings.about.channel.instagram", default: "Instagram") }
    static var settingsAboutContactEmailValue: String { L10n.tr("settings.about.channel.contact_email.value", default: "待填写") }
    static var settingsAboutXiaohongshuValue: String { L10n.tr("settings.about.channel.xiaohongshu.value", default: "待填写") }
    static var settingsAboutInstagramValue: String { L10n.tr("settings.about.channel.instagram.value", default: "待填写") }
    static var noRecords: String { L10n.tr("home.empty.no_records", default: "暂无记录") }
    static var notFinished: String { L10n.tr("home.status.not_finished", default: "未结束") }
    static var stepCount: String { L10n.tr("home.label.step_count", default: "步骤数") }
    static var reviewNotes: String { L10n.tr("home.section.review_notes", default: "复盘备注") }
    static var workspaceStagePreview: String { L10n.tr("workspace.stage.preview", default: "预览") }
    static var workspaceStageFormula: String { L10n.tr("workspace.stage.formula", default: "面团") }
    static var workspaceStageSteps: String { L10n.tr("workspace.stage.steps", default: "流程") }
    static var workspaceStageHistory: String { L10n.tr("workspace.stage.history", default: "记录") }
    static var workspaceStagePicker: String { L10n.tr("workspace.stage.picker", default: "编辑阶段") }
    static var formulaItemMissing: String { L10n.tr("formula.item.missing", default: "这个材料已经不存在了") }
    static var formulaDeleteMaterialConfirmationTitle: String {
        L10n.tr("formula.dialog.delete_material.title", default: "删除这个材料？")
    }
    static var formulaDeleteMaterialConfirmationMessage: String {
        L10n.tr("formula.dialog.delete_material.message", default: "删除后会从当前配方和步骤分配中移除。")
    }
    static var formulaTableIngredient: String { L10n.tr("formula.table.ingredient", default: "材料") }
    static var formulaTablePercentage: String { L10n.tr("formula.table.percentage", default: "比例") }
    static var formulaTableWeight: String { L10n.tr("formula.table.weight", default: "重量") }
    static var recipeSourceNewSection: String { L10n.tr("recipe_source.section.new", default: "新建") }
    static var recipeSourceTemplatesSection: String { L10n.tr("recipe_source.section.templates", default: "模板") }
    static var recipeSourceExistingSection: String { L10n.tr("recipe_source.section.existing", default: "从已有配方开始") }
    static var recipeSourceCustom: String { L10n.tr("recipe_source.action.custom", default: "自定义") }
    static var aiRecipeImportEntry: String { L10n.tr("recipe_import_ai.entry", default: "导入") }
    static var aiRecipeImportTutorialTitle: String { L10n.tr("recipe_import_ai.tutorial.title", default: "导入流程") }
    static var aiRecipeImportTutorialCopyPrompt: String {
        L10n.tr("recipe_import_ai.tutorial.copy_prompt", default: "复制下面的提示词。")
    }
    static var aiRecipeImportTutorialUseAI: String {
        L10n.tr("recipe_import_ai.tutorial.use_ai", default: "打开你常用的 AI，把配方图片和提示词一起发给它。")
    }
    static var aiRecipeImportTutorialPasteJSON: String {
        L10n.tr("recipe_import_ai.tutorial.paste_json", default: "复制 AI 返回的 JSON，粘贴到这里导入。")
    }
    static var aiRecipeImportPromptTitle: String { L10n.tr("recipe_import_ai.prompt.title", default: "AI 提示词") }
    static var aiRecipeImportPromptPreview: String {
        L10n.tr("recipe_import_ai.prompt.preview", default: "让 AI 只返回 Toastmark 可识别的配方 JSON。")
    }
    static var aiRecipeImportCopyPrompt: String { L10n.tr("recipe_import_ai.action.copy_prompt", default: "复制提示词") }
    static var aiRecipeImportPromptCopied: String {
        L10n.tr("recipe_import_ai.prompt.copied", default: "提示词已经复制。")
    }
    static var aiRecipeImportJSONTitle: String { L10n.tr("recipe_import_ai.json.title", default: "粘贴 JSON") }
    static var aiRecipeImportJSONAccessibility: String {
        L10n.tr("recipe_import_ai.json.accessibility", default: "AI 返回的配方 JSON")
    }
    static var aiRecipeImportAction: String { L10n.tr("recipe_import_ai.action.import", default: "导入配方") }
    static var aiRecipeImportFailedTitle: String { L10n.tr("recipe_import_ai.alert.failed", default: "导入失败") }
    static var recipeImportTutorialChooseFile: String {
        L10n.tr("recipe_import.file_tutorial.choose_file", default: "从本地文件中选择之前导出的配方文件。")
    }
    static var recipeImportTutorialLoadRecipe: String {
        L10n.tr("recipe_import.file_tutorial.load_recipe", default: "Toastmark 会读取文件内容，并把配方加载到当前编辑流程。")
    }
    static var recipeImportTutorialEditAfterImport: String {
        L10n.tr("recipe_import.file_tutorial.edit_after_import", default: "导入成功后可以继续调整材料、步骤和备注。")
    }
    static var recipeImportFileTitle: String {
        L10n.tr("recipe_import.file.title", default: "本地文件")
    }
    static var recipeImportFileDescription: String {
        L10n.tr("recipe_import.file.description", default: "请选择 Toastmark 导出的 JSON 配方文件。文件只会在本机读取，用于恢复或迁移配方。")
    }
    static var recipeImportSelectFileAction: String {
        L10n.tr("recipe_import.action.select_file", default: "选择文件")
    }
    static var recipeImportSucceeded: String {
        L10n.tr("recipe_import.status.succeeded", default: "导入成功")
    }
    static var aiRecipeImportPrompt: String {
        L10n.tr("recipe_import_ai.prompt.full", default: """
        请把我提供的烘焙配方图片或文字整理成 Toastmark 可导入的 JSON。

        只输出 JSON，不要输出 Markdown、代码块或解释。
        使用 schema: "bready.recipe"，schemaVersion: 1。
        所有重量使用 grams 数字。时间拆成 duration.value 和 duration.unit，unit 只能是 "min" 或 "hr"。温度拆成 temperature.value 和 temperature.unit，unit 只能是 "F" 或 "C"。
        每个 ingredient 必须有唯一 ingredientId；steps.materialAllocations 只能引用这些 ingredientId。
        不确定的信息写进 notes，不要编造精确重量。

        可用枚举：
        kind: "toast", "chiffon", "countryBread", "custom"
        category: "flour", "starter", "basic", "other"
        tag: "flour", "starter", "water", "salt", "sugar", "butter", "cream", "yeast", "egg", "other"
        step type: "prep", "mixing", "fermentation", "rest", "shaping", "baking", "other"
        productionMethod: "bake", "steam"

        JSON 结构：
        {
          "schema": "bready.recipe",
          "schemaVersion": 1,
          "recipe": {
            "name": "配方名称",
            "kind": "custom",
            "overallNotes": "可选备注",
            "ingredients": [
              {
                "ingredientId": "flour-1",
                "name": "高筋面粉",
                "category": "flour",
                "tag": "flour",
                "weightGrams": 500
              }
            ],
            "steps": [
              {
                "name": "混合",
                "type": "mixing",
                "notes": "步骤说明",
                "duration": { "value": 20, "unit": "min" },
                "temperature": { "value": 350, "unit": "F" },
                "productionMethod": "bake",
                "materialAllocations": [
                  { "ingredientId": "flour-1", "percentage": 100 }
                ]
              }
            ]
          }
        }
        """)
    }
    static var recipeImportErrorInvalidJSON: String {
        L10n.tr("recipe_import.error.invalid_json", default: "没有识别到有效 JSON。")
    }
    static var recipeImportErrorInvalidSchema: String {
        L10n.tr("recipe_import.error.invalid_schema", default: "这个文件不是 Toastmark 配方 JSON。")
    }
    static func recipeImportErrorUnsupportedVersion(_ version: Int) -> String {
        L10n.format("recipe_import.error.unsupported_version", default: "暂不支持 schemaVersion %d。", version)
    }
    static var recipeImportErrorEmptyRecipe: String {
        L10n.tr("recipe_import.error.empty_recipe", default: "JSON 里需要至少一个材料和一个步骤。")
    }
    static func recipeImportErrorInvalidNumber(_ field: String) -> String {
        L10n.format("recipe_import.error.invalid_number", default: "%@ 需要是非负数字。", field)
    }
    static func recipeImportErrorMissingIngredientReference(_ ingredientId: String) -> String {
        L10n.format("recipe_import.error.missing_ingredient_reference", default: "步骤引用了不存在的材料：%@。", ingredientId)
    }
    static var recipeSourceStartBlank: String { L10n.tr("recipe_source.action.start_blank", default: "从空白开始") }
    static var recipeSourceStartBlankDetail: String { L10n.tr("recipe_source.detail.start_blank", default: "手动搭建一个全新的配方") }
    static var recipeSourceToastTemplateDetail: String { L10n.tr("recipe_source.detail.toast_template", default: "吐司、日式牛奶面包、模具面包") }
    static var recipeSourceChiffonTemplateDetail: String { L10n.tr("recipe_source.detail.chiffon_template", default: "奶油蛋糕、戚风、巴斯克、香蕉蛋糕") }
    static var recipeSourceCountryBreadTemplateDetail: String { L10n.tr("recipe_source.detail.country_bread_template", default: "酸面包、法棍、披萨面团") }
    static var recipeSourceEmptySaved: String { L10n.tr("recipe_source.empty.saved", default: "还没有已保存配方") }
    static var bakePickerChooseRecipe: String { L10n.tr("bake_picker.section.choose_recipe", default: "选择一个配方") }
    static var bakePickerEmptyReadyRecipes: String { L10n.tr("bake_picker.empty.ready_recipes", default: "还没有可烘焙的配方") }
    static var bakePickerFooter: String {
        L10n.tr("bake_picker.footer.preview_first", default: "进入预览后，你可以再决定什么时候开始烘焙。")
    }
    static var bakePickerReplaceActiveTitle: String {
        L10n.tr("bake_picker.replace_active.title", default: "开始新的烘焙？")
    }
    static var bakePickerReplaceActiveMessage: String {
        L10n.tr("bake_picker.replace_active.message", default: "现在有一个正在制作的烘焙。开始新的烘焙会替换当前进度。")
    }
    static var bakePickerReplaceActiveConfirm: String {
        L10n.tr("bake_picker.replace_active.confirm", default: "开始新的烘焙")
    }
    static var percentagePickerAccessibility: String {
        L10n.tr("common.percentage_picker.accessibility", default: "调整百分比")
    }
    static var percentagePickerDecrease: String {
        L10n.tr("common.percentage_picker.decrease", default: "减少 1%")
    }
    static var percentagePickerIncrease: String {
        L10n.tr("common.percentage_picker.increase", default: "增加 1%")
    }

    static func activeBakeProgress(stepIndex: Int, totalSteps: Int, stepName: String) -> String {
        L10n.format("home.active_bake.progress", default: "进行到第 %d/%d 步 · %@", stepIndex, totalSteps, stepName)
    }

    static func recipeCopyName(_ sourceName: String) -> String {
        L10n.format("recipe.copy_format", default: "%@ copy", sourceName)
    }

    static var startBakeConfirmationTitle: String {
        L10n.tr("recipe.confirm.start_bake.title", default: "开始烘焙？")
    }

    static var startBakeConfirmationMessage: String {
        L10n.tr("recipe.confirm.start_bake.message", default: "会从这个配方开始一条新的烘焙记录。")
    }

    static var reviewBeforeBakeConfirmationTitle: String {
        L10n.tr("recipe.confirm.review_before_bake.title", default: "还不能开始烘焙")
    }

    static var reviewBeforeBakeConfirmationMessage: String {
        L10n.tr("recipe.confirm.review_before_bake.message", default: "这个配方还没有准备好。先检查制作步骤和材料分配。")
    }

    static var copyRecipeConfirmationTitle: String {
        L10n.tr("recipe.confirm.copy.title", default: "复制这个配方？")
    }

    static var copyRecipeConfirmationMessage: String {
        L10n.tr("recipe.confirm.copy.message", default: "会创建一个新的配方副本，名称为当前名称加上 copy。")
    }

    static var deleteRecipeConfirmationTitle: String {
        L10n.tr("recipe.confirm.delete.title", default: "删除这个配方？")
    }

    static var deleteRecipeConfirmationButton: String {
        L10n.tr("recipe.confirm.delete.button", default: "删除配方")
    }

    static func deleteRecipeConfirmationMessage(_ recipeName: String) -> String {
        L10n.format("recipe.confirm.delete.message", default: "“%@” 会从配方列表中移除。", recipeName)
    }

    static var readinessNeedsSteps: String {
        L10n.tr("workflow.readiness.needs_steps", default: "先添加制作步骤，再标记为准备烘焙。")
    }

    static var readinessNeedsReadyTap: String {
        L10n.tr("workflow.readiness.needs_ready_tap", default: "检查制作步骤后，点“准备烘焙”就可以开始。")
    }

    static func readinessNeedsAssignments(_ count: Int) -> String {
        L10n.format("workflow.readiness.needs_assignments", default: "还有 %d 个材料没有分配到步骤。", count)
    }

    static var readinessReadyToBake: String {
        L10n.tr("workflow.readiness.ready", default: "已准备好，可以开始烘焙。")
    }
    static var workflowReadyConfirmationTitle: String {
        L10n.tr("workflow.ready_confirmation.title", default: "确认变成 Ready？")
    }

    static var cookTitle: String { L10n.tr("cook.title", default: "开始开炉") }
    static var cookHomeAccessibility: String { L10n.tr("cook.action.home", default: "回到首页") }
    static var cookResetAccessibility: String { L10n.tr("cook.action.reset", default: "重置") }
    static var cookOpenRecipePreview: String { L10n.tr("cook.action.open_recipe_preview", default: "查看原配方") }
    static var cookEmptyNeedsSteps: String { L10n.tr("cook.empty.needs_steps", default: "先添加制作步骤，再开始。") }
    static var cookEmptyNotReady: String { L10n.tr("cook.empty.not_ready", default: "配方还没准备好，先把材料分配到步骤。") }
    static var cookCurrentStage: String { L10n.tr("cook.label.current_stage", default: "当前阶段") }
    static var cookIngredients: String { L10n.tr("cook.section.ingredients", default: "本步材料") }
    static var cookTips: String { L10n.tr("cook.section.tips", default: "操作提示") }
    static var cookNow: String { L10n.tr("cook.label.now", default: "当前") }
    static var cookStartAt: String { L10n.tr("cook.label.start_at", default: "开始") }
    static var cookFinishAt: String { L10n.tr("cook.label.finish_at", default: "预计完成") }
    static var cookReminderSection: String { L10n.tr("cook.section.reminder", default: "计时提醒") }
    static var cookReminderTime: String { L10n.tr("cook.label.reminder_time", default: "提醒时间") }
    static var cookSetReminder: String { L10n.tr("cook.action.set_reminder", default: "设置提醒") }
    static var cookUpdateReminder: String { L10n.tr("cook.action.update_reminder", default: "更新提醒") }
    static var cookFoldReminderSection: String { L10n.tr("cook.fold.section.reminder", default: "抱叠提醒") }
    static var cookFoldReminderToggle: String { L10n.tr("cook.fold.reminder.toggle", default: "抱叠提醒") }
    static var cookFoldFrequency: String { L10n.tr("cook.fold.frequency", default: "抱叠频率") }
    static var cookFoldNextTime: String { L10n.tr("cook.fold.next_time", default: "下次抱叠时间") }
    static var cookFoldRecordsSection: String { L10n.tr("cook.fold.section.records", default: "抱叠记录") }
    static var cookFoldAction: String { L10n.tr("cook.fold.action.record", default: "抱叠") }
    static var cookFoldCompleted: String { L10n.tr("cook.fold.status.completed", default: "抱叠已完成，步骤仍需手动完成。") }
    static var cookFoldRecordIndex: String { L10n.tr("cook.fold.record.index", default: "次数") }
    static var cookFoldRecordTime: String { L10n.tr("cook.fold.record.time", default: "记录时间") }
    static var cookFoldRecordsEmpty: String { L10n.tr("cook.fold.records.empty", default: "还没有抱叠记录") }
    static var cookNoStepIngredients: String { L10n.tr("cook.empty.no_step_ingredients", default: "这个步骤还没有分配材料。") }
    static var cookDefaultStepNote: String { L10n.tr("cook.note.default", default: "按你的记录完成这个步骤。") }
    static var cookChecked: String { L10n.tr("cook.status.checked", default: "已确认") }
    static var cookStartTimer: String { L10n.tr("cook.action.start_timer", default: "开始计时") }
    static var cookRestartTimer: String { L10n.tr("cook.action.restart_timer", default: "重新开始计时") }
    static var cookPreviousStep: String { L10n.tr("cook.action.previous_step", default: "上一步") }
    static var cookNextStep: String { L10n.tr("cook.action.next_step", default: "下一步") }
    static var cookReturnToCurrentStep: String { L10n.tr("cook.action.return_to_current_step", default: "回到当前步骤") }
    static var cookCompleteStep: String { L10n.tr("cook.action.complete_step", default: "完成步骤") }
    static var cookFinish: String { L10n.tr("cook.action.finish", default: "完成") }
    static var cookFinishBake: String { L10n.tr("cook.action.finish_bake", default: "完成烘焙") }
    static var cookCompletedStatus: String { L10n.tr("cook.status.completed", default: "已完成") }
    static var cookStepCompleted: String { L10n.tr("cook.status.step_completed", default: "已完成") }
    static var cookCompletedTitle: String { L10n.tr("cook.completed.title", default: "制作完成") }
    static var cookCompletedBody: String { L10n.tr("cook.completed.body", default: "这次流程已经完整跑完，可以顺手记一点复盘。") }
    static var cookActualTime: String { L10n.tr("cook.summary.actual_time", default: "实际耗时") }
    static var cookEstimatedTime: String { L10n.tr("cook.summary.estimated_time", default: "预计耗时") }
    static var cookCompletedSteps: String { L10n.tr("cook.summary.completed_steps", default: "完成步骤") }
    static var cookIngredientCheck: String { L10n.tr("cook.summary.ingredient_check", default: "材料确认") }
    static var cookBakeAgain: String { L10n.tr("cook.action.bake_again", default: "再做一次") }

    static func cookStepProgress(stepIndex: Int, totalSteps: Int) -> String {
        L10n.format("cook.label.step_progress", default: "步骤 %d/%d", stepIndex, totalSteps)
    }

    static func cookCurrentStepProgress(stepIndex: Int, totalSteps: Int) -> String {
        L10n.format("cook.label.current_step_progress", default: "当前 · 步骤 %d/%d", stepIndex, totalSteps)
    }

    static func cookReminderDefaultDetail(_ time: String) -> String {
        L10n.format("cook.reminder.default_detail", default: "默认 %@", time)
    }

    static func cookReminderScheduledAt(_ time: String) -> String {
        L10n.format("cook.reminder.scheduled_at", default: "已设置 %@", time)
    }

    static func cookFoldProgress(completed: Int, target: Int) -> String {
        L10n.format("cook.fold.progress", default: "%d/%d", completed, target)
    }

    static func cookIngredientProgress(checked: Int, total: Int) -> String {
        L10n.format("cook.label.ingredient_progress", default: "%d/%d 已确认", checked, total)
    }

    static func cookIngredientCount(_ count: Int) -> String {
        L10n.format("cook.label.ingredient_count", default: "%d 个", count)
    }

    static func cookWaterContribution(_ weight: String) -> String {
        L10n.format("cook.label.water_contribution", default: "贡献水量 %@", weight)
    }

    static func cookAllocationPercent(_ percent: String) -> String {
        L10n.format("cook.label.allocation_percent", default: "分配 %@%%", percent)
    }

    static var cookTimerFinishedNotificationTitle: String {
        L10n.tr("notification.cook_timer.finished.title", default: "烘焙计时完成")
    }

    static func cookTimerFinishedNotificationBody(stepName: String) -> String {
        L10n.format("notification.cook_timer.finished.body", default: "「%@」时间到了。", stepName)
    }

    static var cookFoldReminderNotificationTitle: String {
        L10n.tr("notification.cook_fold_reminder.title", default: "该抱叠了")
    }

    static func cookFoldReminderNotificationBody(stepName: String, foldIndex: Int) -> String {
        L10n.format("notification.cook_fold_reminder.body", default: "「%@」第 %d 次抱叠时间到了。", stepName, foldIndex)
    }

    static var starterFeedingReminderNotificationTitle: String {
        L10n.tr("notification.starter_feeding.title", default: "酵种喂养提醒")
    }

    static func starterFeedingReminderNotificationBody(starterName: String) -> String {
        L10n.format("notification.starter_feeding.body", default: "今天记得喂养「%@」。", starterName)
    }

    static func starterFeedingPastDueNotificationBody(starterName: String) -> String {
        L10n.format("notification.starter_feeding.past_due.body", default: "「%@」已经超过喂养日期，今天早上记得处理。", starterName)
    }

    static var kitchenTimerTitle: String { L10n.tr("kitchen_timer.title", default: "计时器") }
    static var kitchenTimerOpenAccessibility: String {
        L10n.tr("kitchen_timer.action.open", default: "打开计时器")
    }
    static var kitchenTimerStartAccessibility: String {
        L10n.tr("kitchen_timer.action.start", default: "开始计时")
    }
    static var kitchenTimerPauseAccessibility: String {
        L10n.tr("kitchen_timer.action.pause", default: "暂停计时")
    }
    static var kitchenTimerResumeAccessibility: String {
        L10n.tr("kitchen_timer.action.resume", default: "继续计时")
    }
    static var kitchenTimerStopAccessibility: String {
        L10n.tr("kitchen_timer.action.stop", default: "停止计时")
    }
    static var kitchenTimerAlarmTime: String { L10n.tr("kitchen_timer.label.alarm_time", default: "响铃时间") }
    static var kitchenTimerHours: String { L10n.tr("kitchen_timer.unit.hours", default: "小时") }
    static var kitchenTimerMinutes: String { L10n.tr("kitchen_timer.unit.minutes", default: "分钟") }
    static var kitchenTimerSeconds: String { L10n.tr("kitchen_timer.unit.seconds", default: "秒") }
    static var kitchenTimerIdleStatus: String {
        L10n.tr("kitchen_timer.status.idle", default: "选择时间后开始计时。")
    }
    static var kitchenTimerRunningStatus: String {
        L10n.tr("kitchen_timer.status.running", default: "计时中")
    }
    static var kitchenTimerPausedStatus: String {
        L10n.tr("kitchen_timer.status.paused", default: "已暂停")
    }
    static var kitchenTimerFinishedStatus: String {
        L10n.tr("kitchen_timer.status.finished", default: "时间到了")
    }
    static var kitchenTimerPermissionDeniedStatus: String {
        L10n.tr("kitchen_timer.status.permission_denied", default: "需要允许闹钟权限才能提醒。")
    }
    static var kitchenTimerErrorStatus: String {
        L10n.tr("kitchen_timer.status.error", default: "计时器暂时无法启动。")
    }

    static var stepPrepName: String { L10n.tr("step.default.prep_name", default: "准备工作") }
    static var stepPrepNote: String { L10n.tr("step.default.prep_note", default: "制作种面，或提前处理需要预混的材料。") }
    static var stepMixingName: String { L10n.tr("step.default.mixing_name", default: "打面") }
    static var stepMixingFirstNote: String { L10n.tr("step.default.mixing_note.first", default: "除了盐黄油，混合均匀，打至后膜") }
    static var stepMixingLaterNote: String { L10n.tr("step.default.mixing_note.later", default: "加入盐，黄油，打到手套膜，温度控制28。") }
    static var fermentationStageFirst: String { L10n.tr("step.fermentation.stage.first", default: "一发") }
    static var fermentationStageSecond: String { L10n.tr("step.fermentation.stage.second", default: "二发") }

    static func fermentationStepName(stage: String) -> String {
        L10n.format("step.default.fermentation_name", default: "发酵（%@）", stage)
    }

    static var bakingStepName: String { L10n.tr("step.default.baking_name", default: "烘烤") }
    static var productionStepName: String { L10n.tr("step.default.production_name", default: "制作") }
    static var customStepName: String { L10n.tr("step.default.custom_name", default: "自定义") }

    static var templateToastSimpleNote: String { L10n.tr("template.toast.simple.note", default: "称量材料，黄油提前软化。混合成团后加入盐和黄油，揉到光滑；发酵、整形入模，醒发后烘烤。") }
    static var templateToastPrepName: String { L10n.tr("template.toast.step.prep.name", default: "准备材料") }
    static var templateToastPrepNote: String { L10n.tr("template.toast.step.prep.note", default: "称量材料，黄油提前软化，模具抹油或铺纸。") }
    static var templateToastMixName: String { L10n.tr("template.toast.step.mix.name", default: "混合成团") }
    static var templateToastMixNote: String { L10n.tr("template.toast.step.mix.note", default: "混合到无干粉并开始成团。") }
    static var templateToastButterName: String { L10n.tr("template.toast.step.butter.name", default: "加入黄油") }
    static var templateToastButterNote: String { L10n.tr("template.toast.step.butter.note", default: "加入盐和黄油，揉到光滑有延展性。") }
    static var templateToastBulkName: String { L10n.tr("template.toast.step.bulk.name", default: "基础发酵") }
    static var templateToastBulkNote: String { L10n.tr("template.toast.step.bulk.note", default: "盖好发酵到明显膨胀。") }
    static var templateToastShapeName: String { L10n.tr("template.toast.step.shape.name", default: "整形入模") }
    static var templateToastShapeNote: String { L10n.tr("template.toast.step.shape.note", default: "排气分割，擀卷入模。") }
    static var templateToastProofName: String { L10n.tr("template.toast.step.proof.name", default: "最后醒发") }
    static var templateToastProofNote: String { L10n.tr("template.toast.step.proof.note", default: "醒发到八九分满，轻按有弹性。") }
    static var templateToastBakeName: String { L10n.tr("template.toast.step.bake.name", default: "烘烤") }
    static var templateToastBakeNote: String { L10n.tr("template.toast.step.bake.note", default: "烤到表面金黄，出炉脱模放凉。") }

    static var templateChiffonSimpleNote: String { L10n.tr("template.chiffon.simple.note", default: "分蛋，蛋黄糊乳化后拌入低粉；蛋白加糖打发，翻拌入模，烘烤后倒扣冷却。") }
    static var templateChiffonPrepName: String { L10n.tr("template.chiffon.step.prep.name", default: "准备与分蛋") }
    static var templateChiffonPrepNote: String { L10n.tr("template.chiffon.step.prep.note", default: "预热烤箱，分蛋，蛋白盆保持无油无水。") }
    static var templateChiffonYolkName: String { L10n.tr("template.chiffon.step.yolk.name", default: "蛋黄糊") }
    static var templateChiffonYolkNote: String { L10n.tr("template.chiffon.step.yolk.note", default: "乳化蛋黄糊，筛入低粉拌顺滑。") }
    static var templateChiffonMeringueName: String { L10n.tr("template.chiffon.step.meringue.name", default: "蛋白霜") }
    static var templateChiffonMeringueNote: String { L10n.tr("template.chiffon.step.meringue.note", default: "加糖打发到稳定小弯钩。") }
    static var templateChiffonFoldName: String { L10n.tr("template.chiffon.step.fold.name", default: "混合入模") }
    static var templateChiffonFoldNote: String { L10n.tr("template.chiffon.step.fold.note", default: "蛋白霜分次和蛋黄糊翻拌，入模震气泡。") }
    static var templateChiffonBakeName: String { L10n.tr("template.chiffon.step.bake.name", default: "烘烤") }
    static var templateChiffonBakeNote: String { L10n.tr("template.chiffon.step.bake.note", default: "烤到表面回弹，竹签无湿面糊。") }
    static var templateChiffonCoolName: String { L10n.tr("template.chiffon.step.cool.name", default: "倒扣冷却") }
    static var templateChiffonCoolNote: String { L10n.tr("template.chiffon.step.cool.note", default: "出炉立刻倒扣，冷透后脱模。") }

    static var templateCountryBreadSimpleNote: String { L10n.tr("template.country_bread.simple.note", default: "混合材料到无干粉，室温折叠发酵；冷藏后整形、醒发，割包烘烤。") }
    static var templateCountryBreadMixName: String { L10n.tr("template.country_bread.step.mix.name", default: "混合面团") }
    static var templateCountryBreadMixNote: String { L10n.tr("template.country_bread.step.mix.note", default: "混合到无干粉。") }
    static var templateCountryBreadBulkName: String { L10n.tr("template.country_bread.step.bulk.name", default: "折叠发酵") }
    static var templateCountryBreadBulkNote: String { L10n.tr("template.country_bread.step.bulk.note", default: "室温发酵，中途拉伸折叠。") }
    static var templateCountryBreadColdName: String { L10n.tr("template.country_bread.step.cold.name", default: "冷藏发酵") }
    static var templateCountryBreadColdNote: String { L10n.tr("template.country_bread.step.cold.note", default: "盖好冷藏过夜。") }
    static var templateCountryBreadPreshapeName: String { L10n.tr("template.country_bread.step.preshape.name", default: "预整形") }
    static var templateCountryBreadPreshapeNote: String { L10n.tr("template.country_bread.step.preshape.note", default: "回温后轻轻收圆，松弛再整形。") }
    static var templateCountryBreadProofName: String { L10n.tr("template.country_bread.step.proof.name", default: "最后醒发") }
    static var templateCountryBreadProofNote: String { L10n.tr("template.country_bread.step.proof.note", default: "放入撒粉发酵篮或碗中，醒发到按压后缓慢回弹。") }
    static var templateCountryBreadBakeName: String { L10n.tr("template.country_bread.step.bake.name", default: "割包烘烤") }
    static var templateCountryBreadBakeNote: String { L10n.tr("template.country_bread.step.bake.note", default: "割包入炉，前段加盖或蒸汽，烤到深金色。") }

    static func stepDefaultName(_ number: Int) -> String {
        L10n.format("step.default.numbered_name", default: "步骤%d", number)
    }

    static var starterProfileDefaultName: String { L10n.tr("starter_profile.default_name", default: "酵种") }
    static var starterTabTitle: String { L10n.tr("starter_profile.tab.title", default: "酵种") }
    static var starterSectionName: String { L10n.tr("starter_profile.section.name", default: "名称") }
    static var starterSectionContainer: String { L10n.tr("starter_profile.section.container", default: "容器") }
    static var starterSectionWeight: String { L10n.tr("starter_profile.section.weight", default: "重量") }
    static var starterSectionLastFed: String { L10n.tr("starter_profile.section.last_fed", default: "上次喂养") }
    static var starterSectionFeedingMethod: String { L10n.tr("starter_profile.section.feeding_method", default: "喂养方法") }
    static var starterSectionReminder: String { L10n.tr("starter_profile.section.reminder", default: "提醒") }
    static var starterContainerWeightToggle: String { L10n.tr("starter_profile.container_weight.toggle", default: "扣除容器重量") }
    static var starterContainerWeight: String { L10n.tr("starter_profile.container_weight.label", default: "容器重量") }
    static var starterMeasuredWeight: String { L10n.tr("starter_profile.measured_weight", default: "称重") }
    static var starterFinalWeight: String { L10n.tr("starter_profile.final_weight", default: "酵种重量") }
    static var starterTotalWeight: String { L10n.tr("starter_profile.total_weight", default: "总重量") }
    static var starterPostFeedWeight: String { L10n.tr("starter_profile.post_feed_weight", default: "喂养后重量") }
    static var starterTime: String { L10n.tr("starter_profile.time", default: "时间") }
    static var starterRatio: String { L10n.tr("starter_profile.ratio", default: "比例") }
    static var starterFeedFlour: String { L10n.tr("starter_profile.feed_flour", default: "面粉") }
    static var starterFeedWater: String { L10n.tr("starter_profile.feed_water", default: "水") }
    static var starterReminderToggle: String { L10n.tr("starter_profile.reminder.toggle", default: "喂养提醒") }
    static var starterFeedingFrequencyDays: String { L10n.tr("starter_profile.feeding_frequency_days", default: "喂养频率（天）") }
    static var starterNextFeedingDate: String { L10n.tr("starter_profile.next_feeding_date", default: "下次喂养日期") }
    static var starterReminderTimes: String { L10n.tr("starter_profile.reminder_times", default: "提醒时间") }
    static var starterFedDone: String { L10n.tr("starter_profile.action.done", default: "已完成喂养") }
    static var starterFeedTitle: String { L10n.tr("starter_profile.action.feed", default: "喂养") }
    static var starterMarkFed: String { L10n.tr("starter_profile.action.mark_fed", default: "完成喂养") }
    static var starterSearchPrompt: String { L10n.tr("starter_library.search.prompt", default: "搜索酵种名称") }
    static var clearStarterSearch: String { L10n.tr("starter_library.search.clear", default: "清除酵种搜索") }
    static var starterStatusFilter: String { L10n.tr("starter_library.filter.status", default: "酵种状态筛选") }
    static var starterStatusFilterAll: String { L10n.tr("starter_library.filter.status.all", default: "全部") }
    static var starterStatusFilterDue: String { L10n.tr("starter_library.filter.status.due", default: "需要喂养") }
    static var starterStatusFilterFresh: String { L10n.tr("starter_library.filter.status.fresh", default: "状态正常") }
    static var starterSortFed: String { L10n.tr("starter_library.filter.fed_sort", default: "喂养时间排序") }
    static var starterSortFedNewest: String { L10n.tr("starter_library.filter.fed_sort.newest", default: "最近喂养优先") }
    static var starterSortFedOldest: String { L10n.tr("starter_library.filter.fed_sort.oldest", default: "最早喂养优先") }
    static var addStarter: String { L10n.tr("starter_library.action.add", default: "添加酵种") }
    static var noStarters: String { L10n.tr("starter_library.empty.no_starters", default: "暂无酵种") }
    static var noMatchingStarters: String { L10n.tr("starter_library.empty.no_matching_starters", default: "没有匹配的酵种") }
    static var starterLastFed: String { L10n.tr("starter_library.row.last_fed", default: "上次喂养") }
    static var relativeToday: String { L10n.tr("starter_library.row.last_fed.today", default: "今天") }
    static var relativeYesterday: String { L10n.tr("starter_library.row.last_fed.yesterday", default: "昨天") }
    static func relativeDaysAgo(_ days: Int) -> String {
        L10n.format("starter_library.row.last_fed.days_ago", default: "%d 天前", days)
    }
    static func starterLastFedAccessibilityValue(date: String, relative: String) -> String {
        L10n.format("starter_library.row.last_fed.accessibility_value", default: "%@，%@", date, relative)
    }
    static var starterDeleteConfirmationTitle: String { L10n.tr("starter_library.confirm.delete.title", default: "删除这个酵种？") }
    static var starterDeleteConfirmationButton: String { L10n.tr("starter_library.confirm.delete.button", default: "删除酵种") }
    static func starterDeleteConfirmationMessage(_ name: String) -> String {
        L10n.format("starter_library.confirm.delete.message", default: "“%@” 会从酵种列表中移除。", name)
    }
    static var starterSlideToMarkFed: String { L10n.tr("starter_profile.action.slide_to_mark_fed", default: "向右滑动完成喂养") }
    static var starterWeightAdjustHint: String { L10n.tr("starter_profile.weight.adjust_hint", default: "向左滑动减少克数，也可以直接输入") }
    static var formulaFieldName: String { L10n.tr("formula.field.name", default: "名称") }
    static var formulaPopupNameLabel: String { L10n.tr("formula.popup.name_label", default: "名称") }
    static var formulaFieldWeight: String { L10n.tr("formula.field.weight", default: "重量") }
    static var formulaFieldType: String { L10n.tr("formula.field.type", default: "类型") }
    static var formulaEditMaterials: String { L10n.tr("formula.action.edit_materials", default: "编辑材料") }
    static var formulaDeleteMaterial: String { L10n.tr("formula.action.delete_material", default: "删除材料") }
    static var formulaYeastType: String { L10n.tr("formula.field.yeast_type", default: "酵母类型") }
    static var formulaWaterContent: String { L10n.tr("formula.field.water_content", default: "含水量") }
    static var formulaWaterContribution: String { L10n.tr("formula.field.water_contribution", default: "贡献水量") }
    static var formulaStarterRatio: String { L10n.tr("formula.field.starter_ratio", default: "水粉比例") }
    static var formulaStarterModeRatio: String { L10n.tr("formula.field.starter_mode_ratio", default: "按比例") }
    static var formulaStarterModeWeight: String { L10n.tr("formula.field.starter_mode_weight", default: "按重量") }
    static var formulaStarterAddYeast: String { L10n.tr("formula.field.starter_add_yeast", default: "加入种面酵母") }
    static var formulaStarterYeast: String { L10n.tr("formula.field.starter_yeast", default: "种面酵母") }
    static var formulaStarterAddEgg: String { L10n.tr("formula.field.starter_add_egg", default: "加入种面鸡蛋") }
    static var formulaEggCount: String { L10n.tr("formula.field.egg_count", default: "鸡蛋个数") }
    static var formulaEggUnitWeight: String { L10n.tr("formula.field.egg_unit_weight", default: "单个重量") }
    static var formulaWaterMark: String { L10n.tr("formula.label.water_mark", default: "含水") }
    static var formulaMetricDough: String { L10n.tr("formula.metric.dough", default: "面团") }
    static var formulaMetricFlour: String { L10n.tr("formula.metric.flour", default: "面粉") }
    static var formulaMetricHydration: String { L10n.tr("formula.metric.hydration", default: "含水") }
    static var formulaHydrationInfoAccessibility: String { L10n.tr("formula.hydration_info.accessibility", default: "含水公式说明") }
    static var formulaHydrationInfoTitle: String { L10n.tr("formula.hydration_info.title", default: "含水公式") }
    static var formulaHydrationInfoBody: String { L10n.tr("formula.hydration_info.body", default: "含水 = 总水量 ÷ 总面粉 × 100%。总水量包含直接添加的水、种面中的水，以及鸡蛋等设置了含水量的材料；总面粉包含直接面粉和种面中的面粉。") }
    static var formulaHydrationReceiptIngredient: String { L10n.tr("formula.hydration_receipt.ingredient", default: "材料") }
    static var formulaHydrationReceiptWater: String { L10n.tr("formula.hydration_receipt.water", default: "含水") }
    static var formulaHydrationReceiptFlour: String { L10n.tr("formula.hydration_receipt.flour", default: "面粉") }
    static var formulaHydrationReceiptTotal: String { L10n.tr("formula.hydration_receipt.total", default: "合计") }
    static func formulaHydrationReceiptEquation(water: String, flour: String, percent: String) -> String {
        L10n.format("formula.hydration_receipt.equation", default: "%@ ÷ %@ = %@", water, flour, percent)
    }
    static var formulaExpandMaterialSettings: String { L10n.tr("formula.action.expand_material_settings", default: "展开材料设置") }
    static var formulaCollapseMaterialSettings: String { L10n.tr("formula.action.collapse_material_settings", default: "收起材料设置") }
    static var formulaFileOperationFailed: String { L10n.tr("formula.alert.file_operation_failed", default: "文件操作失败") }
    static var formulaExportJSON: String { L10n.tr("formula.action.export_json", default: "导出") }
    static var formulaImportJSON: String { L10n.tr("formula.action.import_json", default: "导入") }
    static var recipeExportInstructionTitle: String {
        L10n.tr("recipe_export.instruction.title", default: "导出说明")
    }
    static var recipeExportInstructionLocalFile: String {
        L10n.tr("recipe_export.instruction.local_file", default: "导出的文件会保存在你选择的本地位置，例如“文件”App 或 iCloud Drive。")
    }
    static var recipeExportInstructionImportUse: String {
        L10n.tr("recipe_export.instruction.import_use", default: "这个文件可以在 Toastmark 的“导入”入口重新载入，用于恢复或迁移配方。")
    }
    static var recipeExportInstructionKeepFile: String {
        L10n.tr("recipe_export.instruction.keep_file", default: "请保留文件名和 .json 后缀，之后导入时选择同一个文件即可。")
    }
    static var recipeExportInstructionContinue: String {
        L10n.tr("recipe_export.instruction.continue", default: "继续导出")
    }
    static var formulaEmptyMaterials: String { L10n.tr("formula.empty.materials", default: "还没有材料") }
    static var formulaFlourPercentageInfoAccessibility: String { L10n.tr("formula.flour_percentage.accessibility", default: "面粉百分比说明") }
    static var formulaFlourPercentageInfoTitle: String { L10n.tr("formula.flour_percentage.title", default: "仅限面粉表") }
    static var formulaFlourPercentageInfoBody: String {
        L10n.tr("formula.flour_percentage.body", default: "只统计这个面粉表里的面粉。普通面粉按重量算；种面只算其中的面粉。")
    }
    static var formulaIngredientLockToggleAccessibility: String {
        L10n.tr("formula.ingredient_lock.toggle.accessibility", default: "切换材料表锁定方式")
    }
    static var formulaIngredientLockWeight: String { L10n.tr("formula.ingredient_lock.weight", default: "锁定重量") }
    static var formulaIngredientLockPercentage: String { L10n.tr("formula.ingredient_lock.percentage", default: "锁定比例") }
    static var formulaBakerPercentageInfoAccessibility: String { L10n.tr("formula.baker_percentage.accessibility", default: "百分比说明") }
    static var formulaBakerPercentageInfoTitle: String { L10n.tr("formula.baker_percentage.title", default: "基于总面粉") }
    static var formulaBakerPercentageInfoBody: String {
        L10n.tr("formula.baker_percentage.body", default: "包含直接添加的面粉，也包含种面里的面粉。")
    }

    static var stepsOverviewTitle: String { L10n.tr("steps.overview.title", default: "制作安排") }
    static var stepsSectionTitle: String { L10n.tr("steps.section.title", default: "制作步骤") }
    static var stepsModeSection: String { L10n.tr("steps.mode.section", default: "步骤版本") }
    static var stepsModeField: String { L10n.tr("steps.mode.field", default: "版本") }
    static var stepsModeSimple: String { L10n.tr("steps.mode.simple", default: "精简版") }
    static var stepsModeCustom: String { L10n.tr("steps.mode.custom", default: "定制版") }
    static var stepsModeCustomToggle: String { L10n.tr("steps.mode.custom_toggle", default: "定制步骤") }
    static var stepsSimpleStepName: String { L10n.tr("steps.simple.step_name", default: "制作步骤") }
    static var stepsSimpleEditAccessibility: String {
        L10n.tr("steps.simple.edit.accessibility", default: "编辑精简制作步骤")
    }
    static var stepsEditorTitle: String { L10n.tr("steps.editor.title", default: "编辑步骤") }
    static var stepsTimingSection: String { L10n.tr("steps.section.timing", default: "时间与温度") }
    static var stepsMaterialsSection: String { L10n.tr("steps.section.materials", default: "材料") }
    static var stepsPageNotes: String { L10n.tr("steps.section.notes", default: "笔记") }
    static var stepsPageNotesEmpty: String { L10n.tr("steps.empty.notes", default: "还没有笔记") }
    static var stepsDoughSplitSection: String { L10n.tr("steps.dough_split.section", default: "面团分割") }
    static var stepsDoughTotalWeight: String { L10n.tr("steps.dough_split.total_weight", default: "面团总重量") }
    static var stepsDoughPieceCount: String { L10n.tr("steps.dough_split.piece_count", default: "分成份数") }
    static var stepsDoughEachWeight: String { L10n.tr("steps.dough_split.each_weight", default: "每份重量") }
    static var stepsMaterialsEmpty: String { L10n.tr("steps.empty.materials", default: "配方里还没有材料。") }
    static var stepsEmptyMessage: String { L10n.tr("steps.empty.message", default: "添加步骤后，就可以把材料分配到每一步。") }
    static var stepsMissingStep: String { L10n.tr("steps.empty.missing_step", default: "这个步骤已经不存在了") }
    static var stepsTableStep: String { L10n.tr("steps.table.step", default: "步骤") }
    static var stepsTableDuration: String { L10n.tr("steps.table.duration", default: "耗时") }
    static var stepsTableTemperature: String { L10n.tr("steps.table.temperature", default: "温度") }
    static var stepsTotalDuration: String { L10n.tr("steps.metric.total_duration", default: "总时长") }
    static var stepsAddStep: String { L10n.tr("steps.action.add_step", default: "添加步骤") }
    static var stepsEditSteps: String { L10n.tr("steps.action.edit_steps", default: "编辑步骤") }
    static var stepsDeleteStep: String { L10n.tr("steps.action.delete_step", default: "删除步骤") }
    static var stepsAssignAll: String { L10n.tr("steps.action.assign_all", default: "全部分配") }
    static var stepsConfirmAssignment: String { L10n.tr("steps.action.confirm_assignment", default: "确认分配") }
    static var stepsMarkReady: String { L10n.tr("steps.action.mark_ready", default: "标记为准备烘焙") }
    static var stepsMarkDraft: String { L10n.tr("steps.action.mark_draft", default: "改回草稿") }
    static var stepsStateDraftShort: String { L10n.tr("steps.state.draft.short", default: "Draft") }
    static var stepsStateReadyShort: String { L10n.tr("steps.state.ready.short", default: "Ready") }
    static var stepsStatusMenuAccessibility: String { L10n.tr("steps.status_menu.accessibility", default: "配方状态") }
    static var stepsReadyTooltipTitle: String { L10n.tr("steps.tooltip.ready.title", default: "已准备好") }
    static var stepsNotReadyTooltipTitle: String { L10n.tr("steps.tooltip.not_ready.title", default: "还不能烘焙") }
    static var stepsDeleteConfirmationTitle: String { L10n.tr("steps.dialog.delete.title", default: "删除这个步骤？") }
    static var stepsDeleteConfirmationMessage: String { L10n.tr("steps.dialog.delete.message", default: "删除后，这一步的材料分配也会移除。") }
    static var stepsFieldCategory: String { L10n.tr("steps.field.category", default: "分类") }
    static var stepsCategoryMakeStarter: String { L10n.tr("steps.category.make_starter", default: "制作种面") }
    static var stepsCategoryPrepWork: String { L10n.tr("steps.category.prep_work", default: "准备工作") }
    static var stepsCategoryMixing: String { L10n.tr("steps.category.mixing", default: "打面") }
    static var stepsCategoryBatterMixing: String { L10n.tr("steps.category.batter_mixing", default: "混合") }
    static var stepsCategoryFermentation: String { L10n.tr("steps.category.fermentation", default: "发酵") }
    static var stepsCategoryBaking: String { L10n.tr("steps.category.baking", default: "烘焙") }
    static var stepsCategoryShaping: String { L10n.tr("steps.category.shaping", default: "整形") }
    static var stepsCategoryProofing: String { L10n.tr("steps.category.proofing", default: "醒发") }
    static var stepsCategoryCooling: String { L10n.tr("steps.category.cooling", default: "冷却") }
    static var stepsCategoryCustom: String { L10n.tr("steps.category.custom", default: "自定义") }
    static var stepsStarterPickerSection: String { L10n.tr("steps.starter_picker.section", default: "种面") }
    static var stepsStarterPickerEmpty: String { L10n.tr("steps.starter_picker.empty", default: "配方里还没有种面。") }
    static var stepsStarterPickerAccessibility: String { L10n.tr("steps.starter_picker.accessibility", default: "选择种面") }
    static var stepsFieldName: String { L10n.tr("steps.field.name", default: "名称") }
    static var stepsFieldType: String { L10n.tr("steps.field.type", default: "类型") }
    static var stepsFieldDuration: String { L10n.tr("steps.field.duration", default: "耗时") }
    static var stepsFieldTemperature: String { L10n.tr("steps.field.temperature", default: "温度") }
    static var stepsTemperatureUnit: String { L10n.tr("steps.field.temperature_unit", default: "温标") }
    static var stepsSwitchTemperatureUnit: String { L10n.tr("steps.action.switch_temperature_unit", default: "切换温标") }
    static var stepsFieldProductionMethod: String { L10n.tr("steps.field.production_method", default: "方式") }
    static var stepsFieldNotes: String { L10n.tr("steps.field.notes", default: "备注") }
    static var stepsFoldPlanSection: String { L10n.tr("steps.fold.section.plan", default: "抱叠计划") }
    static var stepsFoldCount: String { L10n.tr("steps.fold.count", default: "抱叠次数") }
    static var stepsFoldFrequency: String { L10n.tr("steps.fold.frequency", default: "抱叠频率") }
    static var stepsFoldTotalDuration: String { L10n.tr("steps.fold.total_duration", default: "预计耗时") }
    static var stepsTextBlockAccessibility: String { L10n.tr("steps.text_block.accessibility", default: "制作步骤文字") }
    static var stepsInsertSelectedMaterials: String { L10n.tr("steps.action.insert_selected_materials", default: "加入笔记") }
    static var stepsMinuteUnit: String { L10n.tr("steps.unit.minute", default: "分钟") }
    static var stepsDegreeUnit: String { L10n.tr("steps.unit.degree", default: "°") }
    static var stepsHourShort: String { L10n.tr("steps.unit.hour_short", default: "h") }
    static var stepsMinuteShort: String { L10n.tr("steps.unit.minute_short", default: "m") }
    static var stepsNoValue: String { L10n.tr("steps.value.none", default: "-") }
    static var stepsUsedUp: String { L10n.tr("steps.assignment.used_up", default: "已用完") }
    static var stepsChooseAssignmentPercentage: String {
        L10n.tr("steps.assignment.choose_percentage", default: "选择这一步要加入的比例")
    }
    static var stepsAddWeight: String { L10n.tr("steps.assignment.add_weight", default: "加入") }
    static var stepsAddWeightAccessibility: String { L10n.tr("steps.assignment.add_weight.accessibility", default: "加入克数") }

    static func stepsCount(_ count: Int) -> String {
        L10n.format("steps.count", default: "%d 步", count)
    }

    static func stepsAssignedCount(_ count: Int) -> String {
        L10n.format("steps.assignment.count", default: "%d 个材料", count)
    }

    static func stepsAssignmentPercent(_ percent: String) -> String {
        L10n.format("steps.assignment.percent", default: "%@%%", percent)
    }

    static func stepsRemainingPercent(_ percent: String) -> String {
        L10n.format("steps.assignment.remaining_percent", default: "剩 %@%%", percent)
    }

    static func formulaAddCategory(_ category: String) -> String {
        L10n.format("formula.action.add_category", default: "添加%@", category)
    }

    static func formulaStarterDetail(flour: String, water: String) -> String {
        L10n.format("formula.starter.detail", default: "面粉 %@ / 水 %@", flour, water)
    }

    static func formulaEggDetail(count: String, water: String) -> String {
        L10n.format("formula.egg.detail", default: "%@ 个 / 水 %@", count, water)
    }

    static func formulaEggWaterDetail(_ water: String) -> String {
        L10n.format("formula.egg.water_detail", default: "水 %@", water)
    }

    static func formulaEggWaterContentNote(type: String, percent: String) -> String {
        L10n.format("formula.egg.water_content_note", default: "%@ 含水量 %@%%，水量 = 重量 × 含水量。", type, percent)
    }

    static var recipePreviewEstimatedDuration: String {
        L10n.tr("recipe_preview.estimated_duration", default: "预计耗时")
    }
    static var recipePreviewStartTime: String {
        L10n.tr("recipe_preview.start_time", default: "开始时间")
    }
    static var recipePreviewExportFailed: String {
        L10n.tr("recipe_preview.alert.export_failed", default: "导出长图失败")
    }
    static var recipePreviewExportRenderFailed: String {
        L10n.tr("recipe_preview.alert.render_failed", default: "暂时没能生成长图，请再试一次。")
    }
    static var recipePreviewSaveImageSucceeded: String {
        L10n.tr("recipe_preview.alert.save_image_succeeded", default: "已保存到照片")
    }
    static var recipePreviewSaveImageSucceededMessage: String {
        L10n.tr("recipe_preview.alert.save_image_succeeded_message", default: "这张配方长图已经保存到照片。")
    }
    static var recipePreviewSaveImageFailed: String {
        L10n.tr("recipe_preview.alert.save_image_failed", default: "暂时没能保存长图，请再试一次。")
    }
    static var recipePreviewPhotoAccessDenied: String {
        L10n.tr("recipe_preview.alert.photo_access_denied", default: "需要允许添加照片，才能把长图保存到相册。")
    }
    static var textTutorialTitle: String {
        L10n.tr("recipe_preview.text_tutorial.title", default: "文字教程")
    }
    static var copyTextTutorial: String {
        L10n.tr("recipe_preview.text_tutorial.copy", default: "复制文字教程")
    }
    static var recipePreviewIngredients: String {
        L10n.tr("recipe_preview.section.ingredients", default: "材料")
    }
    static var recipePreviewOverallNotes: String {
        L10n.tr("recipe_preview.section.overall_notes", default: "备注")
    }
    static var recipePreviewOverallNotesPlaceholder: String {
        L10n.tr("recipe_preview.placeholder.overall_notes", default: "记录这次配方的整体提醒。")
    }
    static var recipePreviewSteps: String {
        L10n.tr("recipe_preview.section.steps", default: "步骤")
    }
    static func recipePreviewStarterDetail(flour: String, water: String) -> String {
        L10n.format("recipe_preview.detail.starter", default: "%@ 粉 / %@ 水", flour, water)
    }
    static func recipePreviewEggDetail(count: String, water: String) -> String {
        L10n.format("recipe_preview.detail.egg", default: "%@ 个 / 水 %@", count, water)
    }

    static var onboardingRecipeListTitle: String {
        L10n.tr("onboarding.recipe_list.title", default: "先把配方整理起来")
    }
    static var onboardingRecipeListMessage: String {
        L10n.tr("onboarding.recipe_list.message", default: "把常做配方放进列表，按状态和最近更新快速找到下一次要做的那一个。")
    }
    static var onboardingRecipeViewTitle: String {
        L10n.tr("onboarding.recipe_view.title", default: "看清每个配方的比例")
    }
    static var onboardingRecipeViewMessage: String {
        L10n.tr("onboarding.recipe_view.message", default: "配方页会把材料、烘焙百分比、总重量和含水量放在一起，调整起来更直观。")
    }
    static var onboardingOngoingBakeTitle: String {
        L10n.tr("onboarding.ongoing_bake.title", default: "制作时跟着步骤走")
    }
    static var onboardingOngoingBakeMessage: String {
        L10n.tr("onboarding.ongoing_bake.message", default: "开始烘焙后，当前步骤、计时和材料确认会集中在正在制作页面里。")
    }
    static var onboardingStarterFeedingTitle: String {
        L10n.tr("onboarding.starter_feeding.title", default: "记录种面的喂养")
    }
    static var onboardingStarterFeedingMessage: String {
        L10n.tr("onboarding.starter_feeding.message", default: "为鲁邦种、液种和其他种面记录喂养比例、成熟时间和下一次提醒。")
    }
    static var onboardingNext: String {
        L10n.tr("onboarding.action.next", default: "下一页")
    }
    static var onboardingFinish: String {
        L10n.tr("onboarding.action.finish", default: "开始使用")
    }
    static var onboardingRecipeListPreviewTitle: String {
        L10n.tr("onboarding.preview.recipe_list.title", default: "配方列表")
    }
    static var onboardingRecipeViewPreviewTitle: String {
        L10n.tr("onboarding.preview.recipe_view.title", default: "配方视图")
    }
    static var onboardingRecipeViewPreviewDetail: String {
        L10n.tr("onboarding.preview.recipe_view.detail", default: "450g 面粉基准")
    }
    static var onboardingOngoingPreviewTitle: String {
        L10n.tr("onboarding.preview.ongoing.title", default: "正在制作")
    }
    static var onboardingStarterPreviewTitle: String {
        L10n.tr("onboarding.preview.starter.title", default: "种面喂养")
    }
    static var onboardingMetricDoughWeight: String {
        L10n.tr("onboarding.metric.dough_weight", default: "总面团")
    }
    static var onboardingMetricHydration: String {
        L10n.tr("onboarding.metric.hydration", default: "含水量")
    }
    static var onboardingMetricRemaining: String {
        L10n.tr("onboarding.metric.remaining", default: "剩余")
    }
    static var onboardingCurrentStep: String {
        L10n.tr("onboarding.metric.current_step", default: "当前步骤")
    }
    static var onboardingStarterRatio: String {
        L10n.tr("onboarding.starter.ratio", default: "喂养比例")
    }
    static var onboardingStarterMaturity: String {
        L10n.tr("onboarding.starter.maturity", default: "成熟时间")
    }
    static var onboardingStarterTemperature: String {
        L10n.tr("onboarding.starter.temperature", default: "保存温度")
    }
    static var onboardingStarterSeed: String {
        L10n.tr("onboarding.starter.seed", default: "原种")
    }
    static var onboardingStarterNextFeeding: String {
        L10n.tr("onboarding.starter.next_feeding", default: "下次喂养")
    }
    static var onboardingCelsiusUnit: String {
        L10n.tr("onboarding.unit.celsius", default: "°C")
    }
    static var onboardingSampleRecipeMilkToast: String {
        L10n.tr("onboarding.sample.recipe.milk_toast", default: "牛奶吐司")
    }
    static var onboardingSampleRecipeCountryBread: String {
        L10n.tr("onboarding.sample.recipe.country_bread", default: "高水量欧包")
    }
    static var onboardingSampleRecipeChiffon: String {
        L10n.tr("onboarding.sample.recipe.chiffon", default: "戚风蛋糕")
    }
    static var onboardingSampleUpdatedToday: String {
        L10n.tr("onboarding.sample.updated.today", default: "今天更新")
    }
    static var onboardingSampleUpdatedYesterday: String {
        L10n.tr("onboarding.sample.updated.yesterday", default: "昨天更新")
    }
    static var onboardingSampleUpdatedLastWeek: String {
        L10n.tr("onboarding.sample.updated.last_week", default: "上周更新")
    }
    static var onboardingSampleStepMixing: String {
        L10n.tr("onboarding.sample.step.mixing", default: "基础打面")
    }
    static var onboardingSampleStepFermentation: String {
        L10n.tr("onboarding.sample.step.fermentation", default: "一发")
    }
    static var onboardingSampleStepBake: String {
        L10n.tr("onboarding.sample.step.bake", default: "入炉烘烤")
    }
    static var onboardingSampleStepCompleted: String {
        L10n.tr("onboarding.sample.step.completed", default: "已完成")
    }
    static var onboardingSampleStepCurrent: String {
        L10n.tr("onboarding.sample.step.current", default: "正在计时")
    }
    static var onboardingSampleStepUpcoming: String {
        L10n.tr("onboarding.sample.step.upcoming", default: "待开始")
    }
    static var onboardingSampleTomorrowMorning: String {
        L10n.tr("onboarding.sample.tomorrow_morning", default: "明早")
    }

    static func onboardingSampleBakeCount(_ count: Int) -> String {
        L10n.format("onboarding.sample.bake_count", default: "%d 次制作", count)
    }

    static func onboardingStepProgress(_ current: Int, _ total: Int) -> String {
        L10n.format("onboarding.step.progress", default: "步骤 %d/%d", current, total)
    }
}

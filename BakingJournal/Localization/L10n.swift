import Foundation

enum L10n {
    static func tr(_ key: String, default defaultValue: String) -> String {
        NSLocalizedString(key, bundle: .main, value: defaultValue, comment: "")
    }

    static func format(_ key: String, default defaultValue: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key, default: defaultValue), locale: Locale.current, arguments: arguments)
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
    static var toastTemplateLabel: String { L10n.tr("recipe.toast.template", default: "吐司") }
    static var chiffonTemplateLabel: String { L10n.tr("recipe.chiffon.template", default: "蛋糕") }
    static var countryBreadTemplateLabel: String { L10n.tr("recipe.country_bread.template", default: "欧包") }
    static var recipeKindToast: String { L10n.tr("recipe.kind.toast", default: "吐司") }
    static var recipeKindChiffon: String { L10n.tr("recipe.kind.chiffon", default: "蛋糕") }
    static var recipeKindCountryBread: String { L10n.tr("recipe.kind.country_bread", default: "欧包") }
    static var recipeKindCustom: String { L10n.tr("recipe.kind.custom", default: "配方") }
    static var done: String { L10n.tr("common.done", default: "完成") }
    static var save: String { L10n.tr("common.save", default: "保存") }
    static var saved: String { L10n.tr("common.saved", default: "已保存") }
    static var back: String { L10n.tr("common.back", default: "返回") }
    static var share: String { L10n.tr("common.share", default: "分享") }
    static var edit: String { L10n.tr("common.edit", default: "编辑") }
    static var copy: String { L10n.tr("common.copy", default: "复制") }
    static var delete: String { L10n.tr("common.delete", default: "删除") }
    static var cancel: String { L10n.tr("common.cancel", default: "取消") }
    static var ok: String { L10n.tr("common.ok", default: "好") }
    static var start: String { L10n.tr("common.start", default: "开始") }
    static var end: String { L10n.tr("common.end", default: "结束") }
    static var time: String { L10n.tr("common.time", default: "时间") }
    static var percentage: String { L10n.tr("common.percentage", default: "百分比") }
    static var unitGram: String { L10n.tr("common.unit.gram", default: "g") }
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
    static var settingsToolboxDetail: String { L10n.tr("settings.toolbox.detail", default: "计时器和之后的烘焙小工具") }
    static var toolboxTitle: String { L10n.tr("toolbox.title", default: "工具箱") }
    static var toolboxSectionTools: String { L10n.tr("toolbox.section.tools", default: "可用工具") }
    static var toolboxKitchenTimerDetail: String { L10n.tr("toolbox.kitchen_timer.detail", default: "独立计时器，适合烘烤、发酵和醒发提醒") }
    static var noRecords: String { L10n.tr("home.empty.no_records", default: "暂无记录") }
    static var notFinished: String { L10n.tr("home.status.not_finished", default: "未结束") }
    static var stepCount: String { L10n.tr("home.label.step_count", default: "步骤数") }
    static var reviewNotes: String { L10n.tr("home.section.review_notes", default: "复盘备注") }
    static var workspaceStagePreview: String { L10n.tr("workspace.stage.preview", default: "预览") }
    static var workspaceStageFormula: String { L10n.tr("workspace.stage.formula", default: "配方") }
    static var workspaceStageSteps: String { L10n.tr("workspace.stage.steps", default: "步骤") }
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
    static var recipeSourceTemplatesSection: String { L10n.tr("recipe_source.section.templates", default: "系统预设") }
    static var recipeSourceExistingSection: String { L10n.tr("recipe_source.section.existing", default: "从已有配方开始") }
    static var recipeSourceStartBlank: String { L10n.tr("recipe_source.action.start_blank", default: "从空白开始") }
    static var recipeSourceStartBlankDetail: String { L10n.tr("recipe_source.detail.start_blank", default: "手动搭建一个全新的配方") }
    static var recipeSourceToastTemplateDetail: String { L10n.tr("recipe_source.detail.toast_template", default: "吐司基础配方") }
    static var recipeSourceChiffonTemplateDetail: String { L10n.tr("recipe_source.detail.chiffon_template", default: "蛋糕基础配方") }
    static var recipeSourceCountryBreadTemplateDetail: String { L10n.tr("recipe_source.detail.country_bread_template", default: "欧包基础配方") }
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
    static var cookEmptyNeedsSteps: String { L10n.tr("cook.empty.needs_steps", default: "先添加制作步骤，再开始。") }
    static var cookEmptyNotReady: String { L10n.tr("cook.empty.not_ready", default: "配方还没准备好，先把材料分配到步骤。") }
    static var cookCurrentStage: String { L10n.tr("cook.label.current_stage", default: "当前阶段") }
    static var cookIngredients: String { L10n.tr("cook.section.ingredients", default: "本步材料") }
    static var cookTips: String { L10n.tr("cook.section.tips", default: "操作提示") }
    static var cookNow: String { L10n.tr("cook.label.now", default: "当前") }
    static var cookFinishAt: String { L10n.tr("cook.label.finish_at", default: "预计完成") }
    static var cookNoStepIngredients: String { L10n.tr("cook.empty.no_step_ingredients", default: "这个步骤还没有分配材料。") }
    static var cookDefaultStepNote: String { L10n.tr("cook.note.default", default: "按你的记录完成这个步骤。") }
    static var cookChecked: String { L10n.tr("cook.status.checked", default: "已确认") }
    static var cookStartTimer: String { L10n.tr("cook.action.start_timer", default: "开始计时") }
    static var cookRestartTimer: String { L10n.tr("cook.action.restart_timer", default: "重新开始计时") }
    static var cookPreviousStep: String { L10n.tr("cook.action.previous_step", default: "上一步") }
    static var cookNextStep: String { L10n.tr("cook.action.next_step", default: "下一步") }
    static var cookFinish: String { L10n.tr("cook.action.finish", default: "完成") }
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

    static var kitchenTimerTitle: String { L10n.tr("kitchen_timer.title", default: "厨房计时器") }
    static var kitchenTimerOpenAccessibility: String {
        L10n.tr("kitchen_timer.action.open", default: "打开厨房计时器")
    }
    static var kitchenTimerStartAccessibility: String {
        L10n.tr("kitchen_timer.action.start", default: "开始厨房计时")
    }
    static var kitchenTimerPauseAccessibility: String {
        L10n.tr("kitchen_timer.action.pause", default: "暂停厨房计时")
    }
    static var kitchenTimerResumeAccessibility: String {
        L10n.tr("kitchen_timer.action.resume", default: "继续厨房计时")
    }
    static var kitchenTimerStopAccessibility: String {
        L10n.tr("kitchen_timer.action.stop", default: "停止厨房计时")
    }
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
    static var customStepName: String { L10n.tr("step.default.custom_name", default: "其他") }

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
    static var starterTime: String { L10n.tr("starter_profile.time", default: "时间") }
    static var starterRatio: String { L10n.tr("starter_profile.ratio", default: "比例") }
    static var starterFeedFlour: String { L10n.tr("starter_profile.feed_flour", default: "面粉") }
    static var starterFeedWater: String { L10n.tr("starter_profile.feed_water", default: "水") }
    static var starterReminderToggle: String { L10n.tr("starter_profile.reminder.toggle", default: "喂养提醒") }
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
    static var starterLastFed: String { L10n.tr("starter_library.row.last_fed", default: "喂养") }
    static var starterDeleteConfirmationTitle: String { L10n.tr("starter_library.confirm.delete.title", default: "删除这个酵种？") }
    static var starterDeleteConfirmationButton: String { L10n.tr("starter_library.confirm.delete.button", default: "删除酵种") }
    static func starterDeleteConfirmationMessage(_ name: String) -> String {
        L10n.format("starter_library.confirm.delete.message", default: "“%@” 会从酵种列表中移除。", name)
    }
    static var starterSlideToMarkFed: String { L10n.tr("starter_profile.action.slide_to_mark_fed", default: "向左滑动完成喂养") }
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
    static var formulaExportJSON: String { L10n.tr("formula.action.export_json", default: "导出 JSON") }
    static var formulaImportJSON: String { L10n.tr("formula.action.import_json", default: "导入 JSON") }
    static var formulaEmptyMaterials: String { L10n.tr("formula.empty.materials", default: "还没有材料") }
    static var formulaBakerPercentageInfoAccessibility: String { L10n.tr("formula.baker_percentage.accessibility", default: "百分比说明") }
    static var formulaBakerPercentageInfoTitle: String { L10n.tr("formula.baker_percentage.title", default: "基于总面粉") }
    static var formulaBakerPercentageInfoBody: String {
        L10n.tr("formula.baker_percentage.body", default: "包含直接添加的面粉，也包含种面里的面粉。")
    }

    static var stepsOverviewTitle: String { L10n.tr("steps.overview.title", default: "制作安排") }
    static var stepsSectionTitle: String { L10n.tr("steps.section.title", default: "制作步骤") }
    static var stepsEditorTitle: String { L10n.tr("steps.editor.title", default: "编辑步骤") }
    static var stepsTimingSection: String { L10n.tr("steps.section.timing", default: "时间与温度") }
    static var stepsMaterialsSection: String { L10n.tr("steps.section.materials", default: "材料") }
    static var stepsPageNotes: String { L10n.tr("steps.section.notes", default: "笔记") }
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
    static var stepsFieldName: String { L10n.tr("steps.field.name", default: "名称") }
    static var stepsFieldType: String { L10n.tr("steps.field.type", default: "类型") }
    static var stepsFieldDuration: String { L10n.tr("steps.field.duration", default: "耗时") }
    static var stepsFieldTemperature: String { L10n.tr("steps.field.temperature", default: "温度") }
    static var stepsTemperatureUnit: String { L10n.tr("steps.field.temperature_unit", default: "温标") }
    static var stepsSwitchTemperatureUnit: String { L10n.tr("steps.action.switch_temperature_unit", default: "切换温标") }
    static var stepsFieldProductionMethod: String { L10n.tr("steps.field.production_method", default: "方式") }
    static var stepsFieldNotes: String { L10n.tr("steps.field.notes", default: "备注") }
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
}

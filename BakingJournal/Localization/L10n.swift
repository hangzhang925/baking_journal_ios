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
    static var toastRecipeName: String { L10n.tr("recipe.toast.name", default: "吐司配方") }
    static var chiffonRecipeName: String { L10n.tr("recipe.chiffon.name", default: "戚风蛋糕") }
    static var countryBreadRecipeName: String { L10n.tr("recipe.country_bread.name", default: "欧包配方") }
    static var toastTemplateLabel: String { L10n.tr("recipe.toast.template", default: "吐司") }
    static var chiffonTemplateLabel: String { L10n.tr("recipe.chiffon.template", default: "戚风蛋糕") }
    static var countryBreadTemplateLabel: String { L10n.tr("recipe.country_bread.template", default: "欧包") }
    static var done: String { L10n.tr("common.done", default: "完成") }
    static var save: String { L10n.tr("common.save", default: "保存") }
    static var saved: String { L10n.tr("common.saved", default: "已保存") }
    static var delete: String { L10n.tr("common.delete", default: "删除") }
    static var start: String { L10n.tr("common.start", default: "开始") }
    static var end: String { L10n.tr("common.end", default: "结束") }
    static var time: String { L10n.tr("common.time", default: "时间") }
    static var percentage: String { L10n.tr("common.percentage", default: "百分比") }
    static var moreActions: String { L10n.tr("common.more_actions", default: "更多操作") }
    static var continueAction: String { L10n.tr("common.continue", default: "继续") }
    static var homeTabTitle: String { L10n.tr("home.tab.home", default: "首页") }
    static var recipeTabTitle: String { L10n.tr("home.tab.recipes", default: "配方") }
    static var bakeHistoryTabTitle: String { L10n.tr("home.tab.history", default: "记录") }
    static var bakeHistoryTitle: String { L10n.tr("home.title.history", default: "烘焙记录") }
    static var homeFeedPlaceholderTitle: String { L10n.tr("home.feed.placeholder.title", default: "首页正在发酵") }
    static var homeFeedPlaceholderBody: String { L10n.tr("home.feed.placeholder.body", default: "这里之后会变成烘焙动态和灵感 feed。") }
    static var continueBake: String { L10n.tr("home.action.continue_bake", default: "继续制作") }
    static var addRecipe: String { L10n.tr("home.action.add_recipe", default: "添加配方") }
    static var bakeAction: String { L10n.tr("home.action.bake", default: "烘焙") }
    static var activeBakeSection: String { L10n.tr("home.section.active_bake", default: "正在制作") }
    static var noRecipes: String { L10n.tr("home.empty.no_recipes", default: "暂无配方") }
    static var noRecords: String { L10n.tr("home.empty.no_records", default: "暂无记录") }
    static var notFinished: String { L10n.tr("home.status.not_finished", default: "未结束") }
    static var stepCount: String { L10n.tr("home.label.step_count", default: "步骤数") }
    static var reviewNotes: String { L10n.tr("home.section.review_notes", default: "复盘备注") }
    static var workspaceStageFormula: String { L10n.tr("workspace.stage.formula", default: "配方") }
    static var workspaceStageSteps: String { L10n.tr("workspace.stage.steps", default: "步骤") }
    static var workspaceStagePicker: String { L10n.tr("workspace.stage.picker", default: "编辑阶段") }
    static var percentagePickerAccessibility: String {
        L10n.tr("common.percentage_picker.accessibility", default: "调整百分比")
    }

    static func activeBakeProgress(stepIndex: Int, totalSteps: Int, stepName: String) -> String {
        L10n.format("home.active_bake.progress", default: "进行到第 %d/%d 步 · %@", stepIndex, totalSteps, stepName)
    }

    static func recipeCopyName(_ sourceName: String) -> String {
        L10n.format("recipe.copy_format", default: "%@ 副本", sourceName)
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
    static var starterTime: String { L10n.tr("starter_profile.time", default: "时间") }
    static var starterRatio: String { L10n.tr("starter_profile.ratio", default: "比例") }
    static var starterFeedFlour: String { L10n.tr("starter_profile.feed_flour", default: "面粉") }
    static var starterFeedWater: String { L10n.tr("starter_profile.feed_water", default: "水") }
    static var starterReminderToggle: String { L10n.tr("starter_profile.reminder.toggle", default: "喂养提醒") }
    static var starterNextFeedingDate: String { L10n.tr("starter_profile.next_feeding_date", default: "下次喂养日期") }
    static var starterReminderTimes: String { L10n.tr("starter_profile.reminder_times", default: "提醒时间") }
    static var starterFedDone: String { L10n.tr("starter_profile.action.done", default: "已完成喂养") }
    static var starterMarkFed: String { L10n.tr("starter_profile.action.mark_fed", default: "完成喂养") }
    static var starterSlideToMarkFed: String { L10n.tr("starter_profile.action.slide_to_mark_fed", default: "向左滑动完成喂养") }
    static var starterWeightAdjustHint: String { L10n.tr("starter_profile.weight.adjust_hint", default: "向左滑动减少克数，也可以直接输入") }
    static var formulaFieldName: String { L10n.tr("formula.field.name", default: "名称") }
    static var formulaDeleteMaterial: String { L10n.tr("formula.action.delete_material", default: "删除材料") }
    static var formulaYeastType: String { L10n.tr("formula.field.yeast_type", default: "酵母类型") }
    static var formulaWaterContent: String { L10n.tr("formula.field.water_content", default: "含水量") }
    static var formulaExpandMaterialSettings: String { L10n.tr("formula.action.expand_material_settings", default: "展开材料设置") }
    static var formulaCollapseMaterialSettings: String { L10n.tr("formula.action.collapse_material_settings", default: "收起材料设置") }

    static func formulaAddCategory(_ category: String) -> String {
        L10n.format("formula.action.add_category", default: "添加%@", category)
    }

    static func formulaStarterDetail(flour: String, water: String) -> String {
        L10n.format("formula.starter.detail", default: "面粉 %@ / 水 %@", flour, water)
    }

    static var recipePreviewEstimatedDuration: String {
        L10n.tr("recipe_preview.estimated_duration", default: "预计耗时")
    }
}

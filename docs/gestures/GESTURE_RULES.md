# Gesture Rules

## Rule 1

每个 Page 可以定义自己的 gesture rule。

全局上下左右 scroll 是 default gesture rule，不是永远最高优先级。

如果当前区域没有定义自己的 gesture rule，就使用 global default。

如果当前区域定义了自己的 gesture rule，例如 tab 内部的左右 sub-tab scroll、局部左右切换、card swipe，那么这个区域自己的 gesture rule 优先于 global default。

但是任何 gesture rule 都必须先判断用户意图，不能因为一点点斜向移动就抢走上下滚动或左右滚动。

## Rule 2

底部 bottom menu 是固定的 app shell。

左右切页或上下滚动时，只移动当前 page 的内容，不移动 bottom menu。

## Rule 3

左右切页必须由稳定的 page container 负责。

Main tabs 不做左右切页。Bottom menu 是 main tabs 的唯一切换入口。

拖动时，当前 page 和下一个 page 应该跟着手指平滑移动，像翻书一样。

page 内部的 card、button、list row 不应该各自动画、乱飞、缩放、改变高度或重新排版。

只有用户松手以后，page container 才决定切到下一页，或回到当前页。

## Design Principles

一个区域最好只有一个主要 gesture owner。

不要让一个 card 同时承担 display、textfield、swipe delete、drag reorder、expand editor、page switching 这些职责。

默认页面应该优先保证阅读和滚动稳定。复杂编辑应该进入明确的 edit view。

列表页可以像 iMessage 一样支持左滑删除，但是 row 默认应该是 read-only display，不应该同时放输入框和复杂拖拽。

global gesture 是 fallback，不应该抢局部区域已经声明的 gesture。

不要做 global left/right scroll 来切换 main tabs。左右 scroll 只允许出现在明确的 in-tab sub-tabs 或局部区域里。

## Change Proposal

把 app 拆成稳定的 App Shell：

- content area 负责当前 main tab 内容的上下滚动。
- bottom menu 固定在 App Shell 底部，不放进会被左右拖动的 page container。

Main tabs 之间不使用左右 scroll 切换，只能点击 bottom menu。

如果某个 main tab 内部有 sub-tabs，例如未来配方页面的 preview -> 材料 -> 步骤，才使用 page container 做左右切换。

拖动时移动 page container，所以用户拖到一半时能看到两个 page 的一部分，而不是看到空白背景。

把配方页面改成 display-first：

- 默认配方页像 preview/read view，优先展示和顺滑上下滚动。
- 点击 Edit 进入专门的 edit view。
- edit view 里再处理输入、保存、取消、排序、删除和高级设置。

把 recipe list 保持为 read-only list：

- 上下 scroll 浏览。
- tap row 进入 preview。
- swipe left 删除。
- 新建和批量编辑通过 toolbar 或 edit mode 进入。

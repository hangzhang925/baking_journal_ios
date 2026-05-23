# Gesture Rules

## Rule 1

每个 Page 可以定义自己的 gesture rule。

但是全局规则是：上下滚动永远是最高优先级。

如果用户的手势明显是在上下滑动，任何左右滑动、返回、切页、card swipe 都不应该抢这个手势，也不应该移动 UI。

# 2.2.0 变更说明

## Part 1 总体说明

2.2.0 为 Compose 侧补上一批常用组件与布局能力，让鸿蒙端在返回拦截、命中测试、自定义视图与手势处理等方面对齐其他端，并修复了多端在图片加载、文本渲染、手势与列表滚动上的一批问题。具体如下：

- **Compose 组件与布局扩充**（Compose）：新增 ModalBottomSheet、BoxWithConstraints、下拉刷新与 Switch / ProgressIndicator / Checkbox 等常用组件，补齐 textIndent、阴影颜色、beyondBoundsLineCount 等样式与布局能力；同时修复 LazyColumn 内 Image 不显示、staggeredGrid 扩容、pager / stickyHeader 嵌套滚动与文本输入测量崩溃等问题。
- **鸿蒙平台能力补齐**（鸿蒙）：返回拦截支持同步 onBackPress，新增命中测试模式、自定义视图（content slot）、手势穿透、颜色适配器与 cmodule 基本类型参数/返回值；并修复文本渲染死循环、z-index 错乱、手势事件崩溃与偏好数据多页写入混乱等问题，鸿蒙端 IDE 最低要求提升至 DevEco Studio 5.1.0。
- **多端渲染与稳定性修复**（多端、Android、iOS、跨端）：新增 3D transform 与 TextArea 内容尺寸测量；修复图片加载与占位色、PAG 素材、画布 save/restore、Android 模糊与惯性滚动等问题，vforLazy 与 RefreshView 在跳转、删除与 Scroller 使用场景下不再出现空白或错位。

历史提交可见 [2.1.1...2.2.0](https://github.com/Tencent-TDS/KuiklyUI/compare/2.1.1...2.2.0)，完整条目见下方 Part 2。

---

## Part 2 变更汇总

### Android

- feat: Android font adapter support get contextParams · [#184](https://github.com/Tencent-TDS/KuiklyUI/pull/184)
- fix: `Scroller` in `PageList` may not be able to scroll · [#193](https://github.com/Tencent-TDS/KuiklyUI/pull/193)
- feat: Android嵌套滚动支持OverScroll · [#199](https://github.com/Tencent-TDS/KuiklyUI/pull/199)
- fix: Android add package name to broadcast intent · [#209](https://github.com/Tencent-TDS/KuiklyUI/pull/209)
- fix: Android blurView blurRadius effect inconsistent · [#213](https://github.com/Tencent-TDS/KuiklyUI/pull/213)
- fix: Android make text buildLayout threadsafe to avoid IndexOutOfBoun… · [#230](https://github.com/Tencent-TDS/KuiklyUI/pull/230)
- fix: BlurView not working on CanvasView · [#235](https://github.com/Tencent-TDS/KuiklyUI/pull/235)

### iOS

- feat: ios tintColor apply color adapter · [#140](https://github.com/Tencent-TDS/KuiklyUI/pull/140)
- fix: iOS change PAGImageProtocol FromPath · [#141](https://github.com/Tencent-TDS/KuiklyUI/pull/141)
- feat: ios pass assets src to image adapter if not found · [#142](https://github.com/Tencent-TDS/KuiklyUI/pull/142)
- fix: ios text area set cursor position after pasting · [#143](https://github.com/Tencent-TDS/KuiklyUI/pull/143)
- feat: ios image support loadFailure event · [#145](https://github.com/Tencent-TDS/KuiklyUI/pull/145)
- fix: iOS crash when window is nil · [#147](https://github.com/Tencent-TDS/KuiklyUI/pull/147)
- fix: repeat alloc delegate protocol · [#161](https://github.com/Tencent-TDS/KuiklyUI/pull/161)
- fix: default placeholder color · [#174](https://github.com/Tencent-TDS/KuiklyUI/pull/174)
- fix: iOS suppoert canvas save restore savelayer translate scale rotate skew · [#191](https://github.com/Tencent-TDS/KuiklyUI/pull/191)

### 鸿蒙

- fix: infinite loop in text rendering · [#159](https://github.com/Tencent-TDS/KuiklyUI/pull/159)
- feat: ohos get arkTS view with tag · [#150](https://github.com/Tencent-TDS/KuiklyUI/pull/150)
- fix: OnInterruptGestureEvent not working · [#177](https://github.com/Tencent-TDS/KuiklyUI/pull/177)
- feat: ohos support set assets dir · [#182](https://github.com/Tencent-TDS/KuiklyUI/pull/182)
- chore: add an api to disable view reuse · [#183](https://github.com/Tencent-TDS/KuiklyUI/pull/183)
- feat: support hit test mode setting on ohos · [#180](https://github.com/Tencent-TDS/KuiklyUI/pull/180)
- feat: custom view based on content slot · [#186](https://github.com/Tencent-TDS/KuiklyUI/pull/186)
- feat: ohos gesture through · [#201](https://github.com/Tencent-TDS/KuiklyUI/pull/201)
- feat: add c color adapter support · [#205](https://github.com/Tencent-TDS/KuiklyUI/pull/205)
- fix: gesture event crash and avoid raw pointer usages · [#204](https://github.com/Tencent-TDS/KuiklyUI/pull/204)
- fix: text area specific props · [#208](https://github.com/Tencent-TDS/KuiklyUI/pull/208)
- chore: avoid frequent log in release build · [#211](https://github.com/Tencent-TDS/KuiklyUI/pull/211)
- fix: incorrect z-index · [#220](https://github.com/Tencent-TDS/KuiklyUI/pull/220)
- feat: wrap spinlock into and object · [#222](https://github.com/Tencent-TDS/KuiklyUI/pull/222)
- feat: add unregister invocation and use spin lock to ensure thread sa… · [#223](https://github.com/Tencent-TDS/KuiklyUI/pull/223)
- feat: use new gesture apis when available · [#218](https://github.com/Tencent-TDS/KuiklyUI/pull/218)
- docs: update project readme · [#226](https://github.com/Tencent-TDS/KuiklyUI/pull/226)
- fix: use linear interpolation for tintColor blending on ohos · [#227](https://github.com/Tencent-TDS/KuiklyUI/pull/227)
- fix: ohos preference module multi-page data writing disorder · [#242](https://github.com/Tencent-TDS/KuiklyUI/pull/242)
- feat: ohos support cmodule param and return value basic type · [#245](https://github.com/Tencent-TDS/KuiklyUI/pull/245)
- chore: update version to 2.2.0 · [#247](https://github.com/Tencent-TDS/KuiklyUI/pull/247)

### Compose

- fix: compose `Image` may not show in `LazyColumn` · [#148](https://github.com/Tencent-TDS/KuiklyUI/pull/148)
- fix: fix bugs in pager and stickyHeader components for nested scrolling · [#152](https://github.com/Tencent-TDS/KuiklyUI/pull/152)
- feat: support beyondBoundsLineCount for lazy grid · [#165](https://github.com/Tencent-TDS/KuiklyUI/pull/165)
- feat: support pullToRefresh · [#171](https://github.com/Tencent-TDS/KuiklyUI/pull/171)
- fix: staggeredGrid capacity expansion issue · [#188](https://github.com/Tencent-TDS/KuiklyUI/pull/188)
- feat: support ModalBottomSheet · [#190](https://github.com/Tencent-TDS/KuiklyUI/pull/190)
- feat: support BoxWithConstraints · [#192](https://github.com/Tencent-TDS/KuiklyUI/pull/192)
- feat: support textIndent · [#195](https://github.com/Tencent-TDS/KuiklyUI/pull/195)
- fix: remove outdated comment · [#206](https://github.com/Tencent-TDS/KuiklyUI/pull/206)
- feat: add switch and ProgressIndicator component · [#224](https://github.com/Tencent-TDS/KuiklyUI/pull/224)
- fix: temp fix textfield mearsure crash · [#229](https://github.com/Tencent-TDS/KuiklyUI/pull/229)
- feat: shadow color · [#236](https://github.com/Tencent-TDS/KuiklyUI/pull/236)
- feat: add Checkbox component · [#240](https://github.com/Tencent-TDS/KuiklyUI/pull/240)

### 跨端

- fix:修复 Image组件扩展函数代码错误问题。 · [#135](https://github.com/Tencent-TDS/KuiklyUI/pull/135)
- Vforlazy updates · [#137](https://github.com/Tencent-TDS/KuiklyUI/pull/137)
- fix: remove scrollview get/remove child fun · [#153](https://github.com/Tencent-TDS/KuiklyUI/pull/153)
- feat: expose hexColor getter, add opacity extension method · [#169](https://github.com/Tencent-TDS/KuiklyUI/pull/169)
- fix: vforLazy may show blank after call scrollToPosition · [#196](https://github.com/Tencent-TDS/KuiklyUI/pull/196)
- feat:support RefreshView in Scroller use · [#139](https://github.com/Tencent-TDS/KuiklyUI/pull/139)

### 多端

- feat: ohos support sync onBackPress · [#126](https://github.com/Tencent-TDS/KuiklyUI/pull/126)
- fix: check src empty before call fetchDrawable & remove duplicate registry · [#156](https://github.com/Tencent-TDS/KuiklyUI/pull/156)
- fix: some Android and ohos and core problems · [#179](https://github.com/Tencent-TDS/KuiklyUI/pull/179)
- feat: 3D transform support · [#181](https://github.com/Tencent-TDS/KuiklyUI/pull/181)
- feat: `TextArea` support measure content size · [#189](https://github.com/Tencent-TDS/KuiklyUI/pull/189)
- feat: add iOS swift SPM support · [#231](https://github.com/Tencent-TDS/KuiklyUI/pull/231)

### 其他

- docs: add docs · [#200](https://github.com/Tencent-TDS/KuiklyUI/pull/200)
- docs: update readme · [#202](https://github.com/Tencent-TDS/KuiklyUI/pull/202)
- docs: raise ohos ide requirement to  5.1.0(18) · [#225](https://github.com/Tencent-TDS/KuiklyUI/pull/225)
- chore: correct docs about getString in sp module · [#216](https://github.com/Tencent-TDS/KuiklyUI/pull/216)
- Docs add best practices · [#239](https://github.com/Tencent-TDS/KuiklyUI/pull/239)
- chore: android demo navigation bar overlay · [#237](https://github.com/Tencent-TDS/KuiklyUI/pull/237)
- docs: add demo app experience qrcode · [#244](https://github.com/Tencent-TDS/KuiklyUI/pull/244)

---

## Part 3 破坏性变更

本版无业务可感知的破坏性变更。

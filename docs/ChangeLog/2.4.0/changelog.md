# 2.4.0 变更说明

## Part 1 总体说明

2.4.0 将 Kuikly 的运行目标扩展到 H5 与小程序，显著补齐 Compose 侧常用组件与手势能力，并修复了一批鸿蒙渲染与多端内存、滚动方面的稳定性问题。具体如下：

- **H5 与小程序运行目标**：新增 H5 与小程序两个运行目标，同一套 Kuikly 页面可直接运行在浏览器与小程序中。
- **Compose 组件与手势能力**：补齐 AppBar、Scaffold、SnackBar、AnchoredDraggable 等常用组件，LazyStaggeredGrid 支持 beyondBoundsItemCount 预加载，新增 density scale 与 keyboardActions，并支持 Kotlin 1.9 的 JS IR 编译。
- **画布与鸿蒙渲染**：补齐鸿蒙 canvas API，cModule 支持按 tag 获取 View，并修复 NAPI 错误检查、触摸偏移、HitTestMode 默认值与画布更新等若干问题。
- **内存与滚动稳定性**：修复 iOS 侧内存泄漏；Android pagView 支持 setProgress、图片支持额外参数；列表滑动中的触摸事件保持可用，滚动与尺寸变化引发的空白等问题一并修复。

历史提交可见 [2.2.0...2.4.0](https://github.com/Tencent-TDS/KuiklyUI/compare/2.2.0...2.4.0)，完整条目见下方 Part 2。

---

## Part 2 变更汇总

### Android

- feat: Android pagView support setProgress and call · [#295](https://github.com/Tencent-TDS/KuiklyUI/pull/295)
- fix: perform sync method in `onSizeChanged` may break ui render · [#314](https://github.com/Tencent-TDS/KuiklyUI/pull/314)
- fix: make sublist scroll down priority higher than parentlist overscroll · [#324](https://github.com/Tencent-TDS/KuiklyUI/pull/324)
- feat: Android image support params · [#334](https://github.com/Tencent-TDS/KuiklyUI/pull/334)
- fix: android cursor color avoid depend ColorParseAdapter · [#335](https://github.com/Tencent-TDS/KuiklyUI/pull/335)

### iOS

- fix: demo memory leak · [#309](https://github.com/Tencent-TDS/KuiklyUI/pull/309)
- Fix：修复KuiklyBaseView 、KuiklyRenderViewControllerBaseDelegator内存泄漏 · [#317](https://github.com/Tencent-TDS/KuiklyUI/pull/317)
- feat: support setting custom resource directory on iOS · [#329](https://github.com/Tencent-TDS/KuiklyUI/pull/329)

### 鸿蒙

- fix: text area typo · [#250](https://github.com/Tencent-TDS/KuiklyUI/pull/250)
- fix: TouchParams compile issue · [#260](https://github.com/Tencent-TDS/KuiklyUI/pull/260)
- fix: napi error check · [#263](https://github.com/Tencent-TDS/KuiklyUI/pull/263)
- feat: complete canvas api for ohos · [#264](https://github.com/Tencent-TDS/KuiklyUI/pull/264)
- fix: ohos render compile issue · [#279](https://github.com/Tencent-TDS/KuiklyUI/pull/279)
- fix: ohos KRForwardArkTSViewV2 remove error · [#293](https://github.com/Tencent-TDS/KuiklyUI/pull/293)
- feat: ohos cModule support get View with tag · [#296](https://github.com/Tencent-TDS/KuiklyUI/pull/296)
- fix: prevent crash for network biz exception · [#340](https://github.com/Tencent-TDS/KuiklyUI/pull/340)
- feat: reuse leaf node only · [#342](https://github.com/Tencent-TDS/KuiklyUI/pull/342)
- fix: forwardArkTSView HitTestMode default value none · [#345](https://github.com/Tencent-TDS/KuiklyUI/pull/345)

### Compose

- feat: LazyStaggeredGrid support beyondBoundsItemCount · [#238](https://github.com/Tencent-TDS/KuiklyUI/pull/238)
- feat: support AppBar · [#257](https://github.com/Tencent-TDS/KuiklyUI/pull/257)
- fix: Fix scroll blank space due to LazyColumn size changes · [#262](https://github.com/Tencent-TDS/KuiklyUI/pull/262)
- feat: compose AnchoredDraggable · [#266](https://github.com/Tencent-TDS/KuiklyUI/pull/266)
- feat: compose Scaffold & SnackBar · [#270](https://github.com/Tencent-TDS/KuiklyUI/pull/270)
- fix: Image placeholder not showing · [#280](https://github.com/Tencent-TDS/KuiklyUI/pull/280)
- feat: remove key warpper while render view size change · [#287](https://github.com/Tencent-TDS/KuiklyUI/pull/287)
- fix: slider thumb and track order is wrong · [#288](https://github.com/Tencent-TDS/KuiklyUI/pull/288)
- fix: Modifier.shadow and Modifier.setProp conflicts · [#291](https://github.com/Tencent-TDS/KuiklyUI/pull/291)
- fix: canvas update issue · [#299](https://github.com/Tencent-TDS/KuiklyUI/pull/299)
- fix: add material3 `LocalTextStyle` and `ProvideTextStyle` · [#306](https://github.com/Tencent-TDS/KuiklyUI/pull/306)
- fix: fix touch offset issue on ohos · [#307](https://github.com/Tencent-TDS/KuiklyUI/pull/307)
- Zenipchen/fixtextissue · [#316](https://github.com/Tencent-TDS/KuiklyUI/pull/316)
- fix: fix scroll error after animateScrollTo · [#322](https://github.com/Tencent-TDS/KuiklyUI/pull/322)
- feat: compose density scale and keyboardActions · [#338](https://github.com/Tencent-TDS/KuiklyUI/pull/338)
- fix: quick replace update kuikly view frame · [#351](https://github.com/Tencent-TDS/KuiklyUI/pull/351)
- feat: add compose js ir in kotlin 1.9 · [#353](https://github.com/Tencent-TDS/KuiklyUI/pull/353)

### 跨端

- feat: add `ReactiveObserver` verify failed handler · [#281](https://github.com/Tencent-TDS/KuiklyUI/pull/281)

### 多端

- feat: keep touch events work when the list is sliding. · [#251](https://github.com/Tencent-TDS/KuiklyUI/pull/251)
- feat: support h5 && miniapp · [#349](https://github.com/Tencent-TDS/KuiklyUI/pull/349)

### 其他

- feat: add skinning function to App demo · [#219](https://github.com/Tencent-TDS/KuiklyUI/pull/219)
- chore: change copyright notice entity form THL A29 Limited to Tencent · [#248](https://github.com/Tencent-TDS/KuiklyUI/pull/248)
- docs: update demo_experience.md · [#252](https://github.com/Tencent-TDS/KuiklyUI/pull/252)
- chore: update gradle settings · [#254](https://github.com/Tencent-TDS/KuiklyUI/pull/254)
- feat(demo): add multilingual support to App demo · [#256](https://github.com/Tencent-TDS/KuiklyUI/pull/256)
- docs: add privacy policy · [#265](https://github.com/Tencent-TDS/KuiklyUI/pull/265)
- feat: add AI chat demo which supports real-time markdown render · [#276](https://github.com/Tencent-TDS/KuiklyUI/pull/276)
- docs: ios asset resource · [#282](https://github.com/Tencent-TDS/KuiklyUI/pull/282)
- docs: update spm integration guidelines · [#283](https://github.com/Tencent-TDS/KuiklyUI/pull/283)
- feat(demo): small screen adaptation · [#284](https://github.com/Tencent-TDS/KuiklyUI/pull/284)
- chore: add issue template · [#289](https://github.com/Tencent-TDS/KuiklyUI/pull/289)
- chore: update issue template · [#290](https://github.com/Tencent-TDS/KuiklyUI/pull/290)
- chore: update website changelog · [#297](https://github.com/Tencent-TDS/KuiklyUI/pull/297)
- chore: temporarily disable ai demo · [#304](https://github.com/Tencent-TDS/KuiklyUI/pull/304)
- fix: compile issue · [#305](https://github.com/Tencent-TDS/KuiklyUI/pull/305)
- chore: update reviewers · [#310](https://github.com/Tencent-TDS/KuiklyUI/pull/310)
- chore: delete unused header file · [#311](https://github.com/Tencent-TDS/KuiklyUI/pull/311)
- update readme qrcode · [#331](https://github.com/Tencent-TDS/KuiklyUI/pull/331)
- chore: doc logo change · [#332](https://github.com/Tencent-TDS/KuiklyUI/pull/332)
- chore: update version to 2.4.0 · [#352](https://github.com/Tencent-TDS/KuiklyUI/pull/352)

---

## Part 3 破坏性变更

本版无业务可感知的破坏性变更。

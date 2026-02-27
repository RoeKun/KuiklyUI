# TurboDisplay 首屏加速机制

## 介绍
TurboDisplay 机制是一套用于加速首屏显示的优化机制，采用自动智能采集机制，业务可以在不做任何修改的情况下对首屏显示进行加速。


## 实现原理

TurboDisplay的核心作用是让绝大多数页面不需要做任何改造即可加速原本页面首屏的展示速度，例如原本的页面是先展示Loading，再展示具体页面内容，那么TurboDisplay加速的是Loading的展示；如果原本的页面是先展示缓存的数据，再展示真实数据，那么TurboDisplay加速的是缓存数据的展示。

而 TurboDisplay 实现智能采集的载体是设计了三棵DOM树。

- 缓存树：持久化存储在本地文件中，保存页面的完整结构，生命周期跨越页面重启。
- 真实树：反映当前页面实时渲染状态的节点树，随页面生命周期创建和销毁。
- 快照树：周期性的真实树快照，实际缓存的目标。

三棵树的协作过程可以分为三个阶段，第一阶段是缓存树与真实树的对比，第二阶段是真实树与缓存树的对比 以及 属性更新
阶段1：页面启动加载时，读取TurboDisplay的缓存文件，反序列化形成缓存树。而Native接收Kuikly Kotlin的渲染指令，形成真实树。在真实树的形成过程中，Native 执行第一次Diff-View 算法，上屏缓存的首屏内容。完成首屏的快速的展示。# 这里给Diff-View的说明图

阶段2：Native 执行第二次 Diff-View 算法，将真实树与缓存树对比，将当前真实首屏与缓存首屏比对，局部更新页面内容，展示正确的首屏效果。

阶段1与阶段2完成后，TubroDisplay机制下页面已经完成完成首屏渲染。后续直到完全渲染前，TubroDisplay机制还会自动智能采集首屏view的属性变化，用于下次秒开首屏时显示准确的内容。# 这里给Diff-DOM的说明图


## 使用指引

TurboDisplay 的使用可包括Kotlin侧所定义的view控制和Module方法。Native侧的启动开关以及TurboDisplay能力配置。

### Kotlin侧
#### 属性
- turboDisplayAutoUpdateEnable(Boolean)

TurboDisplay会自动更新同结构的节点，使用该属性可以控制是否不更新同结构的节点，默认是true，设置为false则关闭自动更新，只影响设置该属性的节点及其子孙节点

如上图所示节点5、节点6以及节点7在结构一致的情况下发生属性的变化，变成了节点5'、节点6'以及节点7'，原本会被更新到缓存树上，但是由于节点5'设置了turboDisplayAutoUpdateEnable(false)，所以节点5'及其子孙节点节点6'和节点7'都不会更新到缓存树上

使用示例：
```kotlin
View {
    attr {
        turboDisplayAutoUpdateEnable(false)
    }
}
```
#### 方法

TurboDisplayModule 提供了管理 TurboDisplay 的相关方法：

- setCurrentUIAsFirstScreenForNextLaunch(extraContent)：手动采集当前视图状态保存到缓存，调用后关闭自动采集。
- flushTurboDisplayCache(iCloseUpdate)：立即刷新缓存，iCloseUpdate=true 时关闭后续更新。
- clearCurrentPageCache()：清除当前页面缓存。
- clearAllCache()：清除所有页面缓存。
- isTurboDisplay()：判断本次打开是否使用缓存上屏。

使用示例：
```kotlin
acquireModule<TurboDisplayModule>(TurboDisplayModule.MODULE_NAME).setCurrentUIAsFirstScreenForNextLaunch(extraContent)
```

### Kotlin侧

#### TurboDisplayKey（启动开关）

TurboDisplayKey 是 TurboDisplay 的启动开关，必须在 Native 侧配置。若未设置或为空字符串，则关闭 TurboDisplay。

iOS 配置
```objectivec
// KuiklyRenderViewController.m
- (NSString *)turboDisplayKey {
  return pageName;  // 返回 nil 则关闭 TurboDisplay
  }
  ```

鸿蒙配置：
```typeScript
// Index.ets
KRNativeRender({
turboDisplayKey: pageName  // 空字符串则关闭 TurboDisplay
})
```

#### TurboDisplayConfig（功能配置）

TurboDisplayConfig 用于功能配置，主要参数包括：

- diffDOMMode：设置首屏渲染结束后 待缓存节点的属性更新的模式，Normal（默认）只更新同结构节点的属性，StructureChange 支持结构变化以及节点的属性变更。
- diffViewMode：设置视图更新算法的模式，Normal（默认）为同步执行，Delayed 为延迟执行。延迟执行是为了回放首屏期间所存在的交互事件，如滚动、点击等。鸿蒙侧由于渲染指令响应时序的问题，在执行页面恢复的场景中必须开启。
- autoUpdateTurboDisplay：自动更新开关，默认开启。用于控制是否自动采集首屏之后节点属性值的变化，执行diff-DOM。
- persistentRealTree：真实树持久更新开关，默认开启，用于控制是否还自动维护页面实时状态的DOM树。若关闭，则真实树将持久保留为首屏状态所对应的节点树。此开关是自动更新能力的必要前提，若关闭，则自动更新纵使是true，也不会执行自动更新。

iOS 配置示例：
```objectivec
// KuiklyRenderViewController.m
- (KRTurboDisplayConfig *)turboDisplayConfig {
  KRTurboDisplayConfig *config = [[KRTurboDisplayConfig alloc] init];
  [config enableDelayedDiff];
  [config enableStructureAwareDiffDOM];
  return config;
  }
  ```

鸿蒙配置示例：
```typescript
// Index.ets
KRNativeRender({
turboDisplayKey: 'PageName_CacheKey',
turboDisplayConfig: {
diffViewMode: DiffViewMode.DELAYED,
diffDOMMode: DiffDOMMode.STRUCTURE_CHANGE
}
})
```


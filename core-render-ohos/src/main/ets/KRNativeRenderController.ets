/*
 * Tencent is pleased to support the open source community by making KuiklyUI
 * available.
 * Copyright (C) 2025 Tencent. All rights reserved.
 * Licensed under the License of KuiklyUI;
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://github.com/Tencent-TDS/KuiklyUI/blob/main/LICENSE
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { KRExceptionCallback } from './manager/KRNativeInstance';
import render from 'libkuikly.so';
import { AvoidAreaChangeParams, Insets, KRAny, KRRecord, KRValue } from './utils/KRDataTypes';
import { KRNativeManager } from './manager/KRNativeManager';
import { KRConvertUtil } from './utils/KRConvertUtil';
import { common, EnvironmentCallback } from '@kit.AbilityKit';
import { KRSize } from './foundation/KRSize';
import { display, window } from '@kit.ArkUI';
import { KRRect } from './foundation/KRRect';
import { KRRenderViewExportCreator } from './components/base/KRBaseViewExport';
import { KRRenderModuleExportCreator } from './modules/base/IKRModuleExport';
import { KRRenderLog } from './adapter/KRRenderLog';
import { BusinessError } from '@kit.BasicServicesKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import { KRRenderExecuteModeBase } from './context/KRRenderExecuteModeBase';
import { KRRenderNativeMode } from './context/KRRenderNativeMode';
import { i18n } from '@kit.LocalizationKit';
import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';

/** window尺寸变化事件名 */
export const KRWindowSizeDidChangedEventKey = 'windowSizeDidChanged';

/** RootView尺寸变化事件名. */
export const KRRootViewSizeDidChangedEventKey = 'rootViewSizeDidChanged';

/** 页面可见事件 */
export const KRPageDidAppearEventKey = 'viewDidAppear';

/** 页面不可见事件 */
export const KRPageDidDisappearEventKey = 'viewDidDisappear';

export const KRConfigurationUpdateEventKey = 'configurationDidChanged';

/** 字典key常量 */
export const KRRootViewWidthKey = 'rootViewWidth';

export const KRRootViewHeightKey = 'rootViewHeight';

export const KRUrlKey = 'url';

export const KRStatusBarHeightKey = 'statusBarHeight';

export const KRPlatformKey = 'platform';

export const KRDeviceWidthKey = 'deviceWidth';

export const KRDeviceHeightKey = 'deviceHeight';

export const KRActivityWidthKey = 'activityWidth';

export const KRActivityHeightKey = 'activityHeight';

export const KROsVersionKey = 'osVersion';

export const KRAppVersionKey = 'appVersion';

export const KRParamKey = 'param';

export const KRWidthKey = 'width';

export const KRHeightKey = 'height';

export const KRNativeBuild = 'nativeBuild';

export const KRSafeAreaInsets = 'safeAreaInsets';

export const KRDensityInfo = 'densityInfo';

export const KRExecuteMode = 'executeMode';

export const KRContextCode = 'contextCode';

export const KRDensity = 'density';

export const KRSystemLanguageKey = 'sysLang';

export const KRFeature = 'feature';

const KROnBackPressedKey = 'onBackPressed';

enum KRBackPressConsumedState {
  Undefined = 0,
  Consumed,
  NotConsumed
}

/** safeArea 纠偏：页面与屏幕尺寸匹配容差（dp） */
const KRSafeAreaMatchToleranceDp = 1.0;
/** safeArea 纠偏：真实安全区不可能超过页面对应轴的比例，超出即判定为系统注入的异常值 */
const KRSafeAreaMaxReasonableFraction = 0.25;

/** safeArea 纠偏结果载体（仅内部使用） */
class KRSafeAreaResolution {
  top: number = 0;
  left: number = 0;
  bottom: number = 0;
  right: number = 0;
  correctedHorizontal: boolean = false;
  correctedBottom: boolean = false;
}

/** 全局递增实例ID */
let gGlobalInstanceId = 0;

export class KRNativeRenderController {
  /**
   * 页面实例 id
   */
  instanceId: string = '';
  /**
   * 执行上下文code，驱动渲染对应的代码。KRRenderExecuteMode.Native模式时: 传递 ''
   */
  contextCode: string = '';
  /**
   * assets资源的实际路径，如未设置，默认在resfile中找assets资源
   */
  assetsDir: string = '';
  /**
   * 执行模式
   */
  executeMode: KRRenderExecuteModeBase = KRRenderNativeMode.Native;
  /**
   * 页面名字
   */
  pageName: string = '';
  /**
   * 透传给KR侧的页面数据
   */
  pageParams: KRRecord = {};
  /**
   * 鸿蒙侧，向用户提供新旧两种KRSharedPreferencesMoudle使用的控制开关（变量）
   */
  useOhSharedPreferences: boolean = false;
  /**
   * 所在的窗口Id
   */
  windowId: string = ""
  /**
   * SizeChanged 执行时机是否需提前至 onSizeChanged 而非 onAreaChanged，以避免页面 Size 变化时出现白屏
   */
  private sizeChangeHandledByOnSizeChange: boolean = false;
  /** safeArea 纠偏：上次屏幕短边（dp），用于检测物理显示设备变化并重置 bottom 缓存 */
  private safeAreaResolverScreenShort: number = 0;
  /** safeArea 纠偏：上次屏幕长边（dp） */
  private safeAreaResolverScreenLong: number = 0;
  /** safeArea 纠偏：最近一次可靠的 bottom 安全区值（dp），异常帧丢弃后兜底，避免导航条区域闪一帧 */
  private safeAreaLastReliableBottom: number | null = null;

  private lifecycleCallbacks: Array<IKuiklyRenderViewLifecycleCallback> = [];

  private fontSizeScale = 1.0;
  private fontWeightScale = 1.0;
  /**
   * 输入法模式
   * 在输入法中，获取不到window和safearea，所以只有有view rect后就可以初始化kuikly
   */
  imeMode = false;
  private environmentCallbackId = -1;
  private densityPixels: number = 0;
  private uiContext: UIContext | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  private didInit: Boolean = false;
  private lazyTasks: (() => void)[] = [];
  /**
   * 外部自定义存放在Controller中的数据, 在Module中，可通过Controller来获取数据
   */
  private externalParams: KRRecord = {};
  /**
   * 外部自定义的Controller, 可设置此值，然后在Module中获取
   */
  private externalController: object | null = null;
  private safeAreaRect: KRRect | null = null;
  private viewRect: KRRect | null = null;
  private windowRect: KRRect | null = null;
  private updateSafeInsetsHandler: number = 0;
  private windowClass: window.Window | null = null;
  private destroyed: boolean = false;
  private onWindowSizeChanged: Callback<window.Size> = (params: window.Size) => {
    if (this.imeMode) {
      return;
    }
    const density = this.getWindowActiveDensity();
    const w = params.width / density;
    const h = params.height / density;

    // 同步更新窗口尺寸缓存：旋转/分屏后 windowRect 需跟随变化，
    // 否则 notifySizeChange 下发的 deviceWidth/deviceHeight 会冻结在初始竖屏值，
    // Compose Configuration.screenWidthDp/screenHeightDp 不跟随旋转（BUG-1）
    this.windowRect = new KRRect(0, 0, w, h);
    // 修复BUG-1原理：windowRect 是 deviceWidth/Height 的唯一数据源，必须与窗口同步更新，
    // 否则 Compose Configuration.screenWidthDp/screenHeightDp 冻结在初始朝向
    KRRenderLog.i('Rotation', `windowRect synced: ${w.toFixed(1)}x${h.toFixed(1)} (deviceWidth/Height source updated)`);

    this.notifyWindowSizeChanged(w, h);
    // 同步刷新 safeArea 数据但不下发（详见 refreshSafeAreaSync 注释）：
    // 原始 doUpdateSafeArea() 走 setTimeout(0)，会晚于 onAreaChange/其他下发通道，
    // 用「旧 viewRect + 新 safeAreaRect」算出错配 insets（实测 bottom=534.9/right=502.0）
    this.refreshSafeAreaSync();
  };
  private avoidAreaListener: Callback<AvoidAreaChangeParams> = (params: AvoidAreaChangeParams) => {
    if (this.imeMode) {
      return;
    }
    if (params.type == window.AvoidAreaType.TYPE_SYSTEM ||
      params.type == window.AvoidAreaType.TYPE_CUTOUT ||
      params.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      this.doUpdateSafeArea();
    }
  };

  /**
   * 同步刷新 safeAreaRect 缓存，但不触发下发。
   * 仅用于 windowSizeChange：doUpdateSafeArea() 走 setTimeout(0)，存在与其他下发通道的时序竞争；
   * 此法让 safeAreaRect 与 windowRect 在同一时刻就绪，错配窗口由 L1 纠偏兜底。
   */
  private refreshSafeAreaSync(): void {
    if (this.imeMode || this.windowClass == null) {
      return;
    }
    // 取消排队中的去抖任务：本次已同步取到最新值，避免稍后重复赋值与重复下发
    if (this.updateSafeInsetsHandler > 0) {
      clearTimeout(this.updateSafeInsetsHandler);
      this.updateSafeInsetsHandler = 0;
    }
    try {
      const synced = this.getSafeAreaRect(this.windowClass);
      this.onSafeAreaInsetsChanged(synced, false);
      // 修复时序错配原理：safeAreaRect 与 windowRect 同帧就绪且不下发，
      // 避免 setTimeout(0) 到期时用「旧 viewRect − 新 safeAreaRect」算出错配 insets
      KRRenderLog.i('Rotation', `safeArea synced in-place (no notify): ${synced.width.toFixed(1)}x${synced.height.toFixed(1)}@(${synced.x.toFixed(1)},${synced.y.toFixed(1)})`);
    } catch (e) {
      KRRenderLog.e('Window', `Error obtaining safearea, code:${e.code}`);
    }
  }

  private doUpdateSafeArea() {
    if (this.imeMode) {
      return;
    }
    if (this.updateSafeInsetsHandler > 0) {
      clearTimeout(this.updateSafeInsetsHandler);
    }
    this.updateSafeInsetsHandler = setTimeout(() => {
      this.updateSafeInsetsHandler = 0;
      try {
        this.onSafeAreaInsetsChanged(this.getSafeAreaRect(this.windowClass!));
      } catch (e) {
        KRRenderLog.e('Window', `Error obtaining safearea, code:${e.code}`);
      }
    }, 0);
  }

  init(uiContext: UIContext,
    uiAbilityContext: common.UIAbilityContext,
    executeMode: KRRenderExecuteModeBase,
    pageName: string,
    pageParams: KRRecord,
    contextCode: string,
    imeMode: boolean,
    assetsDir: string,
    useOhSharedPreferences: boolean,
    viewRect?: KRRect,
  ) {
    this.uiContext = uiContext;
    this.uiAbilityContext = uiAbilityContext;
    this.executeMode = executeMode;
    this.pageName = pageName;
    this.pageParams = pageParams;
    this.contextCode = contextCode;
    this.imeMode = imeMode;
    this.assetsDir = assetsDir;
    if (viewRect) {
      this.viewRect = viewRect;
    }
    this.useOhSharedPreferences = useOhSharedPreferences;
    gGlobalInstanceId++;
    this.instanceId = gGlobalInstanceId + '';
    render.OnLaunchStart(this.instanceId, executeMode.mode); //  页面启动事件通知到native层，用于Performance性能采集
    try {
      this.windowClass = window.findWindow(uiContext.getWindowName());
    } catch (e) {
      KRRenderLog.e(`window`, `findWindow, stack: ${e}`);
    }
    this.densityPixels = this.getWindowActiveDensity();
    KRNativeManager.getInstance().createNativeInstance(this.instanceId, uiContext, this);
    const currentConfig = uiAbilityContext.config;
    this.fontSizeScale = currentConfig.fontSizeScale ? currentConfig.fontSizeScale : 1;
    if (!this.fontSizeScaleFollowSystem()) {
      this.fontSizeScale = 1;
    }
    this.fontWeightScale = currentConfig.fontWeightScale ? currentConfig.fontWeightScale : 1;

    const theInstanceId = this.instanceId;
    const theController = this;
    let envCallback: EnvironmentCallback = {
      onConfigurationUpdated(config) {
        theController.onConfigurationUpdate(config);
      },
      onMemoryLevel(level) {
        KRRenderLog.i('Configuration', `memory level: ${level}`);
      }
    };
    try {
      let applicationContext = uiAbilityContext.getApplicationContext();
      this.environmentCallbackId = applicationContext.on('environment', envCallback);
    } catch (paramError) {
      KRRenderLog.e('Configuration',
        `error: ${(paramError as BusinessError).code}, ${(paramError as BusinessError).message}`);
    }

    if (!imeMode) {
      const winRect = this.windowClass!.getWindowProperties().windowRect;
      this.windowRect = new KRRect(0,0, px2vp(winRect.width), px2vp(winRect.height));
      this.windowId = this.windowClass!.getWindowProperties().id + "";
      KRNativeManager.getInstance().onLastWindow(this.windowClass!);
      this.onSafeAreaInsetsChanged(this.getSafeAreaRect(this.windowClass!));
      this.windowClass!.on('avoidAreaChange', this.avoidAreaListener);
      this.windowClass!.on('windowSizeChange', this.onWindowSizeChanged);
    }
  }

  /**
   * 未捕获异常回调
   * @param exceptionCallback
   */
  registerExceptionCallback(exceptionCallback: KRExceptionCallback) {
    KRNativeManager.getInstance().getNativeInstance(this.instanceId)?.registerExceptionCallback(exceptionCallback);
  }

  onViewSizeChanged(rect: KRRect, oldDensity: number = this.densityPixels, newDensity: number = this.densityPixels) {
    this.viewRect = rect;
    if (this.didInit) {
      let densityInfo: KRRecord | null = null;
      if (oldDensity != newDensity) {
        densityInfo = {
          'oldDensity': oldDensity,
          'newDensity': newDensity
        };
      }
      this.notifySizeChange(densityInfo);
    } else {
      this.doOnAttach();
    }
  }

  notifyWindowSizeChanged(width: number, height: number) {
    const data: KRRecord = {};
    data[KRWidthKey] = width;
    data[KRHeightKey] = height;
    render.sendEvent(this.instanceId, KRWindowSizeDidChangedEventKey, JSON.stringify(data));
  }

  paramsReady(): boolean {
    if (this.imeMode) {
      return this.viewRect != null;
    } else {
      return this.safeAreaRect != null && // safearea updated
        KRNativeManager.getInstance().getWindowInfo(this.windowId) != undefined && // window info updated
        this.viewRect != null; // view rect updated
    }
  }
  onConfigurationUpdate(config: Configuration) {
    if(!this.didInit){
      return
    }
    const data: KRRecord = {
      'platform': 'ohos',
    };
    if (config.fontWeightScale) {
      data['fontWeightScale'] = config.fontWeightScale;
    }
    if (config.fontSizeScale) {
      data['fontSizeScale'] = config.fontSizeScale;
    }
    let fontSizeScaleFollowSystem = this.fontSizeScaleFollowSystem();
    if (!fontSizeScaleFollowSystem) {
      data['fontSizeScale'] = 1
    }
    data['fontSizeScaleFollowSystem'] = this.fontSizeScaleFollowSystem();
    try {
      if (config.fontId) {
        data['fontId'] = config.fontId;
      }
    } catch (e) {
      const err = e as BusinessError;
      KRRenderLog.e('Configuration',
        `read config.fontId failed (requires API 14+), code=${err?.code}, message=${err?.message}`);
    }

    const instance = KRNativeManager.getInstance().getNativeInstance(this.instanceId)
    if (instance){
      instance.onConfigurationUpdate()
    }

    // update config to render core
    render.updateConfig(this.instanceId, JSON.stringify(data));

    // notify core to mark text elements dirty
    render.sendEvent(this.instanceId, KRConfigurationUpdateEventKey, JSON.stringify(data));
  }

  /**
   * 更新 safeAreaRect。
   * @param notify 是否立即触发 notifySizeChange，默认 true。
   *   windowSizeChange 场景必须传 false：此刻 ArkUI 尚未重新布局，viewRect 仍是旧朝向，
   *   立即下发会用「旧 viewRect − 新 safeAreaRect」算出错配 insets。
   *   正确做法是只更新数据，等 viewRect 更新到同一朝向后再统一下发。
   */
  onSafeAreaInsetsChanged(rect: KRRect, notify: boolean = true) {
    this.safeAreaRect = rect;
    if (this.didInit) {
      if (notify) {
        this.notifySizeChange();
      }
    } else {
      this.doOnAttach();
    }
  }

  private encodeSafeAreaInsetsString() {
    if (this.safeAreaRect == null || this.viewRect == null) {
      return '0 0 0 0';
    }
    const left = Math.max(0, this.safeAreaRect.x - this.viewRect.x);
    const right = Math.max(0, this.viewRect.width - this.safeAreaRect.width - left);
    const top = Math.max(0, this.safeAreaRect.y - this.viewRect.y);
    const bottom = Math.max(0, this.viewRect.height - this.safeAreaRect.height - top);
    const resolved = this.resolveSafeAreaInsets(top, left, bottom, right);
    return `${resolved.top} ${resolved.left} ${resolved.bottom} ${resolved.right}`;
  }

  /**
   * 鸿蒙 safeArea 注入纠偏（自业务 OhosRotationSafeArea.kt 下沉，业务侧可择机移除自有实现）。
   *
   * 鸿蒙在窗口尺寸突变（旋转 / 分屏 / 折叠）的一瞬间，会把「窗口尺寸变化量」错误地注入
   * safeAreaInsets，两种注入形态分开处理：
   * - 旋转：页面尺寸仍铺满屏幕（仅轴序颠倒），注入值恰好是页面两轴差值，按差值扣减可还原真实安全区
   *   （实测竖转横 bottom=534.9 = 轴差502.0 + 真实导航条32.9，扣减后完全还原）。
   * - 分屏 / 多窗口：页面只是屏幕的一部分，注入值等于窗口尺寸变化量，无法从当前帧推算，
   *   只能按「真实安全区不可能超过该轴 25%」判据丢弃被注入的一侧，保留另一侧真实的挖孔/圆角安全区。
   *
   * bottom 异常帧被丢弃后会落到 0，用最近一次可靠值兜底，等待系统下发正确安全区，
   * 避免底部导航条区域闪一帧。
   */
  private resolveSafeAreaInsets(top: number, left: number, bottom: number, right: number): KRSafeAreaResolution {
    const result = new KRSafeAreaResolution();
    result.top = top;
    result.left = left;
    result.bottom = bottom;
    result.right = right;
    const vr = this.viewRect;
    if (vr == null) {
      return result;
    }
    const pageWidth = vr.width;
    const pageHeight = vr.height;
    // 屏幕物理尺寸（dp）：分屏 / 多窗口下窗口尺寸 ≠ 屏幕尺寸，必须用真实屏幕尺寸判定页面是否铺满
    let screenShort = 0.0;
    let screenLong = 0.0;
    try {
      const d = display.getDefaultDisplaySync();
      const density = d.densityPixels;
      const sw = d.width / density;
      const sh = d.height / density;
      screenShort = Math.min(sw, sh);
      screenLong = Math.max(sw, sh);
    } catch (e) {
      return result;
    }
    const pageShort = Math.min(pageWidth, pageHeight);
    const pageLong = Math.max(pageWidth, pageHeight);
    // 页面铺满屏幕（任意朝向）⟺ 短边、长边分别与屏幕一致
    const pageMatchesScreen = Math.abs(pageShort - screenShort) < KRSafeAreaMatchToleranceDp &&
      Math.abs(pageLong - screenLong) < KRSafeAreaMatchToleranceDp;
    const axisDelta = Math.abs(pageWidth - pageHeight);
    const hasAxisDelta = axisDelta >= KRSafeAreaMatchToleranceDp;
    const horizontalAbnormal = left + right > pageWidth * KRSafeAreaMaxReasonableFraction;
    const bottomAbnormal = bottom > pageHeight * KRSafeAreaMaxReasonableFraction;

    const correctRotationHorizontal = pageMatchesScreen && hasAxisDelta && horizontalAbnormal;
    const correctRotationBottom = pageMatchesScreen && hasAxisDelta && bottomAbnormal;
    const dropWindowHorizontal = !pageMatchesScreen && horizontalAbnormal;
    const dropWindowBottom = !pageMatchesScreen && bottomAbnormal;
    result.correctedHorizontal = correctRotationHorizontal || dropWindowHorizontal;
    result.correctedBottom = correctRotationBottom || dropWindowBottom;

    // 横向纠偏
    if (correctRotationHorizontal) {
      // 旋转形态：从较大一侧（注入侧）开始扣减轴差，剩余部分再从另一侧扣（clamp 0）
      if (left >= right) {
        const primaryReduction = Math.min(left, axisDelta);
        const remainingDelta = axisDelta - primaryReduction;
        result.left = left - primaryReduction;
        result.right = Math.max(0, right - remainingDelta);
      } else {
        const primaryReduction = Math.min(right, axisDelta);
        const remainingDelta = axisDelta - primaryReduction;
        result.right = right - primaryReduction;
        result.left = Math.max(0, left - remainingDelta);
      }
    } else if (dropWindowHorizontal) {
      // 分屏形态：注入只落在单侧（较大一侧），丢弃它并保留另一侧；保留侧若也超阈值则一并丢弃
      const maxReasonable = pageWidth * KRSafeAreaMaxReasonableFraction;
      if (left >= right) {
        result.left = 0;
        result.right = right > maxReasonable ? 0 : right;
      } else {
        result.right = 0;
        result.left = left > maxReasonable ? 0 : left;
      }
    }
    // 底部纠偏
    if (correctRotationBottom) {
      result.bottom = Math.max(0, bottom - axisDelta);
    } else if (dropWindowBottom) {
      result.bottom = 0;
    }

    // 屏幕物理尺寸变化（折叠 / 外接屏）时重置 bottom 缓存
    if (this.safeAreaResolverScreenShort > 0 &&
      (Math.abs(this.safeAreaResolverScreenShort - screenShort) >= KRSafeAreaMatchToleranceDp ||
        Math.abs(this.safeAreaResolverScreenLong - screenLong) >= KRSafeAreaMatchToleranceDp)) {
      this.safeAreaLastReliableBottom = null;
    }
    this.safeAreaResolverScreenShort = screenShort;
    this.safeAreaResolverScreenLong = screenLong;

    // 攒可靠 bottom：合理范围内的正值（<= 该轴 25%）即可信，横竖屏共用一份缓存。
    // 注入值必然超出 25% 阈值，不会进入该分支，无需按形态区分。
    if (result.bottom > 0 && result.bottom <= pageHeight * KRSafeAreaMaxReasonableFraction) {
      this.safeAreaLastReliableBottom = result.bottom;
    }
    // 异常帧 bottom 落 0 时用缓存兜底
    const cachedBottom = this.safeAreaLastReliableBottom;
    if ((result.correctedHorizontal || result.correctedBottom) &&
      result.bottom < KRSafeAreaMatchToleranceDp && cachedBottom != null) {
      result.bottom = cachedBottom;
    }
    // L1纠偏原理日志：仅在注入发生时输出（正确帧零噪音）。
    // 旋转形态=轴差扣减还原真实值；分屏形态=25%阈值丢弃注入侧；bottom=0 时用最近可靠值兜底
    if (result.correctedHorizontal || result.correctedBottom) {
      KRRenderLog.i('Rotation',
        `safeArea injected-value corrected: (${top.toFixed(1)},${left.toFixed(1)},${bottom.toFixed(1)},${right.toFixed(1)}) -> ` +
        `(${result.top.toFixed(1)},${result.left.toFixed(1)},${result.bottom.toFixed(1)},${result.right.toFixed(1)}) ` +
        `[axisDelta=${axisDelta.toFixed(1)}, mode=${pageMatchesScreen ? 'rotation' : 'window'}]`);
    }
    return result;
  }

  private notifySizeChange(densityInfo: KRRecord | null = null) {
    if (this.viewRect == null) {
      return;
    }
    const data: KRRecord = {};
    data[KRWidthKey] = this.viewRect.width;
    data[KRHeightKey] = this.viewRect.height;
    data[KRSafeAreaInsets] = this.encodeSafeAreaInsetsString();
    if (densityInfo) {
      data[KRDensityInfo] = JSON.stringify(densityInfo);
    }
    // 修复旋转后 deviceWidth/deviceHeight 冻结：
    // 下发当前窗口尺寸，Kotlin 侧 PagerData.updateRootViewSize 收到 key 后会同步更新，
    // Compose Configuration.screenWidthDp/screenHeightDp 随之跟随旋转互换（BUG-1）
    if (this.windowRect != null) {
      data[KRDeviceWidthKey] = this.windowRect.width;
      data[KRDeviceHeightKey] = this.windowRect.height;
    }
    // 下发锚点：一行记录 Kotlin 实际收到的全部数据（size + 纠偏后 insets + 同步策略）
    KRRenderLog.i('Rotation',
      `notifySizeChange: ${this.viewRect.width.toFixed(1)}x${this.viewRect.height.toFixed(1)} ` +
      `insets[${data[KRSafeAreaInsets]}] device=${data[KRDeviceWidthKey]}x${data[KRDeviceHeightKey]} ` +
      `sync=${this.syncSendEvent(KRRootViewSizeDidChangedEventKey)}`);
    this.doSendEvent(KRRootViewSizeDidChangedEventKey, data, this.syncSendEvent(KRRootViewSizeDidChangedEventKey));

    this.runKRRenderTask(() => {
      render.onRenderViewSizeChanged(this.instanceId, this.viewRect?.width as number, this.viewRect?.height as number);
    });
  }

  onAttach() {
    this.doOnAttach();
  }
  // 判断 View size 是否发生了改变
  private isViewSizeChanged(width: number, height: number): boolean {
    return this.viewRect == null ||
      Math.abs(this.viewRect.width - width) >= 0.1 ||
      Math.abs(this.viewRect.height - height) >= 0.1;
  }

  onAreaChange(newValue: Area) {
    const newWidth = newValue.width as number;
    const newHeight = newValue.height as number;
    const sizeChanged = this.isViewSizeChanged(newWidth, newHeight);
    // 始终更新 viewRect（包括 globalPosition），确保位置信息准确
    this.viewRect = new KRRect(newValue.globalPosition.x as number,
      newValue.globalPosition.y as number,
      newWidth,
      newHeight);
    if (this.didInit) {
      if (this.sizeChangeHandledByOnSizeChange) {
        // 已在 onSizeChange 中提前处理过，消费标志位，跳过重复执行
        this.sizeChangeHandledByOnSizeChange = false;
      } else if (sizeChanged) {
        // 兜底：onSizeChange 未处理（syncSendEvent=false 或未触发），在此处触发
        this.doOnAreaChange(newValue);
        this.notifySizeChange();
      }
    } else {
      this.doOnAttach();
    }
  }

  onSizeChange(newValue: SizeOptions) {
    if (this.viewRect == null) {
      return;
    }
    const newWidth = newValue.width as number;
    const newHeight = newValue.height as number;
    if (!this.isViewSizeChanged(newWidth, newHeight)) {
      return;
    }
    // 仅当业务方开启了 rootViewSizeDidChanged 同步策略时，才在布局前提前触发同步渲染
    if (this.didInit && this.syncSendEvent(KRRootViewSizeDidChangedEventKey)) {
      // 提前更新 viewRect 尺寸（globalPosition 会在后续 onAreaChange 中更新）
      this.viewRect.width = newWidth;
      this.viewRect.height = newHeight;
      // 修复错配窗口期原理：onSizeChange 是布局前回调，早于 avoidAreaChange 的 setTimeout(0) 到期；
      // 此处更新 viewRect 后，该次到期的下发必然用「新 viewRect − 新 safeAreaRect」，不再错配
      KRRenderLog.i('Rotation', `viewRect pre-updated to ${newWidth.toFixed(1)}x${newHeight.toFixed(1)} (layout-before callback)`);
      this.runKRRenderTask(() => {
        render.onRenderViewSizeChanged(this.instanceId, newWidth, newHeight);
      });
      this.notifySizeChange();
      // 标记已处理，避免 onAreaChange 中重复执行
      this.sizeChangeHandledByOnSizeChange = true;
    }
  }

  onAboutToDisappear() {
    this.destroyed = true;
    try {
      if (this.windowClass) {
        this.windowClass.off('avoidAreaChange', this.avoidAreaListener);
        this.windowClass.off('windowSizeChange', this.onWindowSizeChanged);
      }
      if (this.environmentCallbackId != -1) {
        let applicationContext = this.uiAbilityContext?.getApplicationContext();
        applicationContext?.off('environment', this.environmentCallbackId);
        this.environmentCallbackId = -1;
      }
    } catch (e) {
      KRRenderLog.e('Window', `unregister event failed:${e.code}`);
    }

    this.doAboutToDisappear();
    KRNativeManager.getInstance().removeWindowInfoIfNeed(this.windowId);
    KRNativeManager.getInstance().removeNativeInstance(this.instanceId);
  }

  onPageShow() {
    this.doOnPageShow();

    if (this.didInit && !this.destroyed) {
      const newDensity = this.getWindowActiveDensity();
      if (newDensity != this.densityPixels) {
        // density变化，原因是修改了系统的无障碍选项
        this.doOnDensityChanged(newDensity);
      }
    }
  }

  private doOnDensityChanged(newDensity: number) {
    const oldDensity = this.densityPixels;
    this.densityPixels = newDensity;

    let data: Record<string, string | number> = {
      'vp2px': vp2px(1.0),
    };

    render.updateConfig(this.instanceId, JSON.stringify(data));

    if (this.windowRect) {
      this.windowRect = new KRRect(0, 0,
        px2vp(this.windowRect.width * oldDensity),
        px2vp(this.windowRect.height * oldDensity)
      );

      this.notifyWindowSizeChanged(this.windowRect.width, this.windowRect.height);
    }
    if (this.viewRect) {
      this.viewRect = new KRRect(
        px2vp(this.viewRect.x * oldDensity),
        px2vp(this.viewRect.y * oldDensity),
        px2vp(this.viewRect.width * oldDensity),
        px2vp(this.viewRect.height * oldDensity)
      );

      this.onViewSizeChanged(this.viewRect, oldDensity, newDensity);
    }
    if (this.windowClass) {
      try {
        this.onSafeAreaInsetsChanged(this.getSafeAreaRect(this.windowClass));
      } catch (e) {
        KRRenderLog.e('Window', `doOnDensityChanged update safearea error code:${e.code}`);
      }
    }
  }

  onPageHide() {
    this.doOnPageHide();
  }

  sendEvent(event: string, data: KRRecord) {
    this.doSendEvent(event, data);
  }

  sendEventSync(event: string, data: KRRecord, sync: boolean) {
    this.doSendEvent(event, data, sync);
  }

  onBackPress() {
    const sendTime = Date.now();
    this.doSendEvent(KROnBackPressedKey, {}, this.syncSendEvent(KROnBackPressedKey));
    const result = render.isBackPressConsumed(this.instanceId, sendTime);
    if (result === KRBackPressConsumedState.Consumed) {
      return true;
    } else if (result === KRBackPressConsumedState.NotConsumed) {
      return false;
    }
    return false;
  }

  putParam(key: string, value: KRValue) {
    this.externalParams[key] = value;
  }

  getParam(key: string): KRAny | null {
    return this.externalParams[key];
  }

  setExternalController(controller: object) {
    this.externalController = controller;
  }

  getExternalController<T>(): T {
    return this.externalController as T;
  }

  getUIAbilityContext(): common.UIAbilityContext | null {
    return this.uiAbilityContext;
  }

  private doOnPageShow() {
    const data: KRRecord = {};
    data[KRPageDidAppearEventKey] = '1';
    this.doSendEvent(KRPageDidAppearEventKey, data, this.syncSendEvent(KRPageDidAppearEventKey));
  }

  private doOnPageHide() {
    const data: KRRecord = {};
    data[KRPageDidDisappearEventKey] = '1';
    this.doSendEvent(KRPageDidDisappearEventKey, data, this.syncSendEvent(KRPageDidDisappearEventKey));
  }
  // 外部接口：提供给业务指定需要同步执行的事件
  syncSendEvent(event: string): boolean {
    return event === KROnBackPressedKey;
  }

  private doSendEvent(event: string, data: KRRecord, sync?: boolean) {
    this.runKRRenderTask(() => {
      const shouldSync = sync ?? this.syncSendEvent(event);
      if (shouldSync) {
        render.sendEventSync(this.instanceId, event, KRConvertUtil.anyToCObject(data), true);
      } else {
        render.sendEvent(this.instanceId, event, KRConvertUtil.anyToCObject(data));
      }
    });
  }

  private doOnAttach() {
    if (this.didInit) {
      return;
    }
    if (!this.paramsReady()) {
      return;
    }
    this.doDidInit();
  }

  private doDidInit() {
    if (this.viewRect == null) {
      return;
    }
    this.didInit = true;
    let pageData = this.createPageParams(this.pageParams, this.viewRect.width, this.viewRect.height);
    // 初始下发基线快照（deviceWidth/deviceHeight 初值来自物理屏幕 screenSize）
    let configJson = this.createConfigJson(new KRSize(this.viewRect.width, this.viewRect.height));

    render.onInitRenderView(this.instanceId, this.pageName, pageData, this.viewRect.width, this.viewRect.height,
      configJson
      , this.uiContext, this.uiContext?.getHostContext()?.resourceManager);
    this.runLazyTasksOnce();
  }


  addKuiklyRenderViewLifecycleCallback(callback: IKuiklyRenderViewLifecycleCallback) {
    this.lifecycleCallbacks.push(callback)
  }

  dispatchLifecycleStateChanged(state: number, params?: Object): void {
    switch (state) {
      case KRLifecycleState.STATE_INIT: {
        this.lifecycleCallbacks.forEach(callback => callback.onInit());
        break;
      }
      case KRLifecycleState.STATE_INIT_CORE_START: {
        this.lifecycleCallbacks.forEach(callback => callback.onInitCoreStart());
        break;
      }
      case KRLifecycleState.STATE_INIT_CORE_FINISH: {
        this.lifecycleCallbacks.forEach(callback => callback.onInitCoreFinish());
        break;
      }
      case KRLifecycleState.STATE_INIT_CONTEXT_START: {
        this.lifecycleCallbacks.forEach(callback => callback.onInitContextStart());
        break;
      }
      case KRLifecycleState.STATE_INIT_CONTEXT_FINISH: {
        this.lifecycleCallbacks.forEach(callback => callback.onInitContextFinish());
        break;
      }
      case KRLifecycleState.STATE_CREATE_INSTANCE_START: {
        this.lifecycleCallbacks.forEach(callback => callback.onCreateInstanceStart());
        break;
      }
      case KRLifecycleState.STATE_CREATE_INSTANCE_FINISH: {
        this.lifecycleCallbacks.forEach(callback => callback.onCreateInstanceFinish());
        break;
      }
      case KRLifecycleState.STATE_FIRST_FRAME_PAINT: {
        this.lifecycleCallbacks.forEach(callback => callback.onFirstFramePaint());
        break;
      }
    }
  }

  private doAboutToDisappear() {
    this.runKRRenderTask(() => {
      render.onDestroyRenderView(this.instanceId);
    });
  }

  private doOnAreaChange(newValue: Area) {
    this.runKRRenderTask(() => {
      render.onRenderViewSizeChanged(this.instanceId, newValue.width as number, newValue.height as number);
    });
  }

  private createPageParams(params: KRRecord, viewWidth: number, viewHeight: number): string {
    let screenSize = KRConvertUtil.screenSize();
    let pageData: Record<string, string | number | KRRecord> = {};
    params[KRSystemLanguageKey] = i18n.System.getSystemLanguages()[0];
    pageData[KRParamKey] = params;
    pageData[KRRootViewWidthKey] = viewWidth;
    pageData[KRRootViewHeightKey] = viewHeight;
    pageData[KRUrlKey] = this.pageName;
    if (!this.imeMode) {
      pageData[KRStatusBarHeightKey] = this.safeAreaRect!.y;
      let windowInfo = KRNativeManager.getInstance().getWindowInfo(this.windowId);
      if (windowInfo != undefined) {
        pageData[KRActivityWidthKey] = px2vp(windowInfo.getWindowRect().width);
        pageData[KRActivityHeightKey] = px2vp(windowInfo.getWindowRect().height);
      }
      pageData[KRSafeAreaInsets] = this.encodeSafeAreaInsetsString();
    }

    let versionName = "1.0.0"
    let osFullName = ""
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      versionName = bundleInfo.versionName;
      osFullName = deviceInfo.osFullName; // system version
    }catch (e) {
      // noop
    }

    pageData[KRDeviceWidthKey] = screenSize.width;
    pageData[KRDeviceHeightKey] = screenSize.height;
    pageData[KROsVersionKey] = osFullName; // 系统版本
    pageData[KRNativeBuild] = 2;
    pageData[KRAppVersionKey] = versionName;
    pageData[KRPlatformKey] = 'ohos';
    pageData[KRExecuteMode] = this.executeMode.mode;
    pageData[KRContextCode] = this.contextCode;
    pageData[KRDensity] = this.getWindowActiveDensity();
    pageData[KRFeature] = {
      "box_shadow_fill" : 1
    };
    return JSON.stringify(pageData);
  }

  private createConfigJson(screenSize: KRSize): string {
    let data: Record<string, string | number | boolean> = {
      'vp2px': vp2px(1.0),
      'screen_width': screenSize.width,
      'screen_height': screenSize.height,
      'resfile_dir': getContext().resourceDir,
      'files_dir': getContext().filesDir,
      'assets_dir': this.assetsDir,
      'fontWeightScale': this.fontWeightScale,
      'fontSizeScale': this.fontSizeScale,
      'imeMode': this.imeMode ? 1 : 0,
      'windowId': this.windowId,
      'fontSizeScaleFollowSystem': this.fontSizeScaleFollowSystem() ? 1 : 0,
      'performanceMonitorTypesMask': this.getMonitorTypeMask(),
      "useOhSharedPreferences": this.useOhSharedPreferences
    };

    return JSON.stringify(data);
  }

  private runKRRenderTask(task: () => void) {
    if (this.didInit) {
      task();
    } else {
      this.lazyTasks.push(task);
    }
  }

  private runLazyTasksOnce() {
    this.lazyTasks.forEach((task, _) => {
      task();
    });
    this.lazyTasks = [];
  }

  private getSafeAreaRect(data: window.Window): KRRect {
    const winRect = data.getWindowProperties().windowRect;
    const insets: Insets = {
      left: 0,
      top: 0,
      right: winRect.width,
      bottom: winRect.height,
    };
    const handle = (avoidArea: window.AvoidArea) => {
      if (avoidArea.leftRect.width) {
        insets.left = Math.max(insets.left, avoidArea.leftRect.left + avoidArea.leftRect.width);
      }
      if (avoidArea.topRect.height) {
        insets.top = Math.max(insets.top, avoidArea.topRect.top + avoidArea.topRect.height);
      }
      if (avoidArea.rightRect.width) {
        insets.right = Math.min(insets.right, avoidArea.rightRect.left);
      }
      if (avoidArea.bottomRect.height) {
        insets.bottom = Math.min(insets.bottom, avoidArea.bottomRect.top);
      }
    };
    handle(data.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM));
    handle(data.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT));
    handle(data.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR));
    const result = new KRRect(px2vp(insets.left), px2vp(insets.top), px2vp(insets.right - insets.left),
      px2vp(insets.bottom - insets.top));
    console.log(`getSafeAreaRect safeAreaInsets: ${result.x}, ${result.y}, ${result.width}, ${result.height}`);
    return result;
  }

  /**
   * 获取窗口活跃的density
   * customDensity的值默认为systemDensity
   * 如果windowStage主动设置了DefaultDensityEnabled/CustomDensity,则分别是defaultDensity/customDensity
   * 因此默认取customDensity作为活跃的density
   */
  private getWindowActiveDensity() {
    if (this.windowClass != null) {
      return this.windowClass.getWindowDensityInfo?.().customDensity ?? display.getDefaultDisplaySync().densityPixels;
    } else {
      return display.getDefaultDisplaySync().densityPixels
    }
  }

  /**
   * 字体缩放是否跟随系统
   * @return boolean true:跟随系统(默认) false:不跟随系统(缩放比例为1)
   */
  fontSizeScaleFollowSystem(): boolean {
    return true
  }

  /**
   * 回调启动数据
   */
  onGetLaunchData(data: KRRecord): void {
  }

  /**
   * 回调性能数据
   */
  onGetPerformanceData(data: KRRecord): void {
  }

  /**
   * Kuikly框架设置性能监控选项，默认只开启动监控
   * @return Array<KRMonitorType>: 需要设置的性能监控选项列表
   */
  performanceMonitorTypes(): Array<KRMonitorType> {
    return [KRMonitorType.LAUNCH];
  }

  private getMonitorTypeMask(): number {
    const mask = this.performanceMonitorTypes().reduce((acc: KRMonitorType, cur: KRMonitorType) => acc | cur, 0);
    return mask;
  }

}

export abstract class IKuiklyViewDelegate extends KRNativeRenderController {
  /**
   * 获取自定义扩展渲染视图创建注册Map
   */
  abstract getCustomRenderViewCreatorRegisterMap(): Map<string, KRRenderViewExportCreator>;

  /**
   * 获取自定义扩展渲染视图创建注册Map。
   * 通过这个方式注册的creator，创建的自定义view将不会有影子节点处理基础事件，需要用户在arkts侧响应所有属性的设置。
   * 当这个方式的好处是，由于不存在影子节点，其view曾经和DSL中定义的是保持一致的。
   * 建议仅在有强一致层级需求的时候才采用。
   */
  getCustomRenderViewCreatorRegisterMapV2(): Map<string, KRRenderViewExportCreator>{
    // by default
    return new Map();
  }

  /**
   * 获取自定义扩展module创建注册Map
   */
  abstract getCustomRenderModuleCreatorRegisterMap(): Map<string, KRRenderModuleExportCreator>;

  pageDidAppear() {
    this.onPageShow();
  }

  pageDidDisappear() {
    this.onPageHide();
  }

  /**
   * 获取自定义[KuiklyRenderView]生命周期回调
   */
  getKuiklyRenderViewLifecycleCallback(): IKuiklyRenderViewLifecycleCallback | null {
    return null
  }
}

enum KRLifecycleState {
  STATE_INIT = 1,
  STATE_INIT_CORE_START,
  STATE_INIT_CORE_FINISH,
  STATE_INIT_CONTEXT_START,
  STATE_INIT_CONTEXT_FINISH,
  STATE_CREATE_INSTANCE_START,
  STATE_CREATE_INSTANCE_FINISH,
  STATE_FIRST_FRAME_PAINT
}

/**
 * RenderView 生命周期回调
 */
export interface IKuiklyRenderViewLifecycleCallback {

  /**
   * 启动
   */
  onInit(): void

  /**
   * renderCore 初始化开始
   */
  onInitCoreStart(): void

  /**
   * renderCore 初始化完成
   */
  onInitCoreFinish(): void

  /**
   * 初始化渲染环境开始
   */
  onInitContextStart(): void

  /**
   * 初始化渲染环境完成
   */
  onInitContextFinish(): void

  /**
   * 创建页面开始
   */
  onCreateInstanceStart(): void

  /**
   * 创建页面结束
   */
  onCreateInstanceFinish(): void

  /**
   * 页面首帧渲染完成
   */
  onFirstFramePaint(): void

}

/**
 * 性能监控类型
 */
export enum KRMonitorType {
  LAUNCH = 1 << 0,  // 1 启动监控
  FRAME = 1 << 1,  // 2 FPS监控
  MEMORY = 1 << 2,  // 4 内存监控
}
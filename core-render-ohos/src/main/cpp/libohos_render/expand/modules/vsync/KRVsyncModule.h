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

#ifndef CORE_RENDER_OHOS_KRVSYNCMODULE_H
#define CORE_RENDER_OHOS_KRVSYNCMODULE_H

#include <native_vsync/native_vsync.h>
#include <atomic>
#include <cstdint>
#include <mutex>
#include "libohos_render/export/IKRRenderModuleExport.h"

namespace kuikly {
namespace module {

/**
 * Vsync 模块：基于 OH_NativeVSync 提供系统级 vsync 回调，驱动 Kotlin 侧
 * Compose 帧调度器，使帧节拍与屏幕刷新率严格对齐（替代 Kotlin 侧 12ms Timer 轮询，
 * 支持 60/90/120Hz 及 LTPO 变频自适应）。
 *
 * 数据链路：
 * - 每次系统 vsync 回调时，通过 KRRenderValue(int32_t) 上报「帧间隔纳秒」，
 *   由相邻两次 vsync 时间戳差值计算并钳制到 [1ms, 100ms]；
 * - KRRenderCallback 内部(KRRenderCore 桥接层)会自动切换到 context 线程，
 *   因此 vsync 线程直接调用回调是安全的；
 * - Kotlin 侧 VsyncModule.registerVsyncWithFrameInterval 收到 Int 帧间隔。
 *
 * 线程与生命周期安全：
 * - OH_NativeVSync_RequestFrame 为一次性请求，每帧回调后需重新 arm；
 * - 在途回调通过 weak_ptr + generation 双重保护，模块销毁/反注册后自动失效，
 *   不存在 UAF；
 * - 背压：上一 tick 尚未在 context 线程消化时，新 tick 直接丢弃，防止慢帧堆积。
 */
class KRVsyncModule : public IKRRenderModuleExport {
 public:
    static const char MODULE_NAME[];

    KRVsyncModule() = default;
    ~KRVsyncModule();

    KRAnyValue CallMethod(bool sync, const std::string &method, KRAnyValue params,
                          const KRRenderCallback &callback) override;
    void OnDestroy() override;

 private:
    static const char METHOD_REGISTER_VSYNC[];
    static const char METHOD_UNREGISTER_VSYNC[];

    void RegisterVsync(const KRRenderCallback &callback);
    void UnRegisterVsync();
    // 请求下一帧 vsync 回调，调用前须持有 mutex_
    void RequestNextVsyncLocked();
    // 系统 vsync 线程回调入口
    static void OnVsync(long long timestamp, void *data);

    std::mutex mutex_;
    KRRenderCallback callback_ = nullptr;
    bool running_ = false;
    // 注册代数：反注册/重新注册时递增，使在途回调按代数比对后安全丢弃
    uint64_t generation_ = 0;
    // 背压标志：true 表示上一 tick 已投递 context 线程但尚未消化完毕
    std::atomic<bool> tick_pending_{false};
    // 相邻 vsync 时间戳，用于计算帧间隔
    long long last_timestamp_nanos_ = 0;
    // 最近一次有效帧间隔（异常差值时沿用）
    int32_t last_interval_nanos_ = 0;
    OH_NativeVSync *native_vsync_ = nullptr;
};

}  // namespace module
}  // namespace kuikly

#endif  // CORE_RENDER_OHOS_KRVSYNCMODULE_H

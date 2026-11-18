# 可运行的 16QAM 示例

本目录包含独立源码，不依赖作者的课程工程。build_model.m 使用标准 Simulink 模块建立真实载波 Gray 16QAM 模型；run_example.m 完成无噪声检查、基准仿真、Eb/N0 扫描和绘图。

在仓库根目录执行：

```sh
python scripts/workflow.py run --config examples/16qam/config.json
```

也可在 MATLAB 编辑器打开 run_example.m，点击运行。CLI 使用配置的输出目录并拒绝覆盖；编辑器运行创建带时间戳的结果目录。八张图保存为 PNG 和 FIG，不依赖弹出的窗口数量判断运行是否成功。

parameters 中支持 bits、ebN0Db、sweepDb、bitSeed、noiseSeed。固定采样率 10 kHz、载波 2 kHz、符号率 200 Baud；每符号正好 10 个载波周期。没有定时恢复、载波恢复环路或根升余弦成形。

统计通过读取真正的 Simulink 输出计算，同时由独立阈值/Gray 解码器验证。BER 理论线采用常见高信噪比近似；零误码上界使用近似独立比特试验假设，同一 QAM 符号内的误码可能相关。不要据此宣称生产级统计保证。

源代码按仓库 MIT 协议发布；MATLAB/Simulink 的安装与许可由用户自行提供。

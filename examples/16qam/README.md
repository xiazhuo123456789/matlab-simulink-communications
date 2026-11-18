# 16QAM 适配器

这个示例说明如何把通用 Skill 连接到真实载波、Gray 编码的 16QAM 课程工程。

把 `projectRoot` 配置为包含 `.slx` 模型和 MATLAB 辅助脚本的目录，把 `entryPoint` 配置为工程已经验证过的运行脚本，例如 `run_all_16qam.m`。保留原始模型；如果回调或自动出图需要副本，就使用 click-run 副本。

自然语言示例：

> Use MATLAB Simulink Communications to run my 16QAM model, generate all configured figures, verify BER and SER at 10 dB and across the Eb/N0 sweep, then explain every block and figure.

适配器要求模型工程提供自己的绘图和验证函数。公开仓库不会包含个人绝对路径，也不会发布没有再分发授权的课程模型二进制文件。

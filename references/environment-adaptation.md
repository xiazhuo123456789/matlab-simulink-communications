# 在使用者电脑上适配 MATLAB/Simulink

本指南由 AI 执行，配合 SKILL.md 的环境探测使用。不要求项目维护者安装旧版 MATLAB，不维护臆测的“所有版本支持表”。目标是找出这台电脑的能力缺口，实施小范围等价适配并实测，而不是仅修改兼容性宣传语。

## 环境与运行入口

- 优先使用用户已经选择的 MATLAB 安装或可调用会话。多个安装并存时，不擅自切换版本。
- 使用本机 MATLAB 帮助确认启动参数；支持 -batch 时使用现有 Python 入口。若不支持，现有入口不能直接使用，AI 需在独立工作目录建立本机可用的 -r 或 GUI 运行方式。
- -r 不保证自动退出；包装入口需捕获错误、保存状态和日志、明确 exit，并设置等待上限。不得把启动器退出、弹出窗口或历史结果视为完成。
- 缺少 Python 时，可通过 MATLAB 工具连接器或 GUI 运行 MATLAB 入口。用户要求必须是 Simulink 时，不得用 Octave、NumPy 或仅 MATLAB 数值脚本冒充 Simulink 结果。
- license('test','Simulink') 只是初筛，存在许可条目不保证当前可签出许可；以实际加载/仿真结果为准。

## 适配只发生在工作副本

先复制适配器源码和配置到新工作目录，保留原始哈希或差异。工程根、入口、输出目录跟随副本调整。用户的普通运行请求允许为完成该次运行做必要的可逆适配，但不代表允许重写原课程模型或发布技能更新。

| 观察到的缺口 | 适配方向 | 需验证的语义 |
|---|---|---|
| tiledlayout / nexttile 不存在 | 改为显式 subplot(m,n,k) 与轴句柄 | 子图顺序、曲线归属、图例、轴标签 |
| exportgraphics 不存在或不接受目标对象 | 用本机支持的 print(fig,path,'-dpng','-r160') 导出 | 图片非空、清晰、无裁切、数据一致 |
| xline / yline 不存在 | 用两端点 plot 绘制阈值线 | 阈值数值和轴范围不变 |
| Simulink.SimulationInput 缺失或方法不兼容 | 查询本机 sim 支持形式，在生成模型的工作区传入参数 | 每个 Eb/N0/NoiseEnable 真正生效、基准和扫描无参数串扰 |
| JSON 接口不存在 | 将已校验参数转为 MATLAB struct/MAT，修改副本入口与报告格式 | 类型、数值、随机种子及输出位置不变；验证器同步调整 |
| 脚本局部函数/新语法不可解析 | 拆为独立函数文件，使用该版本可解析语法 | 文件解析及函数路径正确，变量来源不再依赖调用者工作区 |
| 隐式数组扩展不可用 | 使用 bsxfun 或显式维度匹配实现等价计算 | 行/列方向、阈值判决及误码数一致 |
| 新绘图/Scope 属性不存在 | 检查支持的属性，省略可选显示属性或换等价显示方式 | 不影响信号和时序；所需图像仍可生成 |
| 源码编码或字体不受目标环境支持 | 在副本中采用本机可识别编码，必要时用英文显示标签 | 数学逻辑不变，图片文字可读，不损坏原始源码 |
| 库块路径或参数变化 | 查询本机库及 get_param 可用参数，选择经过验证的等价标准模块 | 采样率、输入维度、增益、延迟、随机数含义一致 |

以上是 AI 的适配规则，并不是当前 Python/MATLAB 脚本已经内置的自动回退分支。没有足够证据证明替换等价时，报告缺口，不盲目替换。

## 模型文件兼容

内置示例优先在目标 MATLAB 上从源码创建模型，减少对某个版本保存的二进制模型的依赖。现有新版本模型不能被旧版本打开时，优先使用可用源码；必要时在具备能力的安装中导出旧格式副本。

MathWorks 明确说明，导出旧版本可能移除不支持的功能或把模块替换为空子系统，所以“导出成功”不等于结果正确。禁止仅关闭版本检查后宣布兼容；导出后仍需重新编译、运行并验证。

## 适配验收与失败边界

1. 环境报告：MATLAB/Simulink release、平台、需要的能力和真实缺口。
2. 最小仿真：无噪声零误码，收发采样对齐，模型判决与独立解码一致。
3. 参数生效：小规模扫描至少两个不同 Eb/N0 点，记录实际传入值；不要求有限随机样本的 BER 严格单调。
4. 完整运行：按用户配置生成全部输出，检查文件新鲜度、图像内容、BER/SER 计数和分母。
5. 实测结论：只对当前环境、配置和适配版本确认可用，不推广为所有软件版本均已验证。

适配同一原因失败两次后停止无效重试，留下错误和具体待解决项。缺少 MATLAB、Simulink、许可或必要执行权限时，明确不能完成真实仿真，不把说明书或伪造图像当作运行结果。

## 官方依据

- [ver：安装产品信息](https://www.mathworks.com/help/matlab/ref/ver.html)
- [license：许可检测语义](https://www.mathworks.com/help/matlab/ref/license.html)
- [tiledlayout](https://www.mathworks.com/help/matlab/ref/tiledlayout.html) 与 [subplot](https://www.mathworks.com/help/matlab/ref/subplot.html)
- [exportgraphics](https://www.mathworks.com/help/matlab/ref/exportgraphics.html) 与 [print](https://www.mathworks.com/help/matlab/ref/print.html)
- [Simulink 旧版本导出限制](https://www.mathworks.com/help/simulink/ug/save-models.html)

查阅日期：2026-11-18。具体调用形式仍需核对目标安装自身的帮助。

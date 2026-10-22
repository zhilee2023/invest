# ORBIT 交易观测站 · iPhone个人设备版

原生SwiftUI、iOS17+。封面、图标、深色轨道视觉；今日/持仓/研究/复盘四个入口，点击查看证据和历史。无语音功能、模型权重、API密钥或内置账户数据。

## 接口与数据

服务端为本项目FastAPI；HTTPS入口配置完成后，在App设置中填写服务地址和网页用户名/密码。登录保存于设备钥匙串；URLSession拒绝跨地址重定向、不关闭证书校验、不允许明文HTTP。请先完成服务器端口与HTTPS配置。

- 首页：`GET /api/mobile/overview`，只读紧凑摘要，不调用模型。
- 持仓与预警：`GET /api/monitor`；预警确认只标记已知悉。
- 公司资料库：`GET /api/companies/library` 与单公司档案。
- 复盘action：`GET /api/review/actions`；协议、逐次结果和人工观察分开保存。
- 按需查证：`POST /api/review/query`；一次只读SQL规划，最多30行/12列/12000字符，结果不再回传给第二轮模型。

界面明确区分录入资产与实时净值、当前判断与旧记录、等待样本与已观察结果。后台通知继续由用户已有Server酱通道发送；App只在前台定时刷新，不宣称锁屏后持续盯盘。

## 沿用CosyVoice项目的构建与安装方式

将本文件夹作为独立仓库根目录。`.github/workflows/build-ios.yml`在macOS构建，生成 **unsigned IPA**，无需上传Apple账号。不要将整个交易系统仓库、data、.env、服务器登录凭据或SSH密钥上传。

1. 在已授权的GitHub仓库运行`Build Orbit Trading iOS`；下载unsigned产物。
2. Windows使用现有[Sideloadly](https://sideloadly.io/)安装流程，在本机工具里登录普通Apple ID并签名安装到自己的iPhone；密码不写入本仓库或聊天。
3. 普通账号的个人签名受Apple限制，通常需要7天续签；遵循工具和系统提示。可参考[Apple个人开发账号说明](https://developer.apple.com/help/account/basics/about-your-developer-account)。
4. 有Mac时也可`brew install xcodegen`，运行`swift scripts/generate_icon.swift`与`xcodegen generate`，在Xcode的Signing选择自己的Personal Team、连接iPhone后Build & Run。

云构建成功证明工程可编译；unsigned IPA仍需本机签名，不能标为已签名版本。实际安装与真机使用需要验收。GitHub构建是否占用免费额度由账户套餐与当期用量决定。

## 验收

封面/图标正常；HTTPS登录；未知资产显示“—”；旧决策有历史标记；公司资料可点击展开；实验结果为空不冒充成功；保存观察可重试且不重复写入；前台刷新、退后台停止轮询；Server酱后台通知独立于App运行。

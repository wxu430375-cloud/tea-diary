# 第三方资料与品牌标识

代码遵循 MIT。商标权与官网标识的版权属于各品牌，不随代码许可证转让。本项目仅用于用户识别自己的饮品记录，不代表与品牌合作或获得官方授权。

品牌标识原始地址见 `web/assets/brand-sources.json`。维护者若面向其他地区或商业发布，应自行核对相应标识的使用条件；也可以在 `web/stickers.js` 删除 `logoMap` 对应项，改为纯文字识别标签。

资料库记录产品名称与简短风味/主要原料事实摘要，保留逐项来源链接；不收录整篇文章、完整图片菜单或配方全文。来源可在单品详情访问。它不是实时菜单，也不是完整成分表。

`web/assets/apple-tea.png`、`berry.png`、`grape.png`、`milk.png`、`lemon.png`、`orange.png`、`cocoa.png`、`dragonfruit.png` 为开发时由内置 imagegen 生成的素材。首图含创作性的品牌文字，不能视为官方 Logo 的精确副本。提示词与素材映射见 `docs/illustrations.md`。

## v1.1

新增12个固定品牌标识，原始公开图片及引用页面见 `web/assets/brand-sources-v11.json`。这些标识仅用于用户识别自己的饮品记录，不受代码MIT许可证授权。新增7张插画素材及完整提示词见 `docs/illustrations-v11.md`。v1.1运行时不再混用旧文字Logo或程序简笔杯。

# 资料来源与收录规则 · v1.1.1

核对日期：2026-10-20。内置图鉴收录12个品牌、167款有存在依据的饮品，其中瑞幸50款。

## 收录门槛

每个「品牌 + 单品名称」必须有可追溯的存在证据：品牌官网菜单及产品图、官方发布、公司披露、具名行业现场/上新报道或实际门店消费/售卖记录。仅有第三方聚合菜单页面不再足以收录。未作联网库存核验，历史款与地区款在详情明确标注适用范围。

名称存在与配料核实分别记录。配料只有在已审核来源明确提及后才填写，不能从品名或图片推断成分、营养或完整配方。没有证实的配料已清空，贴纸仅作创意主题插画，不宣称复刻实物。

- [逐款存在证据](catalog-evidence.md)：167款的名称、品牌、来源链接与范围。
- [全部492条审核结果](catalog-audit.json)：85条保留，407条撤下及原因；证据不足不等于被证伪。另补入82款有明确依据的产品。
- `data/catalog-evidence.json`：人工审核后的唯一收录清单。
- `data/catalog-candidates-v11.json`：上一版492条的名称与ID存档，不作为运行时菜单或配方。

## 已核实的纠正

- 瑞幸「柚C美式」：[品牌官网美式菜单](https://lkcoffee.com/products/americanos)。
- 古茗「桃胶木薯炖奶」：[品牌官方回归发布的新浪展示页](https://www.sina.cn/news/detail/5348439273508261.html)，[原料的行业报道](https://m.drinknewspaper.com/sys-nd/754.html)。不同季节可能更换小丸子/青团。
- 瑞幸「经典珍珠奶茶」确有产品：[官方微博](https://weibo.com/2/detail/5355317354824089)，[北京商报2026年10月12日上新报道](https://news.10jqka.com.cn/20261012/c680601800.shtml)。地区和上新时间差异可能导致部分门店看不到。
- 茉莉奶白「白兰抹茶」：[咖门实地报道确认是蛋糕](https://www.foodtalks.cn/news/60849)。原饮品条目已撤下；[官网正确饮品名是「抹茶白兰」](https://cn.mollytea.com/product/white-champaca-matcha-cn/)，作为独立正确条目收录，不擅自重写用户旧记录。
- 喜茶蛋糕、套餐周边，蜜雪冰淇淋/圣代，以及联名杯套等不再作为单杯饮品收录。

## 维护方式

`scripts/expand-catalog.py` 仅把第三方发现结果写到被忽略的 `build/unverified-candidates.json`，不能直接改运行时资料库。人工核验来源并更新 `data/catalog-evidence.json` 后，运行：

```bash
node scripts/build-audited-catalog.cjs
node tests/catalog-update.cjs
node tests/catalog-retirement.cjs
```

生成的 `web/catalog-extra.js` 随应用打包，无运行时联网抓取。审核撤下不会访问或修改用户数据文件，旧记录通过保存时的单品快照继续显示和编辑。

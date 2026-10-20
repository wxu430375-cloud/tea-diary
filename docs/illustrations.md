# 插画素材与提示词

生成方式：内置 `image_gen.imagegen`，透明背景。生成结果已经复制进 `web/assets`，不会引用开发者的个人目录。图像不在用户上传时重新调用云端生成。

第一张 `apple-tea.png` 的提示词：

> Create one transparent PNG illustration asset for a cute Chinese bubble tea journaling desktop app. Subject: a single hand-drawn apple jasmine iced tea in a gently tapered clear takeaway cup, green apple pieces at bottom, light apple-green tea, a few creamy pale layers, tiny jasmine flowers and a green apple leaning beside cup. Exactly the naive oil pastel / wax crayon sketch style of a child's drink menu doodle: wobbly dark brown outlines, uneven crayon fill with visible white gaps, very simple flat front view, charming and handmade, no gradients, no digital glossy 3D, no shadow, no background. Small doodle star and two pink hearts floating beside cup. Large generous clear margin around silhouette. Cup center has a small dark green oval label with simple cream Chinese brand text '1点点'. Design as one sticker, not a sheet, not a screen.

另外六张使用以下模板，`SUBJECT` 替换为表格中的主题：

> A single transparent background PNG crayon sticker illustration of SUBJECT. A tall tapered takeaway cup in front view, cup body occupies from x30% to 70%, y20% to 83% of image, one simple thin straw. Very naive handdrawn wax crayon style, wobbly dark brown pencil contour, irregular scribbly colored fills with visible white paper gaps. Childlike flat drawing matching Chinese DIY tea menu doodles, no 3D no gloss no drop shadow no photorealism. Sparse composition, cup and one ingredient only. At exact center x50% y50% of entire image, a small plain blank cream oval cup label, leave it empty so we can add brand mark in app. Absolutely no words or text, no watermark. Entire silhouette visible with generous margins.

| 文件 | SUBJECT |
|---|---|
| berry.png | strawberry and red berry fruit tea, pink-red layered drink, a strawberry next to the base, tiny leaf and pink heart |
| grape.png | purple grape iced tea, pale lavender top and dark grape-purple at bottom, a tiny bunch of purple grapes next to base |
| milk.png | jasmine milk tea, ivory creamy milk and very pale green tea layers, tiny white jasmine flowers and green leaves beside base |
| lemon.png | lemon iced tea, pale sunny yellow lemon water, a slice of lemon next to base, tiny yellow sparkle |
| orange.png | fresh orange mango fruit tea, warm orange and yellow layers with small fruit chunks, orange wedge and mango next to base |
| cocoa.png | chocolate boba milk tea, cocoa brown and creamy tan layers, dark brown tapioca pearls at bottom, two little chocolate squares beside base |

`dragonfruit.png` 的提示词：

> One single transparent PNG sticker: very naive wax crayon doodle of a red dragon fruit orange yogurt drink in a tall tapered clear takeaway cup with a thin straw, flat front view. The bottom is vivid pink-magenta with tiny black dragonfruit seeds, middle creamy ivory yogurt, top pale blush. A half red dragonfruit with black seeds and an orange wedge lean against the base. Wobbly dark brown pencil outlines, uneven crayon scribbles with white gaps. Matches an elementary-school handdrawn Chinese tea menu. No 3D no glossy shading no shadows no background. A blank ivory oval label at center of cup for later brand logo overlay. No text. Whole cup silhouette visible with generous empty transparent margin. Cup centered at x50%, cup middle blank label near y50%.

## 使用方式与范围

图片表示食材主题和风味印象，不是实际产品照片。已知主题调用静态蜡笔素材并叠加本地品牌标识；相同风味主题会复用底图。未覆盖的风味与自定义款使用 `web/stickers.js` 中按颜色、主题与单品ID绘制的确定性 SVG。当前没有逐款37张独立原画，也没有联网按新标签即席生成图片。

后续新增独立插画可向 `artMap` 添加单品专用映射；品牌标识在 `logoMap` 中设置。SVG导出会把图片数据嵌入文件，移走源码目录后仍能打开。

import { router, promptAction } from '@kit.ArkUI';
import { CleanService } from '../../services/CleanService';
import { ExportService } from '../../services/ExportService';
import { common } from '@kit.AbilityKit';

// 统一古风主题配色
interface AncientTheme {
  paperBg: string;   // 宣纸白
  textInk: string;   // 水墨黑
  textGrey: string;  // 苍灰
  accent: string;    // 苍茶
  accentDark: string;// 黛蓝
  border: string;    // 细米白分割线
}

const ANCIENT_COLORS: AncientTheme = {
  paperBg: '#FDFCF5',
  textInk: '#333333',
  textGrey: '#757575',
  accent: '#A5A07B',
  accentDark: '#2B333E',
  border: '#E0DDD5'
};

@Entry
@Component
export struct ExportPage {
  @State rawText: string = '';
  @State exportText: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.rawText = (params?.text as string) ?? '';
    this.exportText = this.rawText;
  }

  build() {
    Stack() {
      Image($r('app.media.texture_paper'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.05)

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255, 255, 255, 0.85)')

      Image($r('app.media.shanshui_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.08)

      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(22)
            .fontWeight(FontWeight.Lighter)
            .fontColor([ANCIENT_COLORS.textInk])
            .onClick(() => router.back())

          Text('文稿拓印 · 导出')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ANCIENT_COLORS.textInk)
            .margin({ left: 16 })

          Blank()
        }
        .padding({ left: 24, right: 24, top: 24, bottom: 16 })
        .width('100%')

        Scroll() {
          Column() {
            // --- 预览区域：模拟展开的卷轴 ---
            Column() {
              Row() {
                Divider().color(ANCIENT_COLORS.accent).width(20).strokeWidth(1.5)
                Text(' 预览文稿 ')
                  .fontSize(13)
                  .fontColor(ANCIENT_COLORS.accent)
                  .fontWeight(FontWeight.Bold)
                Divider().color(ANCIENT_COLORS.accent).width(20).strokeWidth(1.5)
              }
              .margin({ bottom: 16 })

              Scroll() {
                Text(this.exportText)
                  .fontSize(15)
                  .fontColor(ANCIENT_COLORS.textInk)
                  .lineHeight(24)
                  .width('100%')
              }
              .width('100%')
              .constraintSize({ maxHeight: 300 })
              .edgeEffect(EdgeEffect.Spring)
            }
            .padding(20)
            .margin({ left: 20, right: 20, top: 10, bottom: 20 })
            .backgroundColor('rgba(255,255,255,0.4)')
            .border({ width: { left: 2 }, color: ANCIENT_COLORS.accent })
            .borderRadius({ topRight: 8, bottomRight: 8 })

            Column() {
              this.ExportItem('导出为纯文本（复制）', 'sys.symbol.doc_text_badge_plus', () => {
                CleanService.copy(this.exportText);
                promptAction.showToast({ message: '已复制文本至剪贴板' });
              })

              Divider().color(ANCIENT_COLORS.border).width('90%').opacity(0.5)

              this.ExportItem('导出为 Word 文档', 'sys.symbol.doc_richtext', async () => {
                const ctx = getContext(this) as common.Context;
                const path = await ExportService.exportWord(ctx, this.exportText);
                const ok = await ExportService.saveToFileManager(ctx, path);
                if (ok) promptAction.showToast({ message: '文档已保存' });
              })

              Divider().color(ANCIENT_COLORS.border).width('90%').opacity(0.5)

              this.ExportItem('存为往日记录', 'sys.symbol.calendar_badge_plus', () => {
                CleanService.saveHistory(getContext(this) as common.UIAbilityContext, this.exportText);
                promptAction.showToast({ message: '已存入往日记录' });
              })
            }
            .margin({ left: 20, right: 20 })
            .backgroundColor('#FDFCF5')
            .borderRadius(8)
            .border({ width: 0.5, color: ANCIENT_COLORS.border })
            .shadow({ radius: 10, color: '#11000000', offsetY: 4 })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  ExportItem(label: string, icon: string, action: () => void) {
    Row() {
      SymbolGlyph($r(icon))
        .fontSize(20)
        .fontWeight(FontWeight.Lighter)
        .fontColor([ANCIENT_COLORS.accent])
        .margin({ right: 12 })

      Text(label)
        .fontSize(16)
        .fontColor(ANCIENT_COLORS.textInk)

      Blank()

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([ANCIENT_COLORS.border])
    }
    .width('100%')
    .padding(18)
    .onClick(action)
    .stateStyles({
      pressed: { .backgroundColor('#F2F2F2') },
      normal: { .backgroundColor(Color.Transparent) }
    })
  }
}
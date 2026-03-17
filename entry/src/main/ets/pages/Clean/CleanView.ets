import { CleanService } from '../../services/CleanService';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

interface AncientTheme {
  paperBg: string;
  textInk: string;
  textGrey: string;
  accent: string;
  accentDark: string;
  border: string;
  vip: string;
}

const ANCIENT_COLORS: AncientTheme = {
  paperBg: '#FDFCF5',
  textInk: '#333333',
  textGrey: '#757575',
  accent: '#A5A07B',
  accentDark: '#2B333E',
  border: '#E0DDD5',
  vip: '#C6A300'
};

@Entry
@Component
export struct CleanPage {
  @State input: string = '';
  @State output: string = '';
  @State mode: number = 0; // 0 纯净模式，1 语义模式
  @State showOutline: boolean = false;
  @State outlineItems: string[] = [];
  @State isCleaning: boolean = false;
  // 工具栏开关
  @State showTools: boolean = false;
  @State toolsOpacity: number = 0;
  @State toolsOffset: number = -10;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    const fromText = params?.text as string;
    const fromMode = params?.mode as number;
    if (fromText) {
      this.input = fromText;
    }
    if (fromMode !== undefined) {
      this.mode = fromMode;
    }
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

          Text('墨析·清稿')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(ANCIENT_COLORS.textInk)
            .margin({ left: 16 })
            .fontFamily('SourceHanSerif-Bold')

          Blank()

          SymbolGlyph($r('sys.symbol.ellipsis_message'))
            .fontSize(22)
            .fontWeight(FontWeight.Lighter)
            .fontColor([ANCIENT_COLORS.textInk])
            .onClick(() => this.toggleTools())
        }
        .padding({ left: 24, right: 24, top: 24, bottom: 16 })
        .width('100%')
        .border({ width: { bottom: 0.5 }, color: ANCIENT_COLORS.border })

        if (this.showTools) {
          Column() {
            this.ToolItem('导出', () => {
              this.showTools = false;
              router.pushUrl({ url: 'pages/features/ExportPage', params: { text: this.output } })
            })
            Divider().color(ANCIENT_COLORS.border).width('80%')
            this.ToolItem('往日记录', () => {
              this.showTools = false;
              router.pushUrl({ url: 'pages/features/HistoryPage' })
            })
            Divider().color(ANCIENT_COLORS.border).width('80%')
            this.ToolItem('大纲提取', () => {
              this.showTools = false;
              this.outlineItems = CleanService.extractOutline(this.input);
              if (this.outlineItems.length === 0) {
                promptAction.showToast({ message: '未检测到标题' });
                return;
              }
              this.showOutline = true;
            })
            Divider().color(ANCIENT_COLORS.border).width('80%')
            this.ToolItem('分享', () => {
              this.showTools = false;
              if (!this.output) {
                promptAction.showToast({ message: '请先清理文本，方可拓印分享' });
                return;
              }
              router.pushUrl({
                url: 'pages/features/SharePage',
                params: {
                  text: this.output
                }
              });
            })
          }
          .width(140)
          .backgroundColor('#FDFCF5')
          .borderRadius(8)
          .border({ width: 0.5, color: ANCIENT_COLORS.accent })
          .shadow({ radius: 15, color: '#22000000', offsetY: 8 })
          .position({ x: '58%', y: 70 })
          .opacity(this.toolsOpacity)
          .zIndex(100)
        }

        Scroll() {
          Column() {
            Column() {
              TextArea({ placeholder: '在此挥墨，粘贴 Markdown 文本...', text: this.input })
                .onChange(v => this.input = v)
                .fontSize(16)
                .fontColor(ANCIENT_COLORS.textInk)
                .placeholderColor(ANCIENT_COLORS.textGrey)
                .height(200)
                .backgroundColor(Color.Transparent)
                .padding(0)

              Row() {
                Text(`余墨：${this.input.length} 字`)
                  .fontSize(12)
                  .fontColor(ANCIENT_COLORS.textGrey)

                Blank()

                Text('清空')
                  .fontSize(13)
                  .fontColor(ANCIENT_COLORS.accentDark)
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .onClick(() => this.input = '')
              }
              .margin({ top: 8 })
            }
            .padding(20)
            .margin({ top: 16, left: 16, right: 16 })
            .border({
              width: { left: 2, top: 0.5, right: 0.5, bottom: 0.5 },
              color: ANCIENT_COLORS.accent,
              radius: { topLeft: 2, bottomLeft: 2, topRight: 8, bottomRight: 8 }
            })
            .backgroundColor('rgba(255,255,255,0.4)')

            Row({ space: 24 }) {
              this.ModeItem(0, '纯净清稿')
              this.ModeItem(1, '语义析理（VIP）')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24, bottom: 24 })

            if (this.isCleaning) {
              Row({ space: 8 }) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(ANCIENT_COLORS.accent)
                Text('清稿中...')
                  .fontSize(14)
                  .fontColor(ANCIENT_COLORS.textGrey)
              }
              .margin({ bottom: 16 })
            }

            Button() {
              Row() {
                if (!this.isCleaning) {
                  Text('一键清稿 · 析理完成')
                    .fontSize(16)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                    .letterSpacing(2)
                } else {
                  Text('正在清稿...')
                    .fontSize(16)
                    .fontColor(Color.White)
                }
              }
            }
            .width('85%')
            .height(50)
            .backgroundColor(this.isCleaning ? ANCIENT_COLORS.textGrey : ANCIENT_COLORS.accentDark)
            .borderRadius(6)
            .onClick(() => {
              if (this.isCleaning) return;
              this.cleanAndCopy();
            })
            .margin({ bottom: 24 })
            .shadow({ radius: 4, color: '#33000000', offsetY: 2 })

            if (this.output) {
              Column() {
                Row() {
                  Divider().color(ANCIENT_COLORS.accent).width(30).strokeWidth(2)
                  Text(' 清稿结果 ')
                    .fontSize(13)
                    .fontColor(ANCIENT_COLORS.accent)
                    .fontWeight(FontWeight.Bold)
                  Divider().color(ANCIENT_COLORS.accent).width(30).strokeWidth(2)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .margin({ bottom: 12 })

                Text(this.output)
                  .fontSize(15)
                  .fontColor(ANCIENT_COLORS.textInk)
                  .lineHeight(24)
                  .fontFamily('SourceHanSerif-Regular')
              }
              .padding(20)
              .width('100%')
              .margin({ left: 16, right: 16, bottom: 30 })
              .border({ width: { top: 0.5 }, color: ANCIENT_COLORS.border })
            } else {
              Column() {
                Text('清稿结果将显现于此')
                  .fontSize(14)
                  .fontColor(ANCIENT_COLORS.textGrey)
                  .fontStyle(FontStyle.Italic)
              }
              .margin({ top: 40, bottom: 40 })
            }

          }
          .width('100%')
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)

      }
      .width('100%')
      .height('100%')

      if (this.showOutline) {
        Stack({ alignContent: Alignment.Center }) {
          Rect()
            .fill('rgba(0,0,0,0.4)')
            .width('100%')
            .height('100%')
            .onClick(() => this.showOutline = false)

          Column() {
            Row() {
              Text('文稿大纲')
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(ANCIENT_COLORS.accentDark)
              Blank()
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(20)
                .fontWeight(FontWeight.Lighter)
                .fontColor([ANCIENT_COLORS.textGrey])
                .onClick(() => this.showOutline = false)
            }
            .width('100%')
            .padding({ bottom: 12 })
            .border({ width: { bottom: 1 }, color: ANCIENT_COLORS.accent })

            Scroll() {
              Column() {
                ForEach(this.outlineItems, (item: string) => {
                  Row() {
                    Circle({ width: 6, height: 6 }).fill(ANCIENT_COLORS.accent).margin({ right: 10, top: 2 })
                    Text(item)
                      .fontSize(15)
                      .fontColor(ANCIENT_COLORS.textInk)
                      .layoutWeight(1)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .lineHeight(22)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                  .margin({ top: 10, bottom: 10 })
                })
              }
              .width('100%')
            }
            .width('100%')
            .layoutWeight(1)
            .margin({ top: 8 })
          }
          .padding(24)
          .backgroundColor(ANCIENT_COLORS.paperBg)
          .borderRadius(2)
          .border({ width: 1, color: ANCIENT_COLORS.accentDark })
          .width('85%')
          .height('65%')
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.scale({ x: 0.8, y: 0.8 }).animation({ duration: 250, curve: Curve.EaseOut }),
            TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseIn })
          ))
        }
        .width('100%')
        .height('100%')
        .zIndex(200)
      }
    }
  }

  @Builder ToolItem(label: string, action: () => void) {
    Text(label)
      .fontSize(16)
      .fontColor(ANCIENT_COLORS.textInk)
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 12, bottom: 12 })
      .onClick(action)
      .stateStyles({
        pressed: { .backgroundColor('#EEEBDC') },
        normal: { .backgroundColor(Color.Transparent) }
      })
  }

  @Builder ModeItem(index: number, label: string): void {
    Row() {
      Stack() {
        Circle({ width: 18, height: 18 })
          .stroke(this.mode === index ? ANCIENT_COLORS.accentDark : ANCIENT_COLORS.border)
          .strokeWidth(this.mode === index ? 2 : 1)
          .fill(Color.Transparent)

        if (this.mode === index) {
          Circle({ width: 10, height: 10 })
            .fill(ANCIENT_COLORS.accentDark)
        }
      }
      .margin({ right: 8 })

      Text(label)
        .fontSize(15)
        .fontWeight(this.mode === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.mode === index ? ANCIENT_COLORS.accentDark : ANCIENT_COLORS.textGrey)
      if (index === 1) {
        Text(' (尊享)')
          .fontSize(12)
          .fontColor(ANCIENT_COLORS.vip)
          .fontStyle(FontStyle.Italic)
      }
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.mode === index ? 'rgba(165, 160, 123, 0.1)' : Color.Transparent)
    .borderRadius(20)
    .onClick(() => this.mode = index)
  }

  toggleTools() {
    if (!this.showTools) {
      this.showTools = true;
      animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
        this.toolsOpacity = 1;
        this.toolsOffset = 0;
      })
    } else {
      animateTo({ duration: 200, curve: Curve.EaseIn }, () => {
        this.toolsOpacity = 0;
        this.toolsOffset = -10;
      })
      setTimeout(() => this.showTools = false, 200);
    }
  }

  async cleanAndCopy() {
    if (!this.input.trim()) {
      promptAction.showToast({ message: '请先输入文稿' });
      return;
    }
    this.isCleaning = true;
    this.output = '';

    await new Promise<void>((resolve) => setTimeout(resolve, 800));

    let result = '';

    if (this.mode === 0) {
      result = CleanService.cleanPure(this.input);
    } else if (this.mode === 1) {
      result = CleanService.cleanSemantic(this.input);
    }

    result = CleanService.autoSpacing(result);
    result = CleanService.normalizeHeading(result);
    result = CleanService.removeExtraSpaces(result);

    animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
      this.output = result;
    })

    CleanService.copy(result);
    CleanService.saveHistory(getContext(this) as common.UIAbilityContext, result);

    this.isCleaning = false;
    promptAction.showToast({ message: '清稿完成，已拓印至剪贴板' });
    }
}
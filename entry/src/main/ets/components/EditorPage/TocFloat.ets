// ets/components/EditorPage/TocFloat.ets
import { ANCIENT_COLORS } from '../../pages/Editor/EditorPage'; // 确保路径正确引用你的颜色常量

interface TocItem {
  level: number;
  text: string;
  pos: number;
}

@Component
export struct TocFloat {
  @Link isShow: boolean;
  @Prop content: string;
  onJump: (pos: number) => void = () => {};

  // 解析 Markdown 标题
  private getToc(): TocItem[] {
    const lines = this.content.split('\n');
    const toc: TocItem[] = [];
    let currentPos = 0;

    lines.forEach(line => {
      const match = line.match(/^(#{1,6})\s+(.*)$/);
      if (match) {
        toc.push({
          level: match[1].length,
          text: match[2],
          pos: currentPos
        });
      }
      currentPos += line.length + 1;
    });
    return toc;
  }

  build() {
    if(this.isShow) {
      Stack({ alignContent: Alignment.End }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(43, 51, 62, 0.3)')
          .transition(TransitionEffect.OPACITY.animation({ duration: 500, curve: Curve.Sharp }))
          .onClick(() => this.isShow = false)

        Column() {
          Text('文稿大纲')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ANCIENT_COLORS.accentDark)
            .margin({ top: 60, bottom: 30 })
            .letterSpacing(3)

          Scroll() {
            Column() {
              ForEach(this.getToc(), (item: TocItem) => {
                Row() {
                  Rect()
                    .width(item.level === 1 ? 3 : 1)
                    .height(16)
                    .fill(item.level === 1 ? ANCIENT_COLORS.accent : ANCIENT_COLORS.textGrey)
                    .margin({ right: 12, left: (item.level - 1) * 16 })

                  Text(item.text)
                    .fontSize(item.level === 1 ? 16 : 15)
                    .fontColor(item.level === 1 ? ANCIENT_COLORS.textInk : ANCIENT_COLORS.textGrey)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 15, bottom: 15 })
                .onClick(() => {
                  this.onJump(item.pos);
                  this.isShow = false;
                })

                Divider().color('rgba(0,0,0,0.05)')
              }, (item: TocItem) => item.pos.toString() + item.text)

              if (this.getToc().length === 0) {
                Text('未见章句标题')
                  .fontSize(14)
                  .fontColor(ANCIENT_COLORS.textGrey)
                  .margin({ top: 50 })
              }
            }
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          Text('墨析 · 目录')
            .fontSize(13)
            .fontColor(ANCIENT_COLORS.textGrey)
            .margin({ bottom: 50, top: 20 })
            .opacity(0.5)
        }
        .width('80%')
        .height('100%')
        .backgroundColor(ANCIENT_COLORS.paperBg)
        .padding({ left: 30, right: 30 })
        .alignItems(HorizontalAlign.Start)
        .shadow({ radius: 50, color: 'rgba(0,0,0,0.15)', offsetX: -15 })
        .transition(TransitionEffect.move(TransitionEdge.END).animation({
          duration: 450,
          curve: Curve.EaseInOut
        }))
      }
      .width('100%')
      .height('100%')
    }
  }

}

import { ShareUtils } from '../../utils/ShareUtils';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

// --- 统一古风主题配色 ---
interface AncientTheme {
  paperBg: string;   // 宣纸白
  textInk: string;   // 水墨黑
  textGrey: string;  // 苍灰
  accent: string;    // 苍茶
  accentDark: string;// 黛蓝
  border: string;    // 浅米色分割线
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
export struct SharePage {
  @State text: string = '';
  @State isVip: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params.text) {
      this.text = params.text as string;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(0,0,0,0.4)')
        .onClick(() => router.back())

      Column() {
        Rect()
          .width(40)
          .height(4)
          .fill(ANCIENT_COLORS.accentDark)
          .borderRadius(2)
          .margin({ bottom: 20 })

        Text(this.isVip ? '墨析 · 尊享分享' : '拓印分享')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ANCIENT_COLORS.textInk)
          .margin({ bottom: 24 })

        Column() {
          if (!this.isVip) {
            this.ActionItem('分享纯文本', 'sys.symbol.text_badge_plus', () => {
              ShareUtils.shareText(this.context, this.text); //
              router.back();
            })

            this.ActionItem('获取尊享版解锁更多', 'sys.symbol.crown', () => {
              // TODO: 跳转到未来的 VIP 订阅页面
              promptAction.showToast({ message: '尊享功能正在研磨中' });
              router.back();
            })
          } else {
            this.ActionItem('分享干净文本', 'sys.symbol.doc_text', () => {
              ShareUtils.shareVipText(this.context, this.text);
              router.back();
            })

            this.ActionItem('导出为 Markdown 文件', 'sys.symbol.arrow_up_doc', () => {
              ShareUtils.shareMarkdown(this.context, this.text);
              router.back();
            })

            this.ActionItem('分享为水墨卷轴（图片）', 'sys.symbol.photo', () => {
              // TODO: 截图方案待接入
              promptAction.showToast({ message: '画卷绘制中，敬请期待' });
              router.back();
            })
          }
        }
        .width('100%')

        Text('取消')
          .fontSize(16)
          .fontColor(ANCIENT_COLORS.textGrey)
          .margin({ top: 12, bottom: 10 })
          .padding(10)
          .onClick(() => router.back())
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 20, bottom: 20 })
      .backgroundColor(ANCIENT_COLORS.paperBg) // 宣纸色背景
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 20, color: '#33000000', offsetY: -5 })
      .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ActionItem(label: string, iconSymbol: string, action: () => void) {
    Row() {
      SymbolGlyph($r(iconSymbol))
        .fontSize(22)
        .fontWeight(FontWeight.Lighter)
        .fontColor([ANCIENT_COLORS.accent])
        .margin({ right: 14 })

      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(ANCIENT_COLORS.textInk)

      Blank()

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([ANCIENT_COLORS.border])
    }
    .width('100%')
    .padding(18)
    .margin({ bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .border({ width: 0.5, color: ANCIENT_COLORS.border })
    .shadow({ radius: 8, color: '#05000000', offsetY: 2 })
    .onClick(action)
    .stateStyles({
      pressed: { .backgroundColor('#F2F2F2') },
      normal: { .backgroundColor(Color.White) }
    })
  }
}
import { promptAction } from '@kit.ArkUI';

interface AncientTheme {
  activeText: string;
  inactiveText: string;
  centerBg: string;
  border: string;
  bg: string;
}

const NAV_COLORS: AncientTheme = {
  activeText: '#2A6F6F',  // 激活时的文字颜色
  inactiveText: '#999999',// 未激活时的文字颜色
  centerBg: '#2B333E',    // 黛蓝色（中心按钮背景）
  border: 'rgba(0,0,0,0.08)', // 极浅的分割线
  bg: 'rgba(255, 255, 255, 0.85)' // 宣纸白，带一点通透感
};

interface TabItemConfig {
  index: number;
  label: string;
  icon?: Resource;
  iconActive?: Resource;
  isSpecial?: boolean;
}

@Component
export struct MoxiBottomNavBar {
  @Link currentIndex: number;

  private tabList: TabItemConfig[] = [
    { index: 0, label: '拾墨', icon: $r('app.media.ic_home'), iconActive: $r('app.media.ic_home_active') },
    { index: 1, label: '观止', icon: $r('app.media.ic_read'), iconActive: $r('app.media.ic_read_active') },
    { index: 2, label: 'AI', isSpecial: true },
    { index: 3, label: '清稿', icon: $r('app.media.ic_clean'), iconActive: $r('app.media.ic_clean_active') },
    { index: 4, label: '润笔', icon: $r('app.media.ic_edit'), iconActive: $r('app.media.ic_edit_active') },
  ];

  build() {
    Stack() {
      // 底部宣纸纹理背景
      Image($r('app.media.texture_paper'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 白色遮罩（让宣纸更白、更柔和）
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(255,255,255,0.65)') // 透明度可调：0.5~0.75 都很好看

      // 原来的导航栏内容
      Row() {
        ForEach(this.tabList, (item: TabItemConfig) => {
          if (item.isSpecial) {
            this.SpecialTabItem(item)
          } else {
            this.TabItem(item)
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(70)
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: { top: 0.5 }, color: NAV_COLORS.border })

  }

  @Builder
  SpecialTabItem(item: TabItemConfig) {
    Column() {
      Stack() {
        Circle()
          .width(52)
          .height(52)
          .fill(NAV_COLORS.centerBg)
          .shadow({ radius: 12, color: '#302A6F6F', offsetY: 4 })

        SymbolGlyph($r('sys.symbol.AI'))
          .fontSize(28)
          .fontColor([Color.White])
      }
      .margin({ bottom: 24 })
      .onClick(() => {
        this.currentIndex = item.index;
        promptAction.showToast({ message: '助手正在研磨思路...' });
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder TabItem(item: TabItemConfig) {
    Column() {
      Image(this.currentIndex === item.index ? item.iconActive : item.icon)
        .width(26)
        .height(26)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentIndex === item.index ? 1 : 0.6)

      Text(item.label)
        .fontSize(10)
        .margin({ top: 4 })
        .fontColor(this.currentIndex === item.index ? NAV_COLORS.activeText : NAV_COLORS.inactiveText)
        .fontWeight(this.currentIndex === item.index ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = item.index;
    })
  }
}
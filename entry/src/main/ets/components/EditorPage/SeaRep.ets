import { curves, promptAction } from '@kit.ArkUI';
import { ANCIENT_COLORS } from '../../pages/Editor/EditorPage';

@Component
export struct SeaRep {
  @Link isShow: boolean;
  @Link content: string;
  @State searchQuery: string = '';
  @State replaceQuery: string = '';
  @State searchResults: number[] = [];
  @State currentSearchIndex: number = 0;
  @State searchOpacity: number = 0;
  @State searchScale: number = 0.85;
  @Link isDirty: boolean; // 是否有未保存修改

  private controller: TextAreaController | undefined = undefined;

  // --- 查找核心逻辑
  handleSearch(direction: 'next' | 'prev' | 'first'): void {
    if (!this.searchQuery) {
      promptAction.showToast({ message: '请先输入寻迹词' });
      return;
    }

    // 简单的全局匹配
    const regex = new RegExp(this.searchQuery, 'g');
    const matches: number[] = [];
    let match: RegExpExecArray | null;

    while ((match = regex.exec(this.content)) !== null) {
      matches.push(match.index);
    }
    this.searchResults = matches;

    if (matches.length === 0) {
      promptAction.showToast({ message: '未觅得踪迹' });
      return;
    }

    // 索引定位
    if (direction === 'first') this.currentSearchIndex = 0;
    else if (direction === 'next') this.currentSearchIndex = (this.currentSearchIndex + 1) % matches.length;
    else if (direction === 'prev') this.currentSearchIndex = (this.currentSearchIndex - 1 + matches.length) % matches.length;

    // 选中并滚动到对应位置
    const pos = matches[this.currentSearchIndex];
    // 改为这一行
    this.controller?.setTextSelection(pos, pos + this.searchQuery.length);
    focusControl.requestFocus('editor_textarea');
  }

  handleReplace(all: boolean): void {
    if (!this.searchQuery) return;

    if (all) {
      const parts: string[] = this.content.split(this.searchQuery);
      if (parts.length <= 1) {
        promptAction.showToast({ message: '无迹可更' });
        return;
      }
      this.content = parts.join(this.replaceQuery);
      this.isDirty = true;
      this.searchResults = [];
      promptAction.showToast({ message: `全卷 ${parts.length - 1} 处已更易` });
    } else {
      const pos: number = this.searchResults[this.currentSearchIndex];
      if (pos !== undefined) {
        const start: string = this.content.substring(0, pos);
        const end: string = this.content.substring(pos + this.searchQuery.length);
        this.content = start + this.replaceQuery + end;
        this.isDirty = true;
        // 替换后重新搜索以刷新索引
        this.handleSearch('first');
      }
    }
  }

  private closeSearchPanel(): void {
    animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.searchOpacity = 0;
      this.searchScale = 0.9;
    })
    setTimeout(() => {
      this.isShow = false;
      this.searchResults = [];
      this.currentSearchIndex = 0;
      this.searchQuery = ''; // 清空搜索词
      }, 300)
  }

  build() {
    if (this.isShow) {
      Stack() {
        // 1. 灵动遮罩：不仅压暗，还带有微弱的模糊感
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(43, 51, 62, 0.2)') // 墨色暗影
          .backdropBlur(4) // 毛玻璃效果
          .opacity(this.searchOpacity)
          .onClick(() => this.closeSearchPanel())

        // 2. 弹窗主体：仿不规则宣纸叠放效果
        Column() {
          // 顶部装饰线与进度
          Row() {
            Circle({ width: 6, height: 6 }).fill(ANCIENT_COLORS.accent).margin({ right: 8 })
            Text('寻迹更易')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(ANCIENT_COLORS.accentDark)
              .letterSpacing(1.5)

            Blank()

            if (this.searchResults.length > 0) {
              Text(`${this.currentSearchIndex + 1} / ${this.searchResults.length}`)
                .fontSize(12)
                .fontColor(ANCIENT_COLORS.accent)
                .backgroundColor('rgba(165, 160, 123, 0.1)')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
            }
          }
          .width('100%')
          .margin({ bottom: 25 })

          Column() {
            TextInput({ placeholder: '寻觅何词...', text: this.searchQuery })
              .height(40)
              .width('100%')
              .backgroundColor(Color.Transparent)
              .caretColor(ANCIENT_COLORS.accent)
              .onChange((v: string) => {
                this.searchQuery = v;
                this.handleSearch('first');
              })
            Divider().color(ANCIENT_COLORS.border).strokeWidth(1)
          }.margin({ bottom: 15 })

          Column() {
            TextInput({ placeholder: '更易为何...', text: this.replaceQuery })
              .height(40)
              .width('100%')
              .backgroundColor(Color.Transparent)
              .caretColor(ANCIENT_COLORS.accent)
              .onChange((v: string) => this.replaceQuery = v)
            Divider().color(ANCIENT_COLORS.border).strokeWidth(1)
          }.margin({ bottom: 25 })

          // 灵动按钮组：错落布局
          Row({ space: 10 }) {
            // 翻页小方块
            this.IconButton($r('sys.symbol.chevron_left'), () => this.handleSearch('prev'))
            this.IconButton($r('sys.symbol.chevron_right'), () => this.handleSearch('next'))

            // 操作长按钮
            Button('易此')
              .fontSize(14)
              .height(40)
              .layoutWeight(1)
              .fontColor(ANCIENT_COLORS.accent)
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: ANCIENT_COLORS.accent })
              .borderRadius(10)
              .onClick(() => this.handleReplace(false))

            Button('全卷更易')
              .fontSize(14)
              .height(40)
              .layoutWeight(1.2)
              .fontColor(ANCIENT_COLORS.paperBg)
              .backgroundColor(ANCIENT_COLORS.accentDark)
              .borderRadius(10)
              .shadow({ radius: 10, color: 'rgba(43, 51, 62, 0.2)', offsetY: 4 })
              .onClick(() => this.handleReplace(true))
          }
          .width('100%')

          Text('合卷')
            .fontSize(14)
            .fontColor(ANCIENT_COLORS.textGrey)
            .margin({ top: 30 })
            .padding(10)
            .onClick(() => this.closeSearchPanel())
        }
        .width('88%')
        .padding(28)
        .backgroundColor('rgba(253, 252, 245, 0.96)')
        .borderRadius(24)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.12)', offsetY: 15 })
        .opacity(this.searchOpacity)
        .scale({ x: this.searchScale, y: this.searchScale })
        .onAppear(() => {
          animateTo({
            duration: 500,
            curve: curves.springCurve(10, 1, 200, 25)
          }, () => {
            this.searchOpacity = 1;
            this.searchScale = 1;
          })
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder IconButton(icon: Resource, action: () => void): void {
    Button() {
      SymbolGlyph(icon)
        .fontSize(20)
        .fontColor([ANCIENT_COLORS.accentDark])
    }
    .width(42)
    .height(42)
    .backgroundColor('rgba(0,0,0,0.04)')
    .borderRadius(10)
    .onClick(action)
  }

}
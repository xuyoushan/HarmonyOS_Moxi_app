import { window, promptAction, router, componentSnapshot } from '@kit.ArkUI';
import { EditorService } from '../../services/EditorService';
import { FileService} from '../../services/FileService'
import { TocFloat } from '../../components/EditorPage/TocFloat';
import { SeaRep } from '../../components/EditorPage/SeaRep'
import { RecentPanel } from '../../components/EditorPage/RecentPanel'
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';

interface AncientTheme {
  paperBg: string;
  textInk: string;
  textGrey: string;
  accent: string;
  accentDark: string;
  border: string;
}

export const ANCIENT_COLORS: AncientTheme = {
  paperBg: '#FDFCF5',
  textInk: '#333333',
  textGrey: '#757575',
  accent: '#A5A07B',
  accentDark: '#2B333E',
  border: 'rgba(0,0,0,0.08)',
};

interface RecentFile {
  name: string;
  uri: string;
}

@Entry
@Component
export struct EditorPage {
  @State fileName: string = '未命名文稿.md';
  @State currentFileUri: string = ''; // 记录当前打开文件的路径
  @State content: string = '';
  @State isPreview: boolean = false;
  @State lastCursorPos: number = 0;
  @State contentOpacity: number = 1;
  @State keyboardHeight: number = 0;
  @State isDirty: boolean = false; // 是否有未保存修改
  @State showRecentDialog: boolean = false;
  @State showSearchPanel: boolean = false;
  @State showTocPanel: boolean = false;
  @State isExporting: boolean = false;
  @LocalStorageProp('recentFiles') recentFiles: RecentFile[] = [];

  private autoSaveTimer: number = 0;
  private controller: TextAreaController = new TextAreaController();

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params?.fileName) this.fileName = params.fileName as string;
    if (params?.content) this.content = params.content as string;
    if (params?.uri) this.currentFileUri = params.uri as string;
    window.getLastWindow(getContext(this)).then((win) => {
      win.on('keyboardHeightChange', (height: number) => {
        this.keyboardHeight = px2vp(height);
      });
    })
  }

  async handleExportImage() {
    const context = getContext(this) as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();

    try {
      // 权限检查
      let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let tokenID = bundleInfo.appInfo.accessTokenId;
      let grantStatus = await atManager.checkAccessToken(tokenID, 'ohos.permission.WRITE_IMAGEVIDEO');

      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        const result = await atManager.requestPermissionsFromUser(context, ['ohos.permission.WRITE_IMAGEVIDEO']);
        if (result.authResults[0] !== 0) {
          promptAction.showToast({ message: '请在设置中开启相册权限' });
          return;
        }
      }

      if (!this.isPreview) {
        promptAction.showToast({ message: '请先进入预览模式' });
        return;
      }

      promptAction.showToast({ message: '正在拓印长卷...' });

      componentSnapshot.createFromBuilder(() => {
        this.ExportImageBuilder()
      })
        .then(async (pixelMap: PixelMap) => {
          if (pixelMap) {
            const success = await FileService.saveImageToPhotos(context, pixelMap);
            if (success) {
              promptAction.showToast({ message: '墨迹长卷已收入相册' });
            } else {
              promptAction.showToast({ message: '保存失败' });
            }
            pixelMap.release();
          }
        })
        .catch((err: Error) => {
          console.error('MOXI_LOG Error: ' + err.message);
          promptAction.showToast({ message: '拓印异常：文稿可能过长' });
        })

    } catch (err) {
      console.error('MOXI_LOG Error: ' + JSON.stringify(err));
      promptAction.showToast({ message: '系统响应异常' });
    }
  }

  async autoSave() {
    if (!this.currentFileUri) return; // 新建文稿不自动保存
    if (!this.isDirty) return;

    const ok = await FileService.saveFile(this.currentFileUri, this.content);
    if (ok) {
      this.isDirty = false;
      console.info('MOXI_LOG: AutoSave success');
    }
  }

  async handleSaveAs() {
    const uri = await FileService.saveAs(getContext(this), this.content, this.fileName);
    if (uri) {
      this.currentFileUri = uri;
      this.fileName = uri.split('/').pop() || this.fileName;
      promptAction.showToast({ message: '拓印成功' });
    }
  }

  addToRecentFiles(name: string, uri: string) {
    const list = this.recentFiles.filter(f => f.uri !== uri);
    list.unshift({ name, uri });
    this.recentFiles = list.slice(0, 10);
  }

  onPageHide() {
    if (this.isDirty) {
      promptAction.showDialog({
        title: '尚有墨迹未存',
        message: '是否保存当前文稿？',
        buttons: [
          { text: '保存', color: '#000000' },
          { text: '放弃', color: '#666666' }
        ]
      }).then(async (res) => {
        if (res.index === 0) {
          if (this.currentFileUri) {
            await FileService.saveFile(this.currentFileUri, this.content);
          } else {
            await this.handleSaveAs();
          }
        }
      });
    }
  }

  onBackPress(): boolean {
    if (this.isDirty) {
      this.showUnsavedDialog();
      return true; // 阻止默认返回
    }
    return false;
  }

  showRecentFilesDialog() {
    this.showRecentDialog = true;
  }

  showUnsavedDialog() {
    promptAction.showDialog({
      title: '墨迹未存',
      message: '是否保存当前文稿？',
      buttons: [
        { text: '保存', color: '#000000' },
        { text: '放弃', color: '#666666' }
      ]
    }).then(async (res) => {
      if (res.index === 0) {
        if (this.currentFileUri) {
          await FileService.saveFile(this.currentFileUri, this.content);
        } else {
          await this.handleSaveAs();
        }
        router.back();
      } else {
        router.back();
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景：山水
      Image($r('app.media.shanshui_bg'))
        .width('100%').height('100%')
        .objectFit(ImageFit.Cover).opacity(0.12)

      Column() {
        // 顶部栏
        this.TopBar()

        // 核心内容区
        Stack() {
          Image($r('app.media.texture_paper'))
            .width('100%').height('100%')
            .objectFit(ImageFit.Cover)
            .opacity(this.isPreview ? 0.1 : 0.04)

          if (this.isPreview) {
            Column().width('100%').height('100%')
              .backgroundColor(ANCIENT_COLORS.paperBg)  // 米黄色
            this.ReadingArea()
          } else {
            this.EditorArea()
          }
        }
        .layoutWeight(1).width('100%')
        .opacity(this.contentOpacity)
        .animation({ duration: 400, curve: Curve.EaseInOut })
      }
      .width('100%').height('100%')

      // 底部工具区
      if (!this.isPreview) {
        this.EditorToolbar()
      } else {
        this.ReadingStatusBar()
      }
      RecentPanel({
        isShow: $showRecentDialog,
        content: $content,
        fileName: $fileName,
        currentFileUri: $currentFileUri
      })
      SeaRep({
        isShow: $showSearchPanel, // 连通显示开关
        content: $content,         // 连通内容，实现替换功能
        isDirty: $isDirty,         // 连通脏数据状态，实现保存联动
        controller: this.controller // 连通控制器，实现跳转聚焦
      })
      TocFloat({
        isShow: $showTocPanel,
        content: this.content,
        onJump: (pos: number) => {
          // 跳转并请求焦点，让光标出现在对应位置
          this.controller.setTextSelection(pos, pos);
          focusControl.requestFocus('editor_textarea');
        }
      })
    }
    .width('100%').height('100%')
    .backgroundColor(ANCIENT_COLORS.paperBg)
  }

  // 顶部栏
  @Builder TopBar(): void {
    Row() {
      // 左侧：文件名 + 下拉菜单
      Row() {
        Text(this.fileName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ANCIENT_COLORS.textInk)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '40%' }) // 限制最大宽度，给右侧留位子

        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(14)
          .fontColor([ANCIENT_COLORS.textGrey])
          .margin({ left: 4 })
      }
      .justifyContent(FlexAlign.Start)
      .height('100%')
      .bindMenu([
        {
          value: '新建文稿',
          action: () => {
            this.content = '';
            this.fileName = '未命名文稿.md';
            this.currentFileUri = '';
            promptAction.showToast({ message: '已新建文稿' });
          }
        },
        {
          value: '打开文稿',
          action: async () => {
            const res = await FileService.openFile(getContext(this));
            if (res) {
              this.content = res.content;
              this.fileName = res.fileName;
              this.currentFileUri = res.uri;
              this.addToRecentFiles(res.fileName, res.uri);
              promptAction.showToast({ message: '文稿已开启' });
            }
          }
        },
        {
          value: '最近打开',
          action: () => this.showRecentFilesDialog()
        },
        {
          value: '另存为',
          action: () => this.handleSaveAs()
        },
        {
          value: '拓印为图',
          action: () => this.handleExportImage() // 调用导出逻辑
        }
      ])

      Blank()

      SymbolGlyph($r('sys.symbol.book'))
        .fontSize(22)
        .fontColor([ANCIENT_COLORS.accentDark])
        .margin({ right: 16 })
        .onClick(() => {
          // 沉稳的触发方式
          console.info('MOXI_LOG: 准备开启大纲');
          this.showTocPanel = true;
        })
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(22)
        .fontColor([ANCIENT_COLORS.accentDark])
        .margin({ right: 16 })
        .onClick(() => this.showSearchPanel = true)
      // 中间：保存按钮（经典软盘图标）
      SymbolGlyph($r('sys.symbol.save'))
        .fontSize(22)
        .fontColor([ANCIENT_COLORS.accentDark])
        .margin({ right: 16 })
        .onClick(async () => {
          if (this.currentFileUri) {
            const ok = await FileService.saveFile(this.currentFileUri, this.content);
            if (ok) promptAction.showToast({ message: '墨迹已保存' });
          } else {
            this.handleSaveAs();
          }
        })

      // 右侧：预览切换按钮
      SymbolGlyph(this.isPreview ? $r('sys.symbol.eye_slash') : $r('sys.symbol.eye'))
        .fontSize(26)
        .fontColor([ANCIENT_COLORS.accent])
        .onClick(() => {
          this.contentOpacity = 0;
          setTimeout(() => {
            this.isPreview = !this.isPreview;
            this.contentOpacity = 1;
          }, 200);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 24, right: 24 })
  }

  // 编辑区
  @Builder EditorArea(): void {
    TextArea({
      text: this.content,
      placeholder: '挥毫落纸墨痕新...',
      controller: this.controller
    })
      .id('editor_textarea')
      .width('100%').height('100%')
      .fontSize(18).fontColor(ANCIENT_COLORS.textInk)
      .backgroundColor(Color.Transparent)
      .padding({ bottom: 120, left: 24, right: 24, top: 20 })
      .onChange((value: string) => {
        this.content = value;
        this.isDirty = true;

        // 自动保存防抖
        clearTimeout(this.autoSaveTimer);
        this.autoSaveTimer = setTimeout((): void => {this.autoSave();}, 800);
      })
      .onTextSelectionChange((start: number) => this.lastCursorPos = start)
  }

  // 阅读区
  @Builder ReadingArea(): void {
    Column() {
      Scroll() {
        RichText(EditorService.mdToHtml(this.content))
          .width('100%')
          .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFCF5')
    .padding({ left: 15, right: 15, top: 20, bottom: 80 })
  }

  @Builder
  ExportImageBuilder() {
    Column() {
      // ⭐ 核心：不加 Scroll，宽度固定，高度 auto
      RichText(EditorService.mdToHtml(this.content))
        .width('100%')
        .height('auto')
    }
    .width(400) // 略微加宽，保证排版美观
    .backgroundColor('#FDFCF5')
    .padding({ left: 15, right: 15, top: 20, bottom: 20 })
  }

  // 工具栏（扩展版）
  @Builder EditorToolbar(): void {
    Column() {
      // 第一行：行内格式 + 标题 (润笔)
      Scroll() {
        Row() {
          this.ToolbarItem('B', () => this.handleSmartFormat('bold'))
          this.ToolbarItem('I', () => this.handleSmartFormat('italic'))
          this.ToolbarItem('S', () => this.handleSmartFormat('strike'))
          this.ToolbarItem('`', () => this.handleSmartFormat('inlineCode'))
          this.ToolbarItem('H', () => this.handleSmartFormat('h'))
          this.ToolbarItem('“', () => this.handleSmartFormat('quote'))
          this.ToolbarItem('•', () => this.handleSmartFormat('list'))
          this.ToolbarItem('1.', () => this.handleSmartFormat('olist'))
          this.ToolbarItem('∅', () => this.handleSmartFormat('clear'))
        }
        .padding({ left: 10, right: 10 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 淡淡的分割线
      Divider().color('rgba(0,0,0,0.05)').margin({ left: 15, right: 15, top: 2, bottom: 2 })

      // 第二行：插入类 + 文本处理 (插画/排版)
      Scroll() {
        Row() {
          this.ToolbarItem('IMG', () => this.handleInsert('image'))
          this.ToolbarItem('LINK', () => this.handleInsert('link'))
          this.ToolbarItem('TAB', () => this.handleInsert('table'))
          this.ToolbarItem('CODE', () => this.handleInsert('codeBlock'))
          this.ToolbarItem('—', () => this.handleSmartFormat('divider'))
          this.ToolbarItem('日', () => this.handleInsert('date'))
          this.ToolbarItem('时', () => this.handleInsert('time'))
          this.ToolbarItem('排', () => this.handleProcess('autoFormat'))
        }
        .padding({ left: 10, right: 10 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('96%')
    .padding({ top: 4, bottom: 4 })
    .backgroundColor('rgba(255, 255, 255, 0.82)') // 透明度调至 0.82
    .backgroundBlurStyle(BlurStyle.Thin)
    // 键盘联动逻辑：根据键盘高度动态设置位置
    .position({ x: '2%', y: '100%' })
    .markAnchor({
      x: 0,
      y: this.keyboardHeight > 0 ? (this.keyboardHeight + 100) : 120
    })
    .borderRadius(20)
    .shadow({ radius: 12, color: '#15000000', offsetY: 6 })
    .animation({ duration: 200, curve: Curve.FastOutSlowIn }) // 随键盘弹出的平滑动画
  }

  @Builder ToolbarItem(label: string, action: () => void): void {
    Button() {
      Text(label)
        .fontSize(label.length === 1 ? 18 : 12) // 缩小字号
        .fontWeight(FontWeight.Bold)
        .fontColor(ANCIENT_COLORS.accentDark)
        .letterSpacing(0)
    }
    .type(ButtonType.Circle)
    .backgroundColor(Color.Transparent)
    .width(40).height(40) // 从48缩小到40
    .onClick(action)
  }

  @Builder ReadingStatusBar(): void {
    Row() {
      Text('观止中...')
        .fontSize(14)
        .fontWeight(300)
        .fontColor(ANCIENT_COLORS.accent)
        .letterSpacing(2)
    }
    .width('100%').height(54)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 30 })
  }

  // --- 业务逻辑 ---

  handleSmartFormat(type: string): void {
    const result = EditorService.applySmartFormat(this.content, this.lastCursorPos, type);
    this.content = result.newText;
    promptAction.showToast({ message: '润笔完成' });

    setTimeout(() => {
      this.controller.setTextSelection(result.newPos, result.newPos);
      focusControl.requestFocus('editor_textarea');
    }, 50);
  }

  handleInsert(type: string): void {
    const result = EditorService.insertAt(this.content, this.lastCursorPos, type);
    this.content = result.newText;
    setTimeout(() => {
      this.controller.setTextSelection(result.newPos, result.newPos);
      focusControl.requestFocus('editor_textarea');
    }, 50);
  }

  handleProcess(type: string): void {
    let newText = this.content;
    switch (type) {
      case 'autoFormat':
        newText = EditorService.autoFormat(this.content);
        break;
    }
    this.content = newText;
    promptAction.showToast({ message: '文稿已整饰' });
  }
}

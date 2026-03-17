import { router } from '@kit.ArkUI';
import { CleanService } from '../../services/CleanService';
import { common } from '@kit.AbilityKit';

interface HistoryItem {
  text: string;
  time: number;
}

interface GroupItem {
  title: string;
  items: HistoryItem[];
}

interface DateGroup {
  today: HistoryItem[];
  yesterday: HistoryItem[];
  earlier: HistoryItem[];
}

@Entry
@Component
export struct HistoryPage {
  @State history: HistoryItem[] = [];
  @State filtered: HistoryItem[] = [];
  @State grouped: GroupItem[] = [];

  @State pressedIndex: number = -1;
  @State showDeleteDialog: boolean = false;
  @State deleteIndex: number = -1;

  @State showSelectDialog: boolean = false;
  @State selectedItem: HistoryItem | null = null;

  @State keyword: string = '';

  aboutToAppear() {
    const ctx = getContext(this) as common.Context;
    CleanService.loadHistory(ctx).then(items => {
      // 按时间倒序
      this.history = items.sort((a, b) => b.time - a.time);
      this.filtered = this.history;
      this.grouped = this.groupByDate(this.filtered);
    });
  }

  build() {
    Stack() {
      // 背景图（淡墨）
      Image($r('app.media.shanshui_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.18)

      Column() {
        // 顶部栏
        Row() {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(22)
            .onClick(() => router.back())

          Text('历史记录')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 10 })
        .width('100%')

        // 搜索框
        Row() {
          TextInput({ placeholder: '搜索历史内容…' })
            .width('100%')
            .height(40)
            .backgroundColor('rgba(255,255,255,0.9)')
            .borderRadius(12)
            .padding({ left: 12 })
            .onChange(v => {
              this.keyword = v;
              this.filtered = this.history.filter(h => h.text.includes(v));
              this.grouped = this.groupByDate(this.filtered);
            })
        }
        .padding({ left: 20, right: 20, bottom: 10 })

        // 空状态
        if (this.grouped.length === 0) {
          Column() {
            Text('暂无匹配记录')
              .fontSize(16)
              .fontColor('#666')
              .margin({ top: 40 })

            Text('试试换个关键词')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .width('100%')
          .align(Alignment.Center)
        }

        // 列表（按日期分组）
        if (this.grouped.length > 0) {
          List() {
            ForEach(this.grouped, (group: GroupItem, gIndex: number) => {
              // 分组标题
              ListItem() {
                Text(group.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#444')
                  .margin({ left: 20, top: 12, bottom: 6 })
              }

              // 分组内容
              ForEach(group.items, (item: HistoryItem, index: number) => {
                ListItem() {
                  Column() {
                    Text(item.text)
                      .fontSize(14)
                      .fontColor('#333')
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatTime(item.time))
                      .fontSize(12)
                      .fontColor('#888')
                      .margin({ top: 6 })
                  }
                  .padding(14)
                  .backgroundColor('rgba(255,255,255,0.92)')
                  .borderRadius(12)
                  .shadow({ radius: 6, color: '#11000000', offsetY: 2 })
                  .scale(this.pressedIndex === item.time
                    ? { x: 0.97, y: 0.97 }
                    : { x: 1.0,  y: 1.0 }
                  )
                  .margin({ left: 20, right: 20, top: 8, bottom: 8 })
                  .onTouch(event => {
                    if (event.type === TouchType.Down) {
                      this.pressedIndex = item.time;
                    } else if (event.type === TouchType.Up) {
                      this.pressedIndex = -1;
                      this.selectedItem = item;
                      this.showSelectDialog = true;
                    }
                  })
                  .gesture(
                    GestureGroup(GestureMode.Exclusive,
                      LongPressGesture({ duration: 500 })
                        .onAction(() => {
                          this.deleteIndex = this.history.findIndex(h => h.time === item.time);
                          this.showDeleteDialog = true;
                        }),
                      TapGesture()
                        .onAction(() => {
                          this.selectedItem = item;
                          this.showSelectDialog = true;
                        })
                    )
                  )
                }
              }, (item: HistoryItem) => item.time.toString())
            }, (group: GroupItem) => group.title)
          }
        }
      }
      .width('100%')
      .height('100%')

      // 删除弹窗
      if (this.showDeleteDialog) {
        this.DeleteDialog();
      }

      // 点击选择弹窗（CleanPage / EditPage）
      if (this.showSelectDialog) {
        this.SelectDialog();
      }
    }
  }

  // 时间格式化
  private formatTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getHours()}:${d.getMinutes().toString().padStart(2, '0')}`;
  }

  // 日期分组（今天 / 昨天 / 更早）
  private groupByDate(list: HistoryItem[]): GroupItem[] {
    const today = new Date();
    const yesterday = new Date(Date.now() - 86400000);

    const groups: DateGroup = {
      today: [],
      yesterday: [],
      earlier: [],
    };

    list.forEach(item => {
      const d = new Date(item.time);

      if (d.toDateString() === today.toDateString()) {
        groups.today.push(item);
      } else if (d.toDateString() === yesterday.toDateString()) {
        groups.yesterday.push(item);
      } else {
        groups.earlier.push(item);
      }
    });

    const result: GroupItem[] = [];

    if (groups.today.length > 0) {
      result.push({ title: '今天', items: groups.today } as GroupItem);
    }
    if (groups.yesterday.length > 0) {
      result.push({ title: '昨天', items: groups.yesterday } as GroupItem);
    }
    if (groups.earlier.length > 0) {
      result.push({ title: '更早', items: groups.earlier } as GroupItem);
    }
    return result;
  }

  // ============================
  // 删除弹窗
  // ============================
  @Builder
  DeleteDialog() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showDeleteDialog = false)

      Column() {
        Text('删除记录？')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 12 })

        Text('此操作不可恢复')
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 20 })

        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor('#666')
            .padding(12)
            .backgroundColor('#F2F2F2')
            .borderRadius(8)
            .onClick(() => this.showDeleteDialog = false)

          Blank()

          Text('删除')
            .fontSize(16)
            .fontColor('#B33A3A')
            .padding(12)
            .backgroundColor('#FFF0F0')
            .borderRadius(8)
            .onClick(() => {
              this.history.splice(this.deleteIndex, 1);
              this.filtered = this.history;
              this.grouped = this.groupByDate(this.filtered);
              this.showDeleteDialog = false;
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 12, color: '#22000000', offsetY: 2 })
      .width('70%')
    }
    .width('100%')
    .height('100%')
  }

  // ============================
  // 选择弹窗（CleanPage / EditPage）
  // ============================
  @Builder
  SelectDialog() {
    Stack() {
      Rect()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showSelectDialog = false)

      Column() {
        Text('打开方式')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        // CleanPage
        Text('清理模式打开')
          .fontSize(16)
          .fontColor('#2A6F6F')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ bottom: 10 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Clean/CleanView',
              params: { text: this.selectedItem!.text }
            });
          })

        // EditPage
        Text('编辑模式打开')
          .fontSize(16)
          .fontColor('#2A6F6F')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/EditPage',
              params: { text: this.selectedItem!.text }
            });
          })
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 12, color: '#22000000', offsetY: 2 })
      .width('70%')
    }
    .width('100%')
    .height('100%')
  }
}

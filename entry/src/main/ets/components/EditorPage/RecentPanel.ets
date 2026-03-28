// components/EditorPage/RecentPanel.ets
import { FileService } from '../../services/FileService';

interface RecentFile {
  name: string;
  uri: string;
}

@Component
export struct RecentPanel {
  @Link isShow: boolean;
  @Link content: string;
  @Link fileName: string;
  @Link currentFileUri: string; // 记录当前打开文件的路径
  @LocalStorageProp('recentFiles') recentFiles: RecentFile[] = [];

  build() {
    if (this.isShow) {
      Stack() {
        // 1. 半透明遮罩层
        Column()
          .width('100%').height('100%')
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => this.isShow = false)

        // 2. 弹窗主体内容
        Column() {
          Text('最近打开')
            .fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#2B333E').margin({ bottom: 12 }).letterSpacing(2)

          Divider().strokeWidth(1).color('rgba(0,0,0,0.1)').margin({ bottom: 8 })

          Column() {
            //最近6条
            ForEach(this.recentFiles.slice(0, 6), (f: RecentFile) => {
              Row() {
                SymbolGlyph($r('sys.symbol.doc_text_fill'))
                  .fontSize(20).fontColor(['#A5A07B']).margin({ right: 12 })

                Text(f.name)
                  .fontSize(16).fontColor('#333333').layoutWeight(1)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(14).fontColor(['#757575'])
              }
              .width('100%').padding({ top: 12, bottom: 12, left: 4 })
              .onClick(async () => {
                const res = await FileService.openFileByUri(f.uri);
                if (res) {
                  this.content = res.content;
                  this.fileName = res.fileName;
                  this.currentFileUri = res.uri;
                  this.isShow = false; // 选完合卷
                }
              })

              Divider().color('rgba(0,0,0,0.03)').margin({ left: 32 })
            })

            if (this.recentFiles.length === 0) {
              Text('暂无陈迹').fontSize(14).fontColor('#757575').margin(30)
            }
          }

          Text('合卷')
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#A5A07B')
            .margin({ top: 20 }).padding(10)
            .onClick(() => this.isShow = false)
        }
        .width('80%').padding(24)
        .backgroundColor('#FDFCF5').borderRadius(16)
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.2)' })
      }
      .width('100%').height('100%')
    }
  }
}
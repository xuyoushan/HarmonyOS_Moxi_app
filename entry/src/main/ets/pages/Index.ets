// Index.ets
import { MoxiBottomNavBar } from '../components/BottomNavBar';
import { CleanPage } from './Clean/CleanView';
import { EditorPage } from './Editor/EditorPage';

@Entry
@Component
struct Index {
  @LocalStorageProp('externalUri') @Watch('onExternalUriChanged') externalUri: string = '';
  @State currentIndex: number = 0;

  onExternalUriChanged() {
    console.info('MOXI_LOG: 检测到外部文件，准备切换到编辑器: ' + this.externalUri);
    if (this.externalUri && this.externalUri.length > 0) {
      this.currentIndex = 1;
    }
  }

  aboutToAppear() {
    if (this.externalUri) {
      this.currentIndex = 1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Stack() {
          if (this.currentIndex === 0) {
            this.PlaceholderPage('墨析 · 拾墨')
          } else if (this.currentIndex === 1) {
            this.PlaceholderPage('墨析 · 观止')
          } else if (this.currentIndex === 2) {
            this.PlaceholderPage('墨析 · AI 助手')
          } else if (this.currentIndex === 3) {
            CleanPage()
          } else if (this.currentIndex === 4) {
            EditorPage()
          }
        }
        .layoutWeight(1)
        .width('100%')

        Row().width('100%').height(70)
      }
      .width('100%')
      .height('100%')

      MoxiBottomNavBar({ currentIndex: $currentIndex })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFCF5')
  }

  @Builder
  PlaceholderPage(title: string) {
    Column() {
      Text(title).fontSize(20).fontColor('#757575')
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
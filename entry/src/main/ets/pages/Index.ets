import { MoxiBottomNavBar } from '../components/BottomNavBar';
import { CleanPage } from './Clean/CleanView';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

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
            this.PlaceholderPage('墨析 · 润笔')
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
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#757575')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

interface StorageSchema {
  externalUri: string;
}

export default class EntryAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage({
    'externalUri': ''
  } as Record<string, string>);

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('MOXI_LOG: [Ability] onCreate 启动');
    this.extractUri(want);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      console.error('MOXI_LOG: [Ability] 设置颜色模式失败');
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('MOXI_LOG: [Ability] onNewWant 热启动 (后台唤起)');
    this.extractUri(want);
  }

  private extractUri(want: Want): void {
    console.info('MOXI_LOG: [Ability] Want数据全扫描: ' + JSON.stringify(want));

    let uri = want.uri;

    if (!uri && want.parameters) {
      uri = want.parameters['key_uri'] as string || want.parameters['uri'] as string;
    }

    if (uri) {
      console.info('MOXI_LOG: [Ability] 成功提取到有效 URI: ' + uri);
      this.storage.setOrCreate('externalUri', uri);
    } else {
      console.warn('MOXI_LOG: [Ability] 未检出任何有效 URI 路径');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('MOXI_LOG: [Ability] onWindowStageCreate 准备加载 Index');

    const targetPage = 'pages/Index';

    windowStage.loadContent(targetPage, this.storage, (err) => {
      if (err.code) {
        console.error(`MOXI_LOG: [Ability] 加载 Index 失败! Code: ${err.code}, Msg: ${err.message}`);
        return;
      }
      console.info('MOXI_LOG: [Ability] Index 页面加载成功，当前存储的 URI 为: ' + this.storage.get('externalUri'));
    });
  }

  onWindowStageDestroy(): void { console.info('MOXI_LOG: [Ability] onWindowStageDestroy'); }
  onForeground(): void { console.info('MOXI_LOG: [Ability] onForeground'); }
  onBackground(): void { console.info('MOXI_LOG: [Ability] onBackground'); }
  onDestroy(): void { console.info('MOXI_LOG: [Ability] onDestroy'); }
}
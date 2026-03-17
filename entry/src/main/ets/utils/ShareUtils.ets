import fs from '@ohos.file.fs';
import { common, Want } from '@kit.AbilityKit';

export class ShareUtils {

  static shareText(context: common.UIAbilityContext, text: string) {
    let want: Want = {
      action: 'ohos.want.action.sendData',
      parameters: {
        'share_text': text
      }
    };
    context.startAbility(want).catch((err: Error) => {
      console.error('分享失败: ' + JSON.stringify(err));
    });
  }

  static shareVipText(context: common.UIAbilityContext, text: string) {
    let want: Want = {
      action: 'ohos.want.action.sendData',
      parameters: {
        'share_text': text
      }
    };
    context.startAbility(want).catch((err: Error) => {
      console.error('VIP 文本分享失败: ' + JSON.stringify(err));
    });
  }

  static async shareMarkdown(context: common.UIAbilityContext, text: string) {
    const dir = context.filesDir;
    const filePath = `${dir}/moxi_share_${Date.now()}.md`;

    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    fs.writeSync(file.fd, text);
    fs.closeSync(file);

    let want: Want = {
      action: 'ohos.want.action.sendData',
      uri: `file://${filePath}`,
      type: 'text/markdown',
      flags: 1
    };

    context.startAbility(want).catch((err: Error) => {
      console.error('分享文件失败: ' + JSON.stringify(err));
    });
  }
}
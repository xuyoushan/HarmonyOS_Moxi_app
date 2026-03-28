import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

// 1. 必须 export 接口，否则 EditorPage 无法识别类型
export interface FileInfo {
  fileName: string;
  content: string;
  uri: string;
}

export class FileService {
  /**
   * 核心新增：直接根据 URI 读取文件内容
   * 用于系统外部关联打开的情况
   */
  static async openFileByUri(uri: string): Promise<FileInfo | null> {
    try {
      // 打开文件流
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);

      // 读取缓冲区
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);

      // 解码为字符串
      const decoder = util.TextDecoder.create('utf-8');
      const content = decoder.decodeWithStream(new Uint8Array(buf));

      return {
        // 从路径截取文件名（解码 URI 中的特殊字符）
        fileName: decodeURI(uri).split('/').pop() || '外来文稿.md',
        content: content,
        uri: uri
      };
    } catch (err) {
      console.error('FileService openFileByUri failed:', err);
      return null;
    }
  }

  /**
   * 通过 Picker 选择并打开文件
   */
  static async openFile(context: common.Context): Promise<FileInfo | null> {
    const documentPicker = new picker.DocumentViewPicker(context);
    try {
      const uris = await documentPicker.select();
      if (uris.length === 0) return null;
      return await FileService.openFileByUri(uris[0]);
    } catch (err) {
      return null;
    }
  }

  /**
   * 保存到已知 URI（直接覆盖）
   */
  static async saveFile(uri: string, content: string): Promise<boolean> {
    try {
      // 修正点：使用 TRUNC 确保清空后再写入
      const file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      return true;
    } catch (e) {
      console.error('FileService saveFile failed:', e);
      return false;
    }
  }

  /**
   * 另存为新文件
   */
  static async saveAs(context: common.Context, content: string, defaultName: string): Promise<string | null> {
    const documentPicker = new picker.DocumentViewPicker(context);
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [defaultName];

    try {
      const uris = await documentPicker.save(saveOptions);
      if (uris.length === 0) return null;

      const uri = uris[0];
      // 修正点：保存时也建议加上 TRUNC 保证写入完整性
      const file = fs.openSync(uri, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      return uri;
    } catch (err) {
      console.error('FileService saveAs failed:', err);
      return null;
    }
  }

  // FileService.ets 内部修改
  static async saveImageToPhotos(context: common.Context, pixelMap: image.PixelMap): Promise<boolean> {
    let file: fs.File | undefined;
    try {
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      // 1. 创建资产
      const assetUri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      // 2. 打开文件
      file = fs.openSync(assetUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

      // 3. 打包图片
      const imagePacker = image.createImagePacker();
      const packOptions: image.PackingOption = { format: "image/jpeg", quality: 100 };
      await imagePacker.packToFile(pixelMap, file.fd, packOptions);

      // 4. 【关键步骤】强制同步数据到磁盘
      fs.fsyncSync(file.fd);

      // 5. 关闭文件
      fs.closeSync(file.fd);

      // 6. 释放 Packer 资源
      imagePacker.release();

      return true;
    } catch (err) {
      const error = err as Error;
      console.error('MOXI_LOG_SAVE_ERROR: ' + error.message);
      if (file) {
        fs.closeSync(file.fd);
      }
      return false;
    }
  }
}
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';

export class ExportService {

  // ============================================================
  // 1. 导出为纯文本 (.txt)
  // ============================================================
  static async exportTxt(context: common.Context, text: string): Promise<string> {
    const dir = context.filesDir;
    const filePath = `${dir}/moxi_${Date.now()}.txt`;

    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    fs.writeSync(file.fd, text);
    fs.closeSync(file);

    return filePath;
  }

  // ============================================================
  // 2. 导出为 Word (.doc) —— HTML Word 格式（兼容性极高）
  // ============================================================
  static async exportWord(context: common.Context, text: string): Promise<string> {
    const dir = context.filesDir;
    const filePath = `${dir}/moxi_${Date.now()}.doc`;
    // 转换 Markdown → Word HTML
    const htmlBody = ExportService.convertMarkdownToWordHtml(text);

    const htmlContent = `
      <html xmlns:o='urn:schemas-microsoft-com:office:office'
            xmlns:w='urn:schemas-microsoft-com:office:word'
            xmlns='http://www.w3.org/TR/REC-html40'>
      <head>
        <meta charset='utf-8'>
        <style>
          body {
            font-family: SimSun; /* 宋体 */
            font-size: 14pt;
            line-height: 1.6;
            margin: 2cm;
          }
          h1 { font-size: 24pt; margin: 24pt 0 12pt 0; }
          h2 { font-size: 20pt; margin: 20pt 0 10pt 0; }
          h3 { font-size: 16pt; margin: 16pt 0 8pt 0; }
          p  { margin: 8pt 0; }
          blockquote {
            border-left: 3px solid #999;
            padding-left: 10px;
            color: #555;
            margin: 8pt 0;
          }
          code {
            font-family: Consolas;
            background: #f2f2f2;
            padding: 2px 4px;
            border-radius: 4px;
          }
        </style>
      </head>
      <body>
        ${htmlBody}
      </body>
      </html>
    `;

    // 写入 .doc 文件
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    fs.writeSync(file.fd, htmlContent);
    fs.closeSync(file);

    return filePath;
  }

  // 3. 保存到系统文件管理（FilePicker）
  static async saveToFileManager(context: common.Context, srcPath: string): Promise<boolean> {
    const documentPicker = new picker.DocumentViewPicker(context);
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [srcPath.split('/').pop() ?? 'moxi_export.doc'];

    try {
      const uris = await documentPicker.save(saveOptions);
      if (uris.length === 0) return false;
      const uri = uris[0];

      const target = fs.openSync(uri, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      const src = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);

      const buf = new ArrayBuffer(4096);
      let len = 0;
      while ((len = fs.readSync(src.fd, buf)) > 0) {
        fs.writeSync(target.fd, buf.slice(0, len));
      }

      fs.closeSync(src);
      fs.closeSync(target);
      return true;
    } catch (err) {
      console.error('Save to file manager failed:', err);
      return false;
    }
  }

  // Markdown → Word HTML 转换器
  private static convertMarkdownToWordHtml(text: string): string {
    const lines = text.split('\n');
    const htmlLines: string[] = [];

    for (let raw of lines) {
      let line = raw.trim();

      if (line.startsWith('### ')) {
        htmlLines.push(`<h3>${ExportService.escape(line.substring(4))}</h3>`);
        continue;
      }
      if (line.startsWith('## ')) {
        htmlLines.push(`<h2>${ExportService.escape(line.substring(3))}</h2>`);
        continue;
      }
      if (line.startsWith('# ')) {
        htmlLines.push(`<h1>${ExportService.escape(line.substring(2))}</h1>`);
        continue;
      }

      if (line.startsWith('> ')) {
        htmlLines.push(`<blockquote>${ExportService.escape(line.substring(2))}</blockquote>`);
        continue;
      }

      line = line.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');

      line = line.replace(/\*(.*?)\*/g, '<i>$1</i>');

      line = line.replace(/`([^`]+)`/g, '<code>$1</code>');

      htmlLines.push(`<p>${ExportService.escape(line)}</p>`);
    }

    return htmlLines.join('\n');
  }

  // HTML 转义
  private static escape(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }
}

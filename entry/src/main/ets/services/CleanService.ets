import pasteboard from '@ohos.pasteboard';
import { common } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';

export interface HistoryItem {
  text: string;
  time: number;
}

export class CleanService {
  // ========== 1. 纯净模式（免费） ==========
  static cleanPure(text: string): string {
    if (!text) return '';
    return text
    // 1. 图片 ![alt](url) - 必须写在同一行
      .replace(/!\[.*?\]\(.*?\)/g, '')
      // 2. 链接 [text](url)
      .replace(/\[.*?\]\(.*?\)/g, '')
      // 3. 行内代码 `code` 和代码块 ``` ```
      .replace(/`{1,3}[\s\S]*?`{1,3}/g, '')
      // 4. 标题
      .replace(/^#{1,6}\s*/gm, '')
      // 5. 粗体/斜体
      .replace(/[*_]{1,3}/g, '')
      // 6. 引用
      .replace(/^>\s?/gm, '')
      // 7. 无序列表
      .replace(/^[-*+]\s+/gm, '')
      // 8. 有序列表
      .replace(/^\d+\.\s+/gm, '')
      // 9. 分割线
      .replace(/---+/g, '')
      // 10. 多余空行
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  // ========== 2. 语义模式（VIP） ==========
  static cleanSemantic(text: string): string {
    if (!text) return '';
    let result = text;
    // 标题 → 【标题】
    result = result.replace(/^#{1,6}\s*(.*)$/gm, '【$1】');
    // 粗体 → *重点*
    result = result.replace(/\*\*(.*?)\*\*/g, '*$1*');
    // 斜体 → _内容_
    result = result.replace(/\*(.*?)\*/g, '_$1_');
    // 引用 → 「引用」
    result = result.replace(/^>\s*(.*)$/gm, '「$1」');
    // 列表 → 保留结构
    result = result.replace(/^[-*+]\s+(.*)$/gm, '· $1');
    result = result.replace(/^\d+\.\s+(.*)$/gm, '• $1');
    // 去掉代码块
    result = result.replace(/```[\s\S]*?```/g, '');
    // 去掉多余空行
    result = result.replace(/\n{3,}/g, '\n\n');
    return result.trim();
  }

  // ========== 3. AI 清洗（预留接口） ==========
  static async cleanAI(text: string): Promise<string> {
    // 1. 检查输入
    if (!text.trim()) return '';
    // 2. 如果尚未上线，先进行本地模拟处理（方便 UI 调试）
    // 你可以暂时调用 cleanSemantic 作为 AI 的“本地模拟版”
    console.info('AI Clean requested for length:', text.length);
    try {
      // TODO: 等待阿里云 FC 服务部署完毕后，取消以下注释并替换 URL
      /*
      const httpRequest = http.createHttp();
      const response = await httpRequest.request('你的阿里云FC地址', {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { text: text }
      });
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        return result.cleaned;
      }
      */
      // 当前阶段：返回模拟结果（你可以先用 cleanSemantic 顶替）
      const semanticResult = CleanService.cleanSemantic(text);
      return semanticResult + "\n\n(AI 接口联调中...)";
    } catch (err) {
      console.error('AI Clean failed:', err);
      return text; // 失败时返回原文本，防止丢失内容
    }
  }

  // ========== 4. 自动空行（段落分隔） ==========
  static autoSpacing(text: string): string {
    return text
      .replace(/([^\n])\n([^\n])/g, '$1\n\n$2')
      .trim();
  }

  // ========== 5. 自动标题层级 ==========
  static normalizeHeading(text: string): string {
    return text.replace(/^#{4,6}/gm, '###'); // 统一为三级标题
  }

  // ========== 6. 去重空格 ==========
  static removeExtraSpaces(text: string): string {
    return text.replace(/ {2,}/g, ' ');
  }

  // ========== 7. 提取大纲（结构化） ==========
  static extractOutline(text: string): string[] {
    const lines = text.split('\n');
    const outline: string[] = [];

    lines.forEach(line => {
      const match = line.match(/^(#{1,6})\s*(.*)$/);
      if (match) {
        outline.push(match[2]);
      }
    });

    return outline;
  }

  // ========== 8. 复制到剪贴板 ==========
  static copy(text: string) {
    let systemPasteboard = pasteboard.getSystemPasteboard();
    let pasteData = pasteboard.createPlainTextData(text);
    systemPasteboard.setPasteData(pasteData);
  }

  // ========== 9. 历史记录（本地存储） ==========
  static async saveHistory(context: common.Context, text: string): Promise<void> {
    const pref = await dataPreferences.getPreferences(context, 'clean_history');
    const rawData = await pref.get('items', []) as Object;
    const allItems: HistoryItem[] = rawData as HistoryItem[];

    allItems.unshift({
      text: text,
      time: Date.now()
    });

    if (allItems.length > 20) {
      allItems.pop();
    }

    await pref.put('items', allItems);
    await pref.flush();
  }

  // ========== 10. 读取历史记录 ==========
  static async loadHistory(context: common.Context): Promise<HistoryItem[]> {
    try {
      const pref = await dataPreferences.getPreferences(context, 'clean_history');
      const result = await pref.get('items', []) as Object;
      return result as HistoryItem[];
    } catch (err) {
      console.error('Failed to load history:', err);
      return [];
    }
  }
}

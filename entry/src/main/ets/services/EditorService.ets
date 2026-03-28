export interface EditorResult {
  newText: string;
  newPos: number;
}

export interface RangeResult {
  start: number;
  end: number;
}

export class EditorService {
  // 1. 整句智能编辑（核心：自动识别引号或断句）
  static applySmartFormat(
    text: string,
    pos: number,
    type: string
  ): EditorResult{
    const range = EditorService.detectSentenceRange(text, pos);
    const start = range.start;
    const end = range.end;

    const targetText = text.substring(start, end).trim();
    if (!targetText && type !== 'h') return { newText: text, newPos: pos };

    let transformed = targetText;

    switch (type) {
      case 'bold':
        transformed = EditorService.toggleWrap(targetText, '**');
        break;
      case 'italic':
        transformed = EditorService.toggleWrap(targetText, '*');
        break;
      case 'strike':
        transformed = EditorService.toggleWrap(targetText, '~~');
        break;
      case 'inlineCode':
        transformed = EditorService.toggleWrap(targetText, '`');
        break;
      case 'h':
        transformed = EditorService.toggleHeading(targetText);
        break;
      case 'quote':
        transformed = targetText.startsWith('> ')
          ? targetText.substring(2)
          : `> ${targetText}`;
        break;
      case 'list':
        transformed = targetText.startsWith('- ')
          ? targetText.substring(2)
          : `- ${targetText}`;
        break;
      case 'olist':
        transformed = targetText.match(/^\d+\. /)
          ? targetText.replace(/^\d+\. /, '')
          : `1. ${targetText}`;
        break;
      case 'divider':
        transformed = '---';
        break;
      case 'clear':
        transformed = EditorService.clearMarkdown(targetText);
        break;
    }

    const newText = text.substring(0, start) + transformed + text.substring(end);
    const newPos = start + transformed.length;
    return { newText, newPos };
  }

  static detectSentenceRange(text: string, pos: number): RangeResult {
    const pairRegex = /[“"‘'《]([^“”"‘’》]*)[”"’'》]/g;
    let match: RegExpExecArray | null;
    let rangeStart = 0;
    let rangeEnd = text.length;
    let isInsideQuote = false;

    while ((match = pairRegex.exec(text)) !== null) {
      const matchStart = match.index;
      const matchEnd = match.index + match[0].length;
      if (pos >= matchStart && pos <= matchEnd) {
        rangeStart = matchStart + 1;
        rangeEnd = matchEnd - 1;
        isInsideQuote = true;
        break;
      }
    }

    if (!isInsideQuote) {
      const sentenceBreaks = /[。！？；\n.!?;]/g;
      const allBreaks = Array.from(text.matchAll(sentenceBreaks)).map(m => m.index ?? 0);

      const prevBreaks = allBreaks.filter(i => i < pos);
      rangeStart = prevBreaks.length > 0 ? prevBreaks[prevBreaks.length - 1] + 1 : 0;

      const nextBreaks = allBreaks.filter(i => i >= pos);
      rangeEnd = nextBreaks.length > 0 ? nextBreaks[0] : text.length;
    }

    return { start: rangeStart, end: rangeEnd };
  }

  // 2. 插入类（光标处插入）
  static insertAt(
    text: string,
    pos: number,
    type: string
  ): EditorResult {
    let insertText = '';

    switch (type) {
      case 'image':
        insertText = '![描述](https://)';
        break;
      case 'link':
        insertText = '[链接文本](https://)';
        break;
      case 'table':
        insertText = '\n\n| 列1 | 列2 |\n| --- | --- |\n| 内容 | 内容 |\n\n';
        break;
      case 'codeBlock':
        insertText = '\n```lang\n代码内容\n```\n';
        break;
      case 'date':
        const d = new Date();
        insertText = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
        break;
      case 'time':
        const t = new Date();
        insertText = `${t.getHours().toString().padStart(2, '0')}:${t.getMinutes().toString().padStart(2, '0')}`;
        break;
    }

    const newText = text.substring(0, pos) + insertText + text.substring(pos);
    const newPos = pos + insertText.length;
    return { newText, newPos };
  }

  // 3. 文本处理（自动排版）
  static autoSpacing(text: string): string {
    return text.replace(/([^\n])\n([^\n])/g, '$1\n\n$2');
  }

  static normalizeHeading(text: string): string {
    return text.replace(/^(#+)([^#\s])/gm, '$1 $2');
  }

  static removeExtraSpaces(text: string): string {
    return text.replace(/ {2,}/g, ' ');
  }

  static clearMarkdown(text: string): string {
    return text
      .replace(/^#+\s*/gm, '')
      .replace(/^>\s*/gm, '')
      .replace(/^[-*+]\s+/gm, '')
      .replace(/^\d+\.\s+/gm, '')
      .replace(/\*\*([\s\S]*?)\*\*/g, '$1')
      .replace(/~~([\s\S]*?)~~/g, '$1')
      .replace(/`([\s\S]*?)`/g, '$1')
      .replace(/!\[.*?\]\(.*?\)/g, '')
      .replace(/\[(.*?)\]\(.*?\)/g, '$1');
  }

  static autoFormat(text: string): string {
    let t = text;
    t = EditorService.autoSpacing(t);
    t = EditorService.normalizeHeading(t);
    t = EditorService.removeExtraSpaces(t);
    return t;
  }

  // 4. Markdown → HTML（观止模式渲染）
  static mdToHtml(md: string): string {
    let html = md;

    html = html.replace(/^### (.*)$/gm, '<h3 style="color:#A5A07B;">$1</h3>');
    html = html.replace(/^## (.*)$/gm, '<h2 style="color:#A5A07B;">$1</h2>');
    html = html.replace(/^# (.*)$/gm, '<h1 style="color:#2B333E; border-bottom:1px solid #eee; padding-bottom:5px;">$1</h1>');

    html = html.replace(/^> (.*)$/gm, '<blockquote style="border-left:4px solid #A5A07B; padding-left:15px; color:#666; background:#F9F9F9; margin:10px 0;">$1</blockquote>');

    html = html.replace(/^---$/gm, '<hr style="border:none; border-top:1px double #A5A07B; margin:20px 0;" />');

    html = html.replace(/^\s*[-*+]\s+(.*)$/gm, '<ul><li style="list-style:disc;">$1</li></ul>');
    html = html.replace(/^\s*\d+\.\s+(.*)$/gm, '<ol><li>$1</li></ol>');
    html = html.replace(/<\/ul>\s*<ul>/g, '');
    html = html.replace(/<\/ol>\s*<ol>/g, '');

    html = html.replace(/!\[(.*?)\]\((.*?)\)/g, '<img alt="$1" src="$2" style="max-width:100%; border-radius:4px;" />');
    html = html.replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" style="color:#A5A07B;">$1</a>');

    html = html.replace(/\*\*([\s\S]*?)\*\*/g, '<b>$1</b>');
    html = html.replace(/~~([\s\S]*?)~~/g, '<del>$1</del>');
    html = html.replace(/`([\s\S]*?)`/g, '<code style="background:#f0f0f0; padding:2px 4px; border-radius:3px;">$1</code>');

    html = html.replace(/\n/g, '<br>');

    html = html.replace(/[“《”》]/g, '<span style="color:#A5A07B; font-weight:bold;">$&</span>');

    return `
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            background-color: #FDFCF5;  /* ⭐ 改成米黄色，而不是 transparent */
            -webkit-text-size-adjust: none;
            overflow: hidden !important;
            height: auto !important;
          }
          .moxi-render-container {
            zoom: 1.6;
            line-height: 1.7;
            font-size: 35px !important;
            color: #333333;
            padding: 20px;
            word-wrap: break-word;
            height: auto !important;
            overflow: hidden !important;
          }
          .moxi-render-container * { font-size: 35px !important; }
          h1 { font-size: 50px !important; font-weight: bold; margin-bottom: 15px; }
          blockquote { border-left: 8px solid #A5A07B; padding-left: 20px; color: #666; }
        </style>
      </head>
      <body>
        <div class="moxi-render-container">
          ${html}
        </div>
      </body>
    </html>
  `;
  }

  // 5. 工具内部函数
  private static toggleWrap(text: string, wrap: string): string {
    const escaped = wrap.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`^${escaped}([\\s\\S]*)${escaped}$`);

    if (regex.test(text)) {
      return text.replace(regex, '$1');
    }
    return `${wrap}${text}${wrap}`;
  }

  private static toggleHeading(text: string): string {
    const target = text.trim();
    if (target.startsWith('### ')) return target.substring(4);
    if (target.startsWith('## ')) return '### ' + target.substring(3);
    if (target.startsWith('# ')) return '## ' + target.substring(2);
    return '# ' + target;
  }
}
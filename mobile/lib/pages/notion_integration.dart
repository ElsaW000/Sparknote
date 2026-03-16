import 'dart:html' as html;

import 'package:flutter/material.dart';

enum _DocService { notion, obsidian, logseq }

typedef _DocLink = ({String label, String description, String url});

typedef _ServiceDoc = ({
  String title,
  String subtitle,
  String group,
  List<String> prerequisites,
  List<String> steps,
  List<_DocLink> links,
  String note,
});

class NotionIntegrationPage extends StatefulWidget {
  const NotionIntegrationPage({super.key});

  @override
  State<NotionIntegrationPage> createState() => _NotionIntegrationPageState();
}

class _NotionIntegrationPageState extends State<NotionIntegrationPage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFF4F7F4);
  static const Color _line = Color(0xFFDDE7DA);
  static const Color _muted = Color(0xFF60716F);
  static const Color _ink = Color(0xFF22302C);
  static const double _h1Size = 24;
  static const double _sectionTitleSize = 16;
  static const double _bodySize = 14;
  static const double _bodyHeight = 1.6;

  _DocService _selectedService = _DocService.notion;

  static const Map<_DocService, _ServiceDoc> _docs = {
    _DocService.notion: (
      title: 'Notion API 接入文档',
      subtitle: '适合先完成官方 Integration、Database 和授权准备，再回到设置页填写配置。',
      group: '笔记软件',
      prerequisites: [
        '先在设置页准备好账号资料和职业标签，避免协作上下文缺失。',
        '确认你需要的是 Notion Integration Token 与目标 Database ID。',
        '真正的配置填写入口在“设置 -> API”，这里负责文档说明和官方链接。',
      ],
      steps: [
        '1. 打开 Notion 的 My integrations 页面，创建或选择一个 Integration。',
        '2. 在 Integration 的 Secrets 区域复制 Internal Integration Token。',
        '3. 打开目标 Database 页面，从浏览器地址栏复制 Database ID。',
        '4. 在 Notion 数据库页面点击 Share，把 Integration 加入协作名单。',
        '5. 回到 Sparknote 的“设置 -> API”区，把 Token 和 Database ID 保存进去。',
      ],
      links: [
        (
          label: 'Notion My integrations',
          description: '创建或管理 Integration，获取 Internal Integration Token。',
          url: 'https://www.notion.so/profile/integrations',
        ),
        (
          label: 'Create your first integration',
          description: 'Notion 官方快速开始，适合第一次接入时按步骤走。',
          url: 'https://developers.notion.com/docs/create-a-notion-integration',
        ),
        (
          label: 'Working with databases',
          description: '了解 Database ID、数据库对象和常见操作。',
          url: 'https://developers.notion.com/docs/working-with-databases',
        ),
        (
          label: 'Authorization',
          description: '查看授权模型和接入限制，避免权限配置错误。',
          url: 'https://developers.notion.com/docs/authorization',
        ),
      ],
      note: '这页现在是“操作文档中心”，负责告诉用户怎么准备材料、去哪里找官方说明、按什么步骤完成接入。真正的 Token / Database ID 配置入口已经统一收进设置页。',
    ),
    _DocService.obsidian: (
      title: 'Obsidian 接入文档',
      subtitle: '为本地知识库导入、同步或插件桥接预留的说明位，当前先保留扩展结构。',
      group: '笔记软件',
      prerequisites: [
        '确认你的 Obsidian Vault 是否已经稳定使用，并明确是否需要只读导入、双向同步或模板生成。',
        '如果未来要做插件桥接，需要先确定是桌面插件模式还是导出文件模式。',
        '当前 Sparknote 还没有正式开放 Obsidian 配置项，这里先保留文档结构。',
      ],
      steps: [
        '1. 明确你要同步的是 Markdown 文件、元数据还是附件。',
        '2. 确认 Vault 的目录组织方式，避免后续映射混乱。',
        '3. 等 Sparknote 开放对应配置入口后，再在设置页补接入参数。',
      ],
      links: [
        (
          label: 'Obsidian Help',
          description: 'Obsidian 官方帮助中心，适合查看 Vault、插件与同步基础概念。',
          url: 'https://help.obsidian.md/',
        ),
      ],
      note: 'Obsidian 目前还是后续规划项，这里先采用和 Notion 相同的文档中心结构，保证将来扩展时不需要重做页面骨架。',
    ),
    _DocService.logseq: (
      title: 'Logseq 接入文档',
      subtitle: '为块级笔记、日记流和 Graph 数据接入预留的说明位，当前先建立知识库结构。',
      group: '笔记软件',
      prerequisites: [
        '确认你的 Logseq Graph 是否已经稳定使用，并梳理页面、块、日记这三类核心对象。',
        '如果未来要做双向同步，需要先定义块级引用和页面链接的映射方式。',
        '当前 Sparknote 还没有正式开放 Logseq 配置项，这里先保留文档结构。',
      ],
      steps: [
        '1. 明确要接入的是页面、日记还是块级引用。',
        '2. 确认 Graph 文件结构和附件目录组织方式。',
        '3. 等 Sparknote 开放对应配置入口后，再在设置页补参数。',
      ],
      links: [
        (
          label: 'Logseq Docs',
          description: 'Logseq 官方文档入口，适合了解 Graph、日记流和页面结构。',
          url: 'https://docs.logseq.com/',
        ),
      ],
      note: 'Logseq 目前同样还是规划项，但文档中心已经支持秒级切换不同平台，后续只需要补内容即可。',
    ),
  };

  void _openExternalLink(String url) {
    html.window.open(url, '_blank');
  }

  Widget _buildServiceItem({
    required _DocService service,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedService == service;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedService = service),
        borderRadius: BorderRadius.circular(24),
        hoverColor: _brand.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _brandDark : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? _brandDark : _line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.14) : _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : _brandDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _bodySize,
                        height: _bodyHeight,
                        color: selected ? Colors.white70 : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined, color: _brandDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '文档中心',
                      style: TextStyle(
                        fontSize: _sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '接入指南会按平台沉淀在这里，后续可以继续扩展更多服务。',
                      style: TextStyle(fontSize: _bodySize, color: Color(0xFF666666), height: _bodyHeight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '笔记软件',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          _buildServiceItem(
            service: _DocService.notion,
            title: 'Notion',
            subtitle: 'Integration / Database / 授权',
            icon: Icons.api_outlined,
          ),
          _buildServiceItem(
            service: _DocService.obsidian,
            title: 'Obsidian',
            subtitle: 'Vault / Markdown / 插件桥接',
            icon: Icons.auto_stories_outlined,
          ),
          _buildServiceItem(
            service: _DocService.logseq,
            title: 'Logseq',
            subtitle: 'Graph / 日记流 / 页面映射',
            icon: Icons.account_tree_outlined,
          ),
        ],
      ),
    );
  }

  Widget _docCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: _sectionTitleSize,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildContent() {
    final doc = _docs[_selectedService]!;
    return Container(
      key: ValueKey(_selectedService.name),
      constraints: const BoxConstraints(maxWidth: 820),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x100E1A13),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '接入文档 > ${doc.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: _h1Size,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  doc.subtitle,
                  style: const TextStyle(fontSize: _bodySize, color: Color(0xFF666666), height: _bodyHeight),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/settings'),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('去设置页填写配置'),
                    ),
                    if (doc.links.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _openExternalLink(doc.links.first.url),
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('打开官方文档'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _docCard(
            title: '接入前准备',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: doc.prerequisites
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: _bodySize,
                          color: Color(0xFF666666),
                          height: _bodyHeight,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          _docCard(
            title: '操作步骤',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: doc.steps
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: _bodySize,
                          color: Color(0xFF666666),
                          height: _bodyHeight,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          _docCard(
            title: '官方文档链接',
            child: Column(
              children: doc.links
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _openExternalLink(item.url),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAF7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.open_in_new_outlined, size: 16, color: _brandDark),
                                  SizedBox(width: 8),
                                  Text(
                                    '官方链接',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _brandDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: _sectionTitleSize,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: _bodySize,
                                  color: Color(0xFF666666),
                                  height: _bodyHeight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.url,
                                style: const TextStyle(
                                  fontSize: _bodySize,
                                  color: Color(0xFF666666),
                                  height: _bodyHeight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          _docCard(
            title: '页面说明',
            child: Text(
              doc.note,
              style: const TextStyle(fontSize: _bodySize, color: Color(0xFF666666), height: _bodyHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(),
              const SizedBox(width: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildSidebar(),
          const SizedBox(height: 18),
          _buildContent(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('API文档'),
      ),
      body: SelectionArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 980) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }
}

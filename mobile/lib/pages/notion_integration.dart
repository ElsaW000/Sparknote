import 'dart:html' as html;

import 'package:flutter/material.dart';

class NotionIntegrationPage extends StatelessWidget {
  const NotionIntegrationPage({super.key});

  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFF3F7F1);
  static const Color _line = Color(0xFFDDE7DA);
  static const Color _muted = Color(0xFF60716F);
  static const Color _ink = Color(0xFF22302C);

  void _openExternalLink(String url) {
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('API连接文档'),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DocHero(onTapLink: _openExternalLink),
                  const SizedBox(height: 20),
                  const _DocSection(
                    title: '接入前准备',
                    items: [
                      '先在设置页准备好你的账号资料和职业标签，避免后续协作场景中信息缺失。',
                      '确定你要接入的是 Notion Integration Token 与目标 Database ID。',
                      '如果只是看文档，不需要在这里填写配置；真正的接口配置已经移动到“设置”页。',
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _DocSection(
                    title: '操作步骤',
                    items: [
                      '1. 打开 Notion 的 My integrations 页面，创建或选择一个 Integration。',
                      '2. 在 Integration 的 Secrets 区域复制 Internal Integration Token。',
                      '3. 打开你的目标 Database 页面，从浏览器地址栏复制 Database ID。',
                      '4. 在 Notion 数据库页面点击 Share，把 Integration 加入协作名单。',
                      '5. 回到 Sparknote 的“设置 -> API”区，把 Token 和 Database ID 保存进去。',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LinksSection(onTapLink: _openExternalLink),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _line),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '页面说明',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '这页现在是“操作文档”，负责告诉用户怎么准备材料、去哪里找官方说明、按什么步骤完成接入。真正的 Token / Database ID 配置入口已经统一收进设置页，避免“文档页”和“配置页”混在一起。',
                          style: TextStyle(fontSize: 14, color: _muted, height: 1.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocHero extends StatelessWidget {
  final void Function(String url) onTapLink;

  const _DocHero({required this.onTapLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: NotionIntegrationPage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: NotionIntegrationPage._brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_outlined, color: NotionIntegrationPage._brandDark),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notion API 接入文档',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: NotionIntegrationPage._ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '参考云厂商文档页的阅读方式，把准备项、步骤和官方链接清楚地放在一页里。',
                      style: TextStyle(fontSize: 14, color: NotionIntegrationPage._muted, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('去设置页填写配置'),
              ),
              FilledButton.icon(
                onPressed: () => onTapLink('https://developers.notion.com/docs/create-a-notion-integration'),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('打开官方快速开始'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DocSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NotionIntegrationPage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NotionIntegrationPage._ink,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: NotionIntegrationPage._muted,
                  height: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinksSection extends StatelessWidget {
  final void Function(String url) onTapLink;

  const _LinksSection({required this.onTapLink});

  @override
  Widget build(BuildContext context) {
    const links = [
      (
        'Notion My integrations',
        '创建或管理 Integration，获取 Internal Integration Token。',
        'https://www.notion.so/profile/integrations'
      ),
      (
        'Create your first integration',
        'Notion 官方快速开始，适合第一次接入时按步骤走。',
        'https://developers.notion.com/docs/create-a-notion-integration'
      ),
      (
        'Working with databases',
        '了解 Database ID、数据库对象和常见操作。',
        'https://developers.notion.com/docs/working-with-databases'
      ),
      (
        'Authorization',
        '查看授权模型和接入限制，避免权限配置错误。',
        'https://developers.notion.com/docs/authorization'
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NotionIntegrationPage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '官方文档链接',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NotionIntegrationPage._ink,
            ),
          ),
          const SizedBox(height: 14),
          ...links.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onTapLink(item.$3),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: NotionIntegrationPage._line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.open_in_new_outlined, size: 16, color: NotionIntegrationPage._brandDark),
                          SizedBox(width: 8),
                          Text(
                            '官方链接',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: NotionIntegrationPage._brandDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: NotionIntegrationPage._ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          color: NotionIntegrationPage._muted,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NotionIntegrationPage._muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

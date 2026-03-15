import 'dart:ui';

import 'package:flutter/material.dart';

const Color _sceneBg = Color(0xFF1A3C34);
const Color _sceneBgSoft = Color(0xFF21473E);
const Color _sceneBrand = Color(0xFF2D6A4F);
const Color _sceneMint = Color(0xFFD8E2DC);
const Color _sceneText = Color(0xFFFFFFFF);

class ImmersionScenePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<String> tags;
  final IconData heroIcon;

  const ImmersionScenePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.heroIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_sceneBg, _sceneBgSoft, _sceneBrand],
          ),
        ),
        child: Stack(
          children: [
            const _SceneGlow(top: 40, right: -20, size: 220),
            const _SceneGlow(bottom: 120, left: -40, size: 260),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1100;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _sceneText,
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.arrow_back, size: 22),
                          label: const Text('\u8fd4\u56de\u767b\u5f55/\u6ce8\u518c'),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: wide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildCopyBlock()),
                                    const SizedBox(width: 28),
                                    Expanded(child: _buildVisualCard()),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCopyBlock(),
                                    const SizedBox(height: 24),
                                    Expanded(child: _buildVisualCard()),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 280,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _sceneBrand,
                                foregroundColor: _sceneText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                '\u8fdb\u5165\u6ce8\u518c',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _sceneText,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          subtitle,
          style: const TextStyle(
            color: _sceneMint,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          description,
          style: const TextStyle(
            color: _sceneText,
            fontSize: 16,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tags
              .map(
                (tag) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: _sceneText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildVisualCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _VisualPane(
                        icon: heroIcon,
                        title: '\u6355\u6349\u788e\u7247\u7075\u611f',
                        body:
                            '\u5feb\u901f\u628a\u8111\u6d77\u91cc\u4e00\u95ea\u800c\u8fc7\u7684\u7ebf\u7d22\u6536\u8fdb\u53bb\uff0c\u4e0d\u6253\u65ad\u5f53\u4e0b\u7684\u8282\u594f\u3002',
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _VisualPane(
                        icon: Icons.auto_awesome,
                        title: 'AI \u53c2\u4e0e\u63d0\u70bc',
                        body:
                            '\u628a\u96f6\u6563\u8bb0\u5f55\u805a\u5408\u6210\u7ed3\u6784\u5316\u65b9\u5411\u3001\u63d0\u7eb2\u548c\u53ef\u7ee7\u7eed\u63a8\u8fdb\u7684\u8349\u7a3f\u3002',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_forward, color: _sceneMint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '\u4ece\u788e\u7247\u7075\u611f\u5230\u7ed3\u6784\u5316\u4f5c\u54c1\uff0c\u4e0d\u518d\u662f\u65ad\u88c2\u7684\u4e24\u6b65\uff0c\u800c\u662f\u4e00\u6761\u8fde\u7eed\u7684\u521b\u4f5c\u94fe\u8def\u3002',
                        style: TextStyle(
                          color: _sceneText,
                          fontSize: 15,
                          height: 1.7,
                        ),
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
}

class _SceneGlow extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;

  const _SceneGlow({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _sceneMint.withValues(alpha: 0.55),
                _sceneBrand.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisualPane extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _VisualPane({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: _sceneText, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _sceneText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: _sceneMint,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

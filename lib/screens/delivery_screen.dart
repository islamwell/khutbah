import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class DeliveryScreen extends StatefulWidget {
  final String title;
  final String content;
  final int estimatedMinutes;

  const DeliveryScreen({
    super.key,
    required this.title,
    required this.content,
    required this.estimatedMinutes,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final ScrollController _scrollController = ScrollController();
  late Timer _autoScrollTimer;
  
  bool _isPlaying = false;
  bool _isFullscreen = false;
  double _scrollSpeed = 1.0; // multiplier (0.1x to 2.0x)
  double _fontSize = 24.0;
  double _progress = 0.0;
  
  static const double _baseScrollSpeed = 0.8; // base pixels per frame (very slow for 2 words/sec)

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _scrollController.addListener(_updateProgress);
    
    // Keep screen on during delivery
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _scrollController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _initializeTimer() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isPlaying && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        
        if (currentScroll < maxScroll) {
          final scrollIncrement = _baseScrollSpeed * _scrollSpeed;
          _scrollController.jumpTo(
            (currentScroll + scrollIncrement).clamp(0.0, maxScroll),
          );
        } else {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  void _updateProgress() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      setState(() {
        _progress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _resetScroll() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _isPlaying = false;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
          overlays: [SystemUiOverlay.top]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : _buildAppBar(),
      body: GestureDetector(
        onTap: _isFullscreen ? _togglePlayPause : null,
        child: Stack(
          children: [
            _buildContent(),
            if (!_isFullscreen) _buildControls(),
            _buildProgressBar(),
            if (_isFullscreen) _buildFullscreenControls(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          onPressed: _toggleFullscreen,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildContent() {
    final lines = _prepareContentForDisplay();
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        32,
        _isFullscreen ? 12 : 20,
        32,
        _isFullscreen ? 80 : 80,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) => _buildContentLine(line)).toList(),
        ),
      ),
    );
  }

  List<String> _prepareContentForDisplay() {
    // Split content into lines and process for display
    final lines = widget.content.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        processedLines.add(''); // Keep empty lines for spacing
      } else if (trimmedLine.startsWith('---')) {
        processedLines.add('═══ JALSAH ═══'); // Visual separator
      } else {
        processedLines.add(trimmedLine);
      }
    }
    
    return processedLines;
  }

  Widget _buildContentLine(String line) {
    if (line.isEmpty) {
      return const SizedBox(height: 24);
    }
    
    if (line == '═══ JALSAH ═══') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            line,
            style: TextStyle(
              color: Colors.amber,
              fontSize: _fontSize * 0.8,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
    
    // Check if line is Arabic (contains Arabic characters)
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(line);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Text(
        line,
        style: TextStyle(
          color: Colors.white,
          fontSize: _fontSize,
          height: 1.6,
          fontWeight: isArabic ? FontWeight.w500 : FontWeight.normal,
        ),
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              color: Colors.white,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _scrollSpeed,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          onChanged: (value) {
                            setState(() {
                              _scrollSpeed = (value * 10).round() / 10;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_scrollSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14.0,
                          max: 128.0,
                          divisions: 28,
                          onChanged: (value) {
                            setState(() {
                              _fontSize = ((value / 4).round() * 4).toDouble();
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_fontSize.toInt()}pt',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: _isFullscreen ? 0 : kToolbarHeight,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        color: Colors.white.withValues(alpha: 0.2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _progress,
          child: Container(color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _isPlaying ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                  color: Colors.white,
                  iconSize: 28,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: _toggleFullscreen,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
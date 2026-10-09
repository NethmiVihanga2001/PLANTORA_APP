import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/plant_model.dart';
import '../models/chat_message.dart';
import '../services/assistant_service.dart';
import '../services/database_service.dart';
import 'plant_detail_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class PlantResultScreen extends StatefulWidget {
  final PlantModel plant;
  final String imagePath;
  final double confidence;
  final List<PlantModel> alternatives;

  PlantResultScreen({
    super.key,
    required this.plant,
    required this.imagePath,
    required this.confidence,
    required this.alternatives,
  });

  @override
  State<PlantResultScreen> createState() => _PlantResultScreenState();
}

class _PlantResultScreenState extends State<PlantResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final AssistantService _chatbotService = AssistantService();
  final DatabaseService _dbService = DatabaseService();
  bool _isTyping = false;
  bool _isFavorite = false;
  final _uuid = const Uuid();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIsFavorite();
    // Add initial AI message
    _messages.add(
      ChatMessage(
        text: "Hi! I'm your Plantora Assistant. I see you just scanned a ${widget.plant.name}. What would you like to know about it?",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      )
    );
  }

  Future<void> _checkIsFavorite() async {
    final fav = await _dbService.isFavorite(widget.plant.id);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _toggleFavorite() async {
    await _dbService.toggleFavorite(widget.plant);
    final fav = await _dbService.isFavorite(widget.plant.id);
    if (mounted) {
      setState(() => _isFavorite = fav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Added to favorites! ❤️' : 'Removed from favorites'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMsg = text.trim();
    _chatController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMsg,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Get real AI response from service
    try {
      final responseText = await _chatbotService.sendMessage(_messages);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: responseText,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'I am having trouble connecting to my database. Please try again.',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.headerGradient[0],
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.iconColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: _isFavorite ? Colors.amber : context.iconColor,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: Icon(Icons.share, color: context.iconColor),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or emoji
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.cardGradient,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          Text(plant.emoji,
                                  style: TextStyle(fontSize: 100))
                              .animate()
                              .scale(duration: 500.ms),
                        ],
                      ),
                    ),
                  ),
                  // Confidence badge
                  Positioned(
                    top: 80,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: AppColors.primaryGreen, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${(widget.confidence * 100).toInt()}% match',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: context.cardBg,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name and category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge!
                                    .copyWith(color: context.textPrimary)),
                            Text(plant.scientificName,
                                style: TextStyle(
                                    color: context.textSecondary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14)),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: plant.tags
                                  .take(3)
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.textPrimary.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(tag,
                                            style: TextStyle(
                                                color: context.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Text(plant.description,
                      style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                          height: 1.6)),

                  SizedBox(height: 20),

                  // Quick care stats
                  Row(
                    children: [
                      _buildStatCard('💧', 'Watering', plant.careInfo.wateringFrequency.split('(')[0].trim()),
                      SizedBox(width: 8),
                      _buildStatCard('☀️', 'Light', plant.careInfo.sunlightRequirement.split('(')[0].trim()),
                      SizedBox(width: 8),
                      _buildStatCard('⭐', 'Difficulty', plant.careInfo.difficulty),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: context.textPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: context.textPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: context.cardBg,
                      unselectedLabelColor: context.textSecondary,
                      tabs: const [
                        Tab(text: 'Care Guide'),
                        Tab(text: 'Diseases'),
                        Tab(text: 'Uses'),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCareTab(plant.careInfo),
                        _buildListTab(plant.diseases, Icons.bug_report_outlined,
                            AppColors.error),
                        _buildListTab(plant.uses, Icons.eco_outlined,
                            AppColors.primaryGreen),
                      ],
                    ),
                  ),

                  // Action buttons
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PlantDetailScreen(plant: plant)));
                          },
                          icon: Icon(Icons.info_outline),
                          label: Text('Full Details'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/market'),
                          icon: Icon(Icons.storefront_outlined),
                          label: Text('Find in Market'),
                        ),
                      ),
                    ],
                  ),

                  // Alternatives
                  if (widget.alternatives.isNotEmpty) ...[
                    SizedBox(height: 28),
                    Text('Might also be...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.alternatives.length,
                        itemBuilder: (ctx, i) {
                          final alt = widget.alternatives[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PlantDetailScreen(plant: alt)));
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: context.textPrimary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(alt.emoji,
                                      style: TextStyle(fontSize: 36)),
                                  SizedBox(height: 6),
                                  Text(alt.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkGrey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Chat Messages Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (_isTyping == true && i == _messages.length) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: _messages[i]);
                },
                childCount: _messages.length + (_isTyping ? 1 : 0),
              ),
            ),
          ),
          
          ],
        ),
      ),
    ],
  ),
  bottomNavigationBar: _buildChatInput(),
);
}

  Widget _buildStatCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: context.textSecondary, fontSize: 10)),
            SizedBox(height: 2),
            Text(value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTab(CareInfo care) {
    final rows = [
      ['💧', 'Watering', care.wateringFrequency],
      ['☀️', 'Sunlight', care.sunlightRequirement],
      ['🌱', 'Soil', care.soilType],
      ['🌡️', 'Temperature', care.temperature],
      ['💦', 'Humidity', care.humidity],
      ['🌿', 'Fertilizer', care.fertilizer],
      ['✂️', 'Pruning', care.pruning],
    ];

    return SingleChildScrollView(
      child: Column(
        children: rows
            .map((row) => _buildCareRow(row[0], row[1], row[2]))
            .toList(),
      ),
    );
  }

  Widget _buildCareRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(color: context.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(List<String> items, IconData icon, Color color) {
    return SingleChildScrollView(
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(item,
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      color: context.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Ask about this herb...',
                hintStyle: TextStyle(color: context.textSecondary),
                fillColor: context.textPrimary.withOpacity(0.05),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
              maxLines: null,
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_chatController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

}

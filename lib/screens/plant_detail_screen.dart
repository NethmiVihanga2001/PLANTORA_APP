import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/plant_model.dart';
import '../services/database_service.dart';
import '../data/herbal_market_data.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkIsSaved();
  }

  Future<void> _checkIsSaved() async {
    final saved = await _dbService.isFavorite(widget.plant.id);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: context.headerGradient[0],
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.iconColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? Colors.amber : context.iconColor,
                ),
                onPressed: () async {
                  await _dbService.toggleFavorite(plant);
                  final newState = await _dbService.isFavorite(plant.id);
                  if (mounted) {
                    setState(() => _isSaved = newState);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            _isSaved ? 'Saved to favorites! ❤️' : 'Removed from favorites'),
                        backgroundColor: AppColors.primaryGreen,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                plant.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    HerbalMarketData.getInfo(plant.id, plant.name).imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                      child: Center(
                        child: Text(plant.emoji, style: const TextStyle(fontSize: 90)),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Info bar
                Container(
                  color: context.cardBg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant.scientificName,
                                style: TextStyle(
                                    color: context.textSecondary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13)),
                            Text('Family: ${plant.family}',
                                style: TextStyle(
                                    color: context.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.textPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plant.category.toUpperCase(),
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  color: context.cardBg,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: context.textPrimary,
                    unselectedLabelColor: context.textSecondary,
                    indicatorColor: context.textPrimary,
                    tabs: const [
                      Tab(text: 'Overview', icon: Icon(Icons.info_outline, size: 16)),
                      Tab(text: 'Care', icon: Icon(Icons.water_drop_outlined, size: 16)),
                      Tab(text: 'Diseases', icon: Icon(Icons.bug_report_outlined, size: 16)),
                      Tab(text: 'Uses', icon: Icon(Icons.eco_outlined, size: 16)),
                    ],
                  ),
                ),

                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(plant),
                      _buildCareTab(plant.careInfo),
                      _buildDiseasesTab(plant.diseases),
                      _buildUsesTab(plant.uses),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/market'),
          icon: Icon(Icons.storefront_outlined),
          label: Text('Find in Marketplace'),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(PlantModel plant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          SizedBox(height: 10),
          Text(plant.description,
              style: TextStyle(
                  color: context.textSecondary, fontSize: 14, height: 1.7)),
          SizedBox(height: 20),
          Text('Also Known As',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plant.commonNames
                .map((name) => Chip(
                      label: Text(name),
                      backgroundColor: context.textPrimary.withOpacity(0.08),
                      labelStyle: TextStyle(
                          color: context.textPrimary, fontSize: 13),
                    ))
                .toList(),
          ),
          SizedBox(height: 20),
          Text('Tags',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plant.tags
                .map((tag) => Chip(
                      label: Text('#$tag'),
                      backgroundColor: context.textPrimary.withOpacity(0.05),
                      labelStyle: TextStyle(
                          color: context.textSecondary, fontSize: 12),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTab(CareInfo care) {
    final items = [
      {'emoji': '💧', 'title': 'Watering', 'value': care.wateringFrequency},
      {'emoji': '☀️', 'title': 'Sunlight', 'value': care.sunlightRequirement},
      {'emoji': '🌱', 'title': 'Soil Type', 'value': care.soilType},
      {'emoji': '🌡️', 'title': 'Temperature', 'value': care.temperature},
      {'emoji': '💦', 'title': 'Humidity', 'value': care.humidity},
      {'emoji': '🌿', 'title': 'Fertilizer', 'value': care.fertilizer},
      {'emoji': '✂️', 'title': 'Pruning', 'value': care.pruning},
      {'emoji': '🔁', 'title': 'Propagation', 'value': care.propagation},
      {'emoji': '📈', 'title': 'Growth Rate', 'value': care.growthRate},
      {'emoji': '⭐', 'title': 'Difficulty', 'value': care.difficulty},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    Text(item['emoji']!, style: TextStyle(fontSize: 24)),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: context.textSecondary)),
                        Text(item['value']!,
                            style: TextStyle(
                                fontSize: 14, color: context.textPrimary)),
                      ],
                    ),
                  ],
                ),
              )),
          SizedBox(height: 12),
          if (care.tips.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.textPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Expert Tips',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                  SizedBox(height: 8),
                  ...care.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ',
                                style: TextStyle(color: context.textPrimary)),
                            Expanded(
                              child: Text(tip,
                                  style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDiseasesTab(List<String> diseases) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Regular monitoring can prevent most plant diseases. Contact with diseased plants should be avoided.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ...diseases.asMap().entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bug_report_outlined,
                          color: AppColors.error, size: 18),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(entry.value,
                          style: TextStyle(
                              color: context.textSecondary, fontSize: 14)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUsesTab(List<String> uses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: uses.asMap().entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_outlined,
                        color: AppColors.primaryGreen, size: 18),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(entry.value,
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 14)),
                  ),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

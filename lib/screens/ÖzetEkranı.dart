import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class OzetEkrani extends ConsumerStatefulWidget {
  const OzetEkrani({super.key});

  @override
  ConsumerState<OzetEkrani> createState() => _OzetEkraniState();
}

class _OzetEkraniState extends ConsumerState<OzetEkrani> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _surveys = [];
  Map<String, int> _symptomCounts = {};
  
  // Design Colors
  final Color _primaryColor = const Color(0xFF6BAA75);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3436);
  final Color _subTextColor = const Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final storage = ref.read(storageServiceProvider);
    try {
      final data = await storage.getWeeklySurveys();
      
      // Calculate Symptom Frequency
      final counts = <String, int>{};
      for (var survey in data) {
        final symptoms = List<String>.from(survey['symptoms'] ?? []);
        for (var symptom in symptoms) {
          counts[symptom] = (counts[symptom] ?? 0) + 1;
        }
      }

      // Sort symptoms by frequency
      final sortedKeys = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      
      final Map<String, int> topSymptoms = {};
      for (var key in sortedKeys.take(5)) {
        topSymptoms[key] = counts[key]!;
      }

      if (mounted) {
        setState(() {
          _surveys = data;
          _symptomCounts = topSymptoms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 40),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 36, 
                                height: 36,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Icon(Icons.arrow_back, color: _textColor),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'İlerlemeniz',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 16,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Date Selector (Visual Only for now, defaults to "This Week")
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(7, (index) {
                              final date = DateTime.now().subtract(Duration(days: 6 - index));
                              final isToday = index == 6;
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: ShapeDecoration(
                                  color: isToday ? _primaryColor : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1, color: isToday ? _primaryColor : Colors.transparent),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('E', 'en_US').format(date), // Day name
                                      style: TextStyle(
                                        color: isToday ? Colors.white : _subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: TextStyle(
                                        color: isToday ? Colors.white : _textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Pain Chart Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ağrı Analizi',
                                        style: TextStyle(
                                          color: _textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Son 7 Gün',
                                        style: TextStyle(
                                          color: _subTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.show_chart, color: _primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: _surveys.isEmpty 
                                  ? Center(child: Text("Veri Yok", style: TextStyle(color: _subTextColor)))
                                  : _buildChart(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Symptom Frequency Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En Sık Görülen Belirtiler',
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_symptomCounts.isEmpty)
                                Text("Kayıtlı belirti yok.", style: TextStyle(color: _subTextColor))
                              else
                                ..._symptomCounts.entries.map((e) => _buildSymptomRow(e.key, e.value)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Recent Notes Title
                        Text(
                          "Günlük Notlar",
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Recent Notes List
                        if (_surveys.isEmpty)
                          Text("Henüz not eklenmedi.", style: TextStyle(color: _subTextColor))
                        else
                          ..._surveys.map((s) => _buildNoteCard(s)).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildChart() {
    // Reverse needed because surveys typically fetched newest first, but chart needs oldest->newest left->right
    final sortedSurveys = List.from(_surveys.reversed);
    
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedSurveys.length; i++) {
      spots.add(FlSpot(i.toDouble(), (sortedSurveys[i]['painLevel'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10, // Pain 0-10
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < sortedSurveys.length) {
                  final date = DateTime.parse(sortedSurveys[index]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('d/M').format(date),
                      style: TextStyle(color: _subTextColor, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: _primaryColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.3),
                  _primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomRow(String label, int count) {
    // Basic bar based on max count 7 (weekly)
    double progress = count / 7.0; 
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
              Text('$count gün', style: TextStyle(color: _subTextColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> survey) {
    final note = survey['note'] ?? '';
    if (note.isEmpty) return const SizedBox.shrink();

    final date = DateTime.parse(survey['date']);
    final dateStr = DateFormat('dd MMM yyyy', 'tr_TR').format(date);
    final pain = survey['painLevel'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getPainColor(pain).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$pain/10',
              style: TextStyle(
                color: _getPainColor(pain),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPainColor(dynamic value) {
    if (value is! num) return Colors.grey;
    if (value <= 3) return Colors.green;
    if (value <= 7) return Colors.orange;
    return Colors.red;
  }
}

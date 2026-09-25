import 'package:flutter/material.dart';

class MetricDetailsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String type;

  const MetricDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  @override
  State<MetricDetailsScreen> createState() => _MetricDetailsState();
}

class _MetricDetailsState extends State<MetricDetailsScreen> {
  int _selectedDistrictIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Фоновое изображение из assets
          Positioned.fill(
            child: Image.asset(
              'assets/images/mileage_approved.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (c, e, s) => Image.asset(
                'assets/images/garage_scene.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          // Затемнение поверх картинки для читаемости
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // Контент
          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.type) {
      case 'mileage':
        return _buildMileageContent();
      case 'district':
        return _buildDistrictContent();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildMileageContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthTotalCard('3 420 км', 'Пробег за месяц'),
        const SizedBox(height: 12),
        _buildOdometerCard('124 500 км'),
        const SizedBox(height: 16),
        const Text(
          'История по дням',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildDayRow('Сегодня, 25 сен', '180 км'),
        _buildDayRow('Вчера, 24 сен', '210 км'),
        _buildDayRow('23 сен', '195 км'),
      ],
    );
  }

  Widget _buildDistrictContent() {
    final districts = ['Район 1', 'Район 2', 'Район 3'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthTotalCard('14 поездок', 'Всего по районам'),
        const SizedBox(height: 12),
        Row(
          children: List.generate(districts.length, (index) {
            final isSelected = _selectedDistrictIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(districts[index]),
                selected: isSelected,
                selectedColor: Colors.amber,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDistrictIndex = index;
                    });
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildDayRow('Рейс #102', '340 кг'),
        _buildDayRow('Рейс #101', '520 кг'),
      ],
    );
  }

  Widget _buildDefaultContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthTotalCard(widget.subtitle, widget.title),
      ],
    );
  }

  Widget _buildMonthTotalCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOdometerCard(String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Одометр', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


/// Printable coordinates are millimetres from the top-left of portrait A4.
/// Layout calibrated from the supplied photo; text sizes are PDF points.
class SalesInvoice {
  static const supplier = 'ТОО " Казэкспорт СК"';
  static const warehouse = '5  Склад ГОТОВОЙ ПРОДУКЦИИ (Рублева О.С., (мешки)';
  String number, buyer, basis;
  DateTime date;
  double vat;
  List<SalesLine> rows;
  SalesInvoice({
    this.number = '',
    this.buyer = '',
    this.basis = 'Без договора',
    DateTime? date,
    this.vat = 16,
    List<SalesLine>? rows,
  }) : date = date ?? DateTime.now(),
       rows = rows ?? [SalesLine()];
  int get total => rows.fold(0, (v, r) => v + r.kopecks);
  int get tax => (total * vat / (100 + vat)).round();
  Map<String, dynamic> toJson() => {
    'number': number,
    'buyer': buyer,
    'basis': basis,
    'date': date.toIso8601String(),
    'vat': vat,
    'rows': rows.map((r) => r.toJson()).toList(),
  };
  factory SalesInvoice.fromJson(Map<String, dynamic> j) => SalesInvoice(
    number: j['number'] as String,
    buyer: j['buyer'] as String,
    basis: j['basis'] as String,
    date: DateTime.parse(j['date'] as String),
    vat: (j['vat'] as num).toDouble(),
    rows: [
      for (final r in j['rows'] as List)
        SalesLine.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
  );

  List<List<Map<String, Object>>> pages() {
    final pages = <List<Map<String, Object>>>[];
    late List<Map<String, Object>> p;
    void text(
      String s,
      double x,
      double y,
      double size,
      double width, {
      bool bold = false,
      String align = 'left',
    }) => p.add({
      'op': 'text',
      's': s,
      'x': x,
      'y': y,
      'size': size,
      'width': width,
      'bold': bold,
      'align': align,
    });
    void line(
      double x,
      double y,
      double x2,
      double y2, [
      double weight = .18,
    ]) => p.add({
      'op': 'line',
      'x': x,
      'y': y,
      'x2': x2,
      'y2': y2,
      'weight': weight,
    });
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    const edges = [10.0, 17.0, 35.0, 145.0, 161.0, 177.0, 197.0];
    void grid(double top, double bottom) {
      for (final x in edges) {
        line(x, top, x, bottom);
      }
      line(10, bottom, 197, bottom);
    }

    void header() {
      p = <Map<String, Object>>[];
      pages.add(p);
      text(
        'Расходная накладная № $number от ${date.day} ${months[date.month - 1]} ${date.year} г.',
        10,
        14.5,
        12,
        187,
        bold: true,
      );
      final values = [supplier, buyer, basis, warehouse];
      final labels = ['Поставщик:', 'Покупатель:', 'Основание:', 'Склад:'];
      for (var i = 0; i < 4; i++) {
        text(labels[i], 10, 22.5 + i * 5.8, 9, 24);
        text(values[i], 35.5, 22.5 + i * 5.8, 9, 161.5, bold: true);
      }
      line(10, 43.5, 197, 43.5);
      grid(43.5, 49.3);
      const labels2 = ['№', 'Код', 'Товар', 'Количество', 'Цена', 'Сумма'];
      for (var i = 0; i < 6; i++) {
        text(
          labels2[i],
          edges[i] + .4,
          47.4,
          8.5,
          edges[i + 1] - edges[i] - .8,
          bold: true,
          align: 'center',
        );
      }
    }

    header();
    var y = 49.3;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      // Wrap product names without shrinking the whole table for long names.
      final words = r.name.split(RegExp(r'\s+'));
      final lines = <String>[];
      var current = '';
      for (final word in words) {
        if (current.isNotEmpty && current.length + word.length + 1 > 73) {
          lines.add(current);
          current = '';
        }
        current = current.isEmpty ? word : '$current $word';
      }
      if (current.isNotEmpty) lines.add(current);
      final height = 3.5 * (lines.isEmpty ? 1 : lines.length);
      if (y + height > 260) {
        header();
        y = 49.3;
      }
      grid(y, y + height);
      final values = [
        '${i + 1}',
        r.code,
        '',
        '${quantity(r.quantity).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?:,|$))'), (m) => '${m[1]} ')} ${r.unit}',
        money((r.price * 100).round()),
        money(r.kopecks),
      ];
      for (var c = 0; c < 6; c++) {
        if (c == 2) continue;
        text(
          values[c],
          edges[c] + .4,
          y + 2.65,
          7,
          edges[c + 1] - edges[c] - .8,
          align: c >= 3
              ? 'right'
              : c == 0
              ? 'center'
              : 'left',
        );
      }
      for (var n = 0; n < lines.length; n++) {
        text(lines[n], 35.4, y + 2.65 + n * 3.5, 7, 109.2);
      }
      y += height;
    }
    if (y + 27 > 287) {
      header();
      y = 49.3;
    }
    text('Итого:', 150, y + 4.8, 9, 27, bold: true, align: 'right');
    text(money(total), 177, y + 4.8, 9, 20, bold: true, align: 'right');
    text('В том числе НДС:', 145, y + 8.5, 9, 32, bold: true, align: 'right');
    text(money(tax), 177, y + 8.5, 9, 20, bold: true, align: 'right');
    text(
      'Всего наименований ${rows.length}, на сумму ${money(total)} KZT',
      10,
      y + 13,
      7,
      187,
    );
    text(amountWords(total), 10, y + 16.5, 9, 187, bold: true);
    line(10, y + 19.5, 197, y + 19.5, .4);
    text('Отпустил', 10, y + 25, 9, 28, bold: true);
    line(40, y + 27, 106, y + 27, .4);
    text('Рублева О.', 88, y + 26, 7, 17, align: 'right');
    text('Получил', 110.5, y + 25, 9, 26, bold: true);
    line(136.5, y + 27, 197, y + 27, .4);
    return pages;
  }
}

class SalesLine {
  String code, name, unit;
  double quantity, price;
  SalesLine({
    this.code = '',
    this.name = '',
    this.unit = 'кг',
    this.quantity = 0,
    this.price = 0,
  });
  int get kopecks => (quantity * price * 100).round();
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'price': price,
  };
  factory SalesLine.fromJson(Map<String, dynamic> j) => SalesLine(
    code: j['code'] as String,
    name: j['name'] as String,
    unit: j['unit'] as String,
    quantity: (j['quantity'] as num).toDouble(),
    price: (j['price'] as num).toDouble(),
  );
}

String money(int cents) {
  final whole = (cents ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$whole,${(cents % 100).toString().padLeft(2, '0')}';
}

String quantity(double n) => n
    .toStringAsFixed(3)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');
String amountWords(int cents) {
  const ones = [
    '',
    'один',
    'два',
    'три',
    'четыре',
    'пять',
    'шесть',
    'семь',
    'восемь',
    'девять',
  ];
  const teens = [
    'десять',
    'одиннадцать',
    'двенадцать',
    'тринадцать',
    'четырнадцать',
    'пятнадцать',
    'шестнадцать',
    'семнадцать',
    'восемнадцать',
    'девятнадцать',
  ];
  const tens = [
    '',
    '',
    'двадцать',
    'тридцать',
    'сорок',
    'пятьдесят',
    'шестьдесят',
    'семьдесят',
    'восемьдесят',
    'девяносто',
  ];
  const hundreds = [
    '',
    'сто',
    'двести',
    'триста',
    'четыреста',
    'пятьсот',
    'шестьсот',
    'семьсот',
    'восемьсот',
    'девятьсот',
  ];
  const forms = [
    ['', '', ''],
    ['тысяча', 'тысячи', 'тысяч'],
    ['миллион', 'миллиона', 'миллионов'],
    ['миллиард', 'миллиарда', 'миллиардов'],
  ];
  var n = cents ~/ 100;
  final groups = <String>[];
  for (var g = 0; n > 0; g++, n ~/= 1000) {
    final v = n % 1000;
    if (v == 0) continue;
    final parts = <String>[if (v >= 100) hundreds[v ~/ 100]];
    final tail = v % 100;
    if (tail >= 10 && tail < 20) {
      parts.add(teens[tail - 10]);
    } else {
      if (tail >= 20) parts.add(tens[tail ~/ 10]);
      final u = tail % 10;
      if (u > 0)
        parts.add(
          g == 1 && u == 1
              ? 'одна'
              : g == 1 && u == 2
              ? 'две'
              : ones[u],
        );
    }
    if (g > 0)
      parts.add(
        forms[g][tail >= 11 && tail <= 14
            ? 2
            : tail % 10 == 1
            ? 0
            : tail % 10 >= 2 && tail % 10 <= 4
            ? 1
            : 2],
      );
    groups.insert(0, parts.join(' '));
  }
  final s =
      '${groups.isEmpty ? 'ноль' : groups.join(' ')} тенге ${(cents % 100).toString().padLeft(2, '0')} тиын';
  return s[0].toUpperCase() + s.substring(1);
}

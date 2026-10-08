import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sales_invoice.dart';
import '../services/test_store.dart';

class SalesInvoiceScreen extends StatefulWidget {
  final String owner;
  const SalesInvoiceScreen({super.key, required this.owner});
  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  static const channel = MethodChannel('melnitsa/advance_image');
  var form = GlobalKey<FormState>();
  SalesInvoice doc = SalesInvoice();
  bool busy = true;
  String? error;
  Future<void> writes = Future<void>.value();
  String get keyName => 'sales_invoice_draft_v1_${widget.owner}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final raw = (await TestPreferences.getInstance()).getString(keyName);
      if (raw != null)
        doc = SalesInvoice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      error = 'Не удалось прочитать черновик: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  void changed() {
    setState(() {});
    final snapshot = jsonEncode(doc.toJson());
    writes = writes
        .then((_) async {
          await (await TestPreferences.getInstance()).setString(
            keyName,
            snapshot,
          );
        })
        .catchError((Object e) {
          if (mounted)
            setState(() => error = 'Не удалось сохранить черновик: $e');
        });
  }

  Future<void> newInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая накладная'),
        content: const Text(
          'Очистить текущий черновик? Сначала сохраните нужный бланк в PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Создать новую'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      doc = SalesInvoice();
      form = GlobalKey<FormState>();
      error = null;
      changed();
    }
  }

  Future<void> preview() async {
    if (!form.currentState!.validate()) return;
    if (doc.total >= 100000000000000) {
      setState(() => error = 'Сумма должна быть меньше триллиона тенге');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await writes;
      final result = await channel.invokeMapMethod<String, dynamic>(
        'renderInvoice',
        {'pages': doc.pages()},
      );
      if (result == null) throw StateError('Пустой бланк');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _SalesPreview(
            pdf: result['pdf'] as Uint8List,
            images: (result['images'] as List).cast<Uint8List>(),
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        setState(() => error = 'Не удалось сформировать накладную: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String label,
    String initial,
    ValueChanged<String> change, {
    bool required = false,
    bool numeric = false,
    bool positive = false,
    int max = 160,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: initial,
      maxLength: max,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: (s) {
        if (required && (s ?? '').trim().isEmpty) return 'Заполните поле';
        if (numeric) {
          final n = parse(s ?? '');
          if (n == null ||
              !n.isFinite ||
              n < 0 ||
              (positive && n <= 0) ||
              n > 1000000000)
            return 'Проверьте число';
        }
        return null;
      },
      onChanged: (s) {
        change(s);
        changed();
      },
    ),
  );
  double? parse(String s) =>
      double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.'));
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF12191F),
    appBar: AppBar(
      title: const Text('Расходная накладная'),
      actions: [
        IconButton(
          tooltip: 'Новая накладная',
          onPressed: busy ? null : newInvoice,
          icon: const Icon(Icons.add),
        ),
      ],
      backgroundColor: const Color(0xFF12191F),
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            top: false,
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Поставщик: ${SalesInvoice.supplier}\nСклад: ${SalesInvoice.warehouse}\nОтпустил: Рублева О.',
                    style: TextStyle(
                      color: Color(0xFFABB8C0),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  field(
                    'Номер накладной',
                    doc.number,
                    (s) => doc.number = s.trim(),
                    required: true,
                    max: 40,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Дата'),
                    subtitle: Text(
                      '${doc.date.day.toString().padLeft(2, '0')}.${doc.date.month.toString().padLeft(2, '0')}.${doc.date.year}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: doc.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null && mounted) {
                        doc.date = d;
                        changed();
                      }
                    },
                  ),
                  field(
                    'Покупатель и адрес',
                    doc.buyer,
                    (s) => doc.buyer = s.trim(),
                    required: true,
                  ),
                  field('Основание', doc.basis, (s) => doc.basis = s.trim()),
                  for (var i = 0; i < doc.rows.length; i++)
                    item(doc.rows[i], i),
                  OutlinedButton.icon(
                    onPressed: doc.rows.length >= 100
                        ? null
                        : () {
                            doc.rows.add(SalesLine());
                            changed();
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить товар'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: quantity(doc.vat),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'НДС включён в цену, %',
                      helperText: '16% — как в образце. Можно изменить.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (s) {
                      final n = parse(s ?? '');
                      return n == null || !n.isFinite || n < 0 || n > 100
                          ? 'От 0 до 100%'
                          : null;
                    },
                    onChanged: (s) {
                      final n = parse(s);
                      if (n != null && n.isFinite && n >= 0 && n <= 100) {
                        doc.vat = n;
                        changed();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Итого: ${money(doc.total)} ₸',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('В том числе НДС: ${money(doc.tax)} ₸'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: preview,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Сформировать бланк А4'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Черновик сохраняется автоматически. Цена указывается за выбранную единицу количества.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFABB8C0)),
                  ),
                ],
              ),
            ),
          ),
  );
  Widget item(SalesLine row, int index) => Card(
    key: ObjectKey(row),
    color: const Color(0xFF1C252D),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Товар ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: doc.rows.length == 1
                    ? null
                    : () {
                        doc.rows.remove(row);
                        changed();
                      },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          field('Код', row.code, (s) => row.code = s.trim(), max: 24),
          field(
            'Наименование товара',
            row.name,
            (s) => row.name = s.trim(),
            required: true,
            max: 500,
          ),
          Row(
            children: [
              Expanded(
                child: field(
                  'Количество',
                  quantity(row.quantity),
                  (s) {
                    final n = parse(s);
                    if (n != null && n.isFinite && n >= 0 && n <= 1000000000)
                      row.quantity = n;
                  },
                  numeric: true,
                  positive: true,
                  max: 16,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: field(
                  'Ед.',
                  row.unit,
                  (s) => row.unit = s.trim(),
                  required: true,
                  max: 8,
                ),
              ),
            ],
          ),
          field(
            'Цена за единицу, ₸',
            quantity(row.price),
            (s) {
              final n = parse(s);
              if (n != null && n.isFinite && n >= 0 && n <= 1000000000)
                row.price = n;
            },
            numeric: true,
            max: 16,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Сумма: ${money(row.kopecks)} ₸'),
          ),
        ],
      ),
    ),
  );
}

class _SalesPreview extends StatefulWidget {
  final Uint8List pdf;
  final List<Uint8List> images;
  const _SalesPreview({required this.pdf, required this.images});
  @override
  State<_SalesPreview> createState() => _SalesPreviewState();
}

class _SalesPreviewState extends State<_SalesPreview> {
  bool saving = false;
  Future<void> save() async {
    setState(() => saving = true);
    try {
      final ok = await _SalesInvoiceScreenState.channel.invokeMethod<bool>(
        'save',
        {'bytes': widget.pdf, 'kind': 'invoice'},
      );
      if (mounted && ok == true)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF сохранён')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Бланк А4 · ${widget.images.length} стр.')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Печать: А4, книжная ориентация, масштаб 100%.'),
        ),
        Expanded(
          child: PageView(
            children: [
              for (final bytes in widget.images)
                InteractiveViewer(
                  minScale: .5,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.save_alt),
              label: Text(saving ? 'Сохранение…' : 'Сохранить PDF'),
            ),
          ),
        ),
      ],
    ),
  );
}

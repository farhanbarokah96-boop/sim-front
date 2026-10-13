import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class DetailKantorScreen extends StatefulWidget {
  final String unitId;

  const DetailKantorScreen({super.key, required this.unitId});

  @override
  State<DetailKantorScreen> createState() => _DetailKantorScreenState();
}

class _DetailKantorScreenState extends State<DetailKantorScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository();
    final unit = repo.unitById(widget.unitId);

    if (unit == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: const Text('Detail Kantor'),
        ),
        body: const Center(child: Text('Kantor tidak ditemukan')),
      );
    }

    final allPegawai = repo.pegawaiDiUnit(widget.unitId);
    final filteredPegawai = allPegawai.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.nama.toLowerCase().contains(q) ||
          p.pernr.toLowerCase().contains(q) ||
          p.nip.toLowerCase().contains(q) ||
          p.jabatan.toLowerCase().contains(q);
    }).toList();

    final gap = repo.gapUnit(unit);
    final parentKc = unit.kcIndukId != null ? repo.unitById(unit.kcIndukId!) : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unit.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${unit.jenis.label}${unit.kode.isNotEmpty ? " • Branch ${unit.kode}" : ""}${parentKc != null ? " • ${parentKc.nama}" : ""}',
              style: const TextStyle(fontSize: 11, color: AppColors.navyPale),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Formasi',
                          value: '${unit.formasiTotal}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Existing',
                          value: '${allPegawai.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Gap',
                          value: '$gap',
                          backgroundColor: gap < 0 ? AppColors.dangerBg : AppColors.secondaryBg,
                          valueColor: gap < 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      Chip(
                        label: Text('CS: ${unit.formasiCs}', style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.secondaryBg,
                      ),
                      Chip(
                        label: Text('Teller: ${unit.formasiTeller}', style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.secondaryBg,
                      ),
                      if (unit.formasiUb > 0)
                        Chip(
                          label: Text('UB: ${unit.formasiUb}', style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.secondaryBg,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (gap < 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kekurangan ${-gap} pegawai dari formasi total (${unit.formasiTotal} formasi, ${allPegawai.length} existing)',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Search pegawai in unit
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari pegawai (nama, PERNR, NIP, jabatan)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daftar Pegawai (${filteredPegawai.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              if (_searchQuery.isNotEmpty)
                Text('Filter: "$_searchQuery"',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),

          if (filteredPegawai.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  allPegawai.isEmpty
                      ? 'Belum ada pegawai tercatat di unit ini'
                      : 'Pegawai tidak ditemukan sesuai pencarian',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...filteredPegawai.map((p) => EmployeeTile(pegawai: p)),
        ],
      ),
    );
  }
}

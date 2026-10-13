import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'detail_kantor_screen.dart';

class DetailKcScreen extends StatelessWidget {
  final String kcId;
  final SubUnitCategory? tabAwal;

  const DetailKcScreen({super.key, required this.kcId, this.tabAwal});

  static const _categories = [
    SubUnitCategory.kcp,
    SubUnitCategory.kk,
    SubUnitCategory.unitTeras,
  ];

  @override
  Widget build(BuildContext context) {
    final repo = RekapRepository();
    final kc = repo.unitById(kcId);
    final initialIndex = tabAwal == null ? 0 : _categories.indexOf(tabAwal!).clamp(0, _categories.length - 1);

    if (kc == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: const Text('Detail KC'),
        ),
        body: const Center(child: Text('Kantor Cabang tidak ditemukan')),
      );
    }

    final kcUtamaPegawaiCount = repo.existingDiUnit(kcId);

    return DefaultTabController(
      length: _categories.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kc.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (kc.kode.isNotEmpty)
                Text('Kode Branch: ${kc.kode}', style: const TextStyle(fontSize: 11, color: AppColors.navyPale)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Top Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(label: 'Formasi Total', value: '${repo.formasiTotalKc(kcId)}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(label: 'Existing', value: '${repo.existingTotalKc(kcId)}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Gap',
                          value: '${repo.gapTotalKc(kcId)}',
                          backgroundColor: repo.gapTotalKc(kcId) < 0 ? AppColors.dangerBg : AppColors.secondaryBg,
                          valueColor: repo.gapTotalKc(kcId) < 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  if (kcUtamaPegawaiCount > 0 || kc.formasiTotal > 0) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailKantorScreen(unitId: kc.id)),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.navyPale.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_center_outlined, size: 18, color: AppColors.navy),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pegawai Kantor Utama KC ($kcUtamaPegawaiCount orang)',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.navy),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // High-Contrast Sub-Unit Category TabBar (KCP - KK - Unit & Teras)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.navyPale.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.navyPale),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.navy,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  tabs: _categories.map((cat) {
                    final count = repo.subUnitByCategory(kcId, cat).length;
                    return Tab(
                      height: 38,
                      text: '${cat.label} ($count)',
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),

            // TabBarView Content (KCP, KK, Unit & Teras)
            Expanded(
              child: TabBarView(
                children: _categories.map((cat) => _DaftarSubUnitTab(repo: repo, kcId: kcId, category: cat)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaftarSubUnitTab extends StatelessWidget {
  final RekapRepository repo;
  final String kcId;
  final SubUnitCategory category;

  const _DaftarSubUnitTab({required this.repo, required this.kcId, required this.category});

  @override
  Widget build(BuildContext context) {
    final daftar = repo.subUnitByCategory(kcId, category);

    if (daftar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Belum ada sub unit ${category.label} di ${repo.unitById(kcId)?.nama ?? "KC ini"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daftar.length,
      itemBuilder: (context, index) {
        final unit = daftar[index];
        final existing = repo.existingDiUnit(unit.id);
        final gap = repo.gapUnit(unit);

        String typeLabel = unit.jenis.label;
        if (unit.jenis == JenisKantor.unit) typeLabel = 'Unit';
        if (unit.jenis == JenisKantor.teras) typeLabel = 'Teras';

        return OfficeGapTile(
          nama: unit.nama,
          subtitle: '[$typeLabel] CS: ${unit.formasiCs} | Tel: ${unit.formasiTeller}'
              '${unit.formasiUb > 0 ? " | UB: ${unit.formasiUb}" : ""} · Ext: $existing',
          gap: gap,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailKantorScreen(unitId: unit.id)),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/auth_repository.dart';
import '../data/excel_export.dart';
import '../data/excel_import.dart';
import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'detail_kc_screen.dart';
import 'kc_list_screen.dart';
import 'kontrak_screen.dart';
import 'login_screen.dart';
import 'pegawai_list_screen.dart';
import 'sub_unit_list_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _repo = RekapRepository();
  final _authRepo = AuthRepository();
  bool _isImporting = false;
  bool _isExporting = false;

  void _refreshUI() {
    setState(() {});
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              _authRepo.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('KELUAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak dapat membaca isi file Excel.')),
            );
          }
          return;
        }

        setState(() {
          _isImporting = true;
        });

        // Parse excel bytes asynchronously
        final importResult = parseExcelBytes(bytes);

        _repo.setData(
          unitKerja: importResult.unitKerjaList,
          pegawai: importResult.pegawaiList,
        );

        setState(() {
          _isImporting = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Impor Berhasil'),
                ],
              ),
              content: Text(
                'Berhasil mengimpor ${importResult.unitKerjaList.length} Unit Kerja '
                'dan ${importResult.pegawaiList.length} Pegawai dari file Excel ${file.name}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengimpor file Excel: $e')),
        );
      }
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() {
      _isExporting = true;
    });
    await ExcelExportService.exportAndSaveExcel(context);
    if (mounted) {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showLaporanDialog(BuildContext context) {
    final ringkasan = _repo.ringkasanRegion();
    final totalKc = _repo.semuaKc.length;
    final totalPegawai = _repo.semuaPegawai.length;
    final totalUnit = _repo.semuaUnit.length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Laporan Pemenuhan FL', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wilayah: Region 04 Palembang', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('• Total Main Unit (KC): $totalKc'),
            Text('• Total Seluruh Unit Kerja: $totalUnit'),
            Text('• Total Pegawai Terdata: $totalPegawai'),
            const Divider(height: 16),
            Text('• Total Formasi: ${ringkasan.formasi}'),
            Text('• Total Existing: ${ringkasan.existing}'),
            Text(
              '• Total Gap: ${ringkasan.gap}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ringkasan.gap < 0 ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExportExcel();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_download, size: 16),
                SizedBox(width: 4),
                Text('Ekspor Excel'),
              ],
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringkasan = _repo.ringkasanRegion();
    final kcUrut = _repo.kcUrutGapTerbesar().take(5).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildMenuCard(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ringkasan pemenuhan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('${_repo.semuaKc.length} KC • ${_repo.semuaUnit.length} Unit',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(label: 'Formasi', value: '${ringkasan.formasi}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(label: 'Existing', value: '${ringkasan.existing}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            label: 'Gap',
                            value: '${ringkasan.gap}',
                            backgroundColor: ringkasan.gap < 0 ? AppColors.dangerBg : AppColors.secondaryBg,
                            valueColor: ringkasan.gap < 0 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('KC Perlu Perhatian (Gap Terbesar)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KcListScreen()),
                            );
                          },
                          child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...kcUrut.map((kc) => OfficeGapTile(
                          nama: kc.nama,
                          subtitle: 'Formasi: ${_repo.formasiTotalKc(kc.id)} | Existing: ${_repo.existingTotalKc(kc.id)}',
                          gap: _repo.gapTotalKc(kc.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailKcScreen(kcId: kc.id),
                              ),
                            );
                          },
                        )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = _authRepo.currentUser;
    final nama = user?.nama ?? 'Admin Region 04';
    final role = user?.role ?? 'Region 04 Palembang';
    final initial = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'AU';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 44),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pemenuhan FL Region 04',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.navyPale)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.assessment_outlined, color: AppColors.navyPale, size: 20),
                    tooltip: 'Laporan Pemenuhan',
                    onPressed: () => _showLaporanDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.navyPale, size: 20),
                    tooltip: 'Keluar Akun',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.navyLight,
                child: Text(
                  initial.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: AppColors.navyPale, fontSize: 11.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          children: [
            if (_isImporting)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Memproses file Excel...', style: TextStyle(fontSize: 12, color: AppColors.navy)),
                  ],
                ),
              ),
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Mengekspor file Excel...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.82,
              children: [
                MenuIconButton(
                  icon: Icons.account_balance,
                  label: 'Daftar KC',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KcListScreen()),
                    ).then((_) => _refreshUI());
                  },
                ),
                MenuIconButton(
                  icon: Icons.business,
                  label: 'KCP',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubUnitListScreen(category: SubUnitCategory.kcp)),
                    ).then((_) => _refreshUI());
                  },
                ),
                MenuIconButton(
                  icon: Icons.account_tree,
                  label: 'KK',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubUnitListScreen(category: SubUnitCategory.kk)),
                    ).then((_) => _refreshUI());
                  },
                ),
                MenuIconButton(
                  icon: Icons.storefront,
                  label: 'Unit & Teras',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubUnitListScreen(category: SubUnitCategory.unitTeras)),
                    ).then((_) => _refreshUI());
                  },
                ),
                MenuIconButton(
                  icon: Icons.people_alt,
                  label: 'Daftar Pegawai',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PegawaiListScreen()),
                    );
                  },
                ),
                MenuIconButton(
                  icon: Icons.upload_file,
                  label: 'Impor Excel',
                  onTap: _handleImportExcel,
                ),
                MenuIconButton(
                  icon: Icons.file_download,
                  label: 'Ekspor Excel',
                  onTap: _handleExportExcel,
                ),
                MenuIconButton(
                  icon: Icons.timer_outlined,
                  label: 'Kontrak habis',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KontrakScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

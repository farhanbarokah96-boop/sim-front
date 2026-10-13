import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'detail_kc_screen.dart';
import 'kontrak_screen.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final VoidCallback? onTapAction;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.onTapAction,
  });
}

enum NotificationType { urgent, info, warning }

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  int _selectedCategoryIndex = 0; // 0: Semua, 1: Penting, 2: Informasi

  late List<AppNotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final now = DateTime.now();
    _notifications = [
      AppNotificationItem(
        id: '1',
        title: 'Masa Kontrak Pegawai Segera Habis',
        message: '8 Pegawai Frontliner di Region 04 memiliki sisa kontrak kurang dari 30 hari. Segera lakukan peninjauan atau perpanjangan.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: NotificationType.urgent,
        isRead: false,
        onTapAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KontrakScreen()),
          );
        },
      ),
      AppNotificationItem(
        id: '2',
        title: 'Defisit Pegawai (Gap Negatif Tinggi)',
        message: 'KC Palembang dan KC Bengkulu tercatat memiliki selisih Gap -6 dan -8 pegawai dari target formasi.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.warning,
        isRead: false,
        onTapAction: () {
          final repo = RekapRepository();
          final targetKc = repo.semuaKc.firstWhere(
            (kc) => kc.id.contains('palembang') || kc.nama.toLowerCase().contains('palembang'),
            orElse: () => repo.semuaKc.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailKcScreen(kcId: targetKc.id)),
          );
        },
      ),
      AppNotificationItem(
        id: '3',
        title: 'Pembaruan Data Pemenuhan',
        message: 'Data Rekap Pegawai Region 04 Palembang telah disinkronkan. Total 21 Kantor Cabang terdaftar.',
        timestamp: now.subtract(const Duration(days: 1)),
        type: NotificationType.info,
        isRead: true,
      ),
      AppNotificationItem(
        id: '4',
        title: 'Fitur Ekspor Excel Siap Used',
        message: 'Laporan Rekap Pemenuhan FL kini dapat diekspor langsung ke file .xlsx lengkap dengan sheet KC dan Pegawai.',
        timestamp: now.subtract(const Duration(days: 2)),
        type: NotificationType.info,
        isRead: true,
      ),
      AppNotificationItem(
        id: '5',
        title: 'Pengingat Evaluasi Kinerja CS & Teller',
        message: 'Jadwal evaluasi triwulan SDM Frontliner akan dilaksanakan minggu depan oleh Team SDM Region 04.',
        timestamp: now.subtract(const Duration(days: 3)),
        type: NotificationType.warning,
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<AppNotificationItem> get _filteredNotifications {
    if (_selectedCategoryIndex == 1) {
      return _notifications.where((n) => n.type == NotificationType.urgent || n.type == NotificationType.warning).toList();
    } else if (_selectedCategoryIndex == 2) {
      return _notifications.where((n) => n.type == NotificationType.info).toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j yang lalu';
    } else {
      return '${diff.inDays}hr yang lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Notifikasi & Peringatan',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount Baru',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: AppColors.navyPale, size: 18),
              label: const Text(
                'Baca Semua',
                style: TextStyle(color: AppColors.navyPale, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Semua, Penting, Informasi)
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildFilterChip('Semua (${_notifications.length})', 0),
                const SizedBox(width: 8),
                _buildFilterChip('Penting / Alert', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Informasi', 2),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedCategoryIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.navy : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    IconData iconData;
    Color iconBg;
    Color iconColor;

    switch (item.type) {
      case NotificationType.urgent:
        iconData = Icons.warning_amber_rounded;
        iconBg = AppColors.dangerBg;
        iconColor = AppColors.danger;
        break;
      case NotificationType.warning:
        iconData = Icons.error_outline_rounded;
        iconBg = AppColors.warningBg;
        iconColor = AppColors.warning;
        break;
      case NotificationType.info:
        iconData = Icons.info_outline_rounded;
        iconBg = AppColors.secondaryBg;
        iconColor = AppColors.primary;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: item.isRead ? 0.5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: item.isRead ? Colors.white : const Color(0xFFF7F9FF),
      child: InkWell(
        onTap: () {
          setState(() {
            item.isRead = true;
          });
          if (item.onTapAction != null) {
            item.onTapAction!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(item.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (item.onTapAction != null)
                          const Row(
                            children: [
                              Text(
                                'Buka',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

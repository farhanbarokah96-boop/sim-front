import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import 'mock_data.dart';
import 'repository.dart';

class ExcelExportService {
  /// Meng-generate byte file Excel (.xlsx) yang berisi rekap data pemenuhan & pegawai.
  static Uint8List generateExcelBytes() {
    final excel = Excel.createExcel();
    
    // Default sheet nama "Sheet1" di-rename atau hapus jika perlu
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    // -------------------------------------------------------------
    // SHEET 1: Rekap KC
    // -------------------------------------------------------------
    const String sheetKcName = 'Rekap KC & Unit';
    final Sheet sheetKc = excel[sheetKcName];
    excel.setDefaultSheet(sheetKcName);
    if (defaultSheet != sheetKcName && excel.tables.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    // Header Sheet 1
    sheetKc.appendRow([
      TextCellValue('REKAP PEMENUHAN FRONTLINER - REGION 04 PALEMBANG'),
    ]);
    sheetKc.appendRow([
      TextCellValue('Tanggal Ekspor: ${DateTime.now().toString().split('.').first}'),
    ]);
    sheetKc.appendRow([]); // Row kosong

    sheetKc.appendRow([
      TextCellValue('No'),
      TextCellValue('Kode KC'),
      TextCellValue('Nama Kantor Cabang'),
      TextCellValue('Formasi Total'),
      TextCellValue('Existing Total'),
      TextCellValue('Gap Total'),
      TextCellValue('Status Pemenuhan'),
    ]);

    final repo = RekapRepository();
    final kcList = repo.semuaKc;

    int totalFormasi = 0;
    int totalExisting = 0;

    for (int i = 0; i < kcList.length; i++) {
      final kc = kcList[i];
      final formasi = repo.formasiTotalKc(kc.id);
      final existing = repo.existingTotalKc(kc.id);
      final gap = repo.gapTotalKc(kc.id);

      totalFormasi += formasi;
      totalExisting += existing;

      String statusStr = 'Sesuai';
      if (gap < 0) {
        statusStr = 'Kekurangan (${gap.abs()} org)';
      } else if (gap > 0) {
        statusStr = 'Kelebihan (+$gap org)';
      }

      sheetKc.appendRow([
        IntCellValue(i + 1),
        TextCellValue(kc.kode.isEmpty ? '-' : kc.kode),
        TextCellValue(kc.nama),
        IntCellValue(formasi),
        IntCellValue(existing),
        IntCellValue(gap),
        TextCellValue(statusStr),
      ]);
    }

    // Baris Total
    final totalGap = totalExisting - totalFormasi;
    sheetKc.appendRow([]);
    sheetKc.appendRow([
      TextCellValue(''),
      TextCellValue('TOTAL'),
      TextCellValue('REGION 04 PALEMBANG'),
      IntCellValue(totalFormasi),
      IntCellValue(totalExisting),
      IntCellValue(totalGap),
      TextCellValue(totalGap < 0 ? 'Kekurangan Total' : 'Tercukupi'),
    ]);

    // -------------------------------------------------------------
    // SHEET 2: Daftar Pegawai
    // -------------------------------------------------------------
    final Sheet sheetPegawai = excel['Daftar Pegawai'];
    sheetPegawai.appendRow([
      TextCellValue('DAFTAR PEGAWAI FRONTLINER REGION 04 PALEMBANG'),
    ]);
    sheetPegawai.appendRow([]);

    sheetPegawai.appendRow([
      TextCellValue('No'),
      TextCellValue('PERNR'),
      TextCellValue('NIP'),
      TextCellValue('Nama Pegawai'),
      TextCellValue('Jabatan'),
      TextCellValue('Status Pegawai'),
      TextCellValue('Unit Kerja'),
    ]);

    final pegawaiList = repo.semuaPegawai;
    for (int i = 0; i < pegawaiList.length; i++) {
      final p = pegawaiList[i];
      final unit = repo.unitById(p.unitKerjaId);
      final unitNama = unit != null ? unit.nama : p.unitKerjaId;

      sheetPegawai.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.pernr),
        TextCellValue(p.nip),
        TextCellValue(p.nama),
        TextCellValue(p.jabatan),
        TextCellValue(p.status.label),
        TextCellValue(unitNama),
      ]);
    }

    // -------------------------------------------------------------
    // SHEET 3: Kontrak Akan Habis
    // -------------------------------------------------------------
    final Sheet sheetKontrak = excel['Kontrak Akan Habis'];
    sheetKontrak.appendRow([
      TextCellValue('DAFTAR PEGAWAI DENGAN MASA KONTRAK SEGERA HABIS'),
    ]);
    sheetKontrak.appendRow([]);

    sheetKontrak.appendRow([
      TextCellValue('No'),
      TextCellValue('PERNR'),
      TextCellValue('NIP'),
      TextCellValue('Nama Pegawai'),
      TextCellValue('Jabatan'),
      TextCellValue('Status'),
      TextCellValue('Tanggal Berakhir Kontrak'),
      TextCellValue('Sisa Hari'),
    ]);

    final kontrakList = List<Pegawai>.from(mockPegawaiKontrakHabis)
      ..sort((a, b) => (a.kontrakBerakhir ?? DateTime.now()).compareTo(b.kontrakBerakhir ?? DateTime.now()));

    final now = DateTime.now();
    for (int i = 0; i < kontrakList.length; i++) {
      final p = kontrakList[i];
      final tglStr = p.kontrakBerakhir != null
          ? "${p.kontrakBerakhir!.day.toString().padLeft(2, '0')}-${p.kontrakBerakhir!.month.toString().padLeft(2, '0')}-${p.kontrakBerakhir!.year}"
          : '-';
      final sisaHari = p.kontrakBerakhir != null ? p.kontrakBerakhir!.difference(now).inDays : 0;

      sheetKontrak.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.pernr),
        TextCellValue(p.nip),
        TextCellValue(p.nama),
        TextCellValue(p.jabatan),
        TextCellValue(p.status.label),
        TextCellValue(tglStr),
        IntCellValue(sisaHari),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Gagal membuat data Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Membuka file picker untuk menyimpan file Excel ke perangkat user
  static Future<bool> exportAndSaveExcel(BuildContext context) async {
    try {
      final bytes = generateExcelBytes();
      final nowStr = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
      final fileName = 'Rekap_FL_Region04_$nowStr.xlsx';

      if (kIsWeb) {
        // Untuk Web (jika dijalankan di web browser)
        await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Laporan Excel',
          fileName: fileName,
          bytes: bytes,
        );
        return true;
      }

      // Platform Mobile / Desktop (Windows, MacOS, Android, iOS)
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Laporan Excel Rekap Karyawan',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File Excel berhasil disimpan:\n$outputFile',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1976D2),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return true;
      } else {
        // Pengguna membatalkan dialog simpan
        return false;
      }
    } catch (e) {
      debugPrint('Export excel error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor file Excel: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }
}

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReportService {
  /// Genera un reporte PDF con ingresos, gastos fijos y variables
  Future<File> generateAccountStatement({
    required DateTime month,
    required double budgetLimit,
    required double totalIncome,
    required double totalFixedExpenses,
    required double totalVariableExpenses,
    required List<Map<String, dynamic>> fixedExpenses,
    required List<Map<String, dynamic>> variableExpenses,
  }) async {
    // Inicializar los datos de formato para la localización
    await initializeDateFormatting('es_ES', null);
    
    final pdf = pw.Document();
    final formatter = DateFormat('MMMM yyyy', 'es_ES');
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_US',
      symbol: '\$',
      decimalDigits: 2,
    );

    final totalExpense = totalFixedExpenses + totalVariableExpenses;
    final balance = totalIncome - totalExpense;
    final budgetUtilization = budgetLimit > 0 ? (totalExpense / budgetLimit * 100) : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DRIP WALLET',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Estado de Cuenta',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.normal,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
            ],
          ),

          // Información del período
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Período: ${formatter.format(month)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
            ],
          ),

          // Resumen Presupuesto
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PRESUPUESTO MENSUAL',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Límite de Presupuesto:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(currencyFormatter.format(budgetLimit), style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Gastado:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(currencyFormatter.format(totalExpense), style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Disponible:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      currencyFormatter.format(budgetLimit - totalExpense),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Utilización: ${budgetUtilization.toStringAsFixed(1)}%',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Ingresos
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INGRESOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total: ${currencyFormatter.format(totalIncome)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ),

          // Gastos Fijos
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GASTOS FIJOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (fixedExpenses.isEmpty)
                pw.Text(
                  'No hay gastos fijos registrados',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                )
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    ...fixedExpenses.map((expense) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              expense['title'] ?? 'Sin título',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              currencyFormatter.format(expense['amount'] ?? 0),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal Gastos Fijos:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Text(
                          currencyFormatter.format(totalFixedExpenses),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              pw.SizedBox(height: 16),
            ],
          ),

          // Gastos Variables
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GASTOS VARIABLES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (variableExpenses.isEmpty)
                pw.Text(
                  'No hay gastos variables registrados',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                )
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    ...variableExpenses.map((expense) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              expense['title'] ?? 'Sin título',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              currencyFormatter.format(expense['amount'] ?? 0),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal Gastos Variables:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Text(
                          currencyFormatter.format(totalVariableExpenses),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              pw.SizedBox(height: 20),
            ],
          ),

          // Resumen Final
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESUMEN FINANCIERO',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Ingresos:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      currencyFormatter.format(totalIncome),
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.green),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Gastos Fijos:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      currencyFormatter.format(totalFixedExpenses),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Gastos Variables:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      currencyFormatter.format(totalVariableExpenses),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'BALANCE:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      currencyFormatter.format(balance),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Guardar archivo
    final output = await getTemporaryDirectory();
    final fileName =
        'Estado_Cuenta_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Comparte el PDF generado
  Future<void> shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Estado de Cuenta - Drip Wallet',
      text: 'Mi estado de cuenta de Drip Wallet',
    );
  }
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class PdfInvoiceService {
  static Future<void> generateAndDownloadInvoice({
    required OrderModel order,
    required String customerName,
  }) async {
    final pdf = pw.Document();

    final fontBold = await PdfGoogleFonts.outfitBold();
    final fontRegular = await PdfGoogleFonts.interRegular();

    final double rawItemsSubtotal = order.subtotalAmount ?? order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final double deliveryFeeVal = order.deliveryFee ?? 0.0;

    double discountVal = order.discountAmount ?? 0.0;
    if (discountVal == 0.0 && (rawItemsSubtotal + deliveryFeeVal) > order.totalAmount) {
      discountVal = (rawItemsSubtotal + deliveryFeeVal) - order.totalAmount;
    }

    final String rewardLabel = (order.discountTitle != null && order.discountTitle!.isNotEmpty)
        ? order.discountTitle!
        : 'Loyalty / Reward Discount';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final createdLocal = order.createdAt.toLocal();
          final hour12 = createdLocal.hour == 0 ? 12 : (createdLocal.hour > 12 ? createdLocal.hour - 12 : createdLocal.hour);
          final ampm = createdLocal.hour >= 12 ? "PM" : "AM";
          final min = createdLocal.minute.toString().padLeft(2, '0');
          final formattedDateTime = '${createdLocal.day.toString().padLeft(2, '0')}/${createdLocal.month.toString().padLeft(2, '0')}/${createdLocal.year} $hour12:$min $ampm';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PLANTORA',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 26,
                          color: PdfColor.fromHex('#0B3A22'),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Botanical Marketplace & Eco Delivery',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColor.fromHex('#059669'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColor.fromHex('#0B3A22'),
                        ),
                      ),
                      pw.Text(
                        'Invoice #${order.id.toUpperCase()}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 11,
                          color: PdfColor.fromHex('#4B5563'),
                        ),
                      ),
                      pw.Text(
                        'Date & Time: $formattedDateTime',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromHex('#10B981'), thickness: 1.5),
              pw.SizedBox(height: 16),

              // Customer & Shipping Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#9CA3AF'))),
                      pw.Text(customerName.isNotEmpty ? customerName : 'Valued Customer', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('Phone: ${order.phone.isNotEmpty ? order.phone : "+94 77 123 4567"}', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DELIVERY ADDRESS:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#9CA3AF'))),
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          order.shippingAddress.isNotEmpty ? order.shippingAddress : 'Colombo, Sri Lanka',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Order Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 0.8),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F0FDF4')),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Description', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unit Price', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total (Rs.)', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Table Rows
                  ...order.items.map((item) {
                    final itemTotal = item.price * item.quantity;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.title, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.quantity}', style: pw.TextStyle(font: fontRegular, fontSize: 10), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. ${item.price.toStringAsFixed(2)}', style: pw.TextStyle(font: fontRegular, fontSize: 10), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. ${itemTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontRegular, fontSize: 10), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Total Calculation Row with Full Discount & Fee Breakdown
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 260,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Items Subtotal:', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColor.fromHex('#4B5563'))),
                            pw.Text('Rs. ${rawItemsSubtotal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColor.fromHex('#1F2937'))),
                          ],
                        ),
                        if (discountVal > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount ($rewardLabel):', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColor.fromHex('#059669'))),
                              pw.Text('-Rs. ${discountVal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#059669'))),
                            ],
                          ),
                        ],
                        if (deliveryFeeVal > 0 || order.deliveryFee != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Delivery Fee:', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColor.fromHex('#4B5563'))),
                              pw.Text(
                                deliveryFeeVal > 0 ? 'Rs. ${deliveryFeeVal.toStringAsFixed(2)}' : 'FREE',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: deliveryFeeVal > 0 ? PdfColor.fromHex('#1F2937') : PdfColor.fromHex('#059669'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Divider(color: PdfColor.fromHex('#E5E7EB'), thickness: 0.8),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Payment Status:', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColor.fromHex('#4B5563'))),
                            pw.Text('PAID ONLINE', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#059669'))),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Paid:', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromHex('#0B3A22'))),
                            pw.Text('Rs. ${order.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColor.fromHex('#10B981'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer Note
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Plantora! For inquiries, email supportplantora@gmail.com',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#9CA3AF')),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Share / Print / Download PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Plantora_Invoice_${order.id}.pdf',
    );
  }
}

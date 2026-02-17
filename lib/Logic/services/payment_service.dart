import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:bantuin/Logic/config.dart';

class PaymentService {
  Future<Map<String, dynamic>> createPaymentUrl({
    required String orderId,
    required int amount,
    required dynamic user,
  }) async {
    try {
      String merchantCode = DUITKU_MERCHANT_CODE;
      String apiKey = DUITKU_API_KEY;
      String signatureString = "$merchantCode$orderId$amount$apiKey";
      var bytes = utf8.encode(signatureString);
      var digest = md5.convert(bytes);
      String signature = digest.toString();

      final Map<String, dynamic> body = {
        'merchantCode': merchantCode,
        'paymentAmount': amount,
        'merchantOrderId': orderId,
        'productDetails': 'Pembayaran Pesanan #$orderId',
        'email': user.email,
        'customerVaName': user.displayName ?? 'Pelanggan',
        'callbackUrl': 'https://your-callback-url.com/callback',
        'returnUrl': 'https://your-return-url.com/return',
        'signature': signature,
        'expiryPeriod': 60,
      };

      final response = await http.post(
        Uri.parse('$DUITKU_BASE_URL/api/merchant/v2/inquiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {
          'success': true,
          'paymentUrl': data['paymentUrl'],
          'merchantOrderId': orderId,
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal request Duitku: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus({
    required String merchantOrderId,
  }) async {
    try {
      String merchantCode = DUITKU_MERCHANT_CODE;
      String apiKey = DUITKU_API_KEY;

      String signatureString = "$merchantCode$merchantOrderId$apiKey";
      var bytes = utf8.encode(signatureString);
      var digest = md5.convert(bytes);
      String signature = digest.toString();

      final Map<String, dynamic> body = {
        'merchantCode': merchantCode,
        'merchantOrderId': merchantOrderId,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse('$DUITKU_BASE_URL/api/merchant/transactionStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'statusCode': '99',
          'statusMessage': 'HTTP Error ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'statusCode': '99', 'statusMessage': 'Exception: $e'};
    }
  }
}

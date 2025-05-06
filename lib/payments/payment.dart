import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:payment/payments/keys.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentState();
}

class _PaymentState extends State<PaymentPage> {
  double amount = 200;
  Map<String, dynamic>? paymentIntentData;

  displayPaymentSheet() async {
    try {
      await Stripe.instance
          .presentPaymentSheet()
          .then((value) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Payment Successful')));
            paymentIntentData = null;
          })
          .onError((error, stackTrace) {
            if (kDebugMode) {
              print('Error is ${error.toString()}, ${stackTrace.toString()}');
            }
          });
    } on StripeException catch (e) {
      if (kDebugMode) {
        print('Error is $e');
      }
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      print(e.toString());
    }
  }

  makeIntentPayment(amount, currency) async {
    try {
      Map<String, dynamic>? paymentInfo = {
        'amount': (int.parse(amount) * 100).toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      var responseFromStripeApi = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: paymentInfo,
      );
      print("response:${responseFromStripeApi.body}");
      return jsonDecode(responseFromStripeApi.body);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      print(e.toString());
    }
  }

  void paymentSheetInitialization(amount, currency) async {
    try {
      paymentIntentData = await makeIntentPayment(amount, currency);
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              allowsDelayedPaymentMethods: true,
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              style: ThemeMode.dark,
              merchantDisplayName: 'Saving App',
            ),
          )
          .then((val) {
            print(val);
          });
      displayPaymentSheet();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PaymentPage')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            paymentSheetInitialization(amount.round().toString(), "INR");
          },
          child: Text('Pay $amount'),
        ),
      ),
    );
  }
}

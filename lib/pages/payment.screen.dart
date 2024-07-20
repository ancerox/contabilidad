import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class GooglePayExample extends StatelessWidget {
  const GooglePayExample({super.key});

  @override
  Widget build(BuildContext context) {
    const paymentItems = [
      PaymentItem(
        label: 'Total',
        amount: '99.99',
        status: PaymentItemStatus.final_price,
      )
    ];

    return Scaffold(
      body: FutureBuilder<PaymentConfiguration>(
          future: PaymentConfiguration.fromAsset(
              'assets/googlepay/google_pay_config.json'),
          builder: (context, snapshot) => snapshot.hasData
              ? GooglePayButton(
                  paymentConfiguration: snapshot.data!,
                  paymentItems: paymentItems,
                  type: GooglePayButtonType.buy,
                  margin: const EdgeInsets.only(top: 15.0),
                  onPaymentResult: onGooglePayResult,
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const Center(child: CircularProgressIndicator())),
    );
  }

  void onGooglePayResult(paymentResult) {
    // Send the resulting Google Pay token to your server / PSP
  }
}

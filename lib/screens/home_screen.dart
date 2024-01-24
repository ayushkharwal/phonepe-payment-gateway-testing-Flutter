import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:phonepe_payment_gateway_flutter/utils/helper_functions.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String enviornment = 'SANDBOX';
  String appId = '';
  String merchantId = 'PGTESTPAYUAT';
  String merchantTransactionId =
      DateTime.now().millisecondsSinceEpoch.toString();
  bool enableLogging = true;
  String checksum = '';
  String saltKey = '099eb0cd-02cf-4e2a-8aca-3e6c6aff0399';
  String saltIndex = '1';
  String callbackurl =
      'https://webhook.site/29d7866e-9727-44f1-9904-d5e19067cdda';
  String body = '';
  Object? result;
  String apiEndPoint = '/pg/v1/pay';

  phonepeInit() {
    PhonePePaymentSdk.init(enviornment, appId, merchantId, enableLogging)
        .then((val) => {
              setState(() {
                result = 'PhonePe SDK Initialized - $val';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  getChecksum() {
    final requestData = {
      "merchantId": merchantId,
      "merchantTransactionId": merchantTransactionId,
      "merchantUserId": "MUID123",
      "amount": 1000,
      "callbackUrl": callbackurl,
      "mobileNumber": "9999999999",
      "paymentInstrument": {
        "type": "PAY_PAGE",
      }
    };

    String base64Body = base64.encode(utf8.encode(json.encode(requestData)));

    checksum =
        '${sha256.convert(utf8.encode(base64Body + apiEndPoint + saltKey)).toString()}###$saltIndex';

    return base64Body;
  }

  startPgTransaction() {
    PhonePePaymentSdk.startTransaction(body, callbackurl, checksum, '')
        .then((response) => {
              setState(() {
                if (response != null) {
                  log('startPgTransaction() response ----------------------> $response');

                  String status = response['status'].toString();
                  // String error = response['error'].toString();
                  if (status == 'SUCCESS') {
                    log('Success Hogya oye!!! :)');

                    // "Flow Completed - Status: Success!";

                    checkStatus();
                  } else {
                    log('Error Occured!!!');

                    // "Flow Completed - Status: $status and Error: $error";
                  }
                } else {
                  log('Response is null!!!');

                  // "Flow Incomplete";
                }
              })
            })
        .catchError((error) {
      // handleError(error)
      return <dynamic>{};
    });
  }

  checkStatus() async {
    try {
      String apiUrl =
          'https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/$merchantId/$merchantTransactionId';

      String concatString =
          '/pg/v1/status/$merchantId/$merchantTransactionId$saltKey';

      var bytes = utf8.encode(concatString);

      var digest = sha256.convert(bytes).toString();

      String xverify = '$digest###$saltIndex';

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "X-VERIFY": xverify,
        "X-MERCHANT-ID": merchantId
      };

      await http
          .get(
        Uri.parse(apiUrl),
        headers: headers,
      )
          .then(
        (value) async {
          Map<String, dynamic> responseData = jsonDecode(value.body);

          log('checkStatus() responseData -------------------> $responseData');

          if (responseData['success'] &&
              responseData['code'] == 'PAYMENT_SUCCESS' &&
              responseData['data']['state'] == 'COMPLETED') {
            log('checkStatus() response message ------------------------> ${responseData['message']}');
            HelperMethods.showSnackbar(
              context,
              Text('${responseData['message']}'),
            );
          } else {
            log('checkStatus() else statement message -----------------------> ${responseData['message']}');
          }
        },
      );
    } catch (e) {
      print('checkStatus ERROR: $e');
    }
  }

  handleError(error) {
    setState(() {
      result = {'error': error};
    });
  }

  @override
  void initState() {
    super.initState();

    phonepeInit();

    body = getChecksum().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhonePe Payment Gateway'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                print('checksum: $checksum');
                print('body: $body');

                startPgTransaction();
              },
              child: const Text('Make Payment!!!'),
            ),
            const SizedBox(height: 20),
            Text('Result: $result'),
          ],
        ),
      ),
    );
  }
}

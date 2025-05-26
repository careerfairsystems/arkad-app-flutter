import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketsEventScreen extends StatefulWidget {
  const TicketsEventScreen({super.key});

  @override
  State<TicketsEventScreen> createState() => _TicketsEventScreenState();
}

class _TicketsEventScreenState extends State<TicketsEventScreen> {
  int _randomNumber = 0;
  late Timer _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _randomNumber = _random.nextInt(1000);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _randomNumber = _random.nextInt(1000);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // list with entries for each lunch event (show if used) ->
  // show qr-code on touch
  // get string from db

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: Center(
        child: QrImageView(data: 'ARKAD25 nmr $_randomNumber', size: 200),
      ),
    );
  }
}

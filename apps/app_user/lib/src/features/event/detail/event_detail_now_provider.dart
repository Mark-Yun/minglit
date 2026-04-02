import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<DateTime Function()> eventDetailNowProvider =
    Provider.autoDispose<DateTime Function()>((_) => DateTime.now);

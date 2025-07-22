import 'package:intl/intl.dart';

String formatKoreanPrice(int price) =>
    NumberFormat.decimalPattern('ko').format(price);

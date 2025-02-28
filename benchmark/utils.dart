extension DecimalSeparator on int {
  String asThousands([String separator = ',']) {
    final numberString = toString();
    final numberDigits = List<String>.from(numberString.split(''));
    var index = numberDigits.length - 3;
    while (index > 0) {
      numberDigits.insert(index, separator);
      index -= 3;
    }
    return numberDigits.join();
  }
}

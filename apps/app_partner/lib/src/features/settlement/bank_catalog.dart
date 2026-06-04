class BankOption {
  const BankOption({required this.code, required this.name});

  final String code;
  final String name;
}

const partnerBankCatalog = [
  BankOption(code: 'kb', name: 'KB국민은행'),
  BankOption(code: 'shinhan', name: '신한은행'),
  BankOption(code: 'hana', name: '하나은행'),
  BankOption(code: 'woori', name: '우리은행'),
  BankOption(code: 'ibk', name: 'IBK기업은행'),
  BankOption(code: 'nh', name: 'NH농협은행'),
  BankOption(code: 'kakao', name: '카카오뱅크'),
  BankOption(code: 'toss', name: '토스뱅크'),
  BankOption(code: 'kbank', name: '케이뱅크'),
];

BankOption? bankOptionByCode(String? code) {
  if (code == null || code.isEmpty) return null;
  for (final bank in partnerBankCatalog) {
    if (bank.code == code) return bank;
  }
  return null;
}

BankOption? bankOptionByName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final bank in partnerBankCatalog) {
    if (bank.name == name) return bank;
  }
  return null;
}

import 'package:flutter/material.dart';

enum TransactionType { customerPayment, deliveryDeduction, withdrawal, bankTransfer }

class Transaction {
  final String id;
  final String title;
  final String orderId;
  final String customerName;
  final double amount;
  final double grossAmount;
  final double deliveryFee;
  final DateTime date;
  final bool isCredit;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.title,
    required this.orderId,
    this.customerName = 'Customer',
    required this.amount,
    this.grossAmount = 0.0,
    this.deliveryFee = 0.0,
    required this.date,
    required this.isCredit,
    this.type = TransactionType.customerPayment,
  });
}

class DriverBankAccount {
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String branch;
  final String bankCode;
  final bool isVerified;

  DriverBankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.branch,
    required this.bankCode,
    this.isVerified = false,
  });

  DriverBankAccount copyWith({
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    String? branch,
    String? bankCode,
    bool? isVerified,
  }) {
    return DriverBankAccount(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      branch: branch ?? this.branch,
      bankCode: bankCode ?? this.bankCode,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get maskedAccount {
    if (accountNumber.length < 4) return accountNumber;
    return '**** **** ${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class FinanceService extends ChangeNotifier {
  // Singleton
  static final FinanceService _instance = FinanceService._internal();
  factory FinanceService() => _instance;
  FinanceService._internal();

  double _sellerBalance = 15000.0;
  double _driverBalance = 2450.0;

  final double driverFee = 350.0;

  // Driver bank account (null = not added yet)
  DriverBankAccount? _driverBankAccount;
  DriverBankAccount? get driverBankAccount => _driverBankAccount;

  // Sri Lankan banks list
  static const List<String> sriLankanBanks = [
    'Bank of Ceylon (BOC)',
    'People\'s Bank',
    'Commercial Bank of Ceylon',
    'Hatton National Bank (HNB)',
    'Sampath Bank',
    'Nations Trust Bank (NTB)',
    'Seylan Bank',
    'Union Bank',
    'DFCC Bank',
    'Cargills Bank',
    'Amãna Bank',
    'MCB Bank',
    'Pan Asia Bank',
    'Sanasa Development Bank',
    'National Development Bank (NDB)',
  ];

  final List<Transaction> _sellerTransactions = [
    Transaction(
      id: 'tx_1084_pay',
      title: 'Customer Payment (Order #1084)',
      orderId: '1084',
      customerName: 'Nethmi Vihanga',
      amount: 5200.0,
      grossAmount: 5200.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isCredit: true,
      type: TransactionType.customerPayment,
    ),
    Transaction(
      id: 'tx_1084_cut',
      title: 'Delivery Fee Transferred to Driver (Order #1084)',
      orderId: '1084',
      customerName: 'Driver: Kasun P.',
      amount: 350.0,
      grossAmount: 0.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      isCredit: false,
      type: TransactionType.deliveryDeduction,
    ),
    Transaction(
      id: 'tx_1081_pay',
      title: 'Customer Payment (Order #1081)',
      orderId: '1081',
      customerName: 'Dinusha Perera',
      amount: 4500.0,
      grossAmount: 4500.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isCredit: true,
      type: TransactionType.customerPayment,
    ),
    Transaction(
      id: 'tx_1081_cut',
      title: 'Delivery Fee Transferred to Driver (Order #1081)',
      orderId: '1081',
      customerName: 'Driver: Amila K.',
      amount: 350.0,
      grossAmount: 0.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      isCredit: false,
      type: TransactionType.deliveryDeduction,
    ),
    Transaction(
      id: 'tx_1078_pay',
      title: 'Customer Payment (Order #1078)',
      orderId: '1078',
      customerName: 'Kavindi Silva',
      amount: 6350.0,
      grossAmount: 6350.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isCredit: true,
      type: TransactionType.customerPayment,
    ),
    Transaction(
      id: 'tx_1078_cut',
      title: 'Delivery Fee Transferred to Driver (Order #1078)',
      orderId: '1078',
      customerName: 'Driver: Saman R.',
      amount: 350.0,
      grossAmount: 0.0,
      deliveryFee: 350.0,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      isCredit: false,
      type: TransactionType.deliveryDeduction,
    ),
  ];

  final List<Transaction> _driverTransactions = [
    Transaction(
      id: 'dtx_1',
      title: 'Delivery Charge Received – Order #1084',
      orderId: '1084',
      customerName: 'Meesha Plant Nursery',
      amount: 350,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isCredit: true,
      type: TransactionType.deliveryDeduction,
    ),
    Transaction(
      id: 'dtx_2',
      title: 'Delivery Charge Received – Order #1081',
      orderId: '1081',
      customerName: 'Green Terra Organics',
      amount: 350,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      isCredit: true,
      type: TransactionType.deliveryDeduction,
    ),
    Transaction(
      id: 'dtx_3',
      title: 'Auto Bank Transfer – BOC ****8923',
      orderId: 'TRF-9021',
      customerName: 'Bank Transfer',
      amount: 1000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isCredit: false,
      type: TransactionType.bankTransfer,
    ),
    Transaction(
      id: 'dtx_4',
      title: 'Delivery Charge Received – Order #1078',
      orderId: '1078',
      customerName: 'Botanica LK',
      amount: 350,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isCredit: true,
      type: TransactionType.deliveryDeduction,
    ),
  ];

  double get sellerBalance => _sellerBalance;
  double get driverBalance => _driverBalance;

  List<Transaction> get sellerTransactions => _sellerTransactions;
  List<Transaction> get driverTransactions => _driverTransactions;

  // Computed driver stats
  double get totalDriverEarnings =>
      _driverTransactions.where((t) => t.isCredit).fold(0, (s, t) => s + t.amount);
  double get totalDriverTransferred =>
      _driverTransactions.where((t) => !t.isCredit).fold(0, (s, t) => s + t.amount);
  int get totalDriverDeliveries =>
      _driverTransactions.where((t) => t.type == TransactionType.deliveryDeduction && t.isCredit).length;

  // Computed seller metrics
  double get totalGrossCustomerPayments {
    return _sellerTransactions
        .where((t) => t.type == TransactionType.customerPayment)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalDeliveryFeesDeducted {
    return _sellerTransactions
        .where((t) => t.type == TransactionType.deliveryDeduction)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalWithdrawals {
    return _sellerTransactions
        .where((t) => t.type == TransactionType.withdrawal)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ── Bank Account Management ──

  void saveDriverBankAccount(DriverBankAccount account) {
    _driverBankAccount = account.copyWith(isVerified: true);
    notifyListeners();
  }

  void removeDriverBankAccount() {
    _driverBankAccount = null;
    notifyListeners();
  }

  // ── Financial Operations ──

  // 1. Customer pays -> full amount credited to seller
  void processCustomerPayment(double amount, String orderId, {String customerName = 'Customer'}) {
    _sellerBalance += amount;
    _sellerTransactions.insert(0, Transaction(
      id: 'tx_${orderId}_pay_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Customer Payment (Order #$orderId)',
      orderId: orderId,
      customerName: customerName,
      amount: amount,
      grossAmount: amount,
      deliveryFee: driverFee,
      date: DateTime.now(),
      isCredit: true,
      type: TransactionType.customerPayment,
    ));
    notifyListeners();
  }

  // 2. Seller transfers delivery charge to driver (when driver picks up)
  bool transferDeliveryChargeToDriver(String orderId, {String driverName = 'Driver', String sellerName = 'Seller'}) {
    if (_sellerBalance < driverFee) return false;

    // Deduct from seller
    _sellerBalance -= driverFee;
    _sellerTransactions.insert(0, Transaction(
      id: 'tx_${orderId}_cut_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Delivery Fee Transferred to Driver (Order #$orderId)',
      orderId: orderId,
      customerName: 'Driver: $driverName',
      amount: driverFee,
      grossAmount: 0.0,
      deliveryFee: driverFee,
      date: DateTime.now(),
      isCredit: false,
      type: TransactionType.deliveryDeduction,
    ));

    // Credit to driver's account balance
    _driverBalance += driverFee;
    _driverTransactions.insert(0, Transaction(
      id: 'dtx_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Delivery Charge Received – Order #$orderId',
      orderId: orderId,
      customerName: sellerName,
      amount: driverFee,
      date: DateTime.now(),
      isCredit: true,
      type: TransactionType.deliveryDeduction,
    ));

    notifyListeners();
    return true;
  }

  // Legacy alias
  void assignOrderToDriver(String orderId, {String driverName = 'Driver'}) {
    transferDeliveryChargeToDriver(orderId, driverName: driverName);
  }

  // 3. Seller withdraws funds to bank
  bool withdrawSellerFunds(double amount, {String bankName = 'Commercial Bank', String accountNumber = '**** 8842'}) {
    if (amount <= _sellerBalance && amount > 0) {
      _sellerBalance -= amount;
      _sellerTransactions.insert(0, Transaction(
        id: 'tx_wd_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Withdrawal to $bankName ($accountNumber)',
        orderId: 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        customerName: 'Seller Payout',
        amount: amount,
        date: DateTime.now(),
        isCredit: false,
        type: TransactionType.withdrawal,
      ));
      notifyListeners();
      return true;
    }
    return false;
  }

  // 4. Driver balance auto-transferred to bank (no manual cashout — happens automatically)
  void autoTransferDriverBalance(String orderId, double amount) {
    if (amount > _driverBalance) return;
    _driverBalance -= amount;
    final bankDisplay = _driverBankAccount != null
        ? '${_driverBankAccount!.bankName} ${_driverBankAccount!.maskedAccount}'
        : 'Linked Bank Account';
    _driverTransactions.insert(0, Transaction(
      id: 'dtx_atrf_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Auto Bank Transfer – $bankDisplay',
      orderId: 'TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerName: 'Bank Transfer',
      amount: amount,
      date: DateTime.now(),
      isCredit: false,
      type: TransactionType.bankTransfer,
    ));
    notifyListeners();
  }

  // Legacy (kept for compatibility)
  void withdrawDriverFunds(double amount) => autoTransferDriverBalance('LEGACY', amount);
}

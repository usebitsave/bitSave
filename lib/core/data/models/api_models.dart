/// BitSave Staging API Models

class BitSaveAuthResponse {
  final String token;

  BitSaveAuthResponse({required this.token});

  factory BitSaveAuthResponse.fromJson(Map<String, dynamic> json) {
    return BitSaveAuthResponse(
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'token': token};
}

class BitSaveUserProfile {
  final String id;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BitSaveUserProfile({
    required this.id,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory BitSaveUserProfile.fromJson(Map<String, dynamic> json) {
    return BitSaveUserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class BitSaveSavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String targetAmountNgn;
  final String savedAmountNgn;
  final String category;
  final String contributionFrequency;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BitSaveSavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountNgn,
    this.savedAmountNgn = '0.00',
    this.category = 'General',
    this.contributionFrequency = 'Monthly',
    this.deadline,
    this.createdAt,
    this.updatedAt,
  });

  double get targetAmountDouble => double.tryParse(targetAmountNgn) ?? 0.0;
  double get savedAmountDouble => double.tryParse(savedAmountNgn) ?? 0.0;
  double get progressPercent => targetAmountDouble > 0
      ? (savedAmountDouble / targetAmountDouble).clamp(0.0, 1.0)
      : 0.0;

  factory BitSaveSavingsGoal.fromJson(Map<String, dynamic> json) {
    return BitSaveSavingsGoal(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      targetAmountNgn: json['target_amount_ngn']?.toString() ?? '0.00',
      savedAmountNgn: json['saved_amount_ngn']?.toString() ??
          json['current_amount_ngn']?.toString() ??
          '0.00',
      category: json['category'] ?? 'General',
      contributionFrequency: json['contribution_frequency'] ?? 'Monthly',
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount_ngn': targetAmountNgn,
      'saved_amount_ngn': savedAmountNgn,
      'category': category,
      'contribution_frequency': contributionFrequency,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class BitSaveWallet {
  final String id;
  final String userId;
  final String walletType;
  final String network;
  final String walletIdentifier;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BitSaveWallet({
    required this.id,
    required this.userId,
    required this.walletType,
    required this.network,
    required this.walletIdentifier,
    this.createdAt,
    this.updatedAt,
  });

  factory BitSaveWallet.fromJson(Map<String, dynamic> json) {
    return BitSaveWallet(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      walletType: json['wallet_type'] ?? '',
      network: json['network'] ?? '',
      walletIdentifier: json['wallet_identifier'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_type': walletType,
      'network': network,
      'wallet_identifier': walletIdentifier,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class BitSaveQuote {
  final String id;
  final String userId;
  final String fiatAmount;
  final String fiatCurrency;
  final int btcAmountSats;
  final String exchangeRate;
  final String fee;
  final String provider;
  final String providerQuoteId;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  BitSaveQuote({
    required this.id,
    required this.userId,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.btcAmountSats,
    required this.exchangeRate,
    required this.fee,
    required this.provider,
    required this.providerQuoteId,
    this.expiresAt,
    this.createdAt,
  });

  factory BitSaveQuote.fromJson(Map<String, dynamic> json) {
    return BitSaveQuote(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fiatAmount: json['fiat_amount']?.toString() ?? '0.00',
      fiatCurrency: json['fiat_currency'] ?? 'NGN',
      btcAmountSats: (json['btc_amount_sats'] as num?)?.toInt() ?? 0,
      exchangeRate: json['exchange_rate']?.toString() ?? '0.00',
      fee: json['fee']?.toString() ?? '0.00',
      provider: json['provider'] ?? '',
      providerQuoteId: json['provider_quote_id'] ?? '',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fiat_amount': fiatAmount,
      'fiat_currency': fiatCurrency,
      'btc_amount_sats': btcAmountSats,
      'exchange_rate': exchangeRate,
      'fee': fee,
      'provider': provider,
      'provider_quote_id': providerQuoteId,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class BitSaveTransaction {
  final String id;
  final String userId;
  final String? goalId;
  final String? quoteId;
  final String type;
  final String status;
  final String fiatAmount;
  final String fiatCurrency;
  final int btcAmountSats;
  final String provider;
  final String providerTransactionId;
  final String? idempotencyKey;
  final String? paymentMethod;
  final String? blockchainTxId;
  final String? explorerUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BitSaveTransaction({
    required this.id,
    required this.userId,
    this.goalId,
    this.quoteId,
    required this.type,
    required this.status,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.btcAmountSats,
    required this.provider,
    required this.providerTransactionId,
    this.idempotencyKey,
    this.paymentMethod,
    this.blockchainTxId,
    this.explorerUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory BitSaveTransaction.fromJson(Map<String, dynamic> json) {
    final txId = json['blockchain_tx_id'] ?? json['txid'];
    return BitSaveTransaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      goalId: json['goal_id'],
      quoteId: json['quote_id'],
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      fiatAmount: json['fiat_amount']?.toString() ?? '0.00',
      fiatCurrency: json['fiat_currency'] ?? 'NGN',
      btcAmountSats: (json['btc_amount_sats'] as num?)?.toInt() ?? 0,
      provider: json['provider'] ?? '',
      providerTransactionId: json['provider_transaction_id'] ?? '',
      idempotencyKey: json['idempotency_key'],
      paymentMethod: json['payment_method'] ?? 'MavaPay / Lightning',
      blockchainTxId: txId,
      explorerUrl: json['explorer_url'] ??
          (txId != null && txId.toString().isNotEmpty
              ? 'https://mempool.space/tx/$txId'
              : null),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_id': goalId,
      'quote_id': quoteId,
      'type': type,
      'status': status,
      'fiat_amount': fiatAmount,
      'fiat_currency': fiatCurrency,
      'btc_amount_sats': btcAmountSats,
      'provider': provider,
      'provider_transaction_id': providerTransactionId,
      'idempotency_key': idempotencyKey,
      'payment_method': paymentMethod,
      'blockchain_tx_id': blockchainTxId,
      'explorer_url': explorerUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

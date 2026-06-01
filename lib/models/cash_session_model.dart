class CashSessionModel {
  const CashSessionModel({
    required this.id,
    required this.sessionName,
    required this.businessDate,
    required this.startingBalanceCents,
    required this.status,
    required this.createdAt,
    required this.closedAt,
  });

  final int id;
  final String sessionName;
  final String businessDate;
  final int startingBalanceCents;
  final String status;
  final DateTime createdAt;
  final DateTime? closedAt;

  bool get isOpen => status == 'open';
}

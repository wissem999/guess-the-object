class TurnDto {
  final String playerId;
  final String? question;
  final String? answer;
  final int timestamp;

  const TurnDto({
    required this.playerId,
    this.question,
    this.answer,
    required this.timestamp,
  });

  factory TurnDto.fromJson(Map<String, dynamic> json) {
    return TurnDto(
      playerId: json['playerId'] as String,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      timestamp: (json['timestamp'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        if (question != null) 'question': question,
        if (answer != null) 'answer': answer,
        'timestamp': timestamp,
      };
}

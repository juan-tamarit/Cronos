class Session{
  final int? id;
  final int activityId;
  final DateTime start;
  final DateTime end;
  final int durationSecs;
  final int accumulatedSecs;

  Session({
    this.id,
    required this.activityId,
    required this.start,
    required this.end,
    required this.durationSecs,
    required this.accumulatedSecs
  });

  Map <String, dynamic> toMap(){
    return{
      'id':id,
      'activityId':activityId,
      'start':start.millisecondsSinceEpoch,
      'end':end.millisecondsSinceEpoch,
      'durationSecs':durationSecs,
      'accumulatedSecs': accumulatedSecs
    };
  }
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      activityId: map['activityId'],
      start: DateTime.fromMillisecondsSinceEpoch(int.parse(map['start'])),
      end: DateTime.fromMillisecondsSinceEpoch(int.parse(map['end'])),
      durationSecs: map['durationSecs'],
      accumulatedSecs: map['accumulatedSecs']
    );
  }
}
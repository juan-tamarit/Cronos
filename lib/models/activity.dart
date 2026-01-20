class Activity {
  final int? id;
  final String name;
  final String description;
  final int objetiveMinutes;
  final List<int> daysWeek;
  final bool active;

  Activity({
    this.id,
    required this.name,
    this.description='',
    required this.objetiveMinutes,
    required this.daysWeek,
    this.active=true
  });

  Map <String, dynamic> toMap(){
    return{
      'id':id,
      'name':name,
      'description':description,
      'objetiveMinutes':objetiveMinutes,
      'daysWeek':daysWeek.join(','),
      'active':active ? 1: 0
    };
  }
  factory Activity.fromMap(Map<String,dynamic>map){
    return Activity(
      id:map['id'],
      name: map['name'],
      description: map['description']??'',
      objetiveMinutes: map['objetiveMinutes'],
      daysWeek: (map['daysWeek'] as String).isEmpty
        ? <int>[]
        :(map['daysWeek'] as String).split(',').map((e) =>int.parse(e)).toList(),
      active: map['active']==1
    );
  }
  Activity copyWith({String? name,String? description,int? objetiveMinutes,List<int>? daysWeek,bool? active}) {
    return Activity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      objetiveMinutes: objetiveMinutes ?? this.objetiveMinutes,
      daysWeek: daysWeek ?? List.from(this.daysWeek),
      active: active ?? this.active
    );
  }
}
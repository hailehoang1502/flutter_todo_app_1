class ToDoItem {
  String title;
  bool isFinished;

  ToDoItem({required this.title, this.isFinished = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isFinished': isFinished,
  };

  factory ToDoItem.fromJson(Map<String, dynamic> json) {
    return ToDoItem(
      title: json['title'],
      isFinished: json['isFinished'],
    );
  }
}
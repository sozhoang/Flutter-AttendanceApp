// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ListClass extends StatefulWidget {
  const ListClass({Key? key}) : super(key: key);

  @override
  _ListClassState createState() => _ListClassState();
}

class _ListClassState extends State<ListClass> {
  final List<Map<String, dynamic>> _allUsers = [
    {"id": 1, "name": "Nguyen Duc Anh", "mssv": 20204811},
    {"id": 2, "name": "Nguyen Viet Anh", "mssv": 20200039},
    {"id": 3, "name": "Nguyen Bao Anh", "mssv": 20206110},
    {"id": 4, "name": "Nguyen Sy Dat", "mssv": 20180036},
    {"id": 5, "name": "Ho Van Dien", "mssv": 20160611},
    {"id": 6, "name": "Nguyen Tai Quang Dinh", "mssv": 20200092},
    {"id": 7, "name": "Ha Minh Dung", "mssv": 20200096},
    {"id": 8, "name": "Nguyen Sy Huan", "mssv": 20200253},
    {"id": 9, "name": "Dang Nhat Huy", "mssv": 20200271},
    {"id": 10, "name": "Nguyen Dinh Huy", "mssv": 20200277},
    {"id": 11, "name": "Nguyen Trinh Khang", "mssv": 20200313},
    {"id": 12, "name": "Le Trung Kien", "mssv": 20195893},
    {"id": 13, "name": "Mac Anh Kiet", "mssv": 20200307},
    {"id": 14, "name": "Phan Thanh Long", "mssv": 20200369},
    {"id": 15, "name": "Vu Hoai Nam", "mssv": 20190059},
    {"id": 16, "name": "Nguyen Van Nghiem", "mssv": 20206206},
    {"id": 17, "name": "Nguyen Hoang Nhat", "mssv": 20204772},
    {"id": 18, "name": "Le Hai Phong", "mssv": 20200460},
    {"id": 19, "name": "Nguyen Duc Quan", "mssv": 20200505},
    {"id": 20, "name": "Nguyen Hoang Son", "mssv": 20206165},
    {"id": 21, "name": "Do Dieu Thao", "mssv": 20200599},
    {"id": 22, "name": "Dang Sy Tien", "mssv": 20200537},
    {"id": 23, "name": "Dang Tran Tien", "mssv": 20195927},
    {"id": 24, "name": "Tran Thanh Tung", "mssv": 20206184},
  ];

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color.fromARGB(255, 247, 25, 9),
        middle: Text(
          'Class Deltails',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (context, index) => Card(
                key: ValueKey(_allUsers[index]["id"]),
                color: Colors.blue,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Text(
                    _allUsers[index]["id"].toString(),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  title: Text(_allUsers[index]['name'],
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('${_allUsers[index]["mssv"].toString()}',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

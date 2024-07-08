import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CheckList extends StatefulWidget {
  const CheckList({Key? key, required this.allUsers}) : super(key: key);
  final List<Map<String, dynamic>> allUsers;
  @override
  _CheckListState createState() => _CheckListState();
}

class _CheckListState extends State<CheckList> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color.fromARGB(255, 247, 25, 9),
        middle: Text(
          'Attendence List',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: widget.allUsers.length,
              itemBuilder: (context, index) => Card(
                key: ValueKey(widget.allUsers[index]["id"]),
                color: Colors.blue,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  // leading: Text(
                  //   widget.allUsers[index]["id"].toString(),
                  //   style: const TextStyle(fontSize: 10, color: Colors.white),
                  // ),
                  title: Text(widget.allUsers[index]['name'],
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('${widget.allUsers[index]["id"].toString()}',
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      widget.allUsers[index]['present'].toString() == 'true'
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.red,
                            )
                          : Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                  onTap: () {
                    setState(() {
                      if (widget.allUsers[index]['present'].toString() ==
                          'true') {
                        widget.allUsers[index]['present'] = 'false';
                      } else {
                        widget.allUsers[index]['present'] = 'true';
                      }
                    });
                  },
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

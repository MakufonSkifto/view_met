import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'detailsArt.dart';
import 'favorites.dart';


class SearchPage extends StatefulWidget {
  SearchPage({required this.text});

  final String text;
  //final Map results;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {


  fetchData(String id) async {
    var request = await http.get(Uri.parse("https://collectionapi.metmuseum.org/public/collection/v1/objects/$id"));

    return request.body;
  }

  fetchSearchData(String query) async {
    var request = await http.get(Uri.parse("https://collectionapi.metmuseum.org/public/collection/v1/search?q=$query"));

    return request.body;
  }

  _writeData(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("favorites");

    list!.add(id);

    prefs.setStringList("favorites", list);
  }

  bool visibility = false;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    var text = widget.text;


    builder(String query) {
      visibility = true;

      return FutureBuilder(
        future: fetchSearchData(query),
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: CircularProgressIndicator(),
            );
          }
          var dataSearch = jsonDecode(snapshot.data.toString());

          if (dataSearch["total"] == 0) {
            return Align(
              alignment: Alignment.center,
              child: Text("No results found!", style: TextStyle(fontSize: 15, color: Colors.black)),
            );
          }

          visibility = true;
          count = dataSearch["total"];

          return ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: dataSearch["total"],
            itemBuilder: (BuildContext context, int index) {
              var id = dataSearch["objectIDs"][index];

              return FutureBuilder(
                future: fetchData(id.toString()),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  var data = jsonDecode(snapshot.data.toString());

                  var leading;
                  var artist;

                  try {
                    try {
                      if (data["primaryImageSmall"] == "") {
                        leading = Icon(Icons.dangerous);
                      }
                      else {
                        leading = Image.network(data["primaryImageSmall"]);
                      }
                    }
                    on Exception {
                      leading = Icon(Icons.dangerous);
                    }

                    if (data["artistDisplayName"]== "") {
                      artist = "Unknown";
                    }
                    else {
                      artist = data["artistDisplayName"];
                    }
                  }
                  on TypeError {
                    return SizedBox.shrink();
                  }


                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: leading,
                          title: Text(data["title"]),
                          subtitle: Text(
                            "by $artist",
                            style: TextStyle(color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                        ButtonBar(
                          alignment: MainAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DetailsPage()),
                                );
                              },
                              child: Text("Details", style: TextStyle(color: Color(0xFF6200EE))),
                            ),
                            TextButton(
                              onPressed: () {
                                _writeData(data["objectID"].toString());
                              },
                              child: Text("Add to Favorites", style: TextStyle(color: Color(0xFF6200EE))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              Text("Search results for $text", style: TextStyle(fontSize: 18, color: Colors.black)),
              Visibility(
                visible: visibility,
                child: Text("$count results found", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
              SizedBox(
                height: 700,
                child: Expanded(
                  child: builder(text)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

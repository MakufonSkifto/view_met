import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'detailsArt.dart';


class AllPage extends StatefulWidget {
  @override
  _AllPageState createState() => _AllPageState();
}

class _AllPageState extends State<AllPage> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  fetchData(String id) async {
    var request = await http.get(Uri.parse("https://collectionapi.metmuseum.org/public/collection/v1/objects/$id"));

    return request.body;
  }

  fetchAllData() async {
    var request = await http.get(Uri.parse("https://collectionapi.metmuseum.org/public/collection/v1/objects"));

    return request.body;
  }

  _writeData(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("favorites");

    if (list!.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("This item is already in your favorites!"),
          )
      );
    }
    else {
      list.add(id);

      prefs.setStringList("favorites", list);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added to your favorites list"),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _deleteData(id);
              },
            ),
          )
      );
    }
  }

  _deleteData(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("favorites");

    list!.remove(id);

    prefs.setStringList("favorites", list);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed from your favorites list"),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              _writeData(id);
            },
          ),
        )
    );
  }

  builder() {
    return FutureBuilder(
      future: fetchAllData(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        var data = jsonDecode(snapshot.data.toString());

        return ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: data["total"],
          itemBuilder: (BuildContext context, int index) {
            var id = data["objectIDs"][index];

            return FutureBuilder(
              future: fetchData(id.toString()),
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                var data = jsonDecode(snapshot.data.toString());

                var leading;
                var artist;

                try {
                  try {
                    if (data["primaryImageSmall"] == "") {
                      leading = Icon(Icons.dangerous, color: Colors.red);
                    }
                    else {
                      leading = Image.network(data["primaryImageSmall"]);
                    }
                  }
                  on Exception {
                    leading = Icon(Icons.dangerous, color: Colors.red);
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
                        title: Text(data["title"], style: GoogleFonts.merriweatherSans()),
                        subtitle: Text(
                          "by $artist",
                          style: GoogleFonts.merriweatherSans(color: Colors.black.withOpacity(0.6)),
                        ),
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetailsPage(id: data["objectID"].toString())),
                              );
                            },
                            child: Text("Details", style: GoogleFonts.merriweatherSans(color: Colors.red)),
                          ),
                          TextButton(
                            onPressed: () {
                              _writeData(data["objectID"].toString());
                            },
                            child: Text("Add to Favorites", style: GoogleFonts.merriweatherSans(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All"),
        iconTheme: IconThemeData(
            color: Colors.white
        ),
      ),
      body: ListView(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Text("All of the items in MET (475.000+)", style: GoogleFonts.merriweatherSans(fontSize: 18, color: Colors.black)),
          ),
          Scrollbar(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: builder()
            ),
          )
        ],
      )
    );
  }
}

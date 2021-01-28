import 'package:czech_fonts_validator/blocs/bloc.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/pages/font_validation_page.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final FontBloc fontBloc;

  const ResultPage({
    Key key,
    @required this.fontBloc,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.fontBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      body: buildListStream(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
      ),
    );
  }

  StreamBuilder buildListStream() {
    return StreamBuilder<List<CzechFont>>(
      stream: widget.fontBloc.fontStream,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final czechFontsList = snapshot.data;

          return ListView.separated(
            itemCount: czechFontsList.length,
            separatorBuilder: (_, int index) => Divider(thickness: 2.0),
            itemBuilder: (context, index) {
              final item = czechFontsList[index];
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Row(
                        children: [
                          Text(
                            item.fontName,
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(width: 45.0),
                          Text(
                            item.confidence.toString(),
                            style: TextStyle(color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      czechTestPhrase,
                      style: getFontTextStyle(item.fontName, fontSize: 26.0),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return Text('---');
      },
    );
  }
}

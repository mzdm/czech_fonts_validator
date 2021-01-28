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
  final selectedFilter = new ValueNotifier<Confidence>(Confidence.UNKWN);

  static const drawerMenuActions = <String>{
    'Copy plain data',
    'Download as JSON',
  };

  void _drawerMenu(String value) {
    if (value == drawerMenuActions.elementAt(0)) {
      print(drawerMenuActions.elementAt(0));
    } else {
      print(drawerMenuActions.elementAt(1));
    }
  }

  @override
  void dispose() {
    widget.fontBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildListStream(),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text('Results'),
      actions: <Widget>[
        PopupMenuButton<Confidence>(
          icon: Icon(Icons.filter_alt),
          itemBuilder: (context) {
            return List<PopupMenuEntry<Confidence>>.generate(
              Confidence.values.length,
              (index) {
                return PopupMenuItem(
                  value: Confidence.values[index],
                  child: AnimatedBuilder(
                    child: Text(Confidence.values[index].toString()),
                    animation: selectedFilter,
                    builder: (context, child) {
                      return RadioListTile<Confidence>(
                        value: Confidence.values[index],
                        groupValue: selectedFilter.value,
                        title: child,
                        onChanged: (newVal) => selectedFilter.value = newVal,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        SizedBox(width: 7.0),
        PopupMenuButton<String>(
          icon: Icon(Icons.menu),
          onSelected: _drawerMenu,
          itemBuilder: (context) => drawerMenuActions.map(
            (menuAction) {
              return PopupMenuItem<String>(
                value: menuAction,
                child: Text(menuAction),
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  Widget buildListStream() {
    return ValueListenableBuilder<Confidence>(
      valueListenable: selectedFilter,
      builder: (context, value, child) {
        return StreamBuilder<List<CzechFont>>(
          stream: widget.fontBloc.getFilteredStream(value),
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              final czechFontsList = snapshot.data;

              return czechFontsList.isEmpty
                  ? Center(child: Text('No fonts found in: $value'))
                  : ListView.separated(
                      itemCount: czechFontsList.length,
                      separatorBuilder: (_, __) => Divider(thickness: 2.0),
                      itemBuilder: (_, index) {
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
                              displayComparisonText(baseTestPhrase, item),
                              displayComparisonText(czechTestPhrase, item),
                              // displayComparisonText(czechTestPhraseFull, item),
                            ],
                          ),
                        );
                      },
                    );
            }

            return Text('---');
          },
        );
      },
    );
  }

  Text displayComparisonText(String phrase, CzechFont font) {
    return Text(
      phrase,
      style: getFontTextStyle(font.fontName, fontSize: 26.0),
    );
  }
}

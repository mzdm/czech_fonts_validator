import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/helpers/validation_helper.dart';
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
  final ValidationHelper valHelper = ValidationHelper();

  final selectedFilter = new ValueNotifier<Confidence>(Confidence.UNKWN);

  Confidence get filterState => selectedFilter?.value;

  void changeFilterState(Confidence newVal) => selectedFilter?.value = newVal;

  static const drawerMenuActions = <String>{
    'Copy plain fonts with high conf.',
    'Download all as JSON',
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
    selectedFilter.dispose();
    widget.fontBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Source Code',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {},
          ),
          SizedBox(width: 15.0),
          buildFilterPopupMenu(),
          SizedBox(width: 7.0),
          buildPopupMenu(),
        ],
      ),
      body: buildListStream(),
    );
  }

  PopupMenuButton<Confidence> buildFilterPopupMenu() {
    return PopupMenuButton<Confidence>(
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
                builder: (_, child) {
                  return RadioListTile<Confidence>(
                    value: Confidence.values[index],
                    groupValue: filterState,
                    title: child,
                    onChanged: changeFilterState,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  PopupMenuButton<String> buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu),
      onSelected: _drawerMenu,
      itemBuilder: (_) => drawerMenuActions.map(
        (menuAction) {
          return PopupMenuItem<String>(
            value: menuAction,
            child: Text(menuAction),
          );
        },
      ).toList(),
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
                              displayText(ValidationHelper.latinPhrase, item),
                              displayText(ValidationHelper.czechPhrase, item),
                              // displayText(ValidationHelper.czechPhraseFull, item),
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

  Text displayText(String phrase, CzechFont font) {
    return Text(
      phrase,
      style: valHelper.getFontTextStyle(font.fontName, fontSize: 26.0),
    );
  }
}

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/helpers/validation_helper.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
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
          buildSrcButton(),
          SizedBox(width: 20.0),
          buildFilterPopupMenu(),
          SizedBox(width: 10.0),
          buildPopupMenu(),
        ],
      ),
      body: buildListStream(),
    );
  }

  Widget buildSrcButton() {
    return InkWell(
      child: Center(
        child: Text(
          'SOURCE CODE',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      onTap: () {},
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
      builder: (_, value, __) {
        return StreamBuilder<List<CzechFont>>(
          stream: widget.fontBloc.getFilteredStream(value),
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              final czechFontsList = snapshot.data;

              return czechFontsList.isEmpty
                  ? Center(child: Text('No fonts found in: $value'))
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: czechFontsList.length,
                        separatorBuilder: (_, __) => Divider(thickness: 2.0),
                        itemBuilder: (_, i) => buildListItem(czechFontsList[i]),
                      ),
                    );
            }

            return Text('---');
          },
        );
      },
    );
  }

  Widget buildListItem(CzechFont item) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              children: [
                SelectableText(
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
          displayPhraseText(ValidationHelper.latinPhrase, item),
          displayPhraseText(ValidationHelper.czechPhrase, item),
          // displayText(ValidationHelper.czechPhraseFull, item),
        ],
      ),
    );
  }

  Text displayPhraseText(String phrase, CzechFont font) {
    return Text(
      phrase,
      style: valHelper.getFontTextStyle(font.fontName, fontSize: 26.0),
    );
  }
}

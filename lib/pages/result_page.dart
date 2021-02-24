import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/helpers/validation_helper.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/pages/font_validation_page.dart';
import 'package:czech_fonts_validator/utils/utils.dart'
    if (dart.library.html) 'package:czech_fonts_validator/utils/web_utils.dart'
    as u;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _drawerMenuActions = <String>{
  'Copy plain fonts in this category',
  if (kIsWeb) 'Download all as JSON',
};

class ResultPage extends StatefulWidget {
  final FontBloc fontBloc;

  const ResultPage({
    Key? key,
    required this.fontBloc,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final u.Utils utils = u.Utils();

  FontBloc get fontBloc => widget.fontBloc;

  List<CzechFont> get allFontsList => fontBloc.allValidatedFontsList;

  final selectedFilter = new ValueNotifier<Confidence>(Confidence.HIGHEST);

  Confidence get filterState => selectedFilter.value;

  void changeFilterState(Confidence newVal) => selectedFilter.value = newVal;

  void onDrawerAction(String item) {
    if (item == _drawerMenuActions.elementAt(0)) {
      // Copy plain fonts in this Confidence category
      utils.copyPlainData(context, data: allFontsList, confidence: filterState);
    } else {
      // Download all as JSON
      utils.downloadDataAsJson(context, data: allFontsList);
    }
  }

  @override
  void dispose() {
    selectedFilter.dispose();
    fontBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        actions: <Widget>[
          buildSrcTextButton(context),
          SizedBox(width: 20.0),
          buildFilterPopupMenu(),
          SizedBox(width: 10.0),
          buildDrawerMenu(),
        ],
      ),
      body: buildListStream(),
      floatingActionButton: buildFAB(context),
    );
  }

  Widget buildSrcTextButton(BuildContext context) {
    return InkWell(
      onTap: () => utils.launchUrl(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0),
          child: Text(
            'SOURCE CODE',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  PopupMenuButton<Confidence> buildFilterPopupMenu() {
    return PopupMenuButton<Confidence>(
      tooltip: 'Filter',
      icon: Icon(Icons.filter_alt),
      itemBuilder: (_) {
        return List<PopupMenuEntry<Confidence>>.generate(
          Confidence.values.length,
          (i) {
            return PopupMenuItem(
              value: Confidence.values[i],
              child: AnimatedBuilder(
                child: Text(Confidence.values[i].toString()),
                animation: selectedFilter,
                builder: (_, child) {
                  return RadioListTile<Confidence>(
                    value: Confidence.values[i],
                    groupValue: filterState,
                    title: child,
                    onChanged: (value) => changeFilterState(value!),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  PopupMenuButton<String> buildDrawerMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu),
      onSelected: onDrawerAction,
      itemBuilder: (_) => _drawerMenuActions.map(
        (value) {
          return PopupMenuItem<String>(
            value: value,
            child: Text(value),
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
          stream: fontBloc.getFilteredStream(value),
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              final czFontsList = snapshot.data!;
              final total = czFontsList.length;

              return czFontsList.isEmpty
                  ? Center(child: Text('No fonts found in: $value'))
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: total,
                        separatorBuilder: (_, __) => Divider(thickness: 2.0),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return buildInitialListItem(czFontsList[i], total);
                          }
                          return buildListItem(czFontsList[i]);
                        },
                      ),
                    );
            }

            return Text('---');
          },
        );
      },
    );
  }

  Widget buildInitialListItem(CzechFont czechFont, int length) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Text(
              'Total fonts: $length',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        buildListItem(czechFont),
      ],
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
          // displayPhraseText(ValidationHelper.czechPhrase, item),
          displayPhraseText(ValidationHelper.czechPhraseFull, item),
        ],
      ),
    );
  }

  Text displayPhraseText(String phrase, CzechFont font) {
    final valHelper = ValidationHelper();
    return Text(
      phrase,
      style: valHelper.getFontTextStyle(font.fontName, fontSize: 26.0),
    );
  }

  FloatingActionButton buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FontValidationPage()),
        );
      },
      tooltip: 'Revalidate fonts',
      child: Icon(Icons.refresh),
    );
  }
}

//import 'dart:math';
// import 'dart:ui';
// import 'dart:io';
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_nord_theme/flutter_nord_theme.dart';

import 'package:safenotes/main.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/widgets/search_widget.dart';
// import 'package:safenotes/model/import_file_parser.dart';
import 'package:safenotes/views/add_edit_note.dart';
import 'package:safenotes/widgets/theme_toggle_widget.dart';
import 'package:safenotes/views/note_view.dart';
import 'package:safenotes/widgets/note_card.dart';
import 'package:safenotes/dialogs/change_passphrase.dart';
// import 'package:safenotes/dialogs/import_passphrase_dialog.dart';
import 'package:safenotes/dialogs/toggle_undecrypt_flag.dart';
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/dialogs/export_methord.dart';
import 'package:safenotes/models/file_handler.dart';
import 'package:safenotes/dialogs/file_import.dart';
import 'package:safenotes/utils/snack_message.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late List<SafeNote> notes;
  late List<SafeNote> allnotes;
  bool isLoading = false;
  String query = '';
  bool isHiddenImport = true;
  final importPassphraseController = TextEditingController();
  bool isLogout = false;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  @override
  void dispose() {
    // Bcz if user has log in for undecrypted data then they can move back and log in again so not closing data base
    if (!UnDecryptedLoginControl.getAllowLogUnDecrypted() && !isLogout)
      NotesDatabase.instance.close();

    super.dispose();
  }

  Future _refreshNotes() async {
    setState(() => isLoading = true);
    // storing copy of notes in allnotes so that it does not change while doing search
    this.allnotes =
        this.notes = await NotesDatabase.instance.decryptReadAllNotes();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnDecryptedPeekOn =
        UnDecryptedLoginControl.getNoDecryptionFlag();
    final String officialAppName = AppInfo.getAppName();
    final double appNameFontSize = 24.0;

    return GestureDetector(
      //onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        drawer: isUnDecryptedPeekOn ? null : _buildDrawer(context),
        appBar: AppBar(
            title: Text(officialAppName,
                style: TextStyle(fontSize: appNameFontSize))),
        body: Column(
          children: <Widget>[
            _buildSearch(),
            _handleAndBuildNotes(),
          ],
        ),
        floatingActionButton:
            isUnDecryptedPeekOn ? null : _addANewNoteButton(context),
      ),
    );
  }

  Widget _handleAndBuildNotes() {
    final String noNotes = 'No Notes';
    final String loadingNotes = 'Loading...';
    final double fontSize = 24.0;

    return Expanded(
      child: !isLoading
          ? (notes.isEmpty
              ? Text(noNotes, style: TextStyle(fontSize: fontSize))
              : _buildNotes())
          : Text(loadingNotes, style: TextStyle(fontSize: fontSize)),
    );
  }

  Widget _addANewNoteButton(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddEditNotePage()),
        );
        _refreshNotes();
      },
    );
  }

  Widget _buildSearch() {
    final String searchBoxHint = 'Title or Content';

    return SearchWidget(
      text: query,
      hintText: searchBoxHint,
      onChanged: _searchNote,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final drawerPaddingHorizontal = 15.0;
    final double itemSpacing = 10.0;
    final double dividerSpacing = 5.0;
    final double drawerRadius = 20.0;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(drawerRadius),
        bottomRight: Radius.circular(drawerRadius),
      ),
      child: Drawer(
        child: Material(
          //color: Color.fromRGBO(0, 290, 55, 50),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: drawerPaddingHorizontal),
            children: <Widget>[
              _drawerHeader(topPadding: 40),
              _divide(topPadding: 15),
              _buildMenuItem(
                topPadding: 15,
                text: 'Import Data',
                icon: Icons.file_download_outlined,
                onClicked: () async {
                  Navigator.of(context).pop();
                  await showImportDialog(context);
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'Export Data',
                icon: Icons.file_upload_outlined,
                onClicked: () async {
                  Navigator.of(context).pop();
                  bool wasExportMethordChoosen = false;
                  try {
                    wasExportMethordChoosen = await showExportDialog(context);
                  } catch (e) {
                    showSnackBarMessage(context, "File not saved!");
                    return;
                  }
                  if (!wasExportMethordChoosen) return;
                  //await fileSave();
                  String? snackMsg = await FileHandler().fileSave(allnotes);
                  showSnackBarMessage(context, snackMsg);
                  ExportEncryptionControl.setIsExportEncrypted(true);
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'Change Passphrase',
                icon: Icons.lock_sharp,
                onClicked: () async {
                  Navigator.of(context).pop();
                  await changePassphraseDialog(context);
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'UnDecrypted Control',
                icon: Icons.settings_sharp,
                onClicked: () async {
                  Navigator.of(context).pop();
                  await toggleUndecryptionDialog(context);
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'Dark Mode',
                icon: Icons.format_paint,
                toggle: TheamToggle(),
              ),
              _divide(topPadding: dividerSpacing),
              _buildMenuItem(
                topPadding: dividerSpacing,
                text: 'Help and Feedback',
                icon: Icons.feedback,
                onClicked: () async {
                  Navigator.of(context).pop();
                  var mailUrl = AppInfo.getMailToForFeedback();
                  try {
                    await _launchUrl(Uri.parse(mailUrl));
                  } catch (e) {}
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'Source Code',
                icon: Icons.folder,
                onClicked: () async {
                  var sourceCodeUrl = AppInfo.getSourceCodeUrl();
                  try {
                    await _launchUrl(Uri.parse(sourceCodeUrl));
                  } catch (e) {}
                },
              ),
              _buildMenuItem(
                topPadding: itemSpacing,
                text: 'Report Bug',
                icon: Icons.bug_report,
                onClicked: () async {
                  Navigator.of(context).pop();
                  var mailUrl = AppInfo.getBugReportUrl();
                  try {
                    await _launchUrl(Uri.parse(mailUrl));
                  } catch (e) {}
                },
              ),
              _divide(topPadding: dividerSpacing),
              _buildMenuItem(
                topPadding: dividerSpacing,
                text: 'LogOut',
                icon: Icons.logout_sharp,
                onClicked: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    isLogout = true;
                  });
                  await Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SafeNotes()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> changePassphraseDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return ChangePassphraseDialog(allnotes: allnotes);
      },
    );
  }

  Future<void> toggleUndecryptionDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return ToggleUndecryptionFlag();
      },
    );
  }

  showExportDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ExportMethordDialog();
      },
    );
  }

  showImportDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return FileImportDialog(
          callback: () async {
            String? snackMessage =
                await FileHandler().selectFileAndDoImport(context);
            _refreshNotes();
            if (snackMessage != null)
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(snackMessage)));
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Widget _divide({required double topPadding}) {
    final bool isDarkTheme = AppSecurePreferencesStorage.getIsThemeDark();

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Divider(
        color: isDarkTheme
            ? NordColors.snowStorm.lightest
            : NordColors.polarNight.darker,
      ),
    );
  }

  Widget _drawerHeader({required double topPadding}) {
    final logoPath = AppInfo.getAppLogoPath();
    final officialAppName = AppInfo.getAppName();
    final appSlogan = AppInfo.getAppSlogan();
    final double logoHightWidth = 75.0;
    final double appNameFontSize = 22;
    final double appSloganFontSize = 15;
    final double logoNameGap = 15.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: (EdgeInsets.symmetric(vertical: 5)),
          child: Row(
            children: [
              Center(
                child: Container(
                    width: logoHightWidth,
                    height: logoHightWidth,
                    child: Image.asset(logoPath)),
              ),
              Padding(
                padding: EdgeInsets.only(left: logoNameGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officialAppName,
                      style: TextStyle(fontSize: appNameFontSize),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        appSlogan,
                        style: TextStyle(fontSize: appSloganFontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String text,
    required IconData icon,
    required double topPadding,
    Widget? toggle,
    VoidCallback? onClicked,
  }) {
    final double fontSize = 15.0;
    final double leftPaddingMenuItem = 10.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: ListTile(
        horizontalTitleGap: 0,
        contentPadding: EdgeInsets.only(left: leftPaddingMenuItem),
        visualDensity: VisualDensity.compact,
        leading: Icon(icon),
        title: Text(
          text,
          style: TextStyle(fontSize: fontSize),
        ),
        trailing: toggle,
        onTap: onClicked,
      ),
    );
  }

  Widget _buildNotes() {
    return StaggeredGridView.countBuilder(
      padding: EdgeInsets.all(8),
      itemCount: notes.length,
      staggeredTileBuilder: (index) => StaggeredTile.fit(2),
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemBuilder: (context, index) {
        final note = notes[index];

        return GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NoteDetailPage(noteId: note.id!)));
            _refreshNotes();
          },
          child: NoteCardWidget(note: note, index: index),
        );
      },
    );
  }

  void _searchNote(String query) {
    final notes = allnotes.where((note) {
      final titleLower = note.title.toLowerCase();
      final descriptionLower = note.description.toLowerCase();
      final queryLower = query.toLowerCase();

      return titleLower.contains(queryLower) ||
          descriptionLower.contains(queryLower);
    }).toList();

    setState(
      () {
        this.query = query;
        this.notes = notes;
      },
    );
  }
}
  // fileSave() async {
  //   Directory? directory;
  //   String fileName = AppInfo.getExportFileName();

  //   String preFixToRecord = '{ "records" : ';
  //   String postFixToRecord = ', "recordHandlerHash" : ' +
  //       (ExportEncryptionControl.getIsExportEncrypted()
  //           ? '"${AppSecurePreferencesStorage.getPassPhraseHash().toString()}"'
  //           : '"null"') +
  //       ', "total" : ' +
  //       allnotes.length.toString() +
  //       '}';
  //   String record = (allnotes
  //           .map(
  //               (i) => i.toJson(ExportEncryptionControl.getIsExportEncrypted()))
  //           .toList())
  //       .toString();

  //   try {
  //     if (Platform.isIOS) {
  //       if (await _requestPermission(Permission.storage)) {
  //         directory = await getApplicationDocumentsDirectory();
  //         var jsonFile = new File(directory.path + "/" + fileName);
  //         jsonFile.writeAsStringSync(preFixToRecord + record + postFixToRecord);
  //         showSnackBar(
  //             'File saved in Document folder of ${AppInfo.getAppName()}!');
  //       } else {
  //         showSnackBar('Storage access Denied!');
  //       }
  //     } else if (Platform.isAndroid) {
  //       if (await _requestPermission(Permission.storage)) {
  //         directory = await getExternalStorageDirectory();
  //         String downPath = "";
  //         List<String> folders = directory!.path.split("/");
  //         for (final folder in folders.sublist(1, folders.length)) {
  //           if (folder != "Android") {
  //             downPath += "/" + folder;
  //           } else
  //             break;
  //         }
  //         downPath += "/Download";
  //         directory = Directory(downPath);
  //         //print(directory.path);
  //         var jsonFile = new File(directory.path + "/" + fileName);
  //         //print(jsonFile);
  //         jsonFile.writeAsStringSync(preFixToRecord + record + postFixToRecord);

  //         showSnackBar('File saved in Download folder!');
  //       } else {
  //         showSnackBar('Storage access Denied!');
  //       }
  //     } //Android handler end
  //   } catch (e) {}
  // }

  // Future<bool> _requestPermission(Permission permission) async {
  //   if (await permission.isGranted) {
  //     return true;
  //   } else {
  //     var status = await permission.request();
  //     if (status.isGranted) {
  //       return true;
  //     }
  //     return false;
  //   }
  // }
//End:  Block for handling of data export

//Begin:  Block for handling import of data

/*   Widget importButton() => IconButton(
      icon: Icon(Icons.file_download_outlined),
      onPressed: () async {
        await showImportDialog(context);
      }); */

  // selectFileAndDoImport() async {
  //   String dataFromFileAsString = await getFileAsString();
  //   if (dataFromFileAsString == "null") {
  //     showSnackBar("File not picked!");
  //     return;
  //   } else if (dataFromFileAsString == "unrecognized") {
  //     showSnackBar("Unrecognized File!");
  //     return;
  //   }
  //   try {
  //     var jsonDecodedData = jsonDecode(dataFromFileAsString);
  //     if (jsonDecodedData['recordHandlerHash'] as String == "null") {
  //       //print("eneterd unencrypted are");
  //       ImportEncryptionControl.setIsImportEncrypted(false);
  //       inserNotes(ImportParser.fromJson(jsonDecodedData).getAllNotes());
  //     } else {
  //       ImportEncryptionControl.setIsImportEncrypted(true);
  //       try {
  //         await getImportPassphraseDialog(context);
  //       } catch (e) {}
  //       if (sha256
  //               .convert(
  //                   utf8.encode(ImportPassPhraseHandler.getImportPassPhrase()))
  //               .toString() ==
  //           jsonDecodedData['recordHandlerHash'] as String) {
  //         await inserNotes(
  //             ImportParser.fromJson(jsonDecodedData).getAllNotes());
  //         ImportPassPhraseHandler.setImportPassPhrase("null");
  //       } else {
  //         showSnackBar("Wrong Passphrase!");
  //         ImportPassPhraseHandler.setImportPassPhrase("null");
  //         return;
  //       }
  //     }
  //   } catch (e) {
  //     showSnackBar("Failed to import file!");
  //   }
  // }

  // getImportPassphraseDialog(BuildContext context) => showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (_) {
  //       return ImportPassPhraseDialog();
  //     });

  // Future<String> getFileAsString() async {
  //   try {
  //     if (Platform.isAndroid) {
  //       FilePickerResult? result = await FilePicker.platform.pickFiles(
  //         type: FileType.custom,
  //         allowedExtensions: [AppInfo.getExportFileExtension()],
  //       );
  //       if (result != null) {
  //         PlatformFile file = result.files.first;
  //         if (file.size == 0) return "null";
  //         var jsonFile = new File(file.path!);
  //         String content = jsonFile.readAsStringSync();
  //         return content;
  //       }
  //     } else if (Platform.isIOS) {
  //       FilePickerResult? result = await FilePicker.platform.pickFiles();
  //       if (result != null) {
  //         PlatformFile file = result.files.first;
  //         if (file.size == 0 ||
  //             file.extension != AppInfo.getExportFileExtension()) return "null";
  //         var jsonFile = new File(file.path!);
  //         String content = jsonFile.readAsStringSync();
  //         return content;
  //       }
  //     }
  //   } catch (e) {
  //     showSnackBar("Unrecognized File!");
  //     return "unrecognized";
  //   }
  //   return "null";
  // }

  // inserNotes(List<SafeNote> imported) async {
  //   for (final note in imported) {
  //     await NotesDatabase.instance.encryptAndStore(note);
  //   }
  //   _refreshNotes();
  // }

//End:  Block for handling import of data

//Begin: Handling the render of note cards
  // showSnackBarMessage(BuildContext context, String? message) {
  //   if (message != null)
  //     ScaffoldMessenger.of(context)
  //       ..removeCurrentSnackBar()
  //       ..showSnackBar(
  //         SnackBar(content: Text(message)),
  //       );
  // }
// }

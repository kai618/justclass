import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:justclass/models/note.dart';
import 'package:justclass/providers/note_manager.dart';
import 'package:justclass/themes.dart';
import 'package:justclass/utils/app_context.dart';
import 'package:justclass/utils/mime_type.dart';
import 'package:justclass/utils/validators.dart';
import 'package:justclass/widgets/app_icon_button.dart';
import 'package:justclass/widgets/app_snack_bar.dart';
import 'package:justclass/widgets/opaque_progress_indicator.dart';
import 'package:mime/mime.dart';

class EditNoteScreen extends StatefulWidget {
  static const routeName = 'update-note-screen';

  final Note note;
  final ClassTheme theme;
  final NoteManager noteManager;

  EditNoteScreen({this.note, this.theme, this.noteManager});

  @override
  _EditNoteScreenState createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  BuildContext screenCtx;

  // a flag indicating if the form is valid
  bool _valid = false;

  // a flag showing that whether request is sending or not
  bool _loading = false;

  List<String> _deletedFileIds = [];

  // a map of <file name, file path>
  Map<String, String> _newFiles = {};

  // storing the user input
  String content;

  @override
  void initState() {
    content = widget.note.content;

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => AppContext.add(screenCtx, '${EditNoteScreen.routeName} ${widget.noteManager.cid}'));
    super.initState();
  }

  @override
  void dispose() {
    AppContext.pop();
    super.dispose();
  }

  void _pickFiles(BuildContext context) async {
    _showLoadingSpin();
    try {
      final files = await FilePicker.getMultiFilePath(type: FileType.any);
      if (files != null) _newFiles.addAll(files);
    } catch (error) {
      AppSnackBar.showError(screenCtx, message: "Unable to attach files!");
    } finally {
      _hideLoadingSpin();
    }
    setState(() {});
  }

  void _showLoadingSpin() {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
  }

  void _hideLoadingSpin() {
    if (this.mounted) setState(() => _loading = false);
  }

  void _updateNote(BuildContext context) {
    print('updated');
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.theme.primaryColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: color,
        appBar: _buildAppBar(),
        body: LayoutBuilder(builder: (context, constraints) {
          screenCtx = context;
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return SafeArea(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              child: Container(
                color: Colors.white,
                height: constraints.maxHeight,
                alignment: Alignment.topCenter,
                child: Container(
                  height: constraints.maxHeight - bottom,
                  child: Stack(
                    children: <Widget>[
                      ListView(
                        physics: ClampingScrollPhysics(),
                        children: <Widget>[
                          _buildNoteInput(),
                          Divider(),
                          if (widget.note.attachments.isNotEmpty) _buildOldFileList(color),
                        ],
                      ),
                      Visibility(visible: _loading, child: OpaqueProgressIndicator()),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: widget.theme.primaryColor,
      leading: AppIconButton.cancel(onPressed: () => Navigator.of(context).pop()),
      actions: <Widget>[
        AppIconButton(
          icon: const Icon(Icons.attachment),
          tooltip: 'New Attachment',
          onPressed: _loading ? null : () => _pickFiles(context),
        ),
        AppIconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Update',
          onPressed: (!_valid || _loading) ? null : () => _updateNote(context),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
      child: TextFormField(
        minLines: 1,
        maxLines: 5,
        initialValue: content,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(labelText: 'Share with your class'),
        onChanged: (val) {
          content = val;
          setState(() {
            _valid = NewNoteValidator.validateNote(val) == null &&
                (content != widget.note.content || _deletedFileIds.isNotEmpty || _newFiles.isNotEmpty);
          });
        },
      ),
    );
  }

  Widget _buildOldFileList(Color color) {
    return Column(
      children: <Widget>[
        ...widget.note.attachments
            .map((a) => OldFileTile(
                  color: color,
                  attachment: a,
                  deletedFileIds: _deletedFileIds,
                ))
            .toList()
      ],
    );
  }

//  List<Widget> _buildFileList() {
//
//
//    final iconMap = widget.note.attachments.map((file) => MapEntry(name, MimeType.toIcon(lookupMimeType(file.type))));
//
//    return iconMap.keys
//        .map((key) => Padding(
//              padding: const EdgeInsets.all(5),
//              child: Row(
//                children: <Widget>[
//                  Padding(
//                    padding: const EdgeInsets.symmetric(horizontal: 10),
//                    child: Icon(iconMap[key], size: 30, color: widget.theme.primaryColor),
//                  ),
//                  Expanded(child: Text(key)),
//                  AppIconButton.cancel(
//                    icon: const Icon(Icons.clear, color: Colors.black54, size: 20),
//                    onPressed: () => _removeFile(key),
//                  ),
//                ],
//              ),
//            ))
//        .toList();
//  }
}

class OldFileTile extends StatefulWidget {
  final Color color;
  final Attachment attachment;
  final List<String> deletedFileIds;

  OldFileTile({this.color, this.deletedFileIds, this.attachment});

  @override
  _OldFileTileState createState() => _OldFileTileState();
}

class _OldFileTileState extends State<OldFileTile> {
  bool deleted = false;
  IconData _icon;

  @override
  void initState() {
    _icon = MimeType.toIcon(widget.attachment.type);
    super.initState();
  }

  addId() {
    widget.deletedFileIds.add(widget.attachment.fileId);
    setState(() => deleted = true);
  }

  removeId() {
    widget.deletedFileIds.remove(widget.attachment.fileId);
    setState(() => deleted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: deleted ? Colors.red.withOpacity(0.2) : null,
          borderRadius: const BorderRadius.all(Radius.circular(25)),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(_icon, size: 30, color: widget.color),
            ),
            Expanded(child: Text(widget.attachment.name, overflow: TextOverflow.ellipsis)),
            AppIconButton.cancel(
              icon: Icon(deleted ? Icons.autorenew : Icons.clear, color: Colors.black54, size: 20),
              onPressed: () => deleted ? removeId() : addId(),
            ),
          ],
        ),
      ),
    );
  }
}
// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/models/session.dart';
import 'package:safenotes/utils/passphrase_strength.dart';
import 'package:safenotes/utils/snack_message.dart';
import 'package:safenotes/widgets/login_button.dart';

class SetEncryptionPhrasePage extends StatefulWidget {
  final StreamController<SessionState> sessionStream;
  final bool? isKeyboardFocused;
  SetEncryptionPhrasePage(
      {Key? key, required this.sessionStream, this.isKeyboardFocused})
      : super(key: key);

  @override
  _SetEncryptionPhrasePageState createState() =>
      _SetEncryptionPhrasePageState();
}

class _SetEncryptionPhrasePageState extends State<SetEncryptionPhrasePage> {
  final _formKey = GlobalKey<FormState>();
  final _passPhraseController = TextEditingController();
  final _passPhraseControllerConfirm = TextEditingController();
  bool _isHiddenFirst = true;
  bool _isHiddenConfirm = true;

  @override
  void dispose() {
    this._passPhraseController.dispose();
    this._passPhraseControllerConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(SafeNotesConfig.getFirstLoginPageName()),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildTopLogo(),
            _buildPassphraseSetWorkflow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLogo() {
    final double logoTopPadding = 50.0;
    final double logoWidth = 165.0;
    final double logoHeight = 165.0;

    return Padding(
      padding: EdgeInsets.only(top: logoTopPadding),
      child: Center(
        child: Container(
          width: logoWidth,
          height: logoHeight,
          child: Image.asset(SafeNotesConfig.getAppLogoPath()),
        ),
      ),
    );
  }

  Widget _buildPassphraseSetWorkflow(BuildContext context) {
    final focusConfirm = FocusNode();
    final double padding = 16.0;
    const double inputBoxSeparation = 10.0;
    return Form(
      key: this._formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            _inputFieldFirst(focusConfirm),
            const SizedBox(height: inputBoxSeparation),
            _inputFieldConfirm(context, focusConfirm),
            _buildForgotPassphrase(),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _inputFieldFirst(FocusNode focus) {
    final double inputBoxEdgeRadious = 15.0;
    final String firstHintText = 'Encryption Phrase';

    return TextFormField(
      enableIMEPersonalizedLearning: false,
      controller: this._passPhraseController,
      autofocus: widget.isKeyboardFocused ?? true, //true,
      obscureText: this._isHiddenFirst,
      decoration:
          _inputBoxDecoration('first', firstHintText, inputBoxEdgeRadious),
      keyboardType: TextInputType.visiblePassword,
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focus);
      },
      validator: _firstInputValidator,
    );
  }

  Widget _inputFieldConfirm(BuildContext context, FocusNode focus) {
    final double inputBoxEdgeRadious = 15.0;
    final double padding = 10.0;
    final String confirmHintText = 'Confirm Encryption Phrase';

    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: TextFormField(
        enableIMEPersonalizedLearning: false,
        controller: this._passPhraseControllerConfirm,
        focusNode: focus,
        obscureText: this._isHiddenConfirm,
        decoration: _inputBoxDecoration(
            'confirm', confirmHintText, inputBoxEdgeRadious),
        keyboardType: TextInputType.visiblePassword,
        onEditingComplete: _loginController,
        validator: _confirmInputValidator,
      ),
    );
  }

  InputDecoration _inputBoxDecoration(
      String inputFieldID, String inputHintText, double inputBoxEdgeRadious) {
    bool? visibility = null;
    if (inputFieldID == 'first') {
      visibility = this._isHiddenFirst;
    } else {
      visibility = this._isHiddenConfirm;
    }
    return InputDecoration(
      hintText: inputHintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBoxEdgeRadious),
      ),
      prefixIcon: Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: !visibility ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
        onPressed: () {
          if (inputFieldID == 'first') {
            return setState(() => this._isHiddenFirst = !this._isHiddenFirst);
          } else {
            return setState(
                () => this._isHiddenConfirm = !this._isHiddenConfirm);
          }
        },
      ),
    );
  }

  String? _firstInputValidator(String? passphrase) {
    final int minPassphraseLength = 8;
    final double minPassphraseStrength = 0.5;

    return passphrase == null || passphrase.length < minPassphraseLength
        ? 'Must be at least 8 characters long!'
        : (estimateBruteforceStrength(passphrase) < minPassphraseStrength)
            ? 'Passphrase is too weak!'
            : null;
  }

  String? _confirmInputValidator(String? passphraseConfirm) {
    return passphraseConfirm == null ||
            passphraseConfirm != this._passPhraseController.text
        ? 'Encryption Phrase mismatch!'
        : null;
  }

  Widget _buildLoginButton() {
    return ButtonWidget(
      text: 'LOGIN',
      onClicked: () async {
        _loginController();
      },
    );
  }

  Widget _buildForgotPassphrase() {
    return Container(
      alignment: Alignment.centerRight,
      child: TextButton(
        child: Text('Use Strong Phrase!'),
        onPressed: () {},
      ),
    );
  }

  void _loginController() async {
    final form = this._formKey.currentState!;

    if (form.validate()) {
      final enteredPassphrase = this._passPhraseController.text;
      final enteredPassphraseConfirm = this._passPhraseControllerConfirm.text;
      if (enteredPassphrase == enteredPassphraseConfirm) {
        showSnackBarMessage(context, 'Encryption Phrase Set!');

        // Setting hash for PassPhrase in share prefrences
        Session.setOrChangePassphrase(enteredPassphrase);

        await Navigator.pushReplacementNamed(context, '/home',
            arguments: widget.sessionStream);
      } else
        showSnackBarMessage(context, 'Encryption Phrase missmach!');
    }
  }
}

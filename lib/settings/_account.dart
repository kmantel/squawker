import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:logging/logging.dart';
import 'package:pref/pref.dart';
import 'package:squawker/client/client_account.dart';
import 'package:squawker/constants.dart';
import 'package:squawker/database/entities.dart';
import 'package:squawker/generated/l10n.dart';

class SettingsAccountFragment extends StatefulWidget {

  const SettingsAccountFragment({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsAccountFragmentState();
}

class _SettingsAccountFragmentState extends State<SettingsAccountFragment> {
  static final log = Logger('_SettingsAccountFragmentState');

  List<TwitterTokenEntity> _regularAccountsTokens = [];

  @override
  void initState() {
    super.initState();
    _regularAccountsTokens = TwitterAccount.getRegularAccountsTokens();
  }

  @override
  Widget build(BuildContext context) {
    TwitterAccount.setCurrentContext(context);
    BasePrefService prefs = PrefService.of(context);
    int nbrGuestAccounts = TwitterAccount.nbrGuestAccounts();
    List<Map<String,String>> accountTypeLst = [
      {'id': twitterAccountTypesPriorityToRegular, 'val': L10n.of(context).twitter_account_types_priority_to_regular},
      {'id': twitterAccountTypesBoth, 'val': L10n.of(context).twitter_account_types_both},
      {'id': twitterAccountTypesOnlyRegular, 'val': L10n.of(context).twitter_account_types_only_regular}
    ];
    List<Widget> guestAccountLst = [];
    if (nbrGuestAccounts > 0) {
      guestAccountLst.add(PrefDropdown(
        fullWidth: false,
        title: Text(L10n.of(context).twitter_account_types_label),
        subtitle: Text(L10n.of(context).twitter_account_types_description),
        pref: optionTwitterAccountTypes,
        items: accountTypeLst
            .map((e) => DropdownMenuItem(value: e['id'], child: Text(e['val'] as String)))
            .toList(),
        onChange: (value) {
          if (value ==  twitterAccountTypesBoth || value ==  twitterAccountTypesPriorityToRegular) {
            TwitterAccount.currentAccountTypes = value as String;
            TwitterAccount.sortAccounts();
          }
        },
      ));
      if (prefs.get(optionTwitterAccountTypes) != twitterAccountTypesOnlyRegular) {
        guestAccountLst.add(PrefLabel(
            title: Text(L10n.of(context).nbr_guest_accounts(nbrGuestAccounts))
        ));
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.account)),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          children: [
            ...guestAccountLst,
            PrefButton(
              title: Text(L10n.current.regular_accounts(_regularAccountsTokens.length)),
              child: Icon(Icons.add_outlined),
              onTap: () async {
                var result = await showDialog<bool>(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: AddAccountDialog(),
                    );
                  }
                );
                if (result != null && result) {
                  setState(() {
                    _regularAccountsTokens = TwitterAccount.getRegularAccountsTokens();
                  });
                }
              },
            ),
            ListView.builder(
              itemCount: _regularAccountsTokens.length,
              physics: ClampingScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                List<String> infoLst = [];
                if (_regularAccountsTokens[index].profile!.name != null) {
                  infoLst.add(_regularAccountsTokens[index].profile!.name!);
                }
                if (_regularAccountsTokens[index].profile!.email != null) {
                  infoLst.add(_regularAccountsTokens[index].profile!.email!);
                }
                if (_regularAccountsTokens[index].profile!.phone != null) {
                  infoLst.add(_regularAccountsTokens[index].profile!.phone!);
                }
                return SwipeActionCell(
                  key: Key(_regularAccountsTokens[index].oauthToken),
                  trailingActions: <SwipeAction>[
                    SwipeAction(
                      title: L10n.current.delete,
                      onTap: (CompletionHandler handler) async {
                        TwitterAccount.markTwitterTokenForDeletion(_regularAccountsTokens[index]);
                        await TwitterAccount.deleteTwitterTokensMarkedForDeletion();
                        setState(() {
                          _regularAccountsTokens.removeAt(index);
                        });
                      },
                      color: Colors.red
                    ),
                  ],
                  child: Card(
                    child: ListTile(
                      leading:  const Icon(Icons.person),
                      title: Text(_regularAccountsTokens[index].screenName),
                      subtitle: infoLst.isEmpty ? null : Text(infoLst.join(', ')),
                    )
                  ),
                );
              }
            ),
          ]
        )
      )
    );
  }
}

class AddAccountDialog extends StatefulWidget {
  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();

  const AddAccountDialog({Key? key}): super(key: key);
}

class _AddAccountDialogState extends State<AddAccountDialog> {

  bool _passwordObscured = true;
  bool _saveEnabled = false;
  String _username = '';
  String _password = '';
  String? _name;
  String? _email;
  String? _phone;

  void _checkEnabledSave() {
    if (_username.isEmpty || _password.isEmpty) {
      if (_saveEnabled) {
        setState(() {
          _saveEnabled = false;
        });
      }
    }
    else {
      if (!_saveEnabled) {
        setState(() {
          _saveEnabled = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TwitterAccount.setCurrentContext(context);
    double width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        //physics: NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(L10n.current.add_account_title, style: TextStyle(fontSize: 20))
            ),
            SizedBox(height: 60),
            Text(L10n.current.mandatory_label),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: width / 4,
                  child: Text(L10n.current.username_label),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(contentPadding: EdgeInsets.all(5)),
                    onChanged: (text) {
                      _username = text;
                      _checkEnabledSave();
                    },
                  ),
                )
              ]
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: width / 4,
                  child: Text(L10n.current.password_label),
                ),
                Expanded(
                  child: TextField(
                    obscureText: _passwordObscured,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(5),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordObscured
                          ? Icons.visibility_off
                          : Icons.visibility
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordObscured = !_passwordObscured;
                          });
                        },
                      ),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (text) {
                      _password = text;
                      _checkEnabledSave();
                    },
                  ),
                )
              ]
            ),
            SizedBox(height: 20),
            Text(L10n.current.optional_label),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: width / 4,
                  child: Text(L10n.current.name_label),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(contentPadding: EdgeInsets.all(5)),
                    onChanged: (text) {
                      _name = text;
                    },
                  ),
                ),
              ]
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: width / 4,
                  child: Text(L10n.current.email_label),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(contentPadding: EdgeInsets.all(5)),
                    onChanged: (text) {
                      _email = text;
                    },
                  ),
                ),
              ]
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: width / 4,
                  child: Text(L10n.current.phone_label),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(contentPadding: EdgeInsets.all(5)),
                    onChanged: (text) {
                      _phone = text;
                    },
                  ),
                ),
              ]
            ),
            SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Text(L10n.current.cancel),
                  onPressed: () => Navigator.pop(context, false),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  child: Text(L10n.current.save, style: TextStyle(color: _saveEnabled ? Theme.of(context).textTheme.labelMedium!.color: Theme.of(context).disabledColor)),
                  onPressed: () async {
                    if (!_saveEnabled) {
                      return;
                    }
                    try {
                      await TwitterAccount.createRegularTwitterToken(_username, _password, _name, _email, _phone);
                      Navigator.pop(context, true);
                    }
                    catch (e, _) {
                      await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(L10n.current.error_from_twitter),
                            content: Text(e.toString()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(L10n.current.ok),
                              ),
                            ]
                          );
                        }
                      );
                      Navigator.pop(context, false);
                    }
                  }
                ),
              ]
            )
          ]
        )
      )
    );
  }
}

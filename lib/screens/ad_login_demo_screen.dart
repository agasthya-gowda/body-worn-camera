// Standalone proof-of-concept: authenticates a username/password directly
// against a Windows Active Directory server via LDAP, bypassing the IMS
// backend entirely. Built to demo the AD requirement while the IMS team's
// own backend integration is still blocked.
//
// AD only allows a user to look up their own DN by binding with a real
// account, so a read-only lookup account binds first to find the DN for
// whatever login name was typed, then that DN + the typed password is used
// for the actual credential check. Pass the lookup account's password via
// `--dart-define=AD_SERVICE_PASS=...` at build/run time rather than
// committing it to source.
import 'package:dartdap/dartdap.dart';
import 'package:flutter/material.dart';

const _kAdHost = '116.73.243.111';
const _kAdPort = 636; // LDAPS (encrypted LDAP)
const _kAdBaseDn = 'DC=chipscape,DC=local';
const _kAdServiceDn = 'CN=Administrator,CN=Users,DC=chipscape,DC=local';
const _kAdServicePassword = String.fromEnvironment('AD_SERVICE_PASS');

class AdLoginDemoScreen extends StatefulWidget {
  const AdLoginDemoScreen({super.key});

  @override
  State<AdLoginDemoScreen> createState() => _AdLoginDemoScreenState();
}

class _AdLoginDemoScreenState extends State<AdLoginDemoScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _checking = false;
  String? _resultMessage;
  bool? _success;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  LdapConnection _newConnection({required String bindDn, required String password}) {
    return LdapConnection(
      host: _kAdHost,
      port: _kAdPort,
      ssl: true,
      // The AD server uses a self-signed cert for this demo, so any
      // certificate is accepted here purely for testing purposes.
      badCertificateHandler: (cert) => true,
      bindDN: DN(bindDn),
      password: password,
    );
  }

  Future<String?> _lookupUserDn(String username) async {
    final lookup = _newConnection(
      bindDn: _kAdServiceDn,
      password: _kAdServicePassword,
    );
    try {
      await lookup.open();
      await lookup.bind();
      final results = await lookup.search(
        DN(_kAdBaseDn),
        Filter.equals('sAMAccountName', username),
        ['dn'],
      );
      await for (final entry in results.stream) {
        final dn = entry.dn.toString();
        if (dn.isNotEmpty) return dn;
      }
      return null;
    } finally {
      await lookup.close();
    }
  }

  Future<void> _verifyAgainstAd() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _success = false;
        _resultMessage = 'Enter both username and password';
      });
      return;
    }

    setState(() {
      _checking = true;
      _resultMessage = null;
      _success = null;
    });

    try {
      final userDn = await _lookupUserDn(username);
      if (userDn == null) {
        setState(() {
          _success = false;
          _resultMessage = 'No such user in Active Directory';
        });
        return;
      }

      final userConnection = _newConnection(bindDn: userDn, password: password);
      try {
        await userConnection.open();
        await userConnection.bind();
        setState(() {
          _success = true;
          _resultMessage = 'Verified against Active Directory ($userDn)';
        });
      } finally {
        await userConnection.close();
      }
    } on LdapResultInvalidCredentialsException {
      setState(() {
        _success = false;
        _resultMessage = 'Incorrect username or password';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _resultMessage = 'Could not reach AD server: $e';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AD Login Demo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a Windows Active Directory username/password. '
              'This checks it directly against a real AD server '
              '(chipscape.local) - no IMS backend involved.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'AD Username',
                hintText: 'e.g. jsmith',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _verifyAgainstAd(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checking ? null : _verifyAgainstAd,
              child: _checking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify against Active Directory'),
            ),
            const SizedBox(height: 20),
            if (_resultMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success == true
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _success == true ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _success == true ? Icons.check_circle : Icons.error,
                      color: _success == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_resultMessage!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

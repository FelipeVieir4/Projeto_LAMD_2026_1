import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../widgets/app_bottom_nav.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthRepository();
  String _token = '';
  String _companyName = '';
  String _email = '';
  String? _phone;
  String? _bio;
  List<String> _specialties = [];
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _token = await _auth.getToken() ?? '';
    _companyName = await _auth.getSavedCompanyName() ?? '';
    _email = await _auth.getSavedEmail() ?? '';
    _phone = await _auth.getSavedPhone();

    try {
      final user = await _auth.fetchMe(_token);
      _companyName = user.companyName;
      _email = user.email;
      _phone = user.phone;
      _bio = user.bio;
      _specialties = user.specialties;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _companyCtrl.text = _companyName;
        _phoneCtrl.text = _phone ?? '';
        _bioCtrl.text = _bio ?? '';
        _loading = false;
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveProfile() async {
    final companyName = _companyCtrl.text.trim();
    if (companyName.isEmpty) {
      _showSnack('O nome da empresa não pode estar vazio.');
      return;
    }
    setState(() => _saving = true);
    try {
      final phone = _phoneCtrl.text.trim();
      final bio = _bioCtrl.text.trim();
      await _auth.updateProfile(
        token: _token,
        companyName: companyName,
        phone: phone.isEmpty ? null : phone,
        bio: bio.isEmpty ? null : bio,
      );
      if (!mounted) return;
      setState(() {
        _companyName = companyName;
        _phone = phone.isEmpty ? null : phone;
        _bio = bio.isEmpty ? null : bio;
        _editing = false;
        _saving = false;
      });
      _showSnack('Perfil atualizado!');
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showSnack(e.toString());
    }
  }

  void _cancelEdit() {
    setState(() {
      _companyCtrl.text = _companyName;
      _phoneCtrl.text = _phone ?? '';
      _bioCtrl.text = _bio ?? '';
      _editing = false;
    });
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(
        currentCtrl: currentCtrl,
        newCtrl: newCtrl,
        confirmCtrl: confirmCtrl,
        onSubmit: (current, newPwd) async {
          await _auth.changePassword(token: _token, currentPassword: current, newPassword: newPwd);
        },
        onSuccess: () => _showSnack('Senha alterada com sucesso!'),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!_editing && !_loading)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Editar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.primary,
                      child: Text(
                        _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(_companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Center(child: Text(_email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
                  if (_specialties.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: _specialties
                          .map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_editing) ...[
                    Text(
                      'Editar dados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(labelText: 'Nome da empresa / prestador'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telefone (opcional)', hintText: '(11) 99999-9999'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      decoration: const InputDecoration(labelText: 'Sobre você (opcional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _cancelEdit,
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Empresa', value: _companyName),
                            const Divider(height: 1),
                            _InfoRow(label: 'E-mail', value: _email),
                            const Divider(height: 1),
                            _InfoRow(label: 'Telefone', value: _phone ?? '—'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Segurança',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lock_outline_rounded, color: cs.primary),
                        ),
                        title: const Text('Alterar senha'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showChangePasswordDialog,
                      ),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text('Sair', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;
  final Future<void> Function(String current, String newPwd) onSubmit;
  final VoidCallback onSuccess;

  const _ChangePasswordDialog({
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.onSubmit,
    required this.onSuccess,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  Future<void> _submit() async {
    if (widget.newCtrl.text != widget.confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não conferem.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(widget.currentCtrl.text, widget.newCtrl.text);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Senha atual',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nova senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar nova senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

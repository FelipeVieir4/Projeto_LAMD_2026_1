import 'package:flutter/material.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/specialties_repository.dart';
import '../data/repositories/tickets_repository.dart';
import '../models/specialty.dart';

class CreateTicketScreen extends StatefulWidget {
  final String token;
  final String userId;

  const CreateTicketScreen({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  List<Specialty> _specialties = [];
  Specialty? _selectedSpecialty;
  String? _specialtyError;
  bool _loadingSpecialties = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    final specialties = await SpecialtiesRepository(token: widget.token).list();
    if (!mounted) return;
    setState(() {
      _specialties = specialties;
      _loadingSpecialties = false;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (_selectedSpecialty == null) {
      setState(() => _specialtyError = 'Selecione a especialidade.');
    }
    if (!formValid || _selectedSpecialty == null) return;

    setState(() => _submitting = true);
    try {
      await TicketsRepository(token: widget.token).createTicket(
        customerId: widget.userId,
        specialty: _selectedSpecialty!.name,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        addressText: _addressCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado aberto com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado salvo localmente. Será sincronizado quando houver conexão.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo chamado')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'Sobre o serviço'),
                const SizedBox(height: 12),
                _loadingSpecialties
                    ? const Center(child: CircularProgressIndicator())
                    : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Especialidade *',
                          prefixIcon: const Icon(Icons.category_outlined),
                          errorText: _specialtyError,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Specialty>(
                            value: _selectedSpecialty,
                            hint: const Text('Selecione uma especialidade'),
                            isExpanded: true,
                            isDense: true,
                            items: _specialties
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedSpecialty = v;
                              _specialtyError = null;
                            }),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título do chamado *',
                    prefixIcon: Icon(Icons.title_rounded),
                    hintText: 'Ex: Torneira da cozinha pingando',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o título.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                    hintText: 'Descreva o problema com mais detalhes...',
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: 'Localização'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Endereço *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Rua, número, bairro...',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o endereço.' : null,
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Abrir chamado'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sem internet? O chamado será salvo e enviado quando você reconectar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final raw = _controller.text;
    final cep = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.isEmpty || cep.length != 8) {
      setState(() {
        _error = 'Informe um CEP válido com 8 dígitos.';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('erro') && data['erro'] == true) {
          setState(() {
            _error = 'CEP não encontrado.';
          });
        } else {
          setState(() {
            _result = data;
          });
        }
      } else {
        setState(() {
          _error = 'Erro na requisição: ${resp.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildResult() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_result == null) return const SizedBox.shrink();

    final fields = <String, String>{
      'CEP': _result!['cep'] ?? '',
      'Logradouro': _result!['logradouro'] ?? '',
      'Complemento': _result!['complemento'] ?? '',
      'Bairro': _result!['bairro'] ?? '',
      'Cidade': _result!['localidade'] ?? '',
      'UF': _result!['uf'] ?? '',
      'IBGE': _result!['ibge'] ?? '',
      'DDD': _result!['ddd'] ?? '',
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${e.key}: ${e.value}'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Busca de CEP')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Digite o CEP (somente números)',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _buscarCep,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              _buildResult(),
            ],
          ),
        ),
      ),
    );
  }
}

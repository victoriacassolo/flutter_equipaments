import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestão de Equipamentos')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Cadastro de Equipamentos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CadastroEquipamentosPage()),
                );
              },
            ),
            ListTile(
              title: Text('Consulta de Equipamentos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EquipamentosPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Bem-vindo à gestão de equipamentos')),
    );
  }
}

class CadastroEquipamentosPage extends StatefulWidget {
  @override
  _CadastroEquipamentosPageState createState() =>
      _CadastroEquipamentosPageState();
}

class _CadastroEquipamentosPageState extends State<CadastroEquipamentosPage> {
  final _nomeController = TextEditingController();

  Future<void> cadastrarEquipamento() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'nome': _nomeController.text}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Equipamento cadastrado com sucesso!'),
        ));
        _nomeController.clear();
      } else {
        throw Exception('Falha ao cadastrar equipamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao cadastrar equipamento'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Equipamentos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome do Equipamento'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: cadastrarEquipamento,
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipamentosPage extends StatefulWidget {
  @override
  _EquipamentosPageState createState() => _EquipamentosPageState();
}

class _EquipamentosPageState extends State<EquipamentosPage> {
  List<dynamic> equipamentos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEquipamentos();
  }

  Future<void> fetchEquipamentos() async {
    try {
      final response = await http.get(Uri.parse(
          'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos'));

      if (response.statusCode == 200) {
        setState(() {
          equipamentos = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar equipamentos');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  Future<void> reservarEquipamento(int equipamentoId) async {
    final equipamento =
        equipamentos.firstWhere((e) => e['id'] == equipamentoId);

    if (!equipamento['disponivel']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Equipamento já reservado!'),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos/$equipamentoId/reservar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = false;
            equipamentos[index]['dataRetirada'] =
                DateTime.now().subtract(Duration(hours: 3)).toString();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Equipamento reservado com sucesso!'),
        ));
      } else {
        throw Exception('Falha ao reservar equipamento');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao reservar equipamento'),
      ));
    }
  }

  Future<void> liberarEquipamento(int equipamentoId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos/$equipamentoId/liberar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = true;
            equipamentos[index]['dataRetirada'] = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reserva liberada com sucesso!'),
        ));
      } else {
        throw Exception('Falha ao liberar reserva');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao liberar reserva'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consulta de Equipamentos')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: equipamentos.length,
              itemBuilder: (context, index) {
                final equipamento = equipamentos[index];
                return ListTile(
                  title: Text(equipamento['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(equipamento['disponivel']
                          ? 'Disponível'
                          : 'Reservado'),
                      if (equipamento['dataRetirada'] != null)
                        Text('Retirado em: ${equipamento['dataRetirada']}'),
                    ],
                  ),
                  trailing: equipamento['disponivel']
                      ? ElevatedButton(
                          onPressed: () {
                            reservarEquipamento(equipamento['id']);
                          },
                          child: Text('Reservar'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            liberarEquipamento(equipamento['id']);
                          },
                          child: Text('Liberar'),
                        ),
                );
              },
            ),
    );
  }
}

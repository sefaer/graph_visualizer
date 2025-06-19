import 'package:graph_visualizer/constants/examples.dart';
import 'package:graph_visualizer/helpers/file_importer.dart';
import 'package:graph_visualizer/models/graphs.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  String _inputType = 'matrix';
  String _inputData = '';
  String? _selectedExample;
  final _inputController = TextEditingController();
  String? _importedFileName;
  @override
  void initState() {
    super.initState();
    // Grafik türüne göre varsayılan input tipini ayarla
    _inputType == 'mst' ? 'mst' : 'matrix';
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FileImporter.importGraphFile();

      if (result != null) {
        setState(() {
          _inputData = result.content;
          _inputController.text = result.content;
          _importedFileName = result.fileName;
          _selectedExample = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${result.fileName} başarıyla yüklendi"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Dosya yükleme hatası: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Graphs graph;
      try {
        if (_inputType == 'matrix') {
          List<List<int>> matrix = _parseMatrix(_inputData);
          graph = Graphs.fromAdjacencyMatrix(matrix);
        } else if (_inputType == 'linkedList') {
          Map<int, List<int>> linkedList = _parseLinkedList(_inputData);
          graph = Graphs.fromLinkedList(linkedList);
        } else if (_inputType == "mst" || _inputType == "shortestpath") {
          // Weighted graph input type for MST, Dijkstra and Bellman-Ford
          Map<int, List<Edge>> weightedGraph = _parseWeightedGraph(_inputData);
          graph = Graphs.fromWeightedEdges(weightedGraph);
        } else if (_inputType == 'distributedRoutingExamples') {
          // Weighted graph input for distributed routing algorithms like DV, LS
          Map<int, List<Edge>> weightedGraph = _parseWeightedGraph(_inputData);
          graph = Graphs.fromWeightedEdges(weightedGraph);
        } else {
          throw Exception("Geçersiz giriş tipi");
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeScreen(graph: graph, graphType: _inputType),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  List<List<int>> _parseMatrix(String input) {
    List<List<int>> matrix = [];
    List<String> rows = input.trim().split('\n');

    for (String row in rows) {
      row = row.trim();
      if (row.isEmpty) continue;

      List<int> numbers =
          row.split(' ').where((e) => e.isNotEmpty).map((e) {
            int value = int.parse(e);
            if (value != 0 && value != 1) {
              throw FormatException(
                "Matrix değerleri sadece 0 veya 1 olabilir!",
              );
            }
            return value;
          }).toList();

      matrix.add(numbers);
    }

    int rowCount = matrix.length;
    for (List<int> row in matrix) {
      if (row.length != rowCount) {
        throw FormatException("Matrix kare şeklinde olmalıdır!");
      }
    }

    return matrix;
  }

  Map<int, List<int>> _parseLinkedList(String input) {
    Map<int, List<int>> linkedList = {};
    List<String> lines = input.trim().split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      List<String> parts = line.split(':');
      if (parts.length != 2) {
        throw FormatException("Geçersiz linked list formatı!");
      }

      int node = int.parse(parts[0]);
      List<int> neighbors =
          parts[1]
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => int.parse(e))
              .toList();

      neighbors = neighbors.where((neighbor) => neighbor != node).toList();
      neighbors = neighbors.toSet().toList();

      linkedList[node] = neighbors;
    }

    return linkedList;
  }

  Map<int, List<Edge>> _parseWeightedGraph(String input) {
    Map<int, List<Edge>> weightedGraph = {};
    List<String> lines = input.trim().split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      List<String> parts = line.split(':');
      if (parts.length != 2) {
        throw FormatException("Geçersiz ağırlıklı grafik formatı!");
      }

      int node = int.parse(parts[0]);
      List<Edge> edges = [];

      if (parts[1].isNotEmpty) {
        List<String> edgeStrings = parts[1].split(',');
        for (String edgeStr in edgeStrings) {
          edgeStr = edgeStr.trim();
          if (edgeStr.isEmpty) continue;

          // GÜNCELLENEN: Negatif ağırlıkları destekleyen regex
          RegExpMatch? match = RegExp(r'(\d+)\((-?\d+)\)').firstMatch(edgeStr);
          if (match == null || match.groupCount != 2) {
            throw FormatException("Geçersiz kenar formatı: $edgeStr");
          }

          int target = int.parse(match.group(1)!);
          int weight = int.parse(match.group(2)!);

          if (target == node) continue; // Kendine döngüleri atla

          edges.add(Edge(source: node, destination: target, weight: weight));
        }
      }

      // Tekrar eden kenarları kaldır
      edges = edges.fold([], (List<Edge> uniqueEdges, Edge edge) {
        if (!uniqueEdges.any((e) => e.destination == edge.destination)) {
          uniqueEdges.add(edge);
        }
        return uniqueEdges;
      });

      weightedGraph[node] = edges;
    }

    return weightedGraph;
  }

  void _loadExample(String? exampleKey) {
    if (exampleKey != null) {
      setState(() {
        _selectedExample = exampleKey;
        if (_inputType == 'matrix') {
          _inputData = matrixExamples[exampleKey] ?? '';
        } else if (_inputType == 'linkedList') {
          _inputData = linkedListExamples[exampleKey] ?? '';
        } else if (_inputType == 'shortestpath') {
          _inputData = shortestpathExamples[exampleKey] ?? '';
        } else if (_inputType == 'distributedRoutingExamples') {
          _inputData = distributedRoutingExamples[exampleKey] ?? '';
        } else {
          _inputData = mstExamples[exampleKey] ?? '';
        }
        _inputController.text = _inputData;
      });
    }
  }

  void _clearInput() {
    setState(() {
      _inputData = '';
      _selectedExample = null;
      _inputController.clear();
    });
  }

  String _getFormatGuideForType(String type) {
    switch (_inputType) {
      case 'matrix':
        return "• Her satır bir düğümün bağlantılarını temsil eder\n"
            "• Satırları yeni satırla ayırın\n"
            "• Değerler arasında boşluk bırakın\n"
            "• Sadece 0 (bağ yok) veya 1 (bağ var) kullanın\n"
            "• Matris kare şeklinde olmalıdır (N×N)\n";

      case 'linkedList':
        return "• Her satır bir düğüm ve komşularını temsil eder\n"
            "• Format: `düğüm:komşu1,komşu2,...`\n"
            "• Düğümleri yeni satırla ayırın\n"
            "• Kendine döngüler göz ardı edilir\n"
            "• Tekrar eden bağlar kaldırılır";
      case 'mst':
        return "• Her satır bir düğüm ve kenarlarını temsil eder\n"
            "• Format: `düğüm:hedef1(ağırlık),hedef2(ağırlık),...`\n"
            "• Örnek: `0:1(4),2(1)`\n"
            "• Düğümleri yeni satırla ayırın\n"
            "• Reverse-Delete için büyük ağırlıklı kenarlar silinir\n"
            "• Tekrar eden kenarlar otomatik kaldırılır";
      case 'shortestpath':
        return "• Her satır bir düğüm ve yönlü komşularını temsil eder\n"
            "• Format: `düğüm:hedef1(ağırlık),hedef2(ağırlık),...`\n"
            "• Örnek: `0:1(4),2(-2)`\n"
            "• Düğümleri yeni satırla ayırın\n"
            "• Başlangıç düğümünü ayrıca belirtmeniz gerekir\n"
            "• Negatif ağırlıklar yalnızca Bellman-Ford ile desteklenir\n"
            "• Yönlü grafikte yalnızca belirtilen yönlerde ilerlenir";
      case 'distributedRoutingExamples':
        return "• Her satır bir düğüm ve komşularını temsil eder\n"
            "• Format: `düğüm:komşu1(ağırlık),komşu2(ağırlık),...`\n"
            "• Örnek: `0:1(1),2(3)`\n"
            "• Düğümleri yeni satırla ayırın\n"
            "• Flooding, Distance Vector, Link State gibi algoritmalarda kullanılır\n"
            "• Tüm kenarlar çift yönlü kabul edilir (yönsüz)\n"
            "• Ağırlıklar isteğe bağlı olarak göz önünde bulundurulabilir";

      default:
        return '';
    }
  }

  String _getHintText() {
    switch (_inputType) {
      case 'matrix':
        return "0 1 0 1\n1 0 1 0\n...";
      case 'linkedList':
        return "0:1,2\n1:0,3\n...";
      case 'mst':
        return "0:1(4),2(1)\n1:0(4),3(5)\n...";
      case 'shortestpath':
        return "0:1(4),2(1)\n1:0(4),3(5)\n...";
      case 'distributedRoutingExamples':
        return "0:1,2\n1:0,3\n...";

      default:
        return '';
    }
  }

  Map<String, String> _getExamples() {
    switch (_inputType) {
      case 'matrix':
        return matrixExamples;
      case 'linkedList':
        return linkedListExamples;
      case 'mst':
        return mstExamples;
      case 'shortestpath':
        return shortestpathExamples;
      case 'distributedRoutingExamples':
        return distributedRoutingExamples;

      default:
        return {};
    }
  }

  String _getInputTitle() {
    switch (_inputType) {
      case 'matrix':
        return "Komşuluk Matrisi";
      case 'linkedList':
        return "Bağlı Liste";
      case 'mst':
        return "Ağırlıklı Grafik (MST - Kruskal/Prim/Reverse-Delete)";
      case 'shortestpath':
        return "Ağırlıklı ve Yönlü Grafik (Dijkstra/Bellman Ford)";
      case 'distributedRoutingExamples':
        return "Dağıtık Algoritma";

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Graf Algoritma Analiz Aracı",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "BFS • DFS • Dijkstra • Bellman-Ford • MST • Distrubuted",
              style: TextStyle(
                fontSize: 12,
                color: const Color.fromARGB(179, 12, 4, 230),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: "Yardım",
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_importedFileName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Chip(
                    label: Text(
                      "Yüklenen dosya: $_importedFileName",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    deleteIcon: Icon(Icons.close, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _importedFileName = null;
                      });
                    },
                  ),
                ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Giriş Türü",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        value: _inputType,
                        items: [
                          DropdownMenuItem(
                            value: 'mst',
                            child: Text("Minimum Spaning Tree"),
                          ),

                          DropdownMenuItem(
                            value: 'matrix',
                            child: Text("Komşuluk Matrisi"),
                          ),
                          DropdownMenuItem(
                            value: 'linkedList',
                            child: Text("Bağlı Liste"),
                          ),
                          DropdownMenuItem(
                            value: 'shortestpath',
                            child: Text("Shortest Path"),
                          ),
                          DropdownMenuItem(
                            value: 'distributedRoutingExamples',
                            child: Text("Dağıtık Algoritma"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _inputType = value.toString();
                            _selectedExample = null;
                            _inputData = '';
                            _inputController.clear();
                            _importedFileName = null;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Format Kılavuzu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getFormatGuideForType(''),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getInputTitle(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _clearInput,
                                icon: Icon(Icons.delete),
                                color: Colors.red,
                                tooltip: "Temizle",
                              ),
                              IconButton(
                                icon: Icon(Icons.upload_file),
                                onPressed: _importFromFile,
                                tooltip: "Dosyadan İçe Aktar",
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _inputController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: _getHintText(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Lütfen veri girin";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _inputData = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hazır Örnekler",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedExample,
                        hint: Text("Örnek seçin"),
                        items:
                            _getExamples().keys.map((String key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(key),
                              );
                            }).toList(),
                        onChanged: _loadExample,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Graf Oluştur", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Yardım - Giriş Formatları"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormatHelpItem(
                    "Komşuluk Matrisi",
                    _getFormatGuideForType('matrix'),
                  ),
                  Divider(),
                  _buildFormatHelpItem(
                    "Bağlı Liste",
                    _getFormatGuideForType('linkedList'),
                  ),
                  Divider(),
                  _buildFormatHelpItem("MST", _getFormatGuideForType('mst')),
                  Divider(),
                  _buildFormatHelpItem(
                    "shortestpath",
                    _getFormatGuideForType('shortestpath'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Tamam"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildFormatHelpItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(height: 4),
        Text(content),
      ],
    );
  }
}

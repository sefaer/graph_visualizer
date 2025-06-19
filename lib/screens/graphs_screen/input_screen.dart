import 'package:flutter/material.dart';
import 'package:graph_visualizer/constants/examples.dart';
import 'package:graph_visualizer/helpers/file_importer.dart';
import 'package:graph_visualizer/models/graphs.dart';
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
  bool _formatGuideExpanded = true;

  @override
  void initState() {
    super.initState();
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
          Map<int, List<Edge>> weightedGraph = _parseWeightedGraph(_inputData);
          graph = Graphs.fromWeightedEdges(weightedGraph);
        } else if (_inputType == 'distributedRoutingExamples') {
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

          RegExpMatch? match = RegExp(r'(\d+)\((-?\d+)\)').firstMatch(edgeStr);
          if (match == null || match.groupCount != 2) {
            throw FormatException("Geçersiz kenar formatı: $edgeStr");
          }

          int target = int.parse(match.group(1)!);
          int weight = int.parse(match.group(2)!);

          if (target == node) continue;

          edges.add(Edge(source: node, destination: target, weight: weight));
        }
      }

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

  Widget _buildExampleChip(String exampleName, String exampleKey) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ChoiceChip(
        label: Text(exampleName),
        selected: _selectedExample == exampleKey,
        onSelected: (selected) {
          setState(() {
            _selectedExample = selected ? exampleKey : null;
            _loadExample(_selectedExample);
          });
        },
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color:
              _selectedExample == exampleKey
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                _selectedExample == exampleKey
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
          ),
        ),
      ),
    );
  }

  void _showInteractiveTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Giriş Formatları Rehberi",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTutorialSection(
                          "Komşuluk Matrisi",
                          Icons.grid_on,
                          "• Her satır bir düğümün bağlantılarını temsil eder\n"
                              "• Satırları yeni satırla ayırın\n"
                              "• Değerler arasında boşluk bırakın\n"
                              "• Sadece 0 (bağ yok) veya 1 (bağ var) kullanın\n"
                              "• Matris kare şeklinde olmalıdır (N×N)\n",
                          "0 1 0 1\n1 0 1 0\n0 1 0 1\n1 0 1 0",
                        ),
                        Divider(),
                        _buildTutorialSection(
                          "Bağlı Liste",
                          Icons.list,
                          "• Her satır bir düğüm ve komşularını temsil eder\n"
                              "• Format: `düğüm:komşu1,komşu2,...`\n"
                              "• Düğümleri yeni satırla ayırın\n"
                              "• Kendine döngüler göz ardı edilir\n"
                              "• Tekrar eden bağlar kaldırılır",
                          "0:1,2\n1:0,3\n2:0,3\n3:1,2",
                        ),
                        Divider(),
                        _buildTutorialSection(
                          "Minimum Spanning Tree",
                          Icons.account_tree,
                          "• Her satır bir düğüm ve kenarlarını temsil eder\n"
                              "• Format: `düğüm:hedef1(ağırlık),hedef2(ağırlık),...`\n"
                              "• Örnek: `0:1(4),2(1)`\n"
                              "• Düğümleri yeni satırla ayırın\n"
                              "• Reverse-Delete için büyük ağırlıklı kenarlar silinir\n"
                              "• Tekrar eden kenarlar otomatik kaldırılır",
                          "0:1(4),2(1)\n1:0(4),3(5)\n2:0(1),3(2)\n3:1(5),2(2)",
                        ),
                        Divider(),
                        _buildTutorialSection(
                          "En Kısa Yol Algoritmaları",
                          Icons.alt_route,
                          "• Her satır bir düğüm ve yönlü komşularını temsil eder\n"
                              "• Format: `düğüm:hedef1(ağırlık),hedef2(ağırlık),...`\n"
                              "• Örnek: `0:1(4),2(-2)`\n"
                              "• Düğümleri yeni satırla ayırın\n"
                              "• Başlangıç düğümünü ayrıca belirtmeniz gerekir\n"
                              "• Negatif ağırlıklar yalnızca Bellman-Ford ile desteklenir\n"
                              "• Yönlü grafikte yalnızca belirtilen yönlerde ilerlenir",
                          "0:1(4),2(1)\n1:3(5)\n2:1(2),3(3)\n3:",
                        ),
                        Divider(),
                        _buildTutorialSection(
                          "Dağıtık Algoritma",
                          Icons.lan,
                          "• Her satır bir düğüm ve komşularını temsil eder\n"
                              "• Format: `düğüm:komşu1(ağırlık),komşu2(ağırlık),...`\n"
                              "• Örnek: `0:1(1),2(3)`\n"
                              "• Düğümleri yeni satırla ayırın\n"
                              "• Flooding, Distance Vector, Link State gibi algoritmalarda kullanılır\n"
                              "• Tüm kenarlar çift yönlü kabul edilir (yönsüz)\n"
                              "• Ağırlıklar isteğe bağlı olarak göz önünde bulundurulabilir",
                          "0:1(1),2(3)\n1:0(1),3(2)\n2:0(3),3(1)\n3:1(2),2(1)",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTutorialSection(
    String title,
    IconData icon,
    String description,
    String example,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            example,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Graf Algoritma Analiz Aracı",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "BFS • DFS • Dijkstra • Bellman-Ford • MST • Distributed",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded),
            onPressed: _showInteractiveTutorial,
            tooltip: "Etkileşimli Rehber",
          ),
        ],
      ),
      body: Container(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_importedFileName != null) _buildFileInfoCard(context),
                _buildInputTypeCard(theme),
                _buildFormatGuideCard(theme),
                _buildDataInputCard(theme),
                _buildExamplesCard(theme),
                _buildSubmitButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfoCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.file_present,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Yüklenen dosya: $_importedFileName",
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _importedFileName = null),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTypeCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  "Graf Türü Seçin",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _inputType,
              items: [
                _buildDropdownItem(
                  'mst',
                  "Minimum Spanning Tree",
                  Icons.account_tree,
                ),
                _buildDropdownItem('matrix', "Komşuluk Matrisi", Icons.grid_on),
                _buildDropdownItem('linkedList', "Bağlı Liste", Icons.list),
                _buildDropdownItem(
                  'shortestpath',
                  "En Kısa Yol",
                  Icons.alt_route,
                ),
                _buildDropdownItem(
                  'distributedRoutingExamples',
                  "Dağıtık Algoritma",
                  Icons.lan,
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _inputType = value!;
                  _selectedExample = null;
                  _inputData = '';
                  _inputController.clear();
                  _importedFileName = null;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              isExpanded: true,
              dropdownColor: theme.cardColor,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    String text,
    IconData icon,
  ) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildFormatGuideCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              "Format Kılavuzu",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        initiallyExpanded: _formatGuideExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _formatGuideExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getInputTitle(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getFormatGuideForType(_inputType),
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _getHintText(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataInputCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _getInputTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _clearInput,
                      icon: Icon(Icons.delete_outline),
                      tooltip: "Temizle",
                      color: theme.colorScheme.error,
                    ),
                    IconButton(
                      icon: Icon(Icons.upload_file),
                      onPressed: _importFromFile,
                      tooltip: "Dosyadan İçe Aktar",
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _inputController,
              maxLines: 8,
              minLines: 5,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(12),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesCard(ThemeData theme) {
    final examples = _getExamples();
    if (examples.isEmpty) return SizedBox();

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  "Hazır Örnekler",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              children:
                  examples.entries
                      .map((entry) => _buildExampleChip(entry.key, entry.key))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: Text(
          "Grafı Oluştur ve Görselleştir",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

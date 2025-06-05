import 'package:flutter/material.dart';
import 'package:graph_visualizer/screens/graphs_screen/input_screen.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Algoritma Görselleştirici'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık ve Açıklama
              Column(
                children: [
                  Text(
                    'Graf Algoritmalarını Keşfedin',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Algoritmaları görselleştirerek derinlemesine anlayın',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InputScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'BAŞLA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),

              // Algoritma Kartları
              _buildAlgorithmCard(
                context: context,
                title: "Genişlik Öncelikli Arama (BFS)",
                description:
                    "Düğümleri seviye seviye dolaşan algoritma. Kısa yol problemleri ve ağ analizinde kullanılır.",
                icon: Icons.linear_scale,
                color: Colors.blue,
                info: """
• Seviye seviye ilerler
• Kuyruk (Queue) veri yapısı kullanır
• Komşulukları keşfederken FIFO prensibi
• Başlangıç düğümünden en kısa yolu bulur
• Zaman karmaşıklığı: O(V+E)""",
              ),
              SizedBox(height: 20),

              _buildAlgorithmCard(
                context: context,
                title: "Derinlik Öncelikli Arama (DFS)",
                description:
                    "Bir dalı sonuna kadar keşfeden algoritma. Topolojik sıralama ve bağlı bileşenlerde kullanılır.",
                icon: Icons.call_split,
                color: Colors.green,
                info: """
• Derinlemesine keşif yapar
• Yığın (Stack) veri yapısı kullanır
• Backtracking yöntemiyle çalışır
• Döngü tespiti yapabilir
• Zaman karmaşıklığı: O(V+E)""",
              ),
              SizedBox(height: 20),

              _buildAlgorithmCard(
                context: context,
                title: "Min. Kapsayan Ağaç (MST)",
                description:
                    "Ağırlıklı grafın tüm düğümlerini minimum maliyetle bağlayan algoritmalar.",
                icon: Icons.polyline,
                color: Colors.orange,
                info: """
• Prim: Düğüm temelli, greedy yaklaşım
• Kruskal: Kenar temelli, küme birleştirme
• Minimum toplam ağırlık hedeflenir
• Ağ tasarımında kullanılır
• Zaman karmaşıklığı: O(E log V)""",
              ),
              SizedBox(height: 20),

              _buildAlgorithmCard(
                context: context,
                title: "Dijkstra Algoritması",
                description:
                    "Tek kaynaktan tüm düğümlere en kısa yolu bulan algoritma. Negatif ağırlık desteklemez.",
                icon: Icons.timeline,
                color: Colors.purple,
                info: """
• Greedy yaklaşım kullanır
• Öncelik kuyruğu (Priority Queue) kullanır
• Tüm düğümlere en kısa yolu bulur
• Ulaşım ağlarında kullanılır
• Zaman karmaşıklığı: O((V+E) log V)""",
              ),
              SizedBox(height: 20),

              _buildAlgorithmCard(
                context: context,
                title: "Bellman-Ford Algoritması",
                description:
                    "Negatif ağırlıklı graflarda çalışabilen en kısa yol algoritması. Döngü tespiti yapabilir.",
                icon: Icons.compare_arrows,
                color: Colors.red,
                info: """
• Dinamik programlama yaklaşımı
• Kenar gevşetme (relaxation) işlemi yapar
• Negatif ağırlıklı graflarda çalışır
• Negatif döngü tespiti yapabilir
• Zaman karmaşıklığı: O(VE)""",
              ),

              SizedBox(height: 40),

              // Karşılaştırma Tablosu
              Text(
                'Algoritma Karşılaştırması',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 12),
              _buildComparisonTable(),
              SizedBox(height: 30),

              // Bilgilendirme Kartı
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.purple[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 28,
                          color: Colors.amber[700],
                        ),
                        SizedBox(width: 10),
                        Text(
                          'İpuçları & Kullanım Alanları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildTipItem(
                      "BFS",
                      "Sosyal ağlarda arkadaş önerileri, en kısa yol problemleri",
                    ),
                    _buildTipItem(
                      "DFS",
                      "Labirent çözümü, bağımlılık çözümleme, döngü tespiti",
                    ),
                    _buildTipItem(
                      "MST",
                      "Ağ tasarımı, elektrik hatları, ulaşım ağları",
                    ),
                    _buildTipItem(
                      "Dijkstra",
                      "Navigasyon sistemleri, trafik optimizasyonu, ağ yönlendirme",
                    ),
                    _buildTipItem(
                      "Bellman-Ford",
                      "Finansal arbitraj, negatif ağırlıklı yollar, ağ optimizasyonu",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            children: [
              TextSpan(text: 'Sefa Er © 2025 | '),
              TextSpan(
                text: 'Algoritma Görselleştirici',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlgorithmCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String info,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InputScreen()),
          );
        },
        onHover: (hovering) {},
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: color),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
                child: Text(
                  info,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey[200]!),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blue[50]),
              children: [
                _buildTableHeader(''),
                _buildTableHeader('BFS'),
                _buildTableHeader('DFS'),
                _buildTableHeader('MST'),
                _buildTableHeader('Dijkstra'),
                _buildTableHeader('Bellman-Ford'),
              ],
            ),
            _buildTableRow(
              'Veri Yapısı',
              'Kuyruk (Queue)',
              'Yığın (Stack)',
              'Öncelik Kuyruğu',
              'Öncelik Kuyruğu',
              'Dizi',
            ),
            _buildTableRow(
              'Yaklaşım',
              'Seviye Seviye',
              'Derinlemesine',
              'Greedy',
              'Greedy',
              'Dinamik Programlama',
            ),
            _buildTableRow(
              'Kullanım Alanı',
              'Kısa Yol',
              'Döngü Tespiti',
              'Minimum Maliyet',
              'En Kısa Yol',
              'Negatif Ağırlıklı Yollar',
            ),
            _buildTableRow(
              'Negatif Ağırlık',
              'Yok',
              'Yok',
              'Yok',
              'Desteklemez',
              'Destekler',
            ),
            _buildTableRow(
              'Karmaşıklık',
              'O(V+E)',
              'O(V+E)',
              'O(E log V)',
              'O((V+E) log V)',
              'O(VE)',
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    String bfs,
    String dfs,
    String mst, [
    String dijkstra = '',
    String bellmanFord = '',
  ]) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(bfs, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(dfs, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(mst, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(dijkstra, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(bellmanFord, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
      ),
    );
  }

  Widget _buildTipItem(String algorithm, String usage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              algorithm,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              usage,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

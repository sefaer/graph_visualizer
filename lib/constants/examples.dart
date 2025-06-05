final Map<String, String> linkedListExamples = {
  "Örnek 1 (4-düğümlü döngü)": '''
0:1,3
1:0,2
2:1,3
3:0,2
    ''',
  "Örnek 2 (5-düğümlü ağaç)": '''
0:1,2
1:0,3
2:0,4
3:1
4:2
    ''',
  "Örnek 3 (6-düğümlü graf)": '''
0:1,2
1:0,3
2:0,4
3:1,5
4:2,5
5:3,4
    ''',
  "Örnek 4 (5-düğümlü döngü)": '''
0:1
1:2
2:3
3:4
4:0
    ''',
  "Örnek 5 (6-düğümlü izoleli)": '''
0:1,2
1:0,3
2:0,4
3:1
4:2
5:
    ''',
};

final Map<String, String> matrixExamples = {
  "Örnek 1 (4-düğümlü döngü)": '''
0 1 0 1
1 0 1 0
0 1 0 1
1 0 1 0
    ''',
  "Örnek 2 (5-düğümlü ağaç)": '''
0 1 1 0 0
1 0 0 1 0
1 0 0 0 1
0 1 0 0 0
0 0 1 0 0
    ''',
  "Örnek 3 (6-düğümlü graf)": '''
0 1 1 0 0 0
1 0 0 1 0 0
1 0 0 0 1 0
0 1 0 0 0 1
0 0 1 0 0 1
0 0 0 1 1 0
    ''',
  "Örnek 4 (5-düğümlü döngü)": '''
0 1 0 0 0
1 0 1 0 0
0 1 0 1 0
0 0 1 0 1
0 0 0 1 0
    ''',
  "Örnek 5 (6-düğümlü izoleli)": '''
0 1 1 0 0 0
1 0 0 1 0 0
1 0 0 0 1 0
0 1 0 0 0 0
0 0 1 0 0 0
0 0 0 0 0 0
    ''',
};
final Map<String, String> mstMatrixExamples = {
  "Örnek 1 (4-düğümlü kare - Ağırlıklı)": '''
0 2 0 4
2 0 3 0
0 3 0 5
4 0 5 0
  ''',
  "Örnek 2 (5-düğümlü yıldız)": '''
0 4 7 0 0
4 0 0 9 0
7 0 0 0 8
0 9 0 0 5
0 0 8 5 0
  ''',
  "Örnek 3 (6-düğümlü kompleks)": '''
0 3 1 0 0 0
3 0 7 5 0 0
1 7 0 2 9 0
0 5 2 0 6 4
0 0 9 6 0 8
0 0 0 4 8 0
  ''',
  "Örnek 4 (5-düğümlü halka)": '''
0 2 0 0 6
2 0 3 0 0
0 3 0 4 0
0 0 4 0 5
6 0 0 5 0
  ''',
  "Örnek 5 (6-düğümlü 2 bileşenli)": '''
0 1 4 0 0 0
1 0 2 0 0 0
4 2 0 0 0 0
0 0 0 0 3 7
0 0 0 3 0 5
0 0 0 7 5 0
  ''',
};

const Map<String, String> mstExamples = {
  // PRIM İÇİN İDEAL (Root'tan başlayarak genişleyen yapı)
  'Prim Öğretici':
      '0:1(4),2(1)\n'
      '1:0(4),2(2),3(5)\n'
      '2:0(1),1(2),3(8)\n'
      '3:1(5),2(8)',

  // KRUSKAL İÇİN İDEAL (Kenar sıralaması vurgulu)
  'Kruskal Öğretici':
      '0:1(1),2(2)\n'
      '1:0(1),3(3)\n'
      '2:0(2),3(4)\n'
      '3:1(3),2(4)',

  // KARŞILAŞTIRMALI ALGORİTMA ANALİZİ
  'Algoritma Karşılaştırma':
      '0:1(5),2(10)\n'
      '1:0(5),2(4),3(3)\n'
      '2:0(10),1(4),3(7)\n'
      '3:1(3),2(7)',

  // BÜYÜK ÖLÇEKLİ ÖRNEK (Ders kitabı varyantı)
  'Gelişmiş Örnek':
      '0:1(2),3(6)\n'
      '1:0(2),2(3),3(8),4(5)\n'
      '2:1(3),4(7)\n'
      '3:0(6),1(8),4(9)\n'
      '4:1(5),2(7),3(9)',

  // YOĞUN GRAF (Çok bağlantılı)
  'Yoğun Bağlantılı Örnek':
      '0:1(3),2(1),3(4),4(2)\n'
      '1:0(3),2(6),3(1),4(5)\n'
      '2:0(1),1(6),3(7),4(8)\n'
      '3:0(4),1(1),2(7),4(3)\n'
      '4:0(2),1(5),2(8),3(3)',

  // SEYREK GRAF (Az bağlantılı)
  'Seyrek Bağlantılı Örnek':
      '0:1(4)\n'
      '1:0(4),2(7)\n'
      '2:1(7),3(2)\n'
      '3:2(2)',

  // AĞIRLIKLARI YAKIN KENARLAR
  'Yakın Ağırlıklı Örnek':
      '0:1(5),2(6)\n'
      '1:0(5),2(5),3(6)\n'
      '2:0(6),1(5),3(5)\n'
      '3:1(6),2(5)',

  // ÇEMBERSEL GRAF (Tüm noktalar çember şeklinde bağlı)
  'Çembersel Örnek':
      '0:1(2),3(4)\n'
      '1:0(2),2(3)\n'
      '2:1(3),3(1)\n'
      '3:2(1),0(4)',
  'Çembersel Büyük Örnek':
      '0:1(2),9(4)\n'
      '1:0(2),2(3)\n'
      '2:1(3),3(1)\n'
      '3:2(1),4(4)\n'
      '4:3(4),5(2)\n'
      '5:4(2),6(3)\n'
      '6:5(3),7(1)\n'
      '7:6(1),8(2)\n'
      '8:7(2),9(3)\n'
      '9:8(3),0(4)',

  // DENGESİZ AĞIRLIK DAĞILIMI
  'Dengesiz Ağırlıklı Örnek':
      '0:1(1),2(10)\n'
      '1:0(1),3(50)\n'
      '2:0(10),3(2)\n'
      '3:1(50),2(2)',
  'Dengesiz Ağırlıklı Büyük Örnek':
      '0:1(1),2(10),3(15)\n'
      '1:0(1),4(50)\n'
      '2:0(10),5(2)\n'
      '3:0(15),6(20)\n'
      '4:1(50),7(5)\n'
      '5:2(2),8(3)\n'
      '6:3(20),9(7)\n'
      '7:4(5),8(1),9(10)\n'
      '8:5(3),7(1),9(2)\n'
      '9:6(7),7(10),8(2)',

  'Reverse-Delete Test (Basit Döngü)':
      '0:1(4),2(1)\n1:0(4),2(2)\n2:0(1),1(2),3(3)\n3:2(3),4(2)\n4:3(2)',
  'Reverse-Delete (Ağaç Yapısı)':
      '0:1(5)\n1:0(5),2(3),3(6)\n2:1(3)\n3:1(6),4(2)\n4:3(2)',
  'Reverse-Delete (Çoklu Bağlantı)':
      '0:1(10),2(1)\n1:0(10),2(2),3(7)\n2:0(1),1(2),3(3)\n3:1(7),2(3),4(4)\n4:3(4)',
  'Reverse-Delete (Yüksek Ağırlıklı Örnek)': '''
0:1(20),2(10)
1:0(20),3(5)
2:0(10),3(30)
3:1(5),2(30)''',
};
const Map<String, String> shortestpathExamples = {
  // TEMEL ÖRNEK (Ders kitabı örneği)
  'Dijkstra Temel':
      '0:1(4),2(1)\n'
      '1:3(5)\n'
      '2:1(2),3(8)\n'
      '3:',

  // NEGATİF OLMAYAN AĞIRLIKLAR (Dijkstra için ideal)
  'Pozitif Ağırlıklar':
      '0:1(10),2(3)\n'
      '1:3(2)\n'
      '2:1(4),3(8),4(2)\n'
      '3:4(7)\n'
      '4:3(1)',

  // ÇOK HEDEFLİ YOL
  'Çoklu Hedef':
      '0:1(5),2(3)\n'
      '1:3(6),4(2)\n'
      '2:1(1),3(4)\n'
      '3:4(1)\n'
      '4:',

  // YOĞUN GRAF
  'Yoğun Graf':
      '0:1(2),2(4),3(1)\n'
      '1:0(2),2(1),3(3)\n'
      '2:0(4),1(1),3(2)\n'
      '3:0(1),1(3),2(2)',

  // SEYREK GRAF
  'Seyrek Graf':
      '0:1(3)\n'
      '1:2(4)\n'
      '2:3(5)\n'
      '3:4(2)\n'
      '4:',

  // DÜĞÜMLER ARASI UZUN MESAFE
  'Uzun Mesafe':
      '0:1(100)\n'
      '1:2(100)\n'
      '2:3(100)\n'
      '3:4(100)\n'
      '4:',

  // TEK KAYNAKTAN ÇOK HEDEF
  'Tek Kaynak Çok Hedef':
      '0:1(1),2(2),3(3)\n'
      '1:4(4)\n'
      '2:4(1),5(2)\n'
      '3:5(3)\n'
      '4:6(5)\n'
      '5:6(1)\n'
      '6:',

  // NEGATİF AĞIRLIKLI ÖRNEK
  'B.F Negatif Ağırlık':
      '0:1(4),2(5)\n'
      '1:2(-2)\n'
      '2:3(3)\n'
      '3:1(-1)',

  // NEGATİF DÖNGÜ ÖRNEĞİ
  'B.F Negatif Döngü':
      '0:1(1)\n'
      '1:2(-1)\n'
      '2:3(-1)\n'
      '3:1(-1)',

  // NEGATİF OLSUN AMA DÖNGÜ OLMASIN
  'B.F Negatif Ağırlık (Döngüsüz)':
      '0:1(4),2(5)\n'
      '1:2(-2),3(1)\n'
      '2:3(3)\n'
      '3:',

  // KARMAŞIK NEGATİF YOLLAR
  'B.F Karmaşık Negatif Yollar':
      '0:1(3),2(4)\n'
      '1:2(-2),3(1)\n'
      '2:3(-1),4(2)\n'
      '3:4(-3)\n'
      '4:',

  // BÜYÜK ÖLÇEKLİ NEGATİF GRAF
  'B.F Büyük Negatif Graf':
      '0:1(4),2(3)\n'
      '1:3(-2),4(1)\n'
      '2:1(1),3(4)\n'
      '3:4(-3),5(2)\n'
      '4:5(1)\n'
      '5:2(-4),6(3)\n'
      '6:',

  // POZİTİF VE NEGATİF KARIŞIM
  'B.F Karışık Ağırlıklar':
      '0:1(5),2(3)\n'
      '1:2(-2),3(6)\n'
      '2:3(7),4(4)\n'
      '3:4(-3)\n'
      '4:1(-1)',

  // ÇOKLU NEGATİF KENAR
  'B.F Çoklu Negatif Kenar':
      '0:1(2),2(4)\n'
      '1:2(-3),3(5)\n'
      '2:3(-4),4(1)\n'
      '3:4(-2)\n'
      '4:',
};

const Map<String, String> bellmanFordExamples = {};
const Map<String, String> distributedRoutingExamples = {
  // FLOODING İÇİN ÖĞRETİCİ – Her komşuya gönderilecek yapı
  'Flooding Öğretici':
      '0:1(1),2(1)\n'
      '1:0(1),2(1),3(1)\n'
      '2:0(1),1(1),3(1)\n'
      '3:1(1),2(1)',

  // RANDOM WALK İÇİN – Rastgele dallanacak bağlantılar
  'Random Walk Öğretici':
      '0:1(1),2(1),3(1)\n'
      '1:0(1),2(1)\n'
      '2:0(1),1(1),3(1)\n'
      '3:0(1),2(1)',

  // DISTANCE VECTOR İÇİN – Yönlü ve ağırlıklı yapı
  'Distance Vector Öğretici':
      '0:1(2),2(5)\n'
      '1:0(2),2(1),3(2)\n'
      '2:0(5),1(1),3(3)\n'
      '3:1(2),2(3)',

  // LINK STATE İÇİN – Tüm komşuları bilip en kısa yol hesaplanacak yapı
  'Link State Öğretici':
      '0:1(1),2(4)\n'
      '1:0(1),2(2),3(5)\n'
      '2:0(4),1(2),3(1)\n'
      '3:1(5),2(1)',

  // PATH VECTOR İÇİN – Olası yolların vektör halinde tutulduğu yapı
  'Path Vector Öğretici':
      '0:1(1),2(3)\n'
      '1:0(1),2(1),3(4)\n'
      '2:0(3),1(1),3(2)\n'
      '3:1(4),2(2)',
  'Simple Network': '''
0:1,2
1:0,3
2:0,3
3:1,2,4
4:3
''',
  'Ring Network': '''
0:1,4
1:0,2
2:1,3
3:2,4
4:3,0
''',
  'Star Network': '''
0:1,2,3,4
1:0
2:0
3:0
4:0
''',
};

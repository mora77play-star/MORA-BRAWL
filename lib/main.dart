import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const ArenaApp());

// حقوق التصميم والبرمجة: عمر هاني (Omar Hany) • Arena Brawl
const String creatorName = 'عمر هاني';
const String creatorHandle = 'Omar Hany';

const int tcpPort = 40444;
const int discoveryPort = 40445;
const Color bg = Color(0xFF101426);
const Color panel = Color(0xFF1B2340);
const List<Color> playerColors = [
  Color(0xFF48D7FF), Color(0xFFFF5978), Color(0xFFFFD166),
  Color(0xFF8BE28B), Color(0xFFB99CFF), Color(0xFFFF9D5C),
  Color(0xFF69E0C0), Color(0xFFE9ECF5),
];
const List<String> modes = [
  'قنابل عادية', 'سرعة مجنونة', 'ساحة صغيرة', 'نقاط مضاعفة',
  'قنابل سريعة', 'فوضى الألوان'
];

class ArenaMusic {
  static final AudioPlayer player = AudioPlayer();
  static bool enabled = true;
  static Future<void> start() async {
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(.22);
      await player.play(AssetSource('arena_music.wav'));
    } catch (_) {}
  }
  static Future<void> toggle() async {
    enabled = !enabled;
    if (enabled) { await player.resume(); } else { await player.pause(); }
  }
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF48D7FF), brightness: Brightness.dark),
    ),
    home: const IntroPage(),
  );
}


class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2200),
  )..forward();
  late final Animation<double> fade = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  late final Animation<double> scale = Tween<double>(begin: .65, end: 1).animate(
    CurvedAnimation(parent: controller, curve: Curves.elasticOut));
  @override void initState() {
    super.initState();
    ArenaMusic.start();
    Future.delayed(const Duration(milliseconds: 2900), () {
      if (mounted) Navigator.of(context).pushReplacement(
        PageRouteBuilder(pageBuilder: (_, __, ___) => const LobbyPage(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500)));
    });
  }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(animation: controller, builder: (_, __) => Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0B1020), Color(0xFF172B4D), Color(0xFF321D4D)])),
      child: Stack(children: [
        Positioned(top: 70, left: -30, child: _glow(150, const Color(0xFF48D7FF))),
        Positioned(bottom: 100, right: -25, child: _glow(190, const Color(0xFFFF5978))),
        Center(child: FadeTransition(opacity: fade, child: ScaleTransition(scale: scale,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 126, height: 126, decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white.withOpacity(.07),
              border: Border.all(color: const Color(0xFF48D7FF), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF48D7FF).withOpacity(.25), blurRadius: 35)]),
              child: const Icon(Icons.sports_mma, size: 72, color: Color(0xFF48D7FF))),
            const SizedBox(height: 25),
            const Text('ARENA BRAWL', style: TextStyle(fontSize: 30, letterSpacing: 3, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('استعد للفوضى 💣', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD166))),
            const SizedBox(height: 30),
            const Text('برمجة وتطوير', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            const Text('عمر هاني • OMAR HANY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 25),
            const SizedBox(width: 130, child: LinearProgressIndicator(
              minHeight: 4, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(Color(0xFF48D7FF)))),
            const SizedBox(height: 16),
            const Text('حقوق البرمجة والتصميم © عمر هاني', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ])))),
      ]),
    )),
  );
  Widget _glow(double size, Color color) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(.10),
      boxShadow: [BoxShadow(color: color.withOpacity(.25), blurRadius: 70, spreadRadius: 15)]));
}

class Player {
  Player({required this.id, required this.name, required this.color,
    this.x = .5, this.y = .5, this.score = 0, this.alive = true});
  final String id;
  String name;
  int color;
  double x, y;
  int score;
  bool alive;
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'color': color, 'x': x, 'y': y,
    'score': score, 'alive': alive,
  };
  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: '${j['id']}', name: '${j['name']}', color: (j['color'] as num?)?.toInt() ?? 0,
    x: (j['x'] as num?)?.toDouble() ?? .5, y: (j['y'] as num?)?.toDouble() ?? .5,
    score: (j['score'] as num?)?.toInt() ?? 0, alive: j['alive'] != false,
  );
}

class ArenaNet {
  ServerSocket? server;
  RawDatagramSocket? discovery;
  RawDatagramSocket? scanner;
  Timer? advertiseTimer;
  Timer? gameTimer;
  final Map<String, Socket> sockets = {};
  final Map<String, List<int>> buffers = {};
  final Map<String, Player> players = {};
  final Map<String, Map<String, dynamic>> bombs = {};
  final Map<String, Map<String, dynamic>> rooms = {};
  String? myId;
  String roomName = 'غرفة مورا';
  String mode = modes[0];
  int round = 1;
  int secondsLeft = 90;
  int maxPlayers = 8;
  bool isHost = false;
  bool playing = false;
  String status = '';
  void Function()? changed;
  String get localName => 'لاعب ${myId ?? ''}';

  Future<String> startHost(String name, int limit) async {
    await close();
    isHost = true; maxPlayers = limit; roomName = name;
    myId = 'host_${DateTime.now().millisecondsSinceEpoch}';
    players.clear(); bombs.clear();
    players[myId!] = Player(id: myId!, name: name.isEmpty ? 'المضيف' : name,
      color: 0, x: .5, y: .5);
    server = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort, shared: true);
    server!.listen(_accept, onError: (_) {});
    discovery = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort,
      reuseAddress: true, reusePort: true);
    discovery!.broadcastEnabled = true;
    advertiseTimer = Timer.periodic(const Duration(seconds: 2), (_) => _advertise());
    _advertise();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    status = 'الغرفة شغالة — ابحث من الأجهزة التانية';
    changed?.call();
    return _findLanIp();
  }

  String _findLanIp() {
    // The host can use this for manual connection if broadcast discovery is blocked.
    return 'IP تلقائي من البحث';
  }

  void _advertise() {
    final payload = utf8.encode(jsonEncode({
      'type': 'room', 'name': roomName, 'port': tcpPort,
      'count': players.length, 'max': maxPlayers, 'host': myId,
      'playing': playing,
    }));
    try {
      discovery?.send(payload, InternetAddress('255.255.255.255'), discoveryPort);
      for (final i in [InternetAddress('192.168.43.255'), InternetAddress('192.168.137.255')]) {
        try { discovery?.send(payload, i, discoveryPort); } catch (_) {}
      }
    } catch (_) {}
  }

  void _accept(Socket socket) {
    String? clientId;
    final bytes = <int>[];
    socket.listen((data) {
      bytes.addAll(data);
      while (true) {
        final n = bytes.indexOf(10);
        if (n < 0) break;
        final line = utf8.decode(bytes.sublist(0, n), allowMalformed: true).trim();
        bytes.removeRange(0, n + 1);
        if (line.isEmpty) continue;
        try {
          final m = jsonDecode(line) as Map<String, dynamic>;
          if (m['type'] == 'hello') {
            if (players.length >= maxPlayers) {
              _sendSocket(socket, {'type': 'reject', 'message': 'الغرفة مكتملة'});
              socket.destroy(); return;
            }
            clientId = 'p_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';
            final color = players.length % playerColors.length;
            players[clientId!] = Player(id: clientId!, name: _cleanName('${m['name'] ?? 'لاعب'}'),
              color: color, x: .15 + math.Random().nextDouble() * .7,
              y: .15 + math.Random().nextDouble() * .7);
            sockets[clientId!] = socket;
            buffers[clientId!] = [];
            _sendSocket(socket, {'type': 'welcome', 'id': clientId, 'host': true});
            _broadcastState();
            changed?.call();
          } else if (clientId != null) {
            _handleClient(clientId!, m);
          }
        } catch (_) {}
      }
    }, onDone: () {
      if (clientId != null) {
        sockets.remove(clientId); buffers.remove(clientId); players.remove(clientId);
        _broadcastState(); changed?.call();
      }
    }, onError: (_) {
      if (clientId != null) {
        sockets.remove(clientId); buffers.remove(clientId); players.remove(clientId);
        _broadcastState(); changed?.call();
      }
    });
  }

  String _cleanName(String s) {
    final v = s.trim().replaceAll('\n', '');
    return v.isEmpty ? 'لاعب' : v.substring(0, math.min(v.length, 18));
  }

  void _handleClient(String id, Map<String, dynamic> m) {
    final p = players[id];
    if (p == null) return;
    switch (m['type']) {
      case 'move':
        if (!playing || !p.alive) return;
        p.x = ((m['x'] as num?)?.toDouble() ?? p.x).clamp(.03, .97).toDouble();
        p.y = ((m['y'] as num?)?.toDouble() ?? p.y).clamp(.08, .92).toDouble();
        break;
      case 'bomb':
        if (playing && p.alive) bombs['${id}_${DateTime.now().microsecondsSinceEpoch}'] = {'time': DateTime.now(), 'x': p.x, 'y': p.y, 'owner': id};
        break;
      case 'start':
        break;
    }
    _broadcastState();
  }

  void _sendSocket(Socket s, Map<String, dynamic> m) {
    try { s.write('${jsonEncode(m)}\n'); } catch (_) {}
  }

  void _broadcast(Map<String, dynamic> m) {
    for (final s in sockets.values.toList()) { _sendSocket(s, m); }
  }

  void _broadcastState() {
    final state = {
      'type': 'state', 'players': players.values.map((p) => p.toJson()).toList(),
      'bombs': bombs.entries.map((e) => {'id': e.key, 'age': DateTime.now().difference(e.value['time'] as DateTime).inMilliseconds, 'x': e.value['x'], 'y': e.value['y'], 'owner': e.value['owner']}).toList(),
      'mode': mode, 'round': round, 'seconds': secondsLeft, 'playing': playing,
      'room': roomName, 'max': maxPlayers,
    };
    _broadcast(state); changed?.call();
  }

  void _tick() {
    if (!isHost) return;
    final now = DateTime.now();
    final expired = bombs.entries.where((e) => now.difference(e.value['time'] as DateTime).inMilliseconds > 1500).map((e) => e.key).toList();
    for (final id in expired) {
      final b = bombs.remove(id)!;
      final bomber = '${b['owner']}';
      final bx = (b['x'] as num).toDouble();
      final by = (b['y'] as num).toDouble();
      final radius = mode == 'ساحة صغيرة' ? .20 : (mode == 'قنابل سريعة' ? .13 : .16);
      for (final p in players.values) {
        if (p.alive && math.sqrt(math.pow(p.x - bx, 2) + math.pow(p.y - by, 2)) < radius) {
          p.alive = false;
          final bp = players[bomber];
          if (bp != null && bp.id != p.id) bp.score += mode == 'نقاط مضاعفة' ? 2 : 1;
        }
      }
    }
    if (playing) {
      secondsLeft--;
      if (secondsLeft <= 0 || players.values.where((p) => p.alive).length <= 1 && players.length > 1) {
        playing = false;
        final alive = players.values.where((p) => p.alive).toList();
        if (alive.isNotEmpty) alive.first.score += 2;
        status = 'الجولة $round انتهت';
      }
    }
    _broadcastState();
  }

  void startRound() {
    if (!isHost) return;
    round++; mode = modes[math.Random().nextInt(modes.length)];
    secondsLeft = 90; playing = true; bombs.clear();
    for (final p in players.values) {
      p.alive = true; p.x = .12 + math.Random().nextDouble() * .76;
      p.y = .15 + math.Random().nextDouble() * .7;
    }
    status = 'بدأت الجولة $round — $mode';
    _broadcastState();
  }

  Future<void> searchRooms() async {
    rooms.clear();
    await scanner?.close();
    scanner = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort,
      reuseAddress: true, reusePort: true);
    scanner!.broadcastEnabled = true;
    scanner!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final d = scanner?.receive();
      if (d == null) return;
      try {
        final m = jsonDecode(utf8.decode(d.data)) as Map<String, dynamic>;
        if (m['type'] == 'room') {
          final key = '${d.address.address}:${m['port']}';
          rooms[key] = {...m, 'ip': d.address.address};
          changed?.call();
        }
      } catch (_) {}
    });
    status = 'بدور على غرف قريبة... اتأكد إنكم على نفس الهوتسبوت';
    changed?.call();
    await Future.delayed(const Duration(seconds: 5));
    status = rooms.isEmpty
      ? 'مفيش غرف ظاهرة. اتأكد من نفس الهوتسبوت، أو جرّب الاتصال بالـ IP يدويًا.'
      : 'اختار الغرفة للانضمام';
    changed?.call();
  }

  Future<void> joinRoom(String ip, String name) async {
    await close(keepRooms: true);
    isHost = false; playing = false; status = 'جاري الاتصال...'; changed?.call();
    final socket = await Socket.connect(ip, tcpPort, timeout: const Duration(seconds: 5));
    String? id;
    final bytes = <int>[];
    socket.listen((data) {
      bytes.addAll(data);
      while (true) {
        final n = bytes.indexOf(10);
        if (n < 0) break;
        final line = utf8.decode(bytes.sublist(0, n), allowMalformed: true).trim();
        bytes.removeRange(0, n + 1);
        if (line.isEmpty) continue;
        try {
          final m = jsonDecode(line) as Map<String, dynamic>;
          if (m['type'] == 'welcome') {
            myId = '${m['id']}'; id = myId; sockets[id!] = socket;
            status = 'اتصلت بالغرفة'; changed?.call();
          } else if (m['type'] == 'state') {
            players
              ..clear()
              ..addEntries((m['players'] as List).map((e) {
                final p = Player.fromJson(Map<String, dynamic>.from(e));
                return MapEntry(p.id, p);
              }));
            bombs.clear();
            for (final b in (m['bombs'] as List? ?? [])) {
              bombs['${b['id']}'] = {'time': DateTime.now().subtract(Duration(milliseconds: (b['age'] as num?)?.toInt() ?? 0)), 'x': (b['x'] as num?)?.toDouble() ?? .5, 'y': (b['y'] as num?)?.toDouble() ?? .5, 'owner': '${b['owner'] ?? ''}'};
            }
            mode = '${m['mode']}'; round = (m['round'] as num?)?.toInt() ?? 1;
            secondsLeft = (m['seconds'] as num?)?.toInt() ?? 90;
            playing = m['playing'] == true; roomName = '${m['room'] ?? roomName}';
            maxPlayers = (m['max'] as num?)?.toInt() ?? 8;
            changed?.call();
          } else if (m['type'] == 'reject') {
            status = '${m['message'] ?? 'تعذر الدخول'}'; changed?.call();
          }
        } catch (_) {}
      }
    }, onDone: () { status = 'الاتصال اتقفل'; changed?.call(); }, onError: (_) {
      status = 'حصل خطأ في الاتصال'; changed?.call();
    });
    _sendSocket(socket, {'type': 'hello', 'name': name});
    status = 'بعت طلب الانضمام...'; changed?.call();
  }

  void move(double dx, double dy) {
    final p = players[myId];
    if (p == null || !playing || !p.alive) return;
    final boost = mode == 'سرعة مجنونة' ? 1.6 : 1.0;
    final double x = (p.x + dx * boost).clamp(.03, .97).toDouble();
    final double y = (p.y + dy * boost).clamp(.08, .92).toDouble();
    if (isHost) {
      p.x = x; p.y = y; _broadcastState();
    } else {
      _broadcast({'type': 'move', 'x': x, 'y': y});
      p.x = x; p.y = y; changed?.call();
    }
  }

  void dropBomb() {
    if (!playing) return;
    if (isHost) {
      final p = players[myId];
      if (p != null) bombs['${myId}_${DateTime.now().microsecondsSinceEpoch}'] = {'time': DateTime.now(), 'x': p.x, 'y': p.y, 'owner': myId};
      _broadcastState();
    } else {
      _broadcast({'type': 'bomb'});
    }
  }

  Future<void> close({bool keepRooms = false}) async {
    advertiseTimer?.cancel(); gameTimer?.cancel();
    await scanner?.close(); scanner = null;
    await discovery?.close(); discovery = null;
    for (final s in sockets.values.toList()) { try { s.destroy(); } catch (_) {} }
    sockets.clear(); buffers.clear();
    try { await server?.close(); } catch (_) {}
    server = null; isHost = false; playing = false;
    if (!keepRooms) rooms.clear();
  }
}

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});
  @override State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final net = ArenaNet();
  final name = TextEditingController(text: 'MORA');
  final room = TextEditingController(text: 'غرفة مورا');
  final ip = TextEditingController();
  int cap = 8;
  bool soundOn = true;
  @override void initState() { super.initState(); net.changed = () { if (mounted) setState(() {}); }; }
  @override void dispose() { net.close(); name.dispose(); room.dispose(); ip.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('💣 ARENA — لعب محلي بدون نت', style: TextStyle(fontWeight: FontWeight.w900)), backgroundColor: bg,
      actions: [IconButton(tooltip: soundOn ? 'إيقاف أصوات الواجهة' : 'تشغيل أصوات الواجهة',
        onPressed: () async { await ArenaMusic.toggle(); setState(() => soundOn = ArenaMusic.enabled); },
        icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off))]),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF253A67), Color(0xFF192039)]),
        borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF48D7FF).withOpacity(.45))),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ARENA BRAWL', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('العبوا على نفس نقطة الاتصال / الهوتسبوت. مفيش حسابات ولا سيرفر إنترنت.',
            style: TextStyle(fontSize: 14, height: 1.5)),
        ])),
      const SizedBox(height: 16),
      _field('اسمك في اللعبة', name),
      _field('اسم الغرفة', room),
      const SizedBox(height: 8),
      const Text('أقصى عدد لاعبين', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [2, 4, 6, 8].map((n) => ChoiceChip(
        label: Text('$n لاعبين'), selected: cap == n, onSelected: (_) => setState(() => cap = n))).toList()),
      const SizedBox(height: 14),
      SizedBox(height: 50, child: ElevatedButton.icon(
        onPressed: () async {
          try { await net.startHost(room.text.trim(), cap); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(net: net, isHost: true))); }
          catch (e) { _message('تعذر إنشاء الغرفة: $e'); }
        },
        icon: const Icon(Icons.add_circle), label: const Text('إنشاء غرفة — أنا المضيف'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48D7FF), foregroundColor: bg))),
      const SizedBox(height: 10),
      SizedBox(height: 50, child: OutlinedButton.icon(
        onPressed: () async { await net.searchRooms(); },
        icon: const Icon(Icons.radar), label: const Text('ابحث عن غرف قريبة'))),
      const SizedBox(height: 8),
      if (net.rooms.isNotEmpty) ...[
        const Text('الغرف القريبة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ...net.rooms.entries.map((e) => Card(color: panel, child: ListTile(
          leading: const Icon(Icons.wifi, color: Color(0xFF48D7FF)),
          title: Text('${e.value['name'] ?? 'غرفة'}'),
          subtitle: Text('${e.value['count'] ?? '?'} / ${e.value['max'] ?? '?'} لاعبين • ${e.value['ip']}'),
          trailing: const Icon(Icons.login),
          onTap: () async {
            try { await net.joinRoom('${e.value['ip']}', name.text.trim()); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(net: net, isHost: false))); }
            catch (err) { _message('الاتصال فشل. جرّب تاني أو اتأكد من الهوتسبوت. $err'); }
          }))),
      ],
      const SizedBox(height: 10),
      const Text('لو البحث مش لاقي الغرفة، اكتب IP المضيف يدويًا:', style: TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        Expanded(child: TextField(controller: ip, decoration: const InputDecoration(hintText: 'مثال: 192.168.43.1', filled: true, fillColor: panel, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () async {
          try { await net.joinRoom(ip.text.trim(), name.text.trim()); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(net: net, isHost: false))); }
          catch (e) { _message('الاتصال فشل: $e'); }
        }, child: const Text('اتصل')),
      ]),
      const SizedBox(height: 12),
      Text(net.status, style: const TextStyle(color: Color(0xFF9BA8CE))),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(
        color: panel, borderRadius: BorderRadius.circular(14)),
        child: const Column(children: [
          Text('تطوير وبرمجة: عمر هاني (Omar Hany)', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF48D7FF))),
          SizedBox(height: 4),
          Text('حقوق الكود والتصميم © عمر هاني — Arena Brawl', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white60)),
          SizedBox(height: 5),
          Text('أصوات الواجهة يمكن التحكم بها من زر الصوت. الموسيقى الخلفية تحتاج ملف صوت مضاف للمشروع.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white54)),
        ])),

      const SizedBox(height: 14),
      const Text('مهم: شغّل الهوتسبوت من موبايل المضيف، وصّل كل الأجهزة عليه، ثم افتحوا اللعبة. بعض الهواتف تمنع اكتشاف الغرف بالبث؛ استخدموا IP يدويًا لو لزم.', style: TextStyle(color: Color(0xFFFFD166), height: 1.5)),
    ])),
  );

  Widget _field(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, decoration: InputDecoration(labelText: label, filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
  );
  void _message(String s) => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: panel, content: Text(s), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))]));
}

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.net, required this.isHost});
  final ArenaNet net;
  final bool isHost;
  @override State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  ArenaNet get net => widget.net;
  @override void initState() { super.initState(); net.changed = () { if (mounted) setState(() {}); }; }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('💣 ${net.roomName}'), backgroundColor: bg, actions: [
      IconButton(onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: panel, title: const Text('اللاعبين'), content: Text(net.players.values.map((p) => '${p.name} — ${p.score} نقطة').join('\n')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))])), icon: const Icon(Icons.people)),
    ]),
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Row(children: [
        Expanded(child: Text('الجولة ${net.round} • ${net.mode}', style: const TextStyle(fontWeight: FontWeight.w900))),
        Text('${net.secondsLeft}s', style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w900)),
      ])),
      Expanded(child: Container(margin: const EdgeInsets.all(10), clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF19263A), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF48D7FF).withOpacity(.4))),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth, h = constraints.maxHeight;
          return Stack(children: [
            Positioned.fill(child: CustomPaint(painter: ArenaPainter())),
            ...net.players.values.map((p) {
              final c = playerColors[p.color % playerColors.length];
              return Positioned(left: (p.x * w - 19).clamp(0.0, w - 38).toDouble(), top: (p.y * h - 25).clamp(0.0, h - 50).toDouble(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(color: p.alive ? c : Colors.grey,
                    shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: c.withOpacity(.45), blurRadius: 12)]),
                    child: Icon(p.alive ? Icons.sports_mma : Icons.close, color: bg, size: 20)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(.65), borderRadius: BorderRadius.circular(5)),
                    child: Text('${p.name} ${p.score}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                ]));
            }),
            ...net.bombs.entries.map((e) {
              final bx = (e.value['x'] as num?)?.toDouble() ?? .5;
              final by = (e.value['y'] as num?)?.toDouble() ?? .5;
              return Positioned(left: bx * w - 10, top: by * h - 10,
                child: const Icon(Icons.circle, size: 22, color: Color(0xFFFF5978)));
            }),
            if (!net.playing) Center(child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(16)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('جاهزين للمعركة؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('اللاعبون: ${net.players.length} / ${net.maxPlayers}'),
                if (widget.isHost) ElevatedButton(onPressed: net.startRound, child: const Text('ابدأ الجولة')),
                if (!widget.isHost) const Text('استنى المضيف يبدأ الجولة'),
              ]))),
          ]);
        })),
      Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(children: [
            _moveButton('↑', 0, -.045),
            Row(children: [_moveButton('←', -.045, 0), const SizedBox(width: 6), _moveButton('↓', 0, .045), const SizedBox(width: 6), _moveButton('→', .045, 0)]),
          ]),
          Column(children: [
            SizedBox(width: 106, height: 56, child: ElevatedButton(
              onPressed: () { SystemSound.play(SystemSoundType.click); net.dropBomb(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5978), foregroundColor: Colors.white),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.brightness_1), Text('قنبلة', style: TextStyle(fontWeight: FontWeight.w900))]))),
            const SizedBox(height: 8),
            if (widget.isHost) TextButton.icon(onPressed: net.startRound, icon: const Icon(Icons.skip_next), label: const Text('الجولة التالية')),
          ]),
        ])),
      SizedBox(height: 64, child: ListView(scrollDirection: Axis.horizontal, children: net.players.values.map((p) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Chip(
          avatar: CircleAvatar(backgroundColor: playerColors[p.color % playerColors.length], child: Text('${p.score}', style: const TextStyle(color: bg, fontSize: 10))),
          label: Text(p.name))).toList())),
    ])),
  );

  Widget _moveButton(String label, double dx, double dy) => Padding(
    padding: const EdgeInsets.all(3),
    child: SizedBox(width: 44, height: 40, child: ElevatedButton(
      onPressed: () { SystemSound.play(SystemSoundType.click); net.move(dx, dy); },
      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: panel, foregroundColor: Colors.white),
      child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))));
}

class ArenaPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF2A3A55)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += 32) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    final border = Paint()..color = const Color(0xFF48D7FF)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)), border);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

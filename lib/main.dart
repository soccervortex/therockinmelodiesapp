import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// ============================================================
//  SUPABASE CONFIGURATION — vervang door uw eigen project
// ============================================================
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
const ADMIN_PASSWORD = 'admin123';

// ============================================================
//  MODEL
// ============================================================

class Booking {
  final String id;
  final String date;
  final String time;
  final String location;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String status;

  const Booking({
    required this.id,
    required this.date,
    required this.time,
    required this.location,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        contactName: json['contact_name']?.toString() ?? '',
        contactPhone: json['contact_phone']?.toString() ?? '',
        contactEmail: json['contact_email']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
      );
}

// ============================================================
//  MAIN
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('nl_NL');
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  runApp(const TheRockinMelodiesApp());
}

final supabase = Supabase.instance.client;

String _fmtDate(DateTime d) {
  try {
    return DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(d);
  } catch (_) {
    return DateFormat('yyyy-MM-dd').format(d);
  }
}

// ============================================================
//  THEME
// ============================================================

final _theme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE53935),
    secondary: Color(0xFFFF6F00),
    surface: Color(0xFF1E1E2E),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0D0D0D),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A2E),
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E2E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE53935),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A3E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    labelStyle: const TextStyle(color: Color(0xFFAAAAAA)),
    prefixIconColor: const Color(0xFFFF6F00),
  ),
  useMaterial3: true,
);

// ============================================================
//  APP
// ============================================================

class TheRockinMelodiesApp extends StatelessWidget {
  const TheRockinMelodiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "The Rockin' Melodies",
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: const HomeScreen(),
    );
  }
}

// ============================================================
//  HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  int _tabIndex = 0;

  void _showAdminDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Admin toegang',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Wachtwoord',
            prefixIcon: Icon(Icons.lock),
          ),
          onSubmitted: (_) => _tryLogin(ctrl.text, ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren',
                style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          ElevatedButton(
            onPressed: () => _tryLogin(ctrl.text, ctx),
            child: const Text('Inloggen'),
          ),
        ],
      ),
    );
  }

  void _tryLogin(String pw, BuildContext dialogCtx) {
    if (pw == ADMIN_PASSWORD) {
      setState(() => _isAdmin = true);
      Navigator.pop(dialogCtx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Onjuist wachtwoord'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── GRADIENT HEADER ─────────────────────────────
          _Header(
            isAdmin: _isAdmin,
            onAdminTap: _isAdmin
                ? () => setState(() {
                      _isAdmin = false;
                      _tabIndex = 0;
                    })
                : _showAdminDialog,
          ),

          // ── ADMIN TABS ───────────────────────────────────
          if (_isAdmin)
            Container(
              color: const Color(0xFF1A1A2E),
              child: Row(
                children: [
                  _TabBtn(
                    label: 'Aanvragen',
                    icon: Icons.inbox_rounded,
                    selected: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  _TabBtn(
                    label: 'Blokkeren',
                    icon: Icons.block_rounded,
                    selected: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
            ),

          // ── CONTENT ──────────────────────────────────────
          Expanded(
            child: _isAdmin
                ? (_tabIndex == 0
                    ? const AdminRequestsView()
                    : const AdminBlockView())
                : const ClientView(),
          ),
        ],
      ),
    );
  }
}

// ── Header widget ────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onAdminTap;

  const _Header({required this.isAdmin, required this.onAdminTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A00), Color(0xFF1A1A2E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAdminTap,
                  icon: Icon(
                    isAdmin ? Icons.logout : Icons.admin_panel_settings,
                    size: 16,
                    color: isAdmin
                        ? const Color(0xFFFF6F00)
                        : const Color(0xFF777777),
                  ),
                  label: Text(
                    isAdmin ? 'Uitloggen' : 'Admin',
                    style: TextStyle(
                      color: isAdmin
                          ? const Color(0xFFFF6F00)
                          : const Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.music_note_rounded,
                  size: 52, color: Color(0xFFE53935)),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFFF6F00), Color(0xFFFFCA28)],
                ).createShader(bounds),
                child: const Text(
                  "BOOK THE ROCKIN' MELODIES",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAdmin
                    ? '🎸  Admin Paneel'
                    : 'Selecteer een datum om te boeken',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFFE53935) : const Color(0xFF777777);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: selected
                      ? const Color(0xFFE53935)
                      : Colors.transparent,
                  width: 3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  CLIENT VIEW
// ============================================================

class ClientView extends StatefulWidget {
  const ClientView({super.key});

  @override
  State<ClientView> createState() => _ClientViewState();
}

class _ClientViewState extends State<ClientView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _bookedDates = {};
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _loadBookedDates() async {
    try {
      final data = await supabase
          .from('bookings')
          .select('date')
          .eq('status', 'accepted');
      if (mounted) {
        setState(() {
          _bookedDates =
              Set<String>.from(data.map((r) => r['date'].toString()));
        });
      }
    } catch (e) {
      debugPrint('Error loading booked dates: $e');
    }
  }

  void _subscribeRealtime() {
    _channel = supabase
        .channel('client-bookings-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _loadBookedDates(),
        )
        .subscribe();
  }

  bool _isBooked(DateTime day) =>
      _bookedDates.contains(DateFormat('yyyy-MM-dd').format(day));

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return DateTime(day.year, day.month, day.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    if (_isBooked(selected) || _isPast(selected)) return;
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingFormSheet(date: selected),
    );
  }

  Widget _bookedCell(int dayNum) => Container(
        margin: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2A2A2A),
        ),
        child: Center(
          child: Text(
            '$dayNum',
            style: const TextStyle(
                color: Color(0xFF555555),
                decoration: TextDecoration.lineThrough,
                decorationColor: Color(0xFF666666)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: firstDay,
                lastDay: today.add(const Duration(days: 730)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: _onDaySelected,
                enabledDayPredicate: (d) => !_isBooked(d) && !_isPast(d),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle:
                      TextStyle(color: Color(0xFFFF6F00)),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                  ),
                  selectedTextStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF333355),
                  ),
                  todayTextStyle: TextStyle(
                      color: Color(0xFFFF6F00), fontWeight: FontWeight.bold),
                  disabledTextStyle: TextStyle(color: Color(0xFF444444)),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: Color(0xFFE53935)),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Color(0xFFE53935)),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: Color(0xFFAAAAAA), fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(
                      color: Color(0xFFFF6F00), fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  // Disabled covers both past days AND booked days
                  disabledBuilder: (ctx, day, _) {
                    if (_isBooked(day)) return _bookedCell(day.day);
                    return null; // Default dimmed for past days
                  },
                  // Today might be booked
                  todayBuilder: (ctx, day, _) {
                    if (_isBooked(day)) return _bookedCell(day.day);
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Legend(color: Color(0xFF2A2A2A), label: 'Bezet'),
              SizedBox(width: 20),
              _Legend(color: Color(0xFFE53935), label: 'Geselecteerd'),
              SizedBox(width: 20),
              _Legend(
                  color: Color(0xFF1E1E2E),
                  label: 'Beschikbaar',
                  border: Color(0xFF444444)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Column(
              children: [
                Icon(Icons.touch_app_rounded,
                    color: Color(0xFFFF6F00), size: 30),
                SizedBox(height: 10),
                Text(
                  'Tik op een beschikbare datum\nom een boekingsaanvraag in te dienen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final Color? border;

  const _Legend({required this.color, required this.label, this.border});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: border != null ? Border.all(color: border!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ],
    );
  }
}

// ============================================================
//  BOOKING FORM BOTTOM SHEET
// ============================================================

class BookingFormSheet extends StatefulWidget {
  final DateTime date;
  const BookingFormSheet({super.key, required this.date});

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _timeCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _timeCtrl.dispose();
    _locCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await supabase.from('bookings').insert({
        'date': DateFormat('yyyy-MM-dd').format(widget.date),
        'time': _timeCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'contact_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'contact_email': _emailCtrl.text.trim(),
        'status': 'pending',
      });
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fout bij indienen: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child:
          SingleChildScrollView(child: _success ? _buildOk() : _buildForm()),
    );
  }

  Widget _buildOk() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF4CAF50), size: 80),
        const SizedBox(height: 16),
        const Text('Aanvraag ingediend!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 10),
        Text(
          'Uw boekingsaanvraag voor ${_fmtDate(widget.date)} is succesvol ontvangen.\n\nWij nemen zo snel mogelijk contact met u op.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten')),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          // Title
          Row(
            children: [
              const Icon(Icons.event_rounded,
                  color: Color(0xFFE53935), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Boeking voor ${_fmtDate(widget.date)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Field(
            ctrl: _timeCtrl,
            label: 'Tijdstip',
            hint: 'bijv. 20:00 – 23:00',
            icon: Icons.access_time_rounded,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vul een tijdstip in' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: _locCtrl,
            label: 'Locatie',
            hint: 'Naam en adres van de locatie',
            icon: Icons.location_on_rounded,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vul een locatie in' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: _nameCtrl,
            label: 'Uw naam',
            hint: 'Voor- en achternaam',
            icon: Icons.person_rounded,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vul uw naam in' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: _phoneCtrl,
            label: 'Telefoonnummer',
            hint: '+31 6 12345678',
            icon: Icons.phone_rounded,
            type: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vul uw telefoonnummer in' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: _emailCtrl,
            label: 'E-mailadres',
            hint: 'naam@voorbeeld.nl',
            icon: Icons.email_rounded,
            type: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vul uw e-mailadres in';
              if (!v.contains('@') || !v.contains('.'))
                return 'Ongeldig e-mailadres';
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'Bezig…' : 'Aanvragen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ============================================================
//  ADMIN — INKOMENDE AANVRAGEN
// ============================================================

class AdminRequestsView extends StatefulWidget {
  const AdminRequestsView({super.key});

  @override
  State<AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<AdminRequestsView> {
  List<Booking> _pending = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await supabase
          .from('bookings')
          .select()
          .eq('status', 'pending')
          .order('date', ascending: true);
      if (mounted) {
        setState(() {
          _pending = data.map<Booking>((r) => Booking.fromJson(r)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = supabase
        .channel('admin-requests-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.inbox_rounded, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Text(
                'Inkomende Aanvragen (${_pending.length})',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE53935)))
              : _pending.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFFE53935),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pending.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _pending[i],
                          onAccept: () =>
                              _setStatus(_pending[i].id, 'accepted'),
                          onReject: () =>
                              _setStatus(_pending[i].id, 'rejected'),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 72, color: Color(0xFF4CAF50)),
          SizedBox(height: 16),
          Text('Geen openstaande aanvragen',
              style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    String displayDate = booking.date;
    try {
      displayDate = _fmtDate(DateTime.parse(booking.date));
    } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 15, color: Color(0xFFE53935)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(displayDate,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                          fontSize: 14))),
            ]),
            if (booking.time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 15, color: Color(0xFFFF6F00)),
                const SizedBox(width: 6),
                Text(booking.time,
                    style: const TextStyle(
                        color: Color(0xFFFF6F00), fontSize: 14)),
              ]),
            ],
            const Divider(color: Color(0xFF2A2A2A), height: 20),
            _Row(Icons.location_on_rounded, booking.location),
            _Row(Icons.person_rounded, booking.contactName),
            _Row(Icons.phone_rounded, booking.contactPhone),
            _Row(Icons.email_rounded, booking.contactEmail),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Weigeren'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF5350),
                      side:
                          const BorderSide(color: Color(0xFFEF5350)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Accepteren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF666666)),
          const SizedBox(width: 7),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFFCCCCCC), fontSize: 13))),
        ],
      ),
    );
  }
}

// ============================================================
//  ADMIN — HANDMATIG BLOKKEREN
// ============================================================

class AdminBlockView extends StatefulWidget {
  const AdminBlockView({super.key});

  @override
  State<AdminBlockView> createState() => _AdminBlockViewState();
}

class _AdminBlockViewState extends State<AdminBlockView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _blocked = {};
  bool _saving = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _loadBlocked() async {
    try {
      final data = await supabase
          .from('bookings')
          .select('date')
          .eq('status', 'accepted');
      if (mounted) {
        setState(() {
          _blocked =
              Set<String>.from(data.map((r) => r['date'].toString()));
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _subscribeRealtime() {
    _channel = supabase
        .channel('admin-block-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _loadBlocked(),
        )
        .subscribe();
  }

  bool _isBlocked(DateTime d) =>
      _blocked.contains(DateFormat('yyyy-MM-dd').format(d));

  Future<void> _blockSelected() async {
    if (_selectedDay == null) return;
    setState(() => _saving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    try {
      await supabase.from('bookings').insert({
        'date': dateStr,
        'time': '',
        'location': '',
        'contact_name': 'MANUAL BLOCK',
        'contact_phone': '',
        'contact_email': '',
        'status': 'accepted',
      });
      await _loadBlocked();
      if (mounted) {
        setState(() {
          _selectedDay = null;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dateStr succesvol geblokkeerd'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _blockedCell(int dayNum) => Container(
        margin: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2A2A2A),
        ),
        child: Center(
          child: Text(
            '$dayNum',
            style: const TextStyle(
                color: Color(0xFF555555),
                decoration: TextDecoration.lineThrough,
                decorationColor: Color(0xFF666666)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Selecteer een datum in de kalender om deze te blokkeren voor nieuwe boekingen.',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: firstDay,
                lastDay: today.add(const Duration(days: 730)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                enabledDayPredicate: (d) => !_isBlocked(d),
                onDaySelected: (sel, foc) {
                  if (!_isBlocked(sel)) {
                    setState(() {
                      _selectedDay = sel;
                      _focusedDay = foc;
                    });
                  }
                },
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle:
                      TextStyle(color: Color(0xFFFF6F00)),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                  ),
                  selectedTextStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF333355),
                  ),
                  todayTextStyle: TextStyle(
                      color: Color(0xFFFF6F00),
                      fontWeight: FontWeight.bold),
                  disabledTextStyle: TextStyle(color: Color(0xFF444444)),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left,
                      color: Color(0xFFE53935)),
                  rightChevronIcon: Icon(Icons.chevron_right,
                      color: Color(0xFFE53935)),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(
                      color: Color(0xFFFF6F00),
                      fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  disabledBuilder: (ctx, day, _) {
                    if (_isBlocked(day)) return _blockedCell(day.day);
                    return null;
                  },
                  todayBuilder: (ctx, day, _) {
                    if (_isBlocked(day)) return _blockedCell(day.day);
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE53935)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_busy_rounded,
                          color: Color(0xFFE53935)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fmtDate(_selectedDay!),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _blockSelected,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.block_rounded),
                      label: Text(
                          _saving ? 'Bezig…' : 'Datum Blokkeren'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_blocked.isNotEmpty) ...[
            const Text('Geblokkeerde data:',
                style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (_blocked.toList()..sort()).map((d) {
                    String label = d;
                    try {
                      label = _fmtDate(DateTime.parse(d));
                    } catch (_) {}
                    return Chip(
                      label: Text(label,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 12)),
                      backgroundColor: const Color(0xFF2A2A2A),
                      side: const BorderSide(color: Color(0xFF444444)),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

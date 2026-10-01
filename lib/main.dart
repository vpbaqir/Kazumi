import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MalayalamBooksApp());
}

class Book {
  final String id;
  String title;
  String author;
  String category;
  String description;
  String coverUrl;
  String pdfUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.coverUrl,
    required this.pdfUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'category': category,
        'description': description,
        'coverUrl': coverUrl,
        'pdfUrl': pdfUrl,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        category: json['category'] ?? 'മറ്റുള്ളവ',
        description: json['description'] ?? '',
        coverUrl: json['coverUrl'] ?? '',
        pdfUrl: json['pdfUrl'] ?? '',
      );
}

class BookStore extends ChangeNotifier {
  static const _key = 'malayalam_books';
  final List<Book> books = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      books
        ..clear()
        ..addAll(decoded.map((e) => Book.fromJson(Map<String, dynamic>.from(e))));
    } else {
      books.addAll([
        Book(
          id: '1',
          title: 'എന്റെ മലയാളം പുസ്തകം',
          author: 'മലയാളം ക്ലാസിക്',
          category: 'ക്ലാസിക്',
          description: 'നിങ്ങളുടെ ആദ്യ പുസ്തക ശേഖരത്തിനുള്ള sample book.',
          coverUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
          pdfUrl: '',
        ),
        Book(
          id: '2',
          title: 'കേരള ചരിത്രം',
          author: 'ചരിത്ര വിഭാഗം',
          category: 'ചരിത്രം',
          description: 'കേരളത്തിന്റെ ചരിത്രവും സംസ്കാരവും പരിചയപ്പെടുത്തുന്ന sample entry.',
          coverUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800',
          pdfUrl: '',
        ),
        Book(
          id: '3',
          title: 'ഇസ്‌ലാമിക വിജ്ഞാനം',
          author: 'വിജ്ഞാന പരമ്പര',
          category: 'ഇസ്‌ലാമികം',
          description: 'ഇസ്‌ലാമിക പഠനത്തിനുള്ള sample collection item.',
          coverUrl: 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=800',
          pdfUrl: '',
        ),
      ]);
      await _save();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(books.map((e) => e.toJson()).toList()));
  }

  Future<void> add(Book book) async {
    books.insert(0, book);
    await _save();
    notifyListeners();
  }

  Future<void> update(Book book) async {
    final index = books.indexWhere((e) => e.id == book.id);
    if (index != -1) books[index] = book;
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    books.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }
}

class MalayalamBooksApp extends StatefulWidget {
  const MalayalamBooksApp({super.key});

  @override
  State<MalayalamBooksApp> createState() => _MalayalamBooksAppState();
}

class _MalayalamBooksAppState extends State<MalayalamBooksApp> {
  final store = BookStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Malayalam Books',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ml'), Locale('en')],
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0D12),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C5CFF),
            brightness: Brightness.dark,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF151821),
            margin: EdgeInsets.zero,
          ),
        ),
        home: HomePage(store: store),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final BookStore store;
  const HomePage({super.key, required this.store});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = '';
  String selectedCategory = 'എല്ലാം';

  List<Book> get filtered {
    final q = query.trim().toLowerCase();
    return widget.store.books.where((b) {
      final categoryOk =
          selectedCategory == 'എല്ലാം' || b.category == selectedCategory;
      final searchOk = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  List<String> get categories => [
        'എല്ലാം',
        ...{for (final b in widget.store.books) b.category}
      ];

  Future<void> openAdmin() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN', hintText: 'Admin PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text == '1234'),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminPage(store: widget.store)),
      );
    } else if (ok == false && controller.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admin PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = filtered;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('മലയാളം', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('BOOKS', style: TextStyle(fontSize: 12, letterSpacing: 3)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Admin',
            onPressed: openAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'നിങ്ങളുടെ മലയാളം\nപുസ്തകശേഖരം',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.store.books.length} പുസ്തകങ്ങൾ · വായിക്കാനും സൂക്ഷിക്കാനും',
                    style: TextStyle(color: Colors.white.withOpacity(.58)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'പുസ്തകം, എഴുത്തുകാരൻ എന്നിവ തിരയുക',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFF151821),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = categories[i];
                        return ChoiceChip(
                          label: Text(c),
                          selected: selectedCategory == c,
                          onSelected: (_) =>
                              setState(() => selectedCategory = c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (books.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('പുസ്തകങ്ങൾ കണ്ടെത്താനായില്ല')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => BookCard(book: books[index]),
                  childCount: books.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  childAspectRatio: .61,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Book book;
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: const Color(0xFF1C202A),
                child: book.coverUrl.isEmpty
                    ? const Center(child: Icon(Icons.menu_book, size: 48))
                    : Image.network(
                        book.coverUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.menu_book, size: 48)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class BookDetailsPage extends StatelessWidget {
  final Book book;
  const BookDetailsPage({super.key, required this.book});

  Future<void> openBook(BuildContext context) async {
    if (book.pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ഈ പുസ്തകത്തിന് PDF link ചേർത്തിട്ടില്ല.')),
      );
      return;
    }
    final uri = Uri.tryParse(book.pdfUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF തുറക്കാൻ കഴിഞ്ഞില്ല.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('പുസ്തക വിവരങ്ങൾ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: .72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: book.coverUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFF1C202A),
                      child: Icon(Icons.menu_book, size: 70),
                    )
                  : Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF1C202A),
                        child: Icon(Icons.menu_book, size: 70),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Text(book.category.toUpperCase(),
              style: const TextStyle(fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 7),
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(book.author,
              style: TextStyle(color: Colors.white.withOpacity(.6))),
          const SizedBox(height: 20),
          Text(
            book.description.isEmpty ? 'വിവരണം ലഭ്യമല്ല.' : book.description,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openBook(context),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('വായിക്കുക / PDF തുറക്കുക'),
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  final BookStore store;
  const AdminPage({super.key, required this.store});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Future<void> editBook([Book? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final author = TextEditingController(text: existing?.author ?? '');
    final category =
        TextEditingController(text: existing?.category ?? 'മറ്റുള്ളവ');
    final description =
        TextEditingController(text: existing?.description ?? '');
    final cover = TextEditingController(text: existing?.coverUrl ?? '');
    final pdf = TextEditingController(text: existing?.pdfUrl ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'പുസ്തകം ചേർക്കുക' : 'പുസ്തകം തിരുത്തുക'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(title, 'പുസ്തകത്തിന്റെ പേര്'),
                _field(author, 'എഴുത്തുകാരൻ'),
                _field(category, 'Category'),
                _field(description, 'വിവരണം', maxLines: 4),
                _field(cover, 'Cover image URL'),
                _field(pdf, 'PDF URL'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || title.text.trim().isEmpty) return;

    final book = Book(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.text.trim(),
      author: author.text.trim(),
      category:
          category.text.trim().isEmpty ? 'മറ്റുള്ളവ' : category.text.trim(),
      description: description.text.trim(),
      coverUrl: cover.text.trim(),
      pdfUrl: pdf.text.trim(),
    );

    if (existing == null) {
      await widget.store.add(book);
    } else {
      await widget.store.update(book);
    }
    if (mounted) setState(() {});
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · Books'),
        actions: [
          IconButton(
            onPressed: () => editBook(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: widget.store.books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final book = widget.store.books[i];
          return Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 45,
                  height: 60,
                  child: book.coverUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFF222633),
                          child: Icon(Icons.book),
                        )
                      : Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.book),
                        ),
                ),
              ),
              title: Text(book.title),
              subtitle: Text('${book.author} · ${book.category}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') await editBook(book);
                  if (v == 'delete') {
                    await widget.store.remove(book.id);
                    if (mounted) setState(() {});
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editBook(),
        icon: const Icon(Icons.add),
        label: const Text('പുസ്തകം ചേർക്കുക'),
      ),
    );
  }
}

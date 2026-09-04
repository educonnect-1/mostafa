import 'package:flutter/material.dart';
import '../history/history_store.dart';
import '../input/problem_input_page.dart';
import '../settings/settings_page.dart';
import '../solver/math_solver.dart';
import '../solver/models/solution.dart';
import '../steps/steps_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SolverPage(),
      const HistoryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Solve',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class SolverPage extends StatefulWidget {
  const SolverPage({super.key});

  @override
  State<SolverPage> createState() => _SolverPageState();
}

class _SolverPageState extends State<SolverPage> {
  final _controller = TextEditingController();
  final _solver = MathSolver();
  final _history = HistoryStore();

  Solution? _solution;
  bool _showSteps = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final value = await _history.loadStepsPreference();
    if (mounted) setState(() => _showSteps = value);
  }

  Future<void> _solve() async {
    final problem = _controller.text.trim();
    if (problem.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final result = _solver.solve(problem);
    await _history.add(problem);

    if (!mounted) return;
    setState(() {
      _solution = result;
      _busy = false;
    });
  }

  Future<void> _openInput() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ProblemInputPage()),
    );
    if (result != null && result.trim().isNotEmpty) {
      _controller.text = result;
      await _solve();
    }
  }

  void _setExample(String example) {
    setState(() {
      _controller.text = example;
      _solution = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MathSolve',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: () => setState(() {
              _controller.clear();
              _solution = null;
            }),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Text(
            'Solve mathematics offline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'No online AI solver. Enter a problem, scan it, or speak it.',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Mathematical problem',
                      hintText: '2x + 6 = 14',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _QuickChip(
                        label: '+',
                        onTap: () => _insert(' + '),
                      ),
                      _QuickChip(
                        label: '−',
                        onTap: () => _insert(' - '),
                      ),
                      _QuickChip(
                        label: '×',
                        onTap: () => _insert(' * '),
                      ),
                      _QuickChip(
                        label: '÷',
                        onTap: () => _insert(' / '),
                      ),
                      _QuickChip(
                        label: 'x²',
                        onTap: () => _insert('x^2'),
                      ),
                      _QuickChip(
                        label: '=',
                        onTap: () => _insert(' = '),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openInput,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan / Voice'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _solve,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Solve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _showSteps,
            onChanged: (value) async {
              setState(() => _showSteps = value);
              await _history.saveStepsPreference(value);
            },
            title: const Text('Show mathematical transformations'),
            subtitle: const Text('Disable for answer-only mode.'),
          ),
          const SizedBox(height: 8),
          Text('Try an example',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExampleChip(
                text: '2x + 6 = 14',
                onTap: () => _setExample('2x + 6 = 14'),
              ),
              _ExampleChip(
                text: 'x² - 5x + 6 = 0',
                onTap: () => _setExample('x^2 - 5x + 6 = 0'),
              ),
              _ExampleChip(
                text: '3x - 4 > 8',
                onTap: () => _setExample('3x - 4 > 8'),
              ),
              _ExampleChip(
                text: '2x+3y=7; x-y=1',
                onTap: () => _setExample('2x+3y=7; x-y=1'),
              ),
              _ExampleChip(
                text: 'derivative: x^3 + 2x',
                onTap: () => _setExample('derivative: x^3 + 2x'),
              ),
            ],
          ),
          if (_solution != null) ...[
            const SizedBox(height: 20),
            _AnswerCard(solution: _solution!),
            if (_showSteps && _solution!.success)
              StepsView(solution: _solution!),
          ],
        ],
      ),
    );
  }

  void _insert(String value) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final next = text.replaceRange(start, end, value);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onPressed: onTap,
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final Solution solution;

  const _AnswerCard({required this.solution});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              solution.success ? 'Answer' : 'Could not solve',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            SelectableText(
              solution.success
                  ? solution.answer
                  : (solution.error ?? 'Unknown error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: solution.success ? 24 : 15,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: solution.success
                    ? const Color(0xFF17202A)
                    : const Color(0xFF9B3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _history = HistoryStore();
  List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await _history.load();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _clear() async {
    await _history.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: _clear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No solved problems yet.\nYour recent problems will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.functions_rounded),
                        ),
                        title: Text(
                          item,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          onPressed: () async {
                            await _history.remove(item);
                            await _reload();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

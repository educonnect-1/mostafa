import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/utils/math_text.dart';

class ProblemInputPage extends StatefulWidget {
  const ProblemInputPage({super.key});

  @override
  State<ProblemInputPage> createState() => _ProblemInputPageState();
}

class _ProblemInputPageState extends State<ProblemInputPage> {
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _speech = stt.SpeechToText();

  File? _image;
  bool _busy = false;
  bool _listening = false;
  String _status = '';

  @override
  void dispose() {
    _controller.dispose();
    _recognizer.close();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _busy = true;
      _status = 'Reading the image locally...';
    });

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2400,
      );

      if (picked == null) {
        setState(() => _busy = false);
        return;
      }

      final input = InputImage.fromFilePath(picked.path);
      final result = await _recognizer.processImage(input);
      final normalized = MathText.normalize(result.text);

      if (!mounted) return;
      setState(() {
        _image = File(picked.path);
        _controller.text = normalized;
        _busy = false;
        _status = normalized.isEmpty
            ? 'No text was detected. Enter the problem manually.'
            : 'Review the detected problem before using it.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Image reading failed. You can enter the problem manually.';
      });
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        setState(() => _status =
            'Speech recognition is not available on this device.');
      }
      return;
    }

    setState(() {
      _listening = true;
      _status = 'Listening... speak the equation in English.';
    });

    await _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        if (!mounted) return;
        _controller.text = MathText.cleanVoice(result.recognizedWords);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input problem')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Text('Capture or speak',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'MathSolve reads the input locally. Always check the detected equation before solving.',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _scan(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _scan(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _toggleVoice,
            icon: Icon(_listening
                ? Icons.stop_circle_outlined
                : Icons.mic_none_outlined),
            label: Text(_listening ? 'Stop listening' : 'Speak in English'),
          ),
          if (_image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _image!,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_status, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Detected problem',
              hintText: '2x + 6 = 14',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _controller.text),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Use this problem'),
          ),
        ],
      ),
    );
  }
}

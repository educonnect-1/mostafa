import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/utils/math_text.dart';
import '../ocr/math_region_extractor.dart';

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
    _recognizer.close();
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _busy = true;
      _status = 'Extracting the mathematical problem locally...';
    });

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 100);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      final mathOnly = MathRegionExtractor.extract(result);
      final normalized = MathText.normalize(mathOnly);

      if (!mounted) return;
      setState(() {
        _image = File(file.path);
        _controller.text = normalized;
        _status = normalized.isEmpty
            ? 'No mathematical expression was detected. You can type it manually.'
            : 'Only the detected mathematical expression is shown. Review it before solving.';
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Could not read the image. You can type the equation manually.';
        _busy = false;
      });
    }
  }

  Future<void> _voice() async {
    final available = await _speech.initialize();
    if (!available) {
      if (mounted) setState(() => _status = 'Speech input is not available on this device.');
      return;
    }

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() {
      _listening = true;
      _status = 'Listening for a mathematical problem...';
    });

    await _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        if (!mounted) return;
        final converted = MathText.cleanVoice(result.recognizedWords);
        setState(() {
          _controller.text = converted;
          _controller.selection = TextSelection.collapsed(offset: converted.length);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Problem input')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            onPressed: _busy ? null : _voice,
            icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
            label: Text(_listening ? 'Stop listening' : 'Speak problem'),
          ),
          if (_image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_image!, height: 180, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_status, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Detected mathematical problem',
              hintText: '2x + 6 = 14',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _controller.text),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Use this problem'),
          ),
        ],
      ),
    );
  }
}

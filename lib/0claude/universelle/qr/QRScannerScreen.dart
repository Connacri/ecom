import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../services/enhanced_auth_service.dart';

// ============================================
// ÉCRAN SCANNER QR CODE (MOBILE)
// ============================================

/// Écran pour scanner un QR Code de connexion depuis l'application mobile
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final _authService = EnhancedAuthService();

  MobileScannerController? _cameraController;
  bool _processing = false;
  bool _flashOn = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimation();
  }

  void _initializeCamera() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Traiter le QR Code scanné
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _processing = true);

    try {
      // Extraire le sessionId
      final sessionId = _extractSessionId(code);

      if (sessionId == null) {
        throw Exception('QR Code invalide');
      }

      // Afficher dialogue de confirmation
      if (!mounted) return;
      final confirmed = await _showConfirmDialog();

      if (!confirmed) {
        setState(() => _processing = false);
        return;
      }

      // Approuver la session
      final success = await _authService.approveQRSession(sessionId);

      if (success && mounted) {
        // Succès
        await _showSuccessDialog();

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  /// Extraire le sessionId du QR Code
  String? _extractSessionId(String qrData) {
    try {
      // Format: "auth://login?session=SESSION_ID"
      final uri = Uri.parse(qrData);

      if (uri.scheme != 'auth' || uri.host != 'login') {
        return null;
      }

      return uri.queryParameters['session'];
    } catch (e) {
      debugPrint('❌ Erreur parsing QR: $e');
      return null;
    }
  }

  /// Dialogue de confirmation
  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(child: Text('Autoriser la connexion ?')),
                  ],
                ),
                content: const Text(
                  'Vous êtes sur le point d\'autoriser une connexion sur un autre appareil. '
                  'Continuez uniquement si vous êtes à l\'origine de cette demande.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Autoriser'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  /// Dialogue de succès
  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Connexion autorisée !',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'L\'appareil a été connecté avec succès',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Dialogue d'erreur
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 12),
                Text('Erreur'),
              ],
            ),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Basculer le flash
  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _cameraController?.toggleTorch();
  }

  /// Basculer la caméra
  void _switchCamera() {
    _cameraController?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scanner QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _cameraController, onDetect: _onDetect),

          // Overlay avec animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScannerOverlayPainter(
                  animationValue: _animation.value,
                ),
                child: Container(),
              );
            },
          ),

          // Instructions en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Placez le QR Code dans le cadre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le scan se fera automatiquement',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de traitement
          if (_processing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Vérification...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Painter pour l'overlay du scanner avec animation
class ScannerOverlayPainter extends CustomPainter {
  final double animationValue;

  ScannerOverlayPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    // Zone de scan
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.width * 0.75,
    );

    // Dessiner l'overlay sombre
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(scanArea, const Radius.circular(20)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Dessiner les coins
    final cornerPaint =
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Helper pour dessiner les coins
    void drawCorner(Offset start, Offset end1, Offset end2) {
      canvas.drawLine(start, end1, cornerPaint);
      canvas.drawLine(start, end2, cornerPaint);
    }

    // Haut-gauche
    drawCorner(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(cornerLength, 0),
      scanArea.topLeft + const Offset(0, cornerLength),
    );

    // Haut-droit
    drawCorner(
      scanArea.topRight,
      scanArea.topRight + const Offset(-cornerLength, 0),
      scanArea.topRight + const Offset(0, cornerLength),
    );

    // Bas-gauche
    drawCorner(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(cornerLength, 0),
      scanArea.bottomLeft + const Offset(0, -cornerLength),
    );

    // Bas-droit
    drawCorner(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(-cornerLength, 0),
      scanArea.bottomRight + const Offset(0, -cornerLength),
    );

    // Ligne de scan animée
    final scanLinePaint =
        Paint()
          ..color = Colors.greenAccent.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    final scanY = scanArea.top + (scanArea.height * animationValue);

    canvas.drawLine(
      Offset(scanArea.left, scanY),
      Offset(scanArea.right, scanY),
      scanLinePaint,
    );

    // Gradient de la ligne
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.greenAccent.withOpacity(0),
              Colors.greenAccent.withOpacity(0.5),
              Colors.greenAccent.withOpacity(0),
            ],
          ).createShader(
            Rect.fromLTWH(scanArea.left, scanY - 20, scanArea.width, 40),
          );

    canvas.drawRect(
      Rect.fromLTWH(scanArea.left, scanY - 20, scanArea.width, 40),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

// ============================================
// ÉCRAN AFFICHAGE QR CODE (DESKTOP/WEB)
// ============================================

/// Écran pour afficher un QR Code de connexion sur desktop/web
class QRDisplayScreen extends StatefulWidget {
  const QRDisplayScreen({super.key});

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final _authService = EnhancedAuthService();

  String? _sessionId;
  String? _qrData;
  bool _loading = true;
  QRSessionStatus _status = QRSessionStatus.pending;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _generateQRSession();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  /// Générer une nouvelle session QR
  Future<void> _generateQRSession() async {
    setState(() => _loading = true);

    try {
      final sessionId = await _authService.generateQRSession();

      setState(() {
        _sessionId = sessionId;
        _qrData = 'auth://login?session=$sessionId';
        _loading = false;
        _status = QRSessionStatus.pending;
      });

      // Écouter les changements de statut
      _listenToSessionStatus(sessionId);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Écouter le statut de la session
  void _listenToSessionStatus(String sessionId) {
    _statusSubscription?.cancel();

    _statusSubscription = _authService
        .watchQRSession(sessionId)
        .listen(
          (status) {
            if (!mounted) return;

            setState(() {
              _status = _parseStatus(status);
            });

            // Si approuvé, rediriger vers home
            if (_status == QRSessionStatus.approved) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              });
            }
          },
          onError: (error) {
            debugPrint('❌ Erreur stream: $error');
          },
        );
  }

  QRSessionStatus _parseStatus(String status) {
    switch (status) {
      case 'approved':
        return QRSessionStatus.approved;
      case 'rejected':
        return QRSessionStatus.rejected;
      case 'expired':
        return QRSessionStatus.expired;
      default:
        return QRSessionStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion par QR Code'),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Statut
                    _buildStatusWidget(),

                    const SizedBox(height: 40),

                    // QR Code ou feedback
                    _buildContentWidget(),

                    const SizedBox(height: 40),

                    // Instructions
                    _buildInstructionsWidget(),

                    const SizedBox(height: 24),

                    // Actions
                    _buildActionsWidget(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget() {
    if (_status == QRSessionStatus.pending && _qrData != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: PrettyQrView.data(
            data: _qrData!,
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: Colors.black),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Icon(_getStatusIcon(), size: 150, color: _getStatusColor()),
    );
  }

  Widget _buildInstructionsWidget() {
    if (_status != QRSessionStatus.pending) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Comment se connecter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('1. Ouvrez l\'application sur votre téléphone'),
          Text('2. Connectez-vous à votre compte'),
          Text('3. Appuyez sur "Scanner un QR Code"'),
          Text('4. Scannez ce code'),
          Text('5. Confirmez la connexion'),
        ],
      ),
    );
  }

  Widget _buildActionsWidget() {
    if (_status == QRSessionStatus.pending) {
      return TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Connexion classique'),
      );
    }

    return ElevatedButton.icon(
      onPressed: _generateQRSession,
      icon: const Icon(Icons.refresh),
      label: const Text('Générer un nouveau code'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case QRSessionStatus.pending:
        return Icons.qr_code_2;
      case QRSessionStatus.approved:
        return Icons.check_circle;
      case QRSessionStatus.rejected:
        return Icons.cancel;
      case QRSessionStatus.expired:
        return Icons.timer_off;
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case QRSessionStatus.pending:
        return Colors.blue;
      case QRSessionStatus.approved:
        return Colors.green;
      case QRSessionStatus.rejected:
      case QRSessionStatus.expired:
        return Colors.red;
    }
  }

  String _getStatusTitle() {
    switch (_status) {
      case QRSessionStatus.pending:
        return 'En attente de scan';
      case QRSessionStatus.approved:
        return 'Connexion réussie !';
      case QRSessionStatus.rejected:
        return 'Connexion refusée';
      case QRSessionStatus.expired:
        return 'Code expiré';
    }
  }

  String _getStatusDescription() {
    switch (_status) {
      case QRSessionStatus.pending:
        return 'Scannez ce code depuis votre téléphone';
      case QRSessionStatus.approved:
        return 'Vous allez être redirigé...';
      case QRSessionStatus.rejected:
        return 'La demande a été refusée';
      case QRSessionStatus.expired:
        return 'Ce code a expiré après 5 minutes';
    }
  }
}

enum QRSessionStatus { pending, approved, rejected, expired }

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:naengjang/core/barcode/barcode_service.dart';
import 'package:naengjang/ui/layout.dart';

/// 바코드 스캔 결과
class BarcodeScanResult {
  final String barcode;
  final ProductInfo? productInfo;

  BarcodeScanResult({
    required this.barcode,
    this.productInfo,
  });
}

/// 바코드 스캔 화면
class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({super.key});

  /// 바코드 스캔 화면을 표시하고 결과를 반환
  static Future<BarcodeScanResult?> scan(BuildContext context) async {
    return Navigator.of(context).push<BarcodeScanResult>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScanner(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool isProcessing = false;
  String? scannedBarcode;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      isProcessing = true;
      scannedBarcode = barcode;
    });

    // Open Food Facts API에서 제품 정보 조회
    final productInfo = await BarcodeService.lookupBarcode(barcode);

    if (!mounted) return;

    Navigator.of(context).pop(BarcodeScanResult(
      barcode: barcode,
      productInfo: productInfo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바코드 스캔'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),
          // 스캔 가이드 오버레이
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: Layout.radius.medium,
              ),
            ),
          ),
          // 안내 텍스트
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              isProcessing ? '제품 정보 조회 중...' : '바코드를 사각형 안에 맞춰주세요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.black),
                ],
              ),
            ),
          ),
          // 로딩 인디케이터
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    Layout.gap.medium,
                    Text(
                      '바코드: $scannedBarcode',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Layout.gap.small,
                    const Text(
                      '제품 정보를 조회하고 있습니다...',
                      style: TextStyle(color: Colors.white70),
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

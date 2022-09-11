import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

class BitmapSrcMixin {
  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static final int DEFAULT_SIZE = 20;

  String? bitmapSrc;

  int _bitmapWidth = DEFAULT_SIZE;

  int _bitmapHeight = DEFAULT_SIZE;

  int _bitmapPercent = 100;

  MapPaint? _bitmapPaint;

  final Map<int, int> _widths = {};

  final Map<int, int> _heights = {};

  /// stroke will be drawn thicker at or above this zoomlevel
  late int _strokeMinZoomLevel;

  void initBitmapSrcMixin(int strokeMinZoomLevel) {
    this._strokeMinZoomLevel = strokeMinZoomLevel;
  }

  void prepareScaleBitmapSrcMixin(int zoomLevel) {
    // if (bitmapSrc == null || _bitmaps[zoomLevel] != null) return;
    // if (getBitmapWidth(zoomLevel) == _bitmapWidth &&
    //     getBitmapHeight(zoomLevel) == _bitmapHeight) {
    //   if (_bitmap != null) {
    //     _bitmaps[zoomLevel] = _bitmap!;
    //     return;
    //   } else {
    //     ResourceBitmap? bitmap = await symbolCache.getSymbol(
    //         bitmapSrc!, getBitmapWidth(zoomLevel), getBitmapHeight(zoomLevel));
    //     if (bitmap != null) {
    //       _bitmaps[zoomLevel] = bitmap;
    //       _bitmap = bitmap;
    //     }
    //   }
    // }
    // ResourceBitmap? bitmap = await symbolCache.getSymbol(
    //     bitmapSrc!, getBitmapWidth(zoomLevel), getBitmapHeight(zoomLevel));
    // if (bitmap != null) _bitmaps[zoomLevel] = bitmap;
  }

  int getBitmapHeight(int zoomLevel) {
    if (_heights[zoomLevel] != null) return _heights[zoomLevel]!;
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      _heights[zoomLevel] = (_bitmapHeight * _bitmapPercent / 100.0).round();
    } else {
      _heights[zoomLevel] = _bitmapHeight;
    }
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      //print("scaling $zoomLevel to $scaleFactor and $strokeMinZoomLevel");
      _heights[zoomLevel] = (_heights[zoomLevel]! * scaleFactor).round();
    }
    return _heights[zoomLevel]!;
  }

  int getBitmapWidth(int zoomLevel) {
    if (_widths[zoomLevel] != null) return _widths[zoomLevel]!;
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      _widths[zoomLevel] = (_bitmapWidth * _bitmapPercent / 100.0).round();
    } else {
      _widths[zoomLevel] = _bitmapWidth;
    }
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _widths[zoomLevel] = (_widths[zoomLevel]! * scaleFactor).round();
    }
    return _widths[zoomLevel]!;
  }

  Future<ResourceBitmap?> loadBitmap(
      int zoomLevel, SymbolCache symbolCache) async {
    if (bitmapSrc == null) return null;
    ResourceBitmap? resourceBitmap = await symbolCache.getOrCreateSymbol(
        bitmapSrc!, getBitmapWidth(zoomLevel), getBitmapHeight(zoomLevel));
    return resourceBitmap;
  }

  void setBitmapSrc(String bitmapSrc) {
    this.bitmapSrc = bitmapSrc;
  }

  void setBitmapPercent(int bitmapPercent) {
    _bitmapPercent = bitmapPercent;
  }

  void setBitmapWidth(int bitmapWidth) {
    _bitmapWidth = bitmapWidth;
  }

  void setBitmapHeight(int bitmapHeight) {
    _bitmapHeight = bitmapHeight;
  }

  void setBitmapColorFromNumber(int color) {
    _bitmapPaint ??= GraphicFactory().createPaint();
    _bitmapPaint!.setColorFromNumber(color);
  }

  MapPaint getBitmapPaint() {
    if (_bitmapPaint == null) {
      _bitmapPaint = GraphicFactory().createPaint();
      _bitmapPaint!.setColorFromNumber(0xff000000);
    }
    return _bitmapPaint!;
  }
}

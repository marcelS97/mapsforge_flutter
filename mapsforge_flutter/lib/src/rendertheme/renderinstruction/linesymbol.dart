import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/waydecorator.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapsrcmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';
import 'renderinstruction.dart';

/// Represents an icon along a polyline on the map.
class LineSymbol extends RenderInstruction with BitmapSrcMixin {
  static final double REPEAT_GAP_DEFAULT = 200;
  static final double REPEAT_START_DEFAULT = 30;

  bool alignCenter = true;
  Display display = Display.IFSPACE;
  double _dy = 0;
  final Map<int, double> _dyScaled = {};
  int priority = 0;
  final String? relativePathPrefix;
  bool repeat = true;

  late double _repeatGap;
  final Map<int, double> _repeatGapScaled = {};

  late double repeatStart;
  bool rotate = true;
  Scale scale = Scale.STROKE;
  Position position = Position.CENTER;

  final _strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT;

  LineSymbol(this.relativePathPrefix);

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this._repeatGap = REPEAT_GAP_DEFAULT * displayModel.getFontScaleFactor();
    this.repeatStart = REPEAT_START_DEFAULT * displayModel.getFontScaleFactor();
    this.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.ALIGN_CENTER == name) {
        this.alignCenter = "true" == (value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this._dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.POSITION == name) {
        this.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.REPEAT == name) {
        this.repeat = "true" == (value);
      } else if (RenderInstruction.REPEAT_GAP == name) {
        this._repeatGap =
            double.parse(value) * displayModel.getFontScaleFactor();
      } else if (RenderInstruction.REPEAT_START == name) {
        this.repeatStart =
            double.parse(value) * displayModel.getFontScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        this.rotate = "true" == (value);
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) *
            displayModel.getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("LineSymbol probs: unknown '$name'");
      }
    });
  }

  @override
  Future<void> renderNode(final RenderContext renderContext,
      PointOfInterest poi, SymbolCache symbolCache) {
    return Future.value(null);
    // do nothing
  }

  @override
  Future<void> renderWay(final RenderContext renderContext,
      PolylineContainer way, SymbolCache symbolCache) async {
    if (Display.NEVER == this.display) {
      return;
    }

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    ResourceBitmap? bitmap =
        await loadBitmap(renderContext.job.tile.zoomLevel, symbolCache);
    if (bitmap == null) return;

    WayDecorator.renderSymbol(
        bitmap,
        display,
        priority,
        _dyScaled[renderContext.job.tile.zoomLevel]!,
        alignCenter,
        repeat,
        _repeatGapScaled[renderContext.job.tile.zoomLevel]!.toInt(),
        repeatStart.toInt(),
        rotate,
        way.getCoordinatesAbsolute(renderContext.projection),
        renderContext.labels,
        getBitmapPaint());
  }

  @override
  void prepareScale(int zoomLevel) {
    if (this.scale == Scale.NONE) return;

    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;

      this._dyScaled[zoomLevel] = this._dy * scaleFactor;
      this._repeatGapScaled[zoomLevel] = _repeatGap * scaleFactor;
    } else {
      this._dyScaled[zoomLevel] = this._dy;
      this._repeatGapScaled[zoomLevel] = _repeatGap;
    }
    prepareScaleBitmapSrcMixin(zoomLevel);
  }
}

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/point/pointtextcontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/textkey.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';

/**
 * Represents a text label on the map.
 * <p/>
 * If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
 * center of which is at the point of the POI. The bitmap itself is never rendered.
 */
class Caption extends RenderInstruction with TextMixin, PaintMixin {
  static final _log = new Logger('Caption');
  static final double DEFAULT_GAP = 5;

  Display display = Display.IFSPACE;
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  late double gap;
  Position position = Position.CENTER;
  int priority = 0;
  String? symbolId;
  final SymbolFinder symbolFinder;
  TextKey? textKey;

  /// The maximum width of a text as defined in the displaymodel
  late double maxTextWidth;

  Caption(this.symbolFinder);

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    maxTextWidth = displayModel.getMaxTextWidth();
    gap = DEFAULT_GAP * displayModel.getFontScaleFactor();
    initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        this.textKey = TextKey.getInstance(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.FILL == name) {
        this.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        setFontFamily(value);
      } else if (RenderInstruction.FONT_SIZE == name) {
        this.setFontSize(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.POSITION == name) {
        this.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.STROKE == name) {
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.SYMBOL_ID == name) {
        this.symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, this.textKey);
  }

  @override
  Future<void> renderNode(final RenderContext renderContext,
      PointOfInterest poi, SymbolCache symbolCache) {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return Future.value(null);
    }

    String? caption = this.textKey!.getValue(poi.tags);
    if (caption == null) {
      //_log.info("caption is null for $textKey");
      return Future.value(null);
    }

    _init(renderContext.job.tile.zoomLevel);
    Mappoint poiPosition = renderContext.projection.latLonToPixel(poi.position);
    //_log.info("poiCaption $caption at $poiPosition, postion $position, offset: $horizontalOffset, $verticalOffset ");

    MapTextPaint mapTextPaint = getTextPaint(renderContext.job.tile.zoomLevel);

    renderContext.labels.add(PointTextContainer(
        poiPosition.offset(_horizontalOffset,
            _verticalOffset + getDy(renderContext.job.tile.zoomLevel)),
        display,
        priority,
        caption,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        position,
        mapTextPaint,
        maxTextWidth));
    return Future.value(null);
  }

  @override
  Future<void> renderWay(final RenderContext renderContext,
      PolylineContainer way, SymbolCache symbolCache) {
    if (Display.NEVER == this.display) {
      return Future.value(null);
    }

    String? caption = this.textKey!.getValue(way.getTags());
    if (caption == null) {
      return Future.value(null);
    }

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return Future.value(null);

    _init(renderContext.job.tile.zoomLevel);

    Mappoint centerPoint = way
        .getCenterAbsolute(renderContext.projection)
        .offset(_horizontalOffset,
            _verticalOffset + getDy(renderContext.job.tile.zoomLevel));
    //_log.info("centerPoint is ${centerPoint.toString()}, position is ${position.toString()} for $caption");
    MapTextPaint mapTextPaint = getTextPaint(renderContext.job.tile.zoomLevel);

    PointTextContainer label = PointTextContainer(
        centerPoint,
        display,
        priority,
        caption,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        position,
        mapTextPaint,
        maxTextWidth);
    renderContext.labels.add(label);
    return Future.value(null);
  }

  @override
  void prepareScale(int zoomLevel) {
    prepareScalePaintMixin(zoomLevel);
    prepareScaleTextMixin(zoomLevel);
  }

  void _init(int zoomLevel) {
    _verticalOffset = 0;

    RenderSymbol? renderSymbol;
    if (this.symbolId != null) {
      renderSymbol = symbolFinder.find(this.symbolId!);
      if (renderSymbol == null) {
        _log.warning(
            "Symbol $symbolId referenced in caption in render.xml, but not defined as symbol");
      }
    }

    if (this.position == Position.CENTER && renderSymbol?.bitmapSrc != null) {
      // sensible defaults: below if symbolContainer is present, center if not
      this.position = Position.BELOW;
    }
    switch (this.position) {
      case Position.CENTER:
      case Position.BELOW:
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset +=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.ABOVE:
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset -=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.BELOW_LEFT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset -=
              renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap;
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset +=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.ABOVE_LEFT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset -=
              renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap;
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset -=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.LEFT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset -=
              renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap;
        break;
      case Position.BELOW_RIGHT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset +=
              (renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap);
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset +=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.ABOVE_RIGHT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset +=
              (renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap);
        if (renderSymbol?.getBitmapHeight(zoomLevel) != null)
          _verticalOffset -=
              renderSymbol!.getBitmapHeight(zoomLevel) / 2 + this.gap;
        break;
      case Position.RIGHT:
        if (renderSymbol?.getBitmapWidth(zoomLevel) != null)
          _horizontalOffset +=
              (renderSymbol!.getBitmapWidth(zoomLevel) / 2 + this.gap);
        break;
      default:
        throw new Exception("Position invalid");
    }
  }
}

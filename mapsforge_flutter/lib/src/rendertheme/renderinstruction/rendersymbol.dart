import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/point/symbolcontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapsrcmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [RenderInstruction] implementations.
///
class RenderSymbol extends RenderInstruction with BitmapSrcMixin {
  Display display = Display.IFSPACE;

  String? id;

  int priority = 0;

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.ID == name) {
        this.id = value;
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
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
        throw Exception("Symbol probs");
      }
    });
  }

  String? getId() {
    return this.id;
  }

  @override
  Future<void> renderNode(final RenderContext renderContext,
      PointOfInterest poi, SymbolCache symbolCache) async {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    ResourceBitmap? bitmap =
        await loadBitmap(renderContext.job.tile.zoomLevel, symbolCache);
    if (bitmap == null) return;
    //print("processing bitmap ${bitmap}");
    Mappoint poiPosition = renderContext.projection.latLonToPixel(poi.position);

    renderContext.labels.add(new SymbolContainer(
        point: poiPosition,
        display: display,
        priority: priority,
        bitmap: bitmap,
        paint: getBitmapPaint(),
        alignCenter: true));
  }

  @override
  Future<void> renderWay(final RenderContext renderContext,
      PolylineContainer way, SymbolCache symbolCache) async {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    ResourceBitmap? bitmap =
        await loadBitmap(renderContext.job.tile.zoomLevel, symbolCache);
    if (bitmap == null) return;

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    Mappoint centerPosition = way.getCenterAbsolute(renderContext.projection);
    renderContext.labels.add(new SymbolContainer(
        point: centerPosition,
        display: display,
        priority: priority,
        bitmap: bitmap,
        paint: getBitmapPaint()));
  }

  @override
  void prepareScale(int zoomLevel) {
    prepareScaleBitmapSrcMixin(zoomLevel);
  }
}

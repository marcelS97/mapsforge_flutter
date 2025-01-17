import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

abstract class MarkerCallback {
  /// The factor to scale down the map. With [DisplayModel.deviceScaleFactor] one can scale up the view and make it bigger. With this value
  /// one can scale down the view and make the resolution of the map better. This comes with the cost of increased tile image sizes and thus increased time for creating the tile-images
  abstract final double viewScaleFactor;

  void renderBitmap(ResourceBitmap bitmap, double latitude, double longitude,
      double offsetX, double offsetY, double rotation, MapPaint paint);

  void renderPath(MapPath path, MapPaint paint);

  void renderPathText(String caption, LineString lineString, Mappoint origin,
      MapPaint stroke, MapTextPaint textPaint, double maxTextWidth);

  void renderRect(MapRect rect, MapPaint paint);

  void renderCircle(
      double latitude, double longitude, double radius, MapPaint paint);

  MapViewPosition get mapViewPosition;

  FlutterCanvas get flutterCanvas;
}

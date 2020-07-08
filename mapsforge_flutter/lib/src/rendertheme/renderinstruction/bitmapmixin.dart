import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';

class BitmapMixin {
  SymbolCache symbolCache;

  Bitmap bitmap;
  bool bitmapInvalid = false;
  Future<Bitmap> _future;

  double height = 0;
  int percent = 100;
  double width = 0;

  String src;

  RenderSymbol renderSymbol;

  void destroy() {
    if (this.bitmap != null) {
      this.bitmap.decrementRefCount();
      bitmap = null;
    }
    _future = null;
  }

  @mustCallSuper
  Future<void> initResources() async {
    //print("initResources called for $src");
    if (bitmapInvalid) return;

    if (bitmap != null) return;

    if (renderSymbol != null) {
      try {
        bitmap = await renderSymbol.getBitmap();
      } catch (e, stacktrace) {
        print("Exception $e\nStacktrace $stacktrace");
        bitmap = null;
        bitmapInvalid = true;
      }
      return;
    }

    if (symbolCache != null) {
      if (src == null || src.isEmpty) {
        return;
      }
      try {
        bitmap = await symbolCache.getOrCreateBitmap(src, width.round(), height.round(), percent);
      } catch (e, stacktrace) {
        print("Exception $e\nStacktrace $stacktrace");
        bitmap = null;
        bitmapInvalid = true;
      }
    }
  }

  @protected
  Future<Bitmap> getOrCreateBitmap(String relativePathPrefix, String src) async {
    if (bitmapInvalid) return null;
    if (null == src || src.isEmpty) {
      bitmapInvalid = true;
      return null;
    }
    assert(symbolCache != null);

    if (bitmap != null) return bitmap;

    if (_future != null) {
      return _future;
    }
    try {
      _future = symbolCache.getOrCreateBitmap(src, width.round(), height.round(), percent);
      bitmap = await _future;
      _future = null;
      bitmapInvalid = false;
      return bitmap;
    } catch (e, stacktrace) {
      print("Exception $e\nStacktrace $stacktrace");
      bitmap = null;
      _future = null;
      bitmapInvalid = true;
      return bitmap;
    }
  }
}

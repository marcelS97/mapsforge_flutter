import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/projection/scalefactor.dart';
import 'package:rxdart/rxdart.dart';

class ViewModel {
  Widget? noPositionView;
  MapViewPosition? _mapViewPosition;
  final DisplayModel displayModel;
  ContextMenuBuilder? contextMenuBuilder;

  /// Overlays to the map. Overlays can show things which do not move along with the map. Examples for overlays are zoombuttons.
  List<Widget>? overlays;

  ///
  /// The width and height of the view in pixels
  ///
  Dimension? _viewDimension;

  /// The last position should be reported to a new subscriber
  Subject<MapViewPosition> _injectPosition = BehaviorSubject();

  Stream<MapViewPosition> get observePosition => _injectPosition.stream;

  Subject<TapEvent> _injectTap = PublishSubject();

  Stream<TapEvent> get observeTap => _injectTap.stream;

  Subject<TapEvent> _injectLongTap = PublishSubject();

  Stream<TapEvent> get observeLongTap => _injectLongTap.stream;

  Subject<GestureEvent> _injectGesture = PublishSubject();

  Stream<GestureEvent> get observeGesture => _injectGesture.stream;

  Subject<MoveAroundEvent> _injectMoveAroundStart = PublishSubject();

  Stream<MoveAroundEvent> get observeMoveAroundStart =>
      _injectMoveAroundStart.stream;

  Subject<MoveAroundEvent> _injectMoveAroundUpdate = PublishSubject();

  Stream<MoveAroundEvent> get observeMoveAroundUpdate =>
      _injectMoveAroundUpdate.stream;

  Subject<MoveAroundEvent> _injectMoveAroundEnd = PublishSubject();

  Stream<MoveAroundEvent> get observeMoveAroundEnd =>
      _injectMoveAroundEnd.stream;

  ViewModel(
      {this.contextMenuBuilder = const DefaultContextMenuBuilder(),
      required this.displayModel,
      this.noPositionView,
      this.overlays}) {
    noPositionView ??= NoPositionView();
  }

  void dispose() {
    overlays?.forEach((element) {
      //element.dispose();
    });
    overlays?.clear();
    _injectPosition.close();
    _injectTap.close();
    _injectLongTap.close();
    _injectGesture.close();
    _injectMoveAroundStart.close();
    _injectMoveAroundUpdate.close();
    _injectMoveAroundEnd.close();
  }

  MapViewPosition? get mapViewPosition => _mapViewPosition;

  void setMapViewPosition(double latitude, double longitude) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.latitude == latitude &&
          _mapViewPosition!.longitude == longitude) return;
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          _mapViewPosition!.zoomLevel,
          _mapViewPosition!.indoorLevel,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomIn() {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomInAround(double latitude, double longitude) {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.zoomInAround(_mapViewPosition!, latitude, longitude);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomOut() {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel <= 0) return;
    MapViewPosition newPosition = MapViewPosition.zoomOut(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  MapViewPosition setZoomLevel(int zoomLevel) {
    if (zoomLevel > displayModel.maxZoomLevel)
      zoomLevel = displayModel.maxZoomLevel;
    if (zoomLevel < 0) zoomLevel = 0;
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.zoomLevel == zoomLevel &&
          _mapViewPosition!.scale == 1) return _mapViewPosition!;
      MapViewPosition newPosition =
          MapViewPosition.zoom(_mapViewPosition!, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, zoomLevel,
          displayModel.DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  MapViewPosition zoomAround(double latitude, double longitude, int zoomLevel) {
    assert(_mapViewPosition != null);
    if (zoomLevel > displayModel.maxZoomLevel)
      zoomLevel = displayModel.maxZoomLevel;
    if (zoomLevel < 0) zoomLevel = 0;
    MapViewPosition newPosition = MapViewPosition.zoomAround(
        _mapViewPosition!, latitude, longitude, zoomLevel);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
    return newPosition;
  }

  void indoorLevelUp() {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.indoorLevelUp(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void indoorLevelDown() {
    if (_mapViewPosition == null) return;
    MapViewPosition newPosition =
        MapViewPosition.indoorLevelDown(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  MapViewPosition setIndoorLevel(int indoorLevel) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.indoorLevel == indoorLevel)
        return _mapViewPosition!;
      MapViewPosition newPosition =
          MapViewPosition.setIndoorLevel(_mapViewPosition!, indoorLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null,
          displayModel.DEFAULT_ZOOM, indoorLevel, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  int getIndoorLevel() {
    return _mapViewPosition?.indoorLevel ?? 0;
  }

  ///
  /// sets the new scale relative to the current zoomlevel. A scale of 1 means no action,
  /// 0..1 means zoom-out (you will see more area on screen since at pinch-to-zoom the fingers are moved towards each other)
  /// >1 means zoom-in.
  ///
  MapViewPosition? setScaleAround(Mappoint focalPoint, double scale) {
    assert(scale > 0);
    // do not scale if the scale is too minor to do anything
    if ((scale - 1).abs() < 0.01) return _mapViewPosition;
    if (_mapViewPosition != null) {
      //print("Scaling ${_mapViewPosition.zoomLevel} * $scale");
      if (Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel) *
              scale <
          1) {
        // zoom out until we reached zoomlevel 0
        scale =
            1 / Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel);
      } else {
        double scaleFactor =
            Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel) *
                scale;
        if (scaleFactor >
            Scalefactor.zoomlevelToScalefactor(displayModel.maxZoomLevel)) {
          // zoom in until we reach the maximum zoom level, limit the zoom then
          scale = Scalefactor.zoomlevelToScalefactor(
                  displayModel.maxZoomLevel) /
              Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel);
        }
      }
      MapViewPosition newPosition =
          MapViewPosition.scaleAround(_mapViewPosition!, focalPoint, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      newPosition = MapViewPosition.scaleAround(newPosition, null, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setLeftUpper(
          _mapViewPosition!, left, upper, _viewDimension!);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM - 1,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  /// The user has tapped at the map. The event has been detected by the [FlutterGestureDetector].
  /// left/upper 0/0 indicates the left-upper corner of the map (NOT of the screen)
  void tapEvent(double left, double upper) {
    if (_mapViewPosition == null) return;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    if (_mapViewPosition?.leftUpper == null) return;
    TapEvent event = TapEvent(
        _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        left,
        upper,
        _mapViewPosition!.leftUpper!.x,
        _mapViewPosition!.leftUpper!.y,
        _mapViewPosition!.projection!);
    _injectTap.add(event);
  }

  void clearTapEvent() {
    _injectTap.add(const TapEvent.clear());
  }

  void longTapEvent(double left, double upper) {
    if (_mapViewPosition == null) return;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    if (_mapViewPosition?.leftUpper == null) return;
    TapEvent event = TapEvent(
        _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        left,
        upper,
        _mapViewPosition!.leftUpper!.x,
        _mapViewPosition!.leftUpper!.y,
        _mapViewPosition!.projection!);
    _injectLongTap.add(event);
  }

  /// An event sent by the [FlutterGestureDetector] to indicate a user-driven gesture-event. This can be used to
  /// switch off automatic movement of the map.
  void gestureEvent() {
    _injectGesture.add(GestureEvent());
  }

  void gestureMoveStartEvent(double left, double upper) {
    if (_mapViewPosition == null) return null;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    if (_mapViewPosition?.leftUpper == null) return null;

    MoveAroundEvent event = MoveAroundEvent(
        latitude: _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        longitude: _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        projection: _mapViewPosition!.projection!,
        x: left,
        y: upper,
        leftUpperX: _mapViewPosition!.leftUpper!.x,
        leftUpperY: _mapViewPosition!.leftUpper!.y);
    _injectMoveAroundStart.add(event);
  }

  void gestureMoveUpdateEvent(double left, double upper) {
    if (_mapViewPosition == null) return null;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    if (_mapViewPosition?.leftUpper == null) return null;

    MoveAroundEvent event = MoveAroundEvent(
        latitude: _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        longitude: _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        projection: _mapViewPosition!.projection!,
        x: left,
        y: upper,
        leftUpperX: _mapViewPosition!.leftUpper!.x,
        leftUpperY: _mapViewPosition!.leftUpper!.y);
    _injectMoveAroundUpdate.add(event);
  }

  void gestureMoveEndEvent(double left, double upper) {
    if (_mapViewPosition == null) return null;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    if (_mapViewPosition?.leftUpper == null) return null;

    MoveAroundEvent event = MoveAroundEvent(
        latitude: _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        longitude: _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        projection: _mapViewPosition!.projection!,
        x: left,
        y: upper,
        leftUpperX: _mapViewPosition!.leftUpper!.x,
        leftUpperY: _mapViewPosition!.leftUpper!.y);
    _injectMoveAroundEnd.add(event);
  }

  Dimension? get viewDimension => _viewDimension;

  Dimension? setViewDimension(double width, double height) {
    if (_viewDimension != null &&
        _viewDimension!.width == width &&
        _viewDimension!.height == height) return _viewDimension;
    _viewDimension = Dimension(width, height);
    if (_mapViewPosition != null) _injectPosition.add(_mapViewPosition!);
    return _viewDimension;
  }

  void addOverlay(Widget overlay) {
    overlays ??= [];
    overlays!.add(overlay);
  }
}

/////////////////////////////////////////////////////////////////////////////

class TapEvent implements ILatLong {
  @override
  final double latitude;

  @override
  final double longitude;

  final PixelProjection? _projection;

  /// The x coordinate in pixels where the user tapped at the map. The left/upper point is considered 0/0
  final double x;

  /// The y coordinate in pixels where the user tapped at the map. The left/upper point is considered 0/0
  final double y;

  /// the left-upper point of the map in pixels
  final double leftUpperX;

  /// the left-upper point of the map in pixels
  final double leftUpperY;

  bool isCleared() {
    return _projection == null;
  }

  PixelProjection get projection => _projection!;

  const TapEvent(this.latitude, this.longitude, this.x, this.y, this.leftUpperX,
      this.leftUpperY, PixelProjection projection)
      : _projection = projection;

  const TapEvent.clear()
      : latitude = 0,
        longitude = 0,
        x = -1,
        y = -1,
        leftUpperX = -1,
        leftUpperY = -1,
        _projection = null;
}

/////////////////////////////////////////////////////////////////////////////

class MoveAroundEvent extends TapEvent {
  MoveAroundEvent({
    required double latitude,
    required double longitude,
    required PixelProjection projection,
    required double x,
    required double y,
    required double leftUpperX,
    required double leftUpperY,
  }) : super(latitude, longitude, x, y, leftUpperX, leftUpperY, projection);
}

/////////////////////////////////////////////////////////////////////////////

///
/// This event is triggered as soon as a user gesture intervention is detected.
/// It can be used to disable auto-movement or auto-zoom of the map in order to prevent interfering with the user.
class GestureEvent {}

import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import '../../cache/tilebitmapcache.dart';
import '../../graphics/tilebitmap.dart';
import '../../model/displaymodel.dart';
import 'job.dart';
import 'jobrenderer.dart';

///
/// The jobqueue receives jobs and starts the renderer for missing bitmaps.
class JobQueue {
  static final _log = new Logger('JobQueue');

  final DisplayModel displayModel;
  final JobRenderer jobRenderer;

  Subject<Job> _injectJobResult = PublishSubject();
  ListQueue<Job> _listQueue = ListQueue();

  JobSet _currentJobSet;

  SendPort _sendPort;

  Isolate _isolate;

  TileBitmapCache tileBitmapCache;

  FlutterTileBitmap _missingBitmap;

  FlutterTileBitmap _noDataBitmap;

  // we have only one thread, so limit the number of concurrent renderings for now
  final List<Lock> _lock = List(1);

  int _roundRobin = 0;

  JobQueue(this.displayModel, this.jobRenderer, this.tileBitmapCache)
      : assert(displayModel != null),
        assert(jobRenderer != null) {
    //_startIsolateJob();
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
    // precreate the missing bitmap
    getMissingBitmap(displayModel.tileSize);
  }

  void dispose() {
    if (_isolate != null) {
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  ///
  /// Called whenever a new bitmap is created
  ///
  Stream<Job> get observeJobResult => _injectJobResult.stream;

  TileBitmap getMissingBitmap(double tileSize) {
    if (_missingBitmap != null) return _missingBitmap;
    jobRenderer.createMissingBitmap(tileSize).then((value) {
      _missingBitmap = value;
    });
    return _missingBitmap;
  }

  ///
  /// Let the queue process this jobset
  void processJobset(JobSet jobSet) {
    _currentJobSet = jobSet;
    // remove all jobs from the queue which are not needed anymore because we want to show another view hence other tiles
    _listQueue.removeWhere((element) => !jobSet.jobs.contains(element));
    // now add all new jobs to queue
    _currentJobSet.jobs.where((element) => !_listQueue.contains(element)).forEach((element) {
      _listQueue.add(element);
    });
    _startNextJob();
  }

  void _startNextJob() {
    //print("ListQueue has ${_listQueue.length} elements");
    if (_listQueue.isEmpty) return;
    // let the job in the queue until it is finished, so we prevent adding the job to the queue again
    _lock[_roundRobin++ % _lock.length].synchronized(() async {
      // recheck, it may have changed in the meantime
      if (_listQueue.isEmpty) return;
      Job nextJob = _listQueue.first;
      //print("taken ${nextJob?.toString()} from queue");
//     await _donow3(item);
//     await _donow(item);
      await _donow2(nextJob);
      _listQueue.remove(nextJob);
    });
  }

  Future<void> _donow(Job job) async {
    TileBitmap tileBitmap = await tileBitmapCache.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      job.tileBitmap = tileBitmap;
      _injectJobResult.add(job);
      _startNextJob();
      return;
    }
    _sendPort.send(IsolateParam(job, jobRenderer));
  }

  Future<void> _donow2(Job job) async {
    TileBitmap tileBitmap = await tileBitmapCache.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      job.tileBitmap = tileBitmap;
      _injectJobResult.add(job);
      _startNextJob();
      return;
    }
    Job result = await renderDirect(IsolateParam(job, jobRenderer));
    if (result.hasTileBitmap()) {
      tileBitmapCache.addTileBitmap(job.tile, result.getTileBitmap());
      _injectJobResult.add(result);
      // _log.info("Job executed with bitmap");
    } else {
      // _log.warning("Job executed without bitmap");
    }
    _startNextJob();
  }

  void _donow3(Job job) async {
    TileBitmap tileBitmap = await tileBitmapCache.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      job.tileBitmap = tileBitmap;
      _injectJobResult.add(job);
      _startNextJob();
      return;
    }
    Job result = await compute(renderDirect, IsolateParam(job, jobRenderer));
    if (result.hasTileBitmap()) {
      tileBitmapCache.addTileBitmap(job.tile, result.getTileBitmap());
      _injectJobResult.add(result);
      // _log.info("Job executed with bitmap");
    } else {
      // _log.warning("Job executed without bitmap");
    }
    _startNextJob();
  }

  ///
  /// Isolates currently not suitable for our purpose. Most UI canvas calls are not accessible from isolates
  /// so we cannot produce the bitmap.
  void _startIsolateJob() async {
    var receivePort = new ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);

    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        _sendPort = data;
      } else if (data is Job) {
        Job job = data;
        if (job.hasTileBitmap()) {
          tileBitmapCache.addTileBitmap(job.tile, job.getTileBitmap());
          _injectJobResult.add(job);
          // _log.info("Job executed with bitmap");
        } else {
          // _log.warning("Job executed without bitmap");
        }
        _startNextJob();
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

/// see https://github.com/flutter/flutter/issues/13937
// Entry point for your Isolate
entryPoint(SendPort sendPort) async {
  // Open the ReceivePort to listen for incoming messages (optional)
  var receivePort = new ReceivePort();

  // Send messages to other Isolates
  sendPort.send(receivePort.sendPort);

  // Listen for messages (optional)
  await for (IsolateParam isolateParam in receivePort) {
    print("hello, we received $isolateParam in the isolate");
    Job result = await renderDirect(isolateParam);
    sendPort.send(result);
  }
}

/////////////////////////////////////////////////////////////////////////////

//typedef void Callback(Job job);

/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////

class IsolateParam {
  final Job job;
  final JobRenderer jobRenderer;

  IsolateParam(this.job, this.jobRenderer);
}

/////////////////////////////////////////////////////////////////////////////

///
/// Renders one job and produces the bitmap for the requested tile. In case of errors or no data a special bitmap will be produced.
/// Executes the callback function when finished.
///
Future<Job> renderDirect(IsolateParam isolateParam) async {
  // _lock[++_roundRobin % _lock.length].synchronized(() async {
  Job job = isolateParam.job;
//  if (job.hasTileBitmap()) {
//    return job;
//  }
//  if (job.inWork) {
//    return null;
//  }
  //_log.info("Processing tile ${job.tile.toString()}");
//  TileBitmap tileBitmap = await isolateParam.tileBitmapCache.getTileBitmapAsync(job.tile);
//  if (tileBitmap != null) {
//    job.tileBitmap = tileBitmap;
//    return job;
//  }
  int time = DateTime.now().millisecondsSinceEpoch;
//  job.inWork = true;
  try {
    TileBitmap tileBitmap = await isolateParam.jobRenderer.executeJob(job);
    if (tileBitmap != null) {
      int diff = DateTime.now().millisecondsSinceEpoch - time;
//      if (diff >= 100) _log.info("Renderer needed $diff ms for job ${job.toString()}");
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, tileBitmap);
      job.tileBitmap = tileBitmap;
    } else {
      // no datastore for that tile
      int diff = DateTime.now().millisecondsSinceEpoch - time;
//      if (diff >= 100) _log.info("Renderer needed $diff ms for non-existent job ${job.toString()}");
      TileBitmap bmp = await isolateParam.jobRenderer.createNoDataBitmap(job.tile.tileSize);
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, bmp);
      //bmp.incrementRefCount();
      job.tileBitmap = bmp;
    }
//    job.inWork = false;
    return job;
  } catch (error, stackTrace) {
    print(error.toString());
    print(stackTrace.toString());
    TileBitmap bmp = await isolateParam.jobRenderer.createErrorBitmap(job.tile.tileSize, error);
    bmp.incrementRefCount();
    job.tileBitmap = bmp;
//    job.inWork = false;
    return job;
  }
}

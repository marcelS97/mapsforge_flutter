import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';
import 'package:rxdart/rxdart.dart';

/**
 * Statefull Widget to display a level bar
 * requires a BehaviourSubject of type int for the current indoor level
 * requires an ordered map of levels with an optional level code string
 */
class IndoorLevelBar extends StatefulWidget {
  final BehaviorSubject<int> indoorLevelSubject;
  final Map<int, String> indoorLevels;
  final double width;
  final double itemHeight;
  final int maxVisibleItems;
  final Color fillColor;
  final double elevation;
  final BorderRadius borderRadius;

  const IndoorLevelBar ({
    Key key,
    @required this.indoorLevels,
    @required this.indoorLevelSubject,
    this.width: 30,
    this.itemHeight: 45,
    this.maxVisibleItems: 5,
    this.fillColor: Colors.white,
    this.elevation: 2,
    this.borderRadius
  }) : super(key: key);

  @override
  IndoorLevelBarState createState() => IndoorLevelBarState();
}

class IndoorLevelBarState extends State<IndoorLevelBar> {
  ScrollController _scrollController;

  ValueNotifier<bool> _onTop = ValueNotifier<bool>(false);
  ValueNotifier<bool> _onBottom = ValueNotifier<bool>(false);

  @override
  void dispose () {
    _scrollController.dispose();
    _onTop.dispose();
    _onBottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // widget
    return Material (
      elevation: widget.elevation,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: widget.fillColor,
      child: LayoutBuilder(
        // will also be called on device orientation change
        builder: (context, constraints) {
          // get the total number of levels
          int totalIndoorLevels = widget.indoorLevels.length;

          double maxHeight = min(constraints.maxHeight, widget.maxVisibleItems * widget.itemHeight);
          // calculate nearest multiple item height
          maxHeight = (maxHeight / widget.itemHeight).floor() * widget.itemHeight;
          // check if level bar will be scrollable
          bool isScrollable = maxHeight < totalIndoorLevels * widget.itemHeight;

          // if level bar will be scrollable
          if (isScrollable) {
            // get current indoor level from stream/subject
            int currentIndoorLevel = widget.indoorLevelSubject.value;
            // calculate the scroll position so the selected element is visible at the bottom if possible
            // -3 because we need to shift the index by 1 and by 2 because of scroll buttons taking each the space of one item
            int itemIndex = widget.indoorLevels.keys.toList().indexOf(currentIndoorLevel);
            double selectedItemOffset = max(itemIndex * widget.itemHeight - (maxHeight - 3 * widget.itemHeight), 0);
            // create scroll controller if not existing and set item scroll offset
            if (_scrollController == null) _scrollController = ScrollController(initialScrollOffset: selectedItemOffset);
            else _scrollController.jumpTo(selectedItemOffset);

            // disable/enable scroll buttons accordingly
            _onTop.value = selectedItemOffset == 0;
            _onBottom.value = selectedItemOffset == totalIndoorLevels * widget.itemHeight - (maxHeight - 2 * widget.itemHeight);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              // set to nearest multiple item height
              maxHeight: maxHeight,
              maxWidth: widget.width,
            ),
            child: Column(
              mainAxisSize:MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Visibility(
                  // toggle on if level bar will be scrollable
                  visible: isScrollable,
                  child: ValueListenableBuilder(
                    valueListenable: _onTop,
                    builder: (BuildContext context, bool onTop, Widget childWidget) {
                      return TextButton(
                          style: TextButton.styleFrom(
                          primary: Colors.black,
                          shape: ContinuousRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          // make buttons same height as items
                          minimumSize: Size.fromHeight(widget.itemHeight),
                        ),
                        onPressed: onTop ? null : scrollLevelUp,
                        child: Icon(
                         Icons.keyboard_arrow_up_rounded
                        ),
                      );
                    },
                  ),
                ),
                Flexible(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollChanges,
                    child: StreamBuilder(
                      stream: widget.indoorLevelSubject.stream,
                      initialData: widget.indoorLevelSubject.value,
                      builder: (context, snapshot) {
                        // get current indoor level from stream/subject
                        int currentIndoorLevel = snapshot.data;
                        // widget
                        return ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          itemCount: totalIndoorLevels,
                          itemExtent: widget.itemHeight,
                          itemBuilder: (context, i) {
                            // calc item indoor level from index
                            int itemIndoorLevel = widget.indoorLevels.keys.elementAt(i);
                            // widget
                            return TextButton(
                              style: TextButton.styleFrom(
                                shape: ContinuousRectangleBorder(),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: currentIndoorLevel == itemIndoorLevel ? Colors.blue : Colors.transparent,
                                primary: currentIndoorLevel == itemIndoorLevel ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                // do nothing if already selected
                                if (currentIndoorLevel != itemIndoorLevel) widget.indoorLevelSubject.add(itemIndoorLevel);
                              },
                              child: Text(
                                // show level code if available
                                  widget.indoorLevels[itemIndoorLevel] ?? itemIndoorLevel.toString()
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ),
                Visibility(
                  // toggle on if level bar will be scrollable
                  visible: isScrollable,
                  child: ValueListenableBuilder(
                    valueListenable: _onBottom,
                    builder: (BuildContext context, bool onBottom, Widget childWidget) {
                      return TextButton(
                        style: TextButton.styleFrom(
                          primary: Colors.black,
                          shape: ContinuousRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          // make buttons same height as items
                          minimumSize: Size.fromHeight(widget.itemHeight),
                        ),
                        onPressed: onBottom ? null : scrollLevelDown,
                        child: Icon(
                            Icons.keyboard_arrow_down_rounded
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  bool _handleScrollChanges (notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
        if (_onTop.value == false)_onTop.value = true;
      }
      else if (_onTop.value == true) _onTop.value = false;

      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
        if (_onBottom.value == false) _onBottom.value = true;
      }
      else if (_onBottom.value == true) _onBottom.value = false;
    }
    // cancels notification bubbling
    return true;
  }

  void scrollLevelUp () {
    double itemHeight = widget.itemHeight;
    double nextPosition = _scrollController.offset - itemHeight;
    double roundToNextItemPosition = (nextPosition / itemHeight).round() * itemHeight;
    _scrollController.animateTo(
      roundToNextItemPosition,
      duration: Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }

  void scrollLevelDown () {
    double itemHeight = widget.itemHeight;
    double nextPosition = _scrollController.offset + itemHeight;
    double roundToNextItemPosition = (nextPosition / itemHeight).round() * itemHeight;
    _scrollController.animateTo(
      roundToNextItemPosition,
      duration: Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class XCarousel extends StatefulWidget {
  final Function(BuildContext context, int index) itemBuilder;
  final Function(BuildContext context, int index, Function() onPressed)
      dotBuilder;
  final void Function(int index) onItemFocusChange;
  final int itemCount;
  final bool showDots;
  final bool autoPlay;
  final ControllButtons controlButton;
  final Duration autoPlayInterval;
  final Widget overlayWidget;
  final Duration autoPlayDelay;
  final double viewportFraction;
  final double scale;
  final bool reverse;
  final bool showControlButton;
  final Alignment dotsPosition;
  final Alignment overLayPosition;
  final Duration duration;
  final double containerHeight;

  const XCarousel(
      {@required this.itemBuilder,
      this.autoPlay = false,
      this.dotBuilder,
      this.autoPlayDelay,
      this.viewportFraction,
      this.autoPlayInterval,
      this.duration,
      this.containerHeight,
      this.reverse = false,
      @required this.itemCount,
      this.onItemFocusChange,
      this.showDots = true,
      this.showControlButton = false,
      this.overlayWidget,
      this.dotsPosition = Alignment.center,
      this.scale,
      this.overLayPosition,
      this.controlButton})
      : assert(itemBuilder != null),
        assert((!showControlButton && controlButton == null) ||
            (showControlButton && controlButton != null)),
        assert(itemCount != 0);
  @override
  _PhotoSliderState createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<XCarousel> {
  PageController pageController;
  final ScrollController thumbController = ScrollController();
  List<Widget> items = [];
  List<Widget> dots = [];
  final double thumbSize = 13;
  int page = 0;
  Duration _autoPlayInterval = Duration(seconds: 5);
  Duration _duration = Duration(milliseconds: 500);
  Duration _autoPlayDelay = Duration(seconds: 5);
  ScrollDirection direction = ScrollDirection.forward;
  Timer snapTimer;
  Timer snapTimerPerodic;

  @override
  void initState() {
    pageController =
        PageController(viewportFraction: widget.viewportFraction ?? 1);
    if (widget.duration != null) _duration = widget.duration;
    if (widget.autoPlayDelay != null) _autoPlayDelay = widget.autoPlayDelay;
    if (widget.autoPlayInterval != null)
      _autoPlayInterval = widget.autoPlayInterval;
    if (widget.autoPlay) _autoPlaySnap();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (Notification noti) {
        if (widget.autoPlay) {
          if (noti is ScrollStartNotification) {
            if (noti.dragDetails != null) {
              _stopAutoplay();
            }
          } else if (noti is ScrollEndNotification) {
            if (snapTimer == null) _autoPlaySnap();
          }
        }
        return true;
      },
      child: Container(
          color: Colors.transparent,
          height: widget.containerHeight ?? 350,
          child: Stack(
            children: [
              new PageView(
                controller: pageController,
                onPageChanged: (index) {
                  _setCurrentPage(index);
                  if (widget.showDots)
                    thumbController.animateTo(index * thumbSize,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeIn);
                  if (widget.onItemFocusChange != null)
                    widget.onItemFocusChange(index);
                  _buildSliderDots();
                },
                children: _buildItems(),
              ),
              if (widget.showControlButton) ..._getControlls,
              if (widget.showDots || widget.overlayWidget != null)
                Positioned(
                    bottom: widget.overlayWidget == null ? 10 : 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: widget.overlayWidget != null
                            ? (widget.containerHeight ?? 350) / 2.9
                            : thumbSize,
                        maxHeight: widget.overlayWidget != null
                            ? (widget.containerHeight ?? 350) / 2.9
                            : thumbSize,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showDots) _buildDotsWidget(),
                          if (widget.overlayWidget != null)
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 3, horizontal: 5),
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border(
                                        top: BorderSide(
                                      color: Colors.grey,
                                    ))),
                                width: MediaQuery.of(context).size.width,
                                child: Align(
                                  alignment: widget.overLayPosition ??
                                      Alignment.center,
                                  child: widget.overlayWidget,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ))
            ],
          )),
    );
  }

  void previous() {
    pageController.previousPage(
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  void next() {
    pageController.nextPage(
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  void _setCurrentPage(int index) {
    setState(() {
      page = index;
    });
  }

  List<Widget> get _getControlls {
    return [
      Positioned(
          left: 0,
          bottom: 0,
          top: 0,
          child: widget.controlButton != null
              ? widget.controlButton.left(previous)
              : Center(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.resolveWith(
                                  (s) => EdgeInsets.zero),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.transparent),
                              shape: MaterialStateProperty.resolveWith(
                                  (states) => RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)))),
                          child: Icon(
                            Icons.arrow_back_ios_outlined,
                            size: 15,
                          ),
                          onPressed: previous,
                        ),
                      )),
                )),
      Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: widget.controlButton != null
              ? widget.controlButton.right(next)
              : Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.resolveWith(
                                  (s) => EdgeInsets.zero),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.transparent),
                              shape: MaterialStateProperty.resolveWith(
                                  (states) => RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)))),
                          child: Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                          onPressed: next,
                        ),
                      )),
                )),
    ];
  }

  List<Widget> _buildItems() {
    items = [];
    for (var i = 0; i < widget.itemCount; i++) {
      Widget item = widget.itemBuilder(context, i);

      items.add((widget.viewportFraction != null && widget.viewportFraction < 1)
          ? Transform.scale(
              scale: page == i ? 1 : widget.scale ?? 0.8, child: item)
          : item);
    }
    return items;
  }

  // auto play snap
  _autoPlaySnap() {
    if (items != null && items.isNotEmpty)
      snapTimer = Timer(_autoPlayDelay, () {
        snapTimerPerodic = Timer.periodic(_autoPlayInterval, (timer) {
          if (page == 0 ||
              (page < items.length - 1 &&
                  direction == ScrollDirection.forward)) {
            if (mounted && page == 0)
              setState(() {
                direction = ScrollDirection.forward;
              });
            if (pageController.hasClients)
              pageController.nextPage(
                  duration: _duration, curve: Curves.easeInCubic);
          } else {
            if (page == (-1 + items.length)) {
              if (mounted)
                setState(() {
                  direction = ScrollDirection.reverse;
                });
            }
            if (pageController.hasClients) if (widget.reverse)
              pageController.previousPage(
                  duration: _duration, curve: Curves.easeInCubic);
            else
              pageController.jumpToPage(
                0,
              );
          }
        });
      });
  }

  void _stopAutoplay() {
    if (snapTimerPerodic != null) {
      snapTimerPerodic.cancel();
      snapTimerPerodic = null;
    }
    if (snapTimer != null) {
      snapTimer.cancel();
      snapTimer = null;
    }
  }

  Widget _buildDots(int ind) {
    Function() onDotPressed = () => pageController.animateToPage(ind,
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
    return widget.dotBuilder != null
        ? widget.dotBuilder(context, ind, onDotPressed)
        : new GestureDetector(
            onTap: onDotPressed,
            child: Container(
              margin: EdgeInsets.all(2.5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: page == ind ? Colors.blue : Colors.white),
            ),
          );
  }

  Widget _buildDotsWidget() {
    return Container(
      color: Colors.transparent,
      width: MediaQuery.of(context).size.width,
      height: thumbSize,
      child: new Align(
        alignment: widget.dotsPosition,
        child: new ListView(
          controller: thumbController,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: _buildSliderDots(),
        ),
      ),
    );
  }

  List<Widget> _buildSliderDots() {
    dots = [];
    for (var i = 0; i < items.length; i++) {
      dots.add(_buildDots(i));
    }
    return dots;
  }

  @override
  void dispose() {
    pageController.dispose();
    thumbController.dispose();
    if (snapTimerPerodic != null) {
      snapTimer.cancel();
      snapTimerPerodic.cancel();
    }
    super.dispose();
  }
}

class ControllButtons {
  final Widget Function(VoidCallback onPress) left;
  final Widget Function(VoidCallback onPress) right;

  ControllButtons({@required this.left, @required this.right})
      : assert(left != null),
        assert(right != null);
}

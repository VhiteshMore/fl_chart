import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_helper.dart';
import 'package:fl_chart/src/chart/base/axis_chart/side_titles/side_titles_flex.dart';
import 'package:fl_chart/src/extensions/bar_chart_data_extension.dart';
import 'package:fl_chart/src/extensions/edge_insets_extension.dart';
import 'package:fl_chart/src/extensions/fl_border_data_extension.dart';
import 'package:fl_chart/src/extensions/fl_titles_data_extension.dart';
import 'package:fl_chart/src/extensions/side_titles_extension.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SideTitlesWidget extends StatefulWidget {
  const SideTitlesWidget({
    super.key,
    required this.side,
    required this.axisChartData,
    required this.parentSize,
    this.axisMinOverride,
    this.axisMaxOverride,
    this.isScrollable = false,
  });

  final AxisSide side;
  final AxisChartData axisChartData;
  final Size parentSize;
  final double? axisMinOverride;
  final double? axisMaxOverride;
  final bool isScrollable;

  @override
  State<SideTitlesWidget> createState() => _SideTilesWidgetState();
}

class _SideTilesWidgetState extends State<SideTitlesWidget> {

  ScrollController? scrollController;

  @override
  void initState() {
    if (widget.isScrollable) {
      scrollController = ScrollController(
          initialScrollOffset: (isHorizontal
                  ? (widget.axisChartData.maxX - widget.axisChartData.minX)
                  : (widget.axisChartData.maxY - widget.axisChartData.minY)) *
              widget.axisChartData.horizontalZoomConfig.amount);
      if (widget.axisChartData.scrollController != null) {
        widget.axisChartData.scrollController!.addListener(scrollListener);
      }
    }
    super.initState();
  }

  void scrollListener() {
    final chartScrollOffset = widget.axisChartData.scrollController!.offset;
    final chartMaxScrollOffset = widget.axisChartData.scrollController!.position.maxScrollExtent;
    final titlesMaxScrollOffset = scrollController!.position.maxScrollExtent;
    final offset = chartScrollOffset +
        ((chartMaxScrollOffset > titlesMaxScrollOffset
            ? chartMaxScrollOffset - titlesMaxScrollOffset
            : titlesMaxScrollOffset - chartMaxScrollOffset) - interval) / 2;
    if (offset > titlesMaxScrollOffset) {
      scrollController!.animateTo(titlesMaxScrollOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,);
    } else if (offset < widget.axisChartData.scrollController!.position.minScrollExtent) {
      scrollController!.animateTo(widget.axisChartData.scrollController!.position.minScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,);
    } else {
      scrollController!.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    scrollController?.removeListener(scrollListener);
    scrollController?.dispose();
    super.dispose();
  }

  double interval = 0;

  List<AxisSideTitleMetaData> currentAxisPositions = [];

  bool get isHorizontal => widget.side == AxisSide.top || widget.side == AxisSide.bottom;

  bool get isVertical => !isHorizontal;

  double get minX => widget.axisMinOverride ?? widget.axisChartData.minX;

  double get maxX => widget.axisMaxOverride ?? widget.axisChartData.maxX;

  double get baselineX => widget.axisChartData.baselineX;

  double get minY => widget.axisChartData.minY;

  double get maxY => widget.axisChartData.maxY;

  double get baselineY => widget.axisChartData.baselineY;

  double get axisMin => isHorizontal ? minX : minY;

  double get axisMax => isHorizontal ? maxX : maxY;

  double get axisBaseLine => isHorizontal ? baselineX : baselineY;

  FlTitlesData get titlesData => widget.axisChartData.titlesData;

  bool get isLeftOrTop => widget.side == AxisSide.left || widget.side == AxisSide.top;

  bool get isRightOrBottom => widget.side == AxisSide.right || widget.side == AxisSide.bottom;

  AxisTitles get axisTitles {
    switch (widget.side) {
      case AxisSide.left:
        return titlesData.leftTitles;
      case AxisSide.top:
        return titlesData.topTitles;
      case AxisSide.right:
        return titlesData.rightTitles;
      case AxisSide.bottom:
        return titlesData.bottomTitles;
    }
  }

  SideTitles get sideTitles => axisTitles.sideTitles;

  Axis get direction => isHorizontal ? Axis.horizontal : Axis.vertical;

  Axis get counterDirection => isHorizontal ? Axis.vertical : Axis.horizontal;

  Alignment get alignment {
    switch (widget.side) {
      case AxisSide.left:
        return Alignment.centerLeft;
      case AxisSide.top:
        return Alignment.topCenter;
      case AxisSide.right:
        return Alignment.centerRight;
      case AxisSide.bottom:
        return Alignment.bottomCenter;
    }
  }

  EdgeInsets get thisSidePadding {
    final titlesPadding = titlesData.allSidesPadding;
    final borderPadding = widget.axisChartData.borderData.allSidesPadding;
    switch (widget.side) {
      case AxisSide.right:
      case AxisSide.left:
        return titlesPadding.onlyTopBottom + borderPadding.onlyTopBottom;
      case AxisSide.top:
      case AxisSide.bottom:
        return titlesPadding.onlyLeftRight + borderPadding.onlyLeftRight;
    }
  }

  double get thisSidePaddingTotal {
    final borderPadding = widget.axisChartData.borderData.allSidesPadding;
    final titlesPadding = titlesData.allSidesPadding;
    switch (widget.side) {
      case AxisSide.right:
      case AxisSide.left:
        return titlesPadding.vertical + borderPadding.vertical;
      case AxisSide.top:
      case AxisSide.bottom:
        return titlesPadding.horizontal + borderPadding.horizontal;
    }
  }

  List<AxisSideTitleWidgetHolder> makeWidgets(
    double axisViewSize,
    double axisMin,
    double axisMax,
    AxisSide side,
    ZoomConfig xAxisZoom,
  ) {
    List<AxisSideTitleMetaData> axisPositions;
    final interval = sideTitles.interval ??
        Utils().getEfficientInterval(
          axisViewSize,
          axisMax - axisMin,
        );
    if (isHorizontal && widget.axisChartData.titlesData.bottomTitles.sideTitles.showTitles) {
      this.interval = interval;
    }
    if (isHorizontal && widget.axisChartData is BarChartData) {
      final barChartData = widget.axisChartData as BarChartData;
      if (barChartData.barGroups.isEmpty) {
        return [];
      }
      final xLocations = barChartData.calculateGroupsX(axisViewSize);
      axisPositions = xLocations.asMap().entries.map((e) {
        final index = e.key;
        final xLocation = e.value;
        final xValue = barChartData.barGroups[index].x;
        return AxisSideTitleMetaData(xValue.toDouble(), xLocation);
      }).toList();
      currentAxisPositions = List.from(axisPositions);
    } else {
      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: axisMin,
        max: axisMax,
        minIncluded: sideTitles.minIncluded,
        maxIncluded: sideTitles.maxIncluded,
        baseLine: axisBaseLine,
        interval: interval,
      );
      axisPositions = axisValues.map((axisValue) {
        final axisDiff = axisMax - axisMin;
        var portion = 0.0;
        if (axisDiff > 0) {
          portion = (axisValue - axisMin) / axisDiff;
        }
        if (isVertical) {
          portion = 1 - portion;
        }
        final axisLocation = portion * axisViewSize;
        return AxisSideTitleMetaData(axisValue, axisLocation);
      }).toList();
    }
    final axisChartData = widget.axisChartData;
    return axisPositions.map(
      (metaData) {
        final Widget widget;
        final isOutOfHorizontalAxis = isHorizontal &&
            (metaData.axisValue < axisChartData.minX ||
                metaData.axisValue > axisChartData.maxX);
        final isOutOfVerticalAxis = isVertical &&
            (metaData.axisValue < axisChartData.minY ||
                metaData.axisValue > axisChartData.maxY);
        // if (isOutOfHorizontalAxis || isOutOfVerticalAxis) {
        //   widget = Container();
        // } else {
          widget = sideTitles.getTitlesWidget(
            metaData.axisValue,
            TitleMeta(
              min: axisMin,
              max: axisMax,
              appliedInterval: interval,
              sideTitles: sideTitles,
              formattedValue: Utils().formatNumber(
                axisMin,
                axisMax,
                metaData.axisValue,
              ),
              axisSide: side,
              parentAxisSize: axisViewSize,
              axisPosition: metaData.axisPixelLocation,
            ),
          );
        // }
        return AxisSideTitleWidgetHolder(metaData, widget);
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!axisTitles.showAxisTitles && !axisTitles.showSideTitles) {
      return Container();
    }
    final axisViewSize = widget.isScrollable
        ? (widget.axisChartData.horizontalZoomConfig.amount)
        : (isHorizontal ? widget.parentSize.width : widget.parentSize.height);
    final Widget child = Flex(
      direction: counterDirection,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLeftOrTop && axisTitles.axisNameWidget != null)
          _AxisTitleWidget(
            axisTitles: axisTitles,
            side: widget.side,
            axisViewSize: axisViewSize,
          ),
        if (sideTitles.showTitles)
          Container(
            // color: Colors.red,
            width: isHorizontal ? axisViewSize : sideTitles.reservedSize,
            height: isHorizontal ? sideTitles.reservedSize : axisViewSize,
            margin: thisSidePadding,
            child: SideTitlesFlex(
              direction: direction,
              axisSideMetaData: AxisSideMetaData(
                axisMin,
                axisMax,
                axisViewSize - thisSidePaddingTotal,
              ),
              widgetHolders: makeWidgets(
                axisViewSize - thisSidePaddingTotal,
                axisMin,
                axisMax,
                widget.side,
                widget.axisChartData.horizontalZoomConfig,
              ),
            ),
          ),
        if (isRightOrBottom && axisTitles.axisNameWidget != null)
          _AxisTitleWidget(
            axisTitles: axisTitles,
            side: widget.side,
            axisViewSize: axisViewSize,
          ),
      ],
    );
    return Align(
      alignment: alignment,
      child: widget.isScrollable ? Container(
              margin: widget.isScrollable
                  ? EdgeInsets.only(
                      left: widget.axisChartData.titlesData.leftTitles.totalReservedSize,
                      right: widget.axisChartData.titlesData.rightTitles.totalReservedSize,
                    )
                  : EdgeInsets.zero,
              // constraints: BoxConstraints(maxWidth: widget.parentSize.width - 0),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          hitTestBehavior: HitTestBehavior.deferToChild,
          scrollDirection: direction,
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: child,
        ),
      ) : child,
    );
  }
}

class _AxisTitleWidget extends StatelessWidget {
  const _AxisTitleWidget({
    required this.axisTitles,
    required this.side,
    required this.axisViewSize,
  });

  final AxisTitles axisTitles;
  final AxisSide side;
  final double axisViewSize;

  int get axisNameQuarterTurns {
    switch (side) {
      case AxisSide.right:
        return 3;
      case AxisSide.left:
        return 3;
      case AxisSide.top:
        return 0;
      case AxisSide.bottom:
        return 0;
    }
  }

  bool get isHorizontal => side == AxisSide.top || side == AxisSide.bottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isHorizontal ? axisViewSize : axisTitles.axisNameSize,
      height: isHorizontal ? axisTitles.axisNameSize : axisViewSize,
      child: Center(
        child: RotatedBox(
          quarterTurns: axisNameQuarterTurns,
          child: axisTitles.axisNameWidget,
        ),
      ),
    );
  }
}

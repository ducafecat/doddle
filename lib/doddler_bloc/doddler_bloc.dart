import 'package:bloc/bloc.dart';
import 'package:doddle/draw_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;

import 'doddler_event.dart';
import 'doddler_state.dart';

class DoddlerBloc extends Bloc<DoddlerEvent, DoddlerState> {
  DrawController? drawController;
  DoddlerBloc({this.drawController = const DrawController()})
      : super(UpdateCanvasState());

  @override
  Stream<DoddlerState> mapEventToState(DoddlerEvent event) async* {
    if (event is ClearPageEvent) {
      drawController!.points!.clear();
      yield UpdateCanvasState(drawController: drawController);
    } else if (event is AddPointEvent) {
      drawController!.points!.add(event.point);
      yield UpdateCanvasState(drawController: drawController);
    } else if (event is UndoPointEvent) {
    } else if (event is RedoPointEvent) {
    } else if (event is ChangeCurrentColorEvent) {
      drawController =
          drawController?.copyWith(currentColor: event.color ?? Colors.white);
    } else if (event is SavePageToGalleryEvent) {
      save(event.globalKey ?? drawController!.globalKey!);
    } else if (event is InitGlobalKeyEvent) {
      drawController = drawController?.copyWith(globalKey: event.globalKey);
      // drawController!.globalKey = event.globalKey;
    } else if (event is UpdateSymmetryLines) {
      drawController =
          drawController?.copyWith(symmetryLines: event.symmetryLines);
      // drawController!.globalKey = event.globalKey;
    } else if (event is TakePageStampEvent) {
      try {
        ui.Image image = await canvasToImage(event.globalKey);
        List<Stamp?>? stamps = List.from(drawController!.stamp!);
        stamps.add(Stamp(image: image));
        drawController =drawController!.copyWith(stamp: stamps);
      } catch (e) {
        print(e);
      }
      yield UpdateCanvasState(drawController: drawController);
    }
  }

  Future<ui.Image> canvasToImage(GlobalKey globalKey) async {
    final boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage();
    return image;
  }

  Future<void> save(GlobalKey globalKey) async {
    try {
      final boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final saved = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: DateTime.now().toIso8601String() + ".jpeg",
        isReturnImagePathOfIOS: true,
      );
    } catch (e) {
      print(e);
    }
  }
}

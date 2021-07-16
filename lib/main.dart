import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:photo_view/photo_view.dart';
import 'package:receiver_app/models/drawing_area.dart';
import 'package:receiver_app/widgets/default_widget.dart';
import 'package:receiver_app/widgets/image_widget.dart';
import 'package:receiver_app/widgets/text_widget.dart';
import 'widgets/custom_painter.dart';

void main() => runApp(MyApp());

enum Mode {
  IMAGE,
  TEXT,
  DRAW,
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = "Retro the first";
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  Map<String, ConnectionInfo> endpointMap = Map();

  Mode mode;

  Widget _getCurrentChild() {
    if (mode == null) {
      // return logo.
      return DefaultWidget();
    }
    switch (mode) {
      case Mode.TEXT:
        return SentText(
          sentText: sentText,
          color: color,
          fontSize: fontSize,
        );

      case Mode.IMAGE:
        return SentImage(
          filePath: filePath,
          controller: controller,
        );

      case Mode.DRAW:
        return CustomPaint(
          painter: MyCustomPainter(points: points),
        );

      default:
        return Text("Default");
    }
  }

  @override
  void initState() {
    controller = PhotoViewController(initialScale: 0.1);
    points = [];
    discover();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // divide widgets here
    return Center(
      child: Container(
        width: 500,
        height: 500,
        child: _getCurrentChild(),
      ),
    );
  }

  void discover() async {
    if (await Nearby().checkLocationPermission())
      Nearby().askLocationPermission();
    bool a = false;
    while (!a) {
      try {
        a = await Nearby().startAdvertising(
          userName,
          strategy,
          onConnectionInitiated: onConnectionInit,
          onConnectionResult: (id, status) {
            showSnackbar(status);
          },
          onDisconnected: (id) {
            showSnackbar(
                "Disconnected: ${endpointMap[id].endpointName}, id $id");
            setState(() {
              endpointMap.remove(id);
            });
            print("Stopping advertising");
            Nearby().stopAdvertising();
            discover();
          },
        );
        if (a) showSnackbar("START ADVERTISING");
      } catch (exception) {
        showSnackbar(exception);
      }
    }
  }

  void showSnackbar(dynamic a) {
    print(a);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(a.toString()),
    // ));
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory()).absolute.path;
    final b =
        await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$fileName');

    setState(() {
      filePath = "$parentDir/$fileName";
      sentText = null;
      points = [];
      mode = Mode.IMAGE;
    });
    showSnackbar("Moved file:" + b.toString());
    return b;
  }

  String checkCode(String str) {
    String checker = str.substring(0, 4);
    setState(() {
      switch (checker) {
        case "s45:": // scale
          controller.scale = double.parse(str.split(":")[1]);
          mode = Mode.IMAGE;
          break;

        case "r45:": // rotation
          controller.rotation = double.parse(str.split(":")[1]);
          mode = Mode.IMAGE;
          break;

        case "p45:": // points
          String point = str.split(":")[1];

          if (point.contains("delete"))
            points.clear();
          else if (point.contains("null"))
            points.add(null);
          else
            points.add(DrawingArea.fromMap(point));

          mode = Mode.DRAW;
          break;
        case "t45:": // text
          List<String> data = str.split("\n");
          sentText = data[1];
          color = Color(int.parse("0x${data[2]}"));
          fontSize = double.parse(data[3]);
          filePath = null;
          controller = PhotoViewController(initialScale: 0.1);
          points = [];

          mode = Mode.TEXT;
          break;
      }
    });
    return checker;
  }

  String sentText;
  Color color;
  double fontSize;
  String filePath;
  PhotoViewControllerBase controller;
  List<DrawingArea> points;

  String tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = Map(); //store deviceId

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, ConnectionInfo info) {
    setState(() {
      endpointMap[id] = info;
    });
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes);

          String checker = checkCode(str);

          if (str.contains(':') &&
              checker != "s45:" &&
              checker != "r45:" &&
              checker != "p45:" &&
              checker != "t45:") {
            // used for file payload as file payload is mapped as
            // payloadId:filename
            int payloadId = int.parse(str.split(':')[0]);
            String fileName = (str.split(':')[1]);

            if (map.containsKey(payloadId)) {
              if (tempFileUri != null) {
                moveFile(tempFileUri, fileName);
              } else {
                showSnackbar("File doesn't exist");
              }
            } else {
              //add to map if not already
              map[payloadId] = fileName;
            }
          }
        } else if (payload.type == PayloadType.FILE) {
          showSnackbar(endid + ": File transfer started");
          tempFileUri = payload.uri;
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
        if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRESS) {
          print(payloadTransferUpdate.bytesTransferred);
        } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
          print("failed");
          showSnackbar(endid + ": FAILED to transfer file");
        } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          showSnackbar(
              "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");

          if (map.containsKey(payloadTransferUpdate.id)) {
            //rename the file now
            String name = map[payloadTransferUpdate.id];
            moveFile(tempFileUri, name);
          } else {
            //bytes not received till yet
            map[payloadTransferUpdate.id] = "";
          }
        }
      },
    );
  }
}

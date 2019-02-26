import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FireMap(),
      ),
    );
  }
}

class FireMap extends StatefulWidget {
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  Location location = new Location();

  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  BehaviorSubject<double> radius = BehaviorSubject(seedValue: 100.0);
  Stream<dynamic> query;

  List<String> workers = new List();
  List<String> material = new List();
  String casa;
  TextEditingController _myCasaController = new TextEditingController();
  TextEditingController _myWorkersController = new TextEditingController();
  TextEditingController _myMaterialController = new TextEditingController();

  String dateFormat;


  StreamSubscription subscription;

  build(context) {
    return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(24.150, -110.32), zoom: 10),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            mapType: MapType.hybrid,
            trackCameraPosition: true,
          ),

          Positioned(
            bottom: 90,
            right: 10,
            child: FlatButton(
              child: Icon(Icons.play_arrow),
              color: Colors.green,
              onPressed: () {
                _showDialog();
              },
            ),
          ),
          Positioned(
            bottom: 50,
            right: 10,
            child: FlatButton(
              child: Icon(Icons.stop),
              color: Colors.red,
              onPressed: () {
                _showDialogMaterial();
                workers.clear();
              },
            ),
          ),
          Positioned(
            bottom: 50,
            left: 10,
            child: Slider(
              min: 100.0,
              max: 500.0,
              divisions: 4,
              value: radius.value,
              label: 'Radius ${radius.value}km',
              activeColor: Colors.green,
              inactiveColor: Colors.green.withOpacity(0.2),
              onChanged: _updateQuery,
            ),
          ),
        ]
    );
  }
  
  _addMarker() {
    var marker = MarkerOptions(
      position: mapController.cameraPosition.target,
      icon: BitmapDescriptor.defaultMarker,
      infoWindowText: InfoWindowText('Comienzo', 'Aqui estamos trabajando')
    );
    
    mapController.addMarker(marker);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  Future<DocumentReference> _addGeoPoint(List<String> workers, String casa, String dateFormat) async {
    var pos = await location.getLocation();
    GeoFirePoint point = geo.point(latitude: pos['latitude'], longitude: pos['longitude']);
    return firestore.collection('locations').add({
      'position': point.data,
      'name': casa,
      'workers': workers,
      'date': dateFormat
    });

  }

  Future<DocumentReference> _addFinishWork(List<String> material, String dateFormat) async {
    var pos = await location.getLocation();
    GeoFirePoint point = geo.point(latitude: pos['latitude'], longitude: pos['longitude']);
    return firestore.collection('finish').add({
      'position': point.data,
      'material': material,
      'date': dateFormat
    });
  }

  _updateQuery(value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    mapController.moveCamera(CameraUpdate.zoomTo(zoom));

    setState(() {
      radius.add(value);
    });
  }

  _showDialog() async {
    await showDialog<String>(
      context: context,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                    autofocus: true,
                    decoration: new InputDecoration(
                        labelText: 'Trabajador', hintText: 'ej. John Smith'
                    ),
                    controller: _myWorkersController,
                    onSubmitted: (text) {
                      setState(() {
                        workers.add(text);
                        _myWorkersController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                    autofocus: true,
                    decoration: new InputDecoration(
                        labelText: 'Casa', hintText: 'ej. Pedro Formentera'
                    ),
                    controller: _myCasaController,
                    onSubmitted: (text) {
                      setState(() {
                        casa = text;
                        _myCasaController.clear();
                      });
                    },
                  ),
                )
              ],
            )


          ],
        ),
        actions: <Widget>[
          new FlatButton(
              child: const Text('GRABAR'),
              onPressed: () {
                dateFormat = DateFormat.yMEd().add_jms().format(new DateTime.now());
                _addGeoPoint(workers, casa, dateFormat);
                _addMarker();
                Navigator.pop(context);
              })
        ],
      ),
    );
  }

  _showDialogMaterial() async {
    await showDialog<String>(
      context: context,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                    autofocus: true,
                    decoration: new InputDecoration(
                        labelText: 'Has usado material', hintText: 'ej. Tierra'
                    ),
                    controller: _myWorkersController,
                    onSubmitted: (text) {
                      setState(() {
                        material.add(text);
                        _myMaterialController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          new FlatButton(
              child: const Text('GRABAR'),
              onPressed: () {
                dateFormat = DateFormat.yMEd().add_jms().format(new DateTime.now());
                _addFinishWork(material, dateFormat);
                Navigator.pop(context);
              })
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    subscription.cancel();
    super.dispose();
  }
}


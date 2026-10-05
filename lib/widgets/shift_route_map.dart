import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/gps_tracker.dart';

// Real geographic tiles and GPS samples share one Web Mercator projection.
class ShiftRouteMap extends StatefulWidget {
  final String? shiftId;
  final bool paused;
  final bool satellite;
  final double unit;
  const ShiftRouteMap({super.key,required this.shiftId,this.paused=false,this.unit=1,this.satellite=false});
  @override State<ShiftRouteMap> createState()=>_ShiftRouteMapState();
}
class _ShiftRouteMapState extends State<ShiftRouteMap> {
  List<Map<String,dynamic>> points=[];Timer? timer;bool loading=false;String? error;
  int zoomDelta=0,generation=0;Offset pan=Offset.zero;
  late bool satellite;bool follow=true;
  @override void initState(){super.initState();satellite=widget.satellite;refresh();timer=Timer.periodic(const Duration(seconds:3),(_){if(mounted&&TickerMode.of(context))refresh();});}
  @override void didUpdateWidget(covariant ShiftRouteMap old){super.didUpdateWidget(old);if(old.shiftId!=widget.shiftId){generation++;points=[];pan=Offset.zero;zoomDelta=0;follow=true;refresh();}}
  Future<void> refresh()async{
    if(loading||!mounted)return;final id=widget.shiftId;if(id==null)return;loading=true;final token=generation;
    try{final rows=await GpsRouteStore.points(id);if(mounted&&token==generation)setState((){points=rows.where((p)=>p['lat'] is num&&p['lng'] is num&&(p['lat'] as num).isFinite&&(p['lng'] as num).isFinite).toList();error=null;});}
    catch(_){if(mounted)setState(()=>error='Не удалось прочитать GPS-трек');}finally{loading=false;}
  }
  @override void dispose(){generation++;timer?.cancel();super.dispose();}
  Offset project(Map<String,dynamic> p){final lat=(p['lat'] as num).toDouble().clamp(-85.0511,85.0511)*math.pi/180;
    return Offset(((p['lng'] as num).toDouble()+180)/360,(1-math.log(math.tan(lat)+1/math.cos(lat))/math.pi)/2);}
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,box){
    final u=widget.unit;
    // Default viewport is a regional overview, never presented as a GPS fix.
    final projected=points.map(project).toList();
    final bounds=projected.isEmpty?[project({'lat':53.3,'lng':69.4})]:projected;
    var minX=bounds.first.dx,maxX=minX,minY=bounds.first.dy,maxY=minY;
    for(final p in bounds){minX=math.min(minX,p.dx);maxX=math.max(maxX,p.dx);minY=math.min(minY,p.dy);maxY=math.max(maxY,p.dy);}
    final tileSize=256*u;final fit=math.min((box.maxWidth-50*u)/(math.max(maxX-minX,projected.isEmpty ? .006 : .0003)*tileSize),(box.maxHeight-60*u)/(math.max(maxY-minY,projected.isEmpty ? .006 : .0003)*tileSize));
    final fitZoom=(math.log(math.max(1,fit))/math.ln2).floor().clamp(3,15);
    final z=((follow&&projected.isNotEmpty?14:fitZoom)+zoomDelta).clamp(3,18);final n=1<<z;final world=tileSize*n;
    final center=(follow&&projected.isNotEmpty?projected.last:Offset((minX+maxX)/2,(minY+maxY)/2))*world;
    final origin=center-Offset(box.maxWidth/2,box.maxHeight/2)-pan;
    final firstX=(origin.dx/tileSize).floor(),lastX=((origin.dx+box.maxWidth)/tileSize).floor();
    final firstY=(origin.dy/tileSize).floor(),lastY=((origin.dy+box.maxHeight)/tileSize).floor();
    final offsets=projected.map((p)=>p*world-origin).toList();
    return ClipRect(child:GestureDetector(onPanUpdate:(d)=>setState(()=>pan+=d.delta),child:Stack(children:[
      const Positioned.fill(child:ColoredBox(color:Color(0xFF10202B))),
      for(var y=firstY;y<=lastY;y++)for(var x=firstX;x<=lastX;x++)if(y>=0&&y<n)
        Positioned(left:x*tileSize-origin.dx,top:y*tileSize-origin.dy,width:tileSize+.5,height:tileSize+.5,
          child:_RouteTile(key:ValueKey('$z/${x%n}/$y/$satellite'),z:z,x:x%n,y:y,satellite:satellite)),
      Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_RouteStroke(offsets,points,u)))),
      Positioned(right:8*u,top:8*u,child:Column(children:[control(Icons.add,()=>setState(()=>zoomDelta=(zoomDelta+1).clamp(-10,10)),u),
        control(Icons.remove,()=>setState(()=>zoomDelta=(zoomDelta-1).clamp(-10,10)),u),
        control(Icons.my_location,()=>setState((){zoomDelta=0;pan=Offset.zero;follow=true;}),u),
        control(Icons.route,()=>setState((){zoomDelta=0;pan=Offset.zero;follow=false;}),u)])),
      Positioned(left:8*u,top:8*u,child:Material(color:const Color(0xE6091720),borderRadius:BorderRadius.circular(8*u),child:InkWell(
        borderRadius:BorderRadius.circular(8*u),onTap:()=>setState(()=>satellite=!satellite),child:Padding(padding:EdgeInsets.symmetric(horizontal:9*u,vertical:7*u),child:Row(mainAxisSize:MainAxisSize.min,children:[
          Icon(Icons.layers_outlined,size:15*u,color:const Color(0xFFE4B264)),SizedBox(width:5*u),Text(satellite?'Спутник':'Карта',style:TextStyle(color:Colors.white,fontSize:11*u)),
        ]))))),
      Positioned(left:5*u,bottom:3*u,child:GestureDetector(onTap:()=>showAboutDialog(context:context,applicationName:'Источники карты',
        children:const [Text('Снимки: Esri, Vantor, Earthstar Geographics, GIS User Community.\nhttps://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer\nКарта: © OpenStreetMap contributors · ODbL\nhttps://www.openstreetmap.org/copyright')]),
        child:Container(color:const Color(0xCC09141D),padding:EdgeInsets.all(3*u),child:Text(satellite?'Esri, Vantor, Earthstar Geographics · © OSM':'© OpenStreetMap contributors',style:TextStyle(color:Colors.white70,fontSize:9*u))))),
      if(points.isEmpty)Positioned(left:8*u,right:48*u,bottom:25*u,child:Container(padding:EdgeInsets.all(7*u),color:const Color(0xDD09141D),child:Text(error??(widget.shiftId==null?'Откройте смену для записи маршрута':'Ожидание координат GPS'),style:TextStyle(color:Colors.white70,fontSize:11*u)))),
      if(widget.paused)Positioned(left:8*u,top:43*u,child:Text('GPS на паузе',style:TextStyle(color:Colors.amber,fontSize:11*u))),
    ])));
  });
  Widget control(IconData icon,VoidCallback action,double u)=>SizedBox(width:30*u,height:30*u,child:Material(color:const Color(0xDB0A1720),
    borderRadius:BorderRadius.circular(7*u),child:InkWell(onTap:action,child:Icon(icon,color:const Color(0xFFE4B264),size:18*u))));
}
class _RouteStroke extends CustomPainter {
  final List<Offset> pts;final List<Map<String,dynamic>> samples;final double u;
  _RouteStroke(this.pts,this.samples,this.u);
  @override void paint(Canvas c,Size s){if(pts.isEmpty)return;final path=Path()..moveTo(pts.first.dx,pts.first.dy);
    for(var i=1;i<pts.length;i++){
      final a=DateTime.tryParse(samples[i-1]['time']?.toString()??'');final b=DateTime.tryParse(samples[i]['time']?.toString()??'');
      // Do not invent a road across a signal gap or paused recording.
      if(a==null||b==null||b.difference(a).inSeconds>120){path.moveTo(pts[i].dx,pts[i].dy);}else{path.lineTo(pts[i].dx,pts[i].dy);}}
    c.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeWidth=8*u..color=const Color(0x99F7AC41)..maskFilter=MaskFilter.blur(BlurStyle.normal,5*u));
    c.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeWidth=5*u..color=const Color(0xFF493516));
    c.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..strokeWidth=2.5*u..color=const Color(0xFFFFC965));
    c.drawCircle(pts.first,4*u,Paint()..color=const Color(0xFFFFCB78));
    c.drawCircle(pts.last,9*u,Paint()..color=const Color(0x9961D9FF)..maskFilter=MaskFilter.blur(BlurStyle.normal,5*u));
    c.drawCircle(pts.last,7*u,Paint()..color=const Color(0xFF008DBC));c.drawCircle(pts.last,7*u,Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=1.5*u);
    final caption=TextPainter(text:TextSpan(text:'Вы здесь',style:TextStyle(color:Colors.white,fontSize:11*u,fontWeight:FontWeight.w600)),textDirection:TextDirection.ltr)..layout();
    final x=(pts.last.dx-caption.width/2).clamp(4*u,math.max(4*u,s.width-caption.width-10*u)).toDouble();
    final y=(pts.last.dy+13*u).clamp(4*u,math.max(4*u,s.height-caption.height-24*u)).toDouble();
    if((Offset.zero&s).contains(pts.last)){
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-4*u,y-3*u,caption.width+8*u,caption.height+6*u),Radius.circular(4*u)),Paint()..color=const Color(0xE6091720));
      caption.paint(c,Offset(x,y));
    }
  }
  @override bool shouldRepaint(covariant _RouteStroke old)=>true;
}
class _RouteTile extends StatefulWidget {
  final int z,x,y;final bool satellite;const _RouteTile({super.key,required this.z,required this.x,required this.y,this.satellite=false});
  @override State<_RouteTile> createState()=>_RouteTileState();
}
class _RouteTileState extends State<_RouteTile>{
  late Future<Uint8List> bytes;bool imagery=false;
  static final client=HttpClient()..userAgent='MelnitsaDriver/1.1 (Android shift route map)'..connectionTimeout=const Duration(seconds:12);
  Future<Uint8List> fetch(){final satellite=widget.satellite;imagery=satellite;final key='${satellite?'imagery':'osm'}_${widget.z}_${widget.x}_${widget.y}';return (()async{
    final dir=Directory('${Directory.systemTemp.path}/melnitsa_map_tiles');await dir.create(recursive:true);final file=File('${dir.path}/$key.png');
    try{if(await file.exists()&&DateTime.now().difference(await file.lastModified()).inDays<7)return await file.readAsBytes();final request=await client.getUrl(Uri.parse(satellite?'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${widget.z}/${widget.y}/${widget.x}':'https://tile.openstreetmap.org/${widget.z}/${widget.x}/${widget.y}.png'));
      final response=await request.close().timeout(const Duration(seconds:15));if(response.statusCode!=200)throw HttpException('Карта недоступна');
      final builder=BytesBuilder();await for(final chunk in response.timeout(const Duration(seconds:15))){builder.add(chunk);}
      final data=builder.takeBytes();await file.writeAsBytes(data);return data;
    }catch(_){if(await file.exists())return file.readAsBytes();
      if(satellite){
        imagery=false;
        final request=await client.getUrl(Uri.parse('https://tile.openstreetmap.org/${widget.z}/${widget.x}/${widget.y}.png'));
        final response=await request.close().timeout(const Duration(seconds:15));
        if(response.statusCode!=200)throw HttpException('Карта недоступна');
        final data=BytesBuilder();await for(final chunk in response.timeout(const Duration(seconds:15))){data.add(chunk);}return data.takeBytes();
      }rethrow;}
  })();}
  @override void initState(){super.initState();bytes=fetch();}
  @override void didUpdateWidget(covariant _RouteTile old){super.didUpdateWidget(old);if(old.z!=widget.z||old.x!=widget.x||old.y!=widget.y||old.satellite!=widget.satellite)bytes=fetch();}
  @override Widget build(BuildContext context)=>FutureBuilder<Uint8List>(future:bytes,builder:(context,s){
    if(!s.hasData)return Container(color:const Color(0xFF14232D),child:s.hasError?Center(child:TextButton(onPressed:()=>setState(()=>bytes=fetch()),
      child:const Text('Нет карты\nПовторить',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Colors.white54)))):null);
    if(imagery)return Image.memory(s.data!,fit:BoxFit.fill,gaplessPlayback:true,color:const Color(0xFFB6C9D2),colorBlendMode:BlendMode.modulate);
    // Keep original road labels legible; the old inversion erased context.
    return Image.memory(s.data!,fit:BoxFit.fill,gaplessPlayback:true,
      color:const Color(0xFFD2DBDE),colorBlendMode:BlendMode.modulate);
  });
}

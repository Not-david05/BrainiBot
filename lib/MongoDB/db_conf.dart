import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static const String mongoUrl = "mongodb+srv://davidvalentin:<abc_D123>@cluster0.ipccr.mongodb.net/flutter_imatges?retryWrites=true&w=majority&appName=Cluster0";
  static const String collectionName = "usuarios";

  static late Db _db;
  static late DbCollection _collection;

  static Future<void> conectar() async {
    _db = await Db.create(mongoUrl);
    await _db.open();
    _collection = _db.collection(collectionName);
  }

  static Future<void> cerrarConexion() async {
    await _db.close();
  }

  static Future<Map<String, dynamic>?> obtenerUsuario(String uid) async {
    return await _collection.findOne(where.eq('_id', uid));
  }

  static Future<void> actualizarImagenPerfil(String uid, String imageUrl) async {
    await _collection.updateOne(
      where.eq('_id', uid),
      modify.set('profile_image_url', imageUrl),
    );
  }
}
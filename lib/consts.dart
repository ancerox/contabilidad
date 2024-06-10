import 'package:flutter/material.dart';

const subtitles =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20);

Size size(BuildContext context) {
  return MediaQuery.of(context).size;
}

Future<bool> showConfirmDialog(BuildContext context, String mensaje) async {
  return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmación'),
            content: Text(mensaje),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí'),
              ),
            ],
          );
        },
      ) ??
      false; // En caso de que el usuario cierre el diálogo por otros medios, consideramos que la respuesta es 'No'.
}

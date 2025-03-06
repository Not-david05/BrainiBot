
import 'package:brainibot/Pages/Log%20in.dart';
import 'package:brainibot/Pages/Sign%20up.dart';
import 'package:flutter/material.dart';

class LoginORegistre extends StatefulWidget {
  const LoginORegistre({super.key});

  @override
  State<LoginORegistre> createState() => _LoginORegistreState();
}

class _LoginORegistreState extends State<LoginORegistre> {
 bool mostraPaginaLogin= true;
 void intercanviarPaginesLoginRegistre(){
  setState(() {
  mostraPaginaLogin = !mostraPaginaLogin;
});
 }
  @override
  Widget build(BuildContext context) {
    print("Mostra login val:"+ mostraPaginaLogin.toString());
    if(mostraPaginaLogin){
    return LogInPage(ferClic:intercanviarPaginesLoginRegistre ,);
    }else{
    return SignInPage(ferClic:intercanviarPaginesLoginRegistre);
    }
    
  }
}
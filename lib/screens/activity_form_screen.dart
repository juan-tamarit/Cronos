import 'package:cronos/db/activity_dao.dart';
import 'package:cronos/models/activity.dart';
import 'package:flutter/material.dart';

class ActivityFormScreen extends StatefulWidget{
  final Activity? activity;
  const ActivityFormScreen({super.key,this.activity});

  @override
  State<ActivityFormScreen> createState()=> _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen>{
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _objetiveController;

  List <int> _daysWeek=[];
  bool _active=true;

  @override
  void initState() {
    super.initState();

    _nameController=TextEditingController(text: widget.activity?.name??'');
    _descriptionController=TextEditingController(text:widget.activity?.description??'');
    _objetiveController=TextEditingController(text: widget.activity?.objetiveMinutes.toString()??'');

    _daysWeek= widget.activity?.daysWeek?? [];
    _active= widget.activity?.active ?? true;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text( widget.activity==null
        ? 'Nueva Actividad'
        : 'Editar Actividad'),
      ),
      body:Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child:ListView(
            children: [
              _buildNameField(),
              _buildDescriptionField(),
              _buildObjetiveField(),
              _buildDaysSelector(),
              _buildActiveSwitch(),
              const SizedBox(height:24),
              _buildSveButton()
            ]
          ),
        ) 
      )
    );
  }

  Widget _buildNameField(){
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Nombre'),
      validator: (value){
        if (value==null|| value.trim().isEmpty){
          return 'El nombre es obligatorio';
        }
        return null;
      }
    );
  }
  Widget _buildDescriptionField(){
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(labelText: 'Descripción'),
    );
  }
  Widget _buildObjetiveField(){
    return TextFormField(
      controller: _objetiveController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Objetivo(minutos)'),
      validator: (value){
        if (value==null|| int.tryParse(value)==null){
          return 'Introduce un número válido';
        }
        return null;
      }
    );
  }
  Widget _buildDaysSelector(){
    final days=['L','M','X','J','V','S','D'];

    return Wrap(
      spacing: 8,
      children: List.generate(days.length,(index){
        return FilterChip(
          label: Text(days[index]),
          selected: _daysWeek.contains(index),
          onSelected: (selected){
            setState(() {
              selected
              ? _daysWeek.add(index)
              : _daysWeek.remove(index);
            });
          }
        );
      })
    );
  }

  Widget _buildActiveSwitch(){
    return SwitchListTile(
      title: const Text('Activa'),
      value: _active,
      onChanged: (value){
        setState(() {
          _active=value;
        });
      }
    );
  }
  Widget _buildSveButton(){
    return ElevatedButton(
      onPressed: _save,
      child: const Text('Guardar')
    );
  }

  Future <void> _save() async{
    if(!_formKey.currentState!.validate()) return;

    final activity=Activity(
      id: widget.activity?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      objetiveMinutes: int.parse(_objetiveController.text),
      daysWeek: _daysWeek,
      active: _active
    );
    final dao= ActivityDao();

    if(widget.activity==null){
      await dao.insert(activity);
    }else{
      await dao.update(activity);
    }
    Navigator.pop(context,true);
  }
}
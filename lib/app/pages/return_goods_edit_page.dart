import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:retog/app/models/buyer_goods.dart';
import 'package:retog/app/models/goods.dart';
import 'package:retog/app/models/goods_barcode.dart';
import 'package:retog/app/models/return_goods.dart';
import 'package:retog/app/models/return_order.dart';
import 'package:retog/app/widgets/date_picker_widget.dart';

class ReturnGoodsEditPage extends StatefulWidget {
  final ReturnOrder returnOrder;
  final ReturnGoods returnGoods;
  final List<Goods> goodsDict;

  ReturnGoodsEditPage({
    @required this.returnOrder,
    @required this.returnGoods,
    @required this.goodsDict,
    Key key
  }) : super(key: key);

  @override
  _ReturnGoodsEditPageState createState() => _ReturnGoodsEditPageState();
}

class _ReturnGoodsEditPageState extends State<ReturnGoodsEditPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _goodsController = TextEditingController();
  TextEditingController _volumeController = TextEditingController();
  TextEditingController _blackVolumeController = TextEditingController();
  TextEditingController _leftVolumeController = TextEditingController();
  TextEditingController _leftBlackVolumeController = TextEditingController();
  BuyerGoods buyerGoods;
  bool isBad;
  DateTime productionDate;
  int volume;
  int blackVolume;
  Goods goods;

  Widget _buildGoodsSearch(BuildContext context) {
    ThemeData theme = Theme.of(context);

    _goodsController.text = goods != null ? goods.name : '';

    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        maxLines: 2,
        cursorColor: theme.textSelectionColor,
        autocorrect: false,
        controller: _goodsController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(8),
          labelText: 'Товар',
          suffixIcon: IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _scanBarcode
          )
        )
      ),
      errorBuilder: (BuildContext ctx, error) {
        return Padding(
          padding: EdgeInsets.all(8),
          child: Text('Произошла ошибка', style: TextStyle(color: theme.errorColor)),
        );
      },
      noItemsFoundBuilder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Ничего не найдено',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.disabledColor, fontSize: 14.0),
          ),
        );
      },
      suggestionsCallback: (String value) async {
        return (await Goods.byBuyer(widget.returnOrder.buyerId)).where(
          (Goods goods) => goods.name.toLowerCase().contains(value.toLowerCase())
        ).toList();
      },
      itemBuilder: (BuildContext ctx, Goods suggestion) {
        return ListTile(
          isThreeLine: false,
          title: Text(suggestion.name, style: Theme.of(context).textTheme.caption)
        );
      },
      onSuggestionSelected: (Goods suggestion) async {
        goods = suggestion;
        buyerGoods = await BuyerGoods.find(widget.returnOrder.buyerId, suggestion.id);

        _leftVolumeController.text = buyerGoods.leftVolume.toString();
        _leftBlackVolumeController.text = buyerGoods.leftBlackVolume.toString();
      }
    );
  }

  Widget _buildTypeDropDown(BuildContext context) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Состояние'
      ),
      items: <bool>[false, true].map((bool value) {
        return DropdownMenuItem<bool>(
          value: value,
          child: Text(value ? 'Некондиция' : 'Кондиция'),
        );
      }).toList(),
      value: isBad,
      onChanged: (bool value) async {
        isBad = value;
        setState(() {});
      }
    );
  }

  Widget _buildProductionDate(BuildContext context) {
    return DatePickerWidget(
      selectedDate: productionDate,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Дата производства',
        suffixIcon: productionDate != null ?
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () async {
              productionDate = null;
              setState(() {});
            },
          ) : null
      ),
      selectDate: (DateTime value) async {
        productionDate = value;
        setState(() {});
      }
    );
  }

  Widget _buildLeftVolumeField(BuildContext context) {
    return TextField(
      controller: _leftVolumeController,
      enabled: false,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Продано'
      )
    );
  }

  Widget _buildLeftBlackVolumeField(BuildContext context) {
    return TextField(
      controller: _leftBlackVolumeController,
      enabled: false,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Продано (Ю2)'
      )
    );
  }

  Widget _buildVolumeField(BuildContext context) {
    return TextField(
      controller: _volumeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Возврат'
      ),
      onChanged: (String value) async {
        volume = int.tryParse(value) ?? 0;
        setState(() {});
      }
    );
  }

  Widget _buildBlackVolumeField(BuildContext context) {
    return TextField(
      controller: _blackVolumeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(8),
        labelText: 'Возврат (Ю2)'
      ),
      onChanged: (String value) async {
        blackVolume = int.tryParse(value) ?? 0;
        setState(() {});
      }
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(8),
      children: <Widget>[
        _buildGoodsSearch(context),
        _buildTypeDropDown(context),
        _buildProductionDate(context),
        Row(
          children: <Widget>[
            Flexible(child: _buildLeftVolumeField(context)),
            SizedBox(width: 8,),
            Flexible(child: _buildLeftBlackVolumeField(context)),
          ],
        ),
        Row(
          children: <Widget>[
            Flexible(child: _buildVolumeField(context)),
            SizedBox(width: 8,),
            Flexible(child: _buildBlackVolumeField(context))
          ],
        ),
      ]
    );
  }

  void _scanBarcode() async {
    String errorMsg;

    try {
      List<GoodsBarcode> barcodes = await GoodsBarcode.byBarcode(await BarcodeScanner.scan());

      if (barcodes.isNotEmpty) {
        GoodsBarcode firstRec = barcodes.first;
        Goods foundGoods = widget.goodsDict.firstWhere((Goods goods) => goods.id == firstRec.goodsId, orElse: () => null);

        if (goods == null) {
          errorMsg = 'Покупателю указанный товар не отгружался';
        } else {
          goods = foundGoods;

          setState(() {});
        }
      } else {
        errorMsg = 'Товар не найден';
      }
    } on PlatformException catch (e) {
      errorMsg = 'Произошла ошибка';

      if (e.code == BarcodeScanner.CameraAccessDenied) {
        errorMsg = 'Необходимо дать доступ к использованию камеры';
      }
    }

    if (errorMsg != null) {
      _showMessage(errorMsg);
    }
  }

  void _showMessage(String content) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(content)));
  }

  Future<void> _loadData() async {
    volume = widget.returnGoods.volume ?? 0;
    blackVolume = widget.returnGoods.blackVolume ?? 0;
    productionDate = widget.returnGoods.productionDate;
    isBad = widget.returnGoods.isBad;

    _volumeController.text = volume.toString() ?? '';
    _blackVolumeController.text = blackVolume.toString() ?? '';

    if (widget.returnGoods.goodsId != null) {
      goods = await Goods.find(widget.returnGoods.goodsId);
      buyerGoods = await BuyerGoods.find(widget.returnOrder.buyerId, widget.returnGoods.goodsId);
      _leftVolumeController.text = (buyerGoods.leftVolume + volume).toString();
      _leftBlackVolumeController.text = (buyerGoods.leftBlackVolume + blackVolume).toString();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (volume == 0 && blackVolume == 0) {
      _showMessage('Указано не верное количество');
      return;
    }

    if (goods == null) {
      _showMessage('Не указан товар');
      return;
    }

    if (isBad == null) {
      _showMessage('Не указано состояние');
      return;
    }

    if (widget.returnGoods.volume != volume) {
      int currentLeftVolume = buyerGoods.leftVolume + (widget.returnGoods.volume ?? 0);

      if (currentLeftVolume < volume) {
        _showMessage('Возвращаемое кол-во должно быть меньше или равно проданному кол-ву');
        return;
      }

      buyerGoods.leftVolume = currentLeftVolume - volume;
      widget.returnGoods.volume = volume;
    }
    if (widget.returnGoods.blackVolume != blackVolume) {
      int currentLeftBlackVolume = buyerGoods.leftBlackVolume + (widget.returnGoods.blackVolume ?? 0);

      if (currentLeftBlackVolume < blackVolume) {
        _showMessage('Возвращаемое кол-во должно быть меньше или равно проданному кол-ву');
        return;
      }

      buyerGoods.leftBlackVolume = currentLeftBlackVolume - blackVolume;
      widget.returnGoods.blackVolume = blackVolume;
    }
    widget.returnGoods.productionDate = productionDate;
    widget.returnGoods.isBad = isBad;
    widget.returnGoods.goodsId = goods.id;

    await widget.returnGoods.update();
    await buyerGoods.update();
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterButtons: <Widget>[
        FlatButton(
          onPressed: _save,
          child: Text('Сохранить'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))
        ),
      ],
      key: _scaffoldKey,
      appBar: AppBar(title: Text('Позиция')),
      body: _buildBody(context)
    );
  }
}

import 'dart:async';

import 'package:bytebank/components/response_dialog.dart';
import 'package:bytebank/components/transaction_auth_dialog.dart';
import 'package:bytebank/http/webclients/transaction_webclient.dart';
import 'package:bytebank/models/contact.dart';
import 'package:bytebank/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionForm extends StatefulWidget {
  final Contact contact;

  TransactionForm(this.contact);

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final TextEditingController _valueController = TextEditingController();
  final TransactionWebClient _webClient = TransactionWebClient();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New transaction'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.contact.name,
                  style: TextStyle(
                    fontSize: 24.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    widget.contact.accountNumber.toString(),
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                    controller: _valueController,
                    style: TextStyle(fontSize: 24.0),
                    decoration: InputDecoration(labelText: 'Value'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: RaisedButton(
                      child: Text('Transfer'),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _formValid(context);
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _formValid(BuildContext context) {
    final double value = double.tryParse(_valueController.text);
    final transactionCreated = Transaction(value, widget.contact);
    showDialog(
        context: context,
        builder: (contextDialog) {
          return TransactionAuthDialog(
            onConfirm: (String password) {
              _save(transactionCreated, password, context);
            },
          );
        });
  }

  void _save(
    Transaction transactionCreated,
    String password,
    BuildContext context,
  ) async {
    final Transaction transaction = await _webClient
        .saveTransaction(transactionCreated, password)
        .catchError((e) => _showFailureDialog(context, e),
            test: (e) => e is HttpException)
        .catchError((e) => _showFailureDialog(context, e),
            test: (e) => e is TimeoutException);

    await _showSuccessDialog(transaction, context);
  }

  Future _showSuccessDialog(
      Transaction transaction, BuildContext context) async {
    if (transaction != null) {
      await showDialog(
          context: context,
          builder: (contextDialog) {
            return SuccessDialog('successful transaction');
          });
      Navigator.pop(context);
    }
  }

  Future _showFailureDialog(BuildContext context, e) {
    return showDialog(
        context: context,
        builder: (contextDialog) {
          return FailureDialog(e.message);
        });
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_card.dart';
import 'package:planka_app/providers/board_provider.dart';
import 'package:planka_app/providers/card_provider.dart';
import 'package:planka_app/widgets/card_list.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/planka_board.dart';
import '../../providers/card_actions_provider.dart';
import '../../providers/list_provider.dart';

class FCardScreen extends StatefulWidget {
  PlankaBoard? currentBoard;
  PlankaCard? card;

  FCardScreen({super.key, this.currentBoard, this.card});


  @override
  _FCardScreenState createState() => _FCardScreenState();
}

class _FCardScreenState extends State<FCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isEditingTitle = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleEditTitle(String cardName) {
    setState(() {
      _isEditingTitle = !_isEditingTitle;
      if (_isEditingTitle) {
        _titleController.text = cardName;
      }
    });
  }

  void _saveTitle(PlankaCard card, BuildContext ctx) {
    if(_titleController.text.isNotEmpty && _titleController.text != ""){
      Provider.of<CardProvider>(ctx, listen: false).updateCardTitle(
        newCardTitle: _titleController.text,
        context: ctx,
        cardId: card.id,
      );

      setState(() {
        card.name = _titleController.text;
        _isEditingTitle = false;
      });
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message:
          'not_empty_name'.tr(),
        ),
      );

      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  /// Callback method to refresh the lists
  void _refreshCard() {
    setState(() {
      Provider.of<CardProvider>(context, listen: false).fetchCard(cardId: widget.card!.id, context: context);
      Provider.of<CardActionsProvider>(context, listen: false).fetchCardComment(widget.card!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, 'refresh'); // Pass 'refresh' as the result
        return false; // Prevent default pop action as we handle it manually
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isEditingTitle ? Container(
            color: Colors.transparent,
            height: kToolbarHeight,
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _titleController,
              autofocus: true,
              onSubmitted: (_) => _saveTitle(widget.card!, context),
            ),
          ) : GestureDetector(
            onTap: () => _toggleEditTitle(widget.card!.name),
            child: Container(
              color: Colors.transparent,
              height: kToolbarHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.card!.name),
            ),
          ),
        ),

        body: FutureBuilder(
          future: Future.wait([
            Provider.of<CardProvider>(context, listen: false).fetchCard(cardId: widget.card!.id, context: context),
            Provider.of<CardActionsProvider>(context, listen: false).fetchCardComment(widget.card!.id),
          ]),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('${'error'.tr()}: ${snapshot.error}'));
            } else {
              return Consumer2<CardProvider, CardActionsProvider>(
                builder: (ctx, cardProvider, cardActionsProvider, _) {
                  final fetchedCard = cardProvider.card;
                  final cardActions = cardActionsProvider.cardActions;

                  if (fetchedCard == null) {
                    return Center(child: Text('card_not_found'.tr()));
                  } else {
                    return CardList(
                      fetchedCard,
                      previewCard: widget.card!,
                      cardActions: cardActions,
                      onRefresh: _refreshCard,
                      currentBoard: widget.currentBoard!,
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );

  }
}

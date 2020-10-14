import 'dart:async';

import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

// ignore_for_file: avoid_print

class VerticalNestedExample extends StatefulWidget {
  const VerticalNestedExample();

  @override
  State<StatefulWidget> createState() => VerticalNestedExampleState();
}

class VerticalNestedExampleState extends State<VerticalNestedExample> {
  List<String> nestedList = List.generate(20, (i) => "$i");
  bool nestedInReorder = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
      ),
      body: ImplicitlyAnimatedReorderableList<String>(
        padding: const EdgeInsets.all(24),
        spawnIsolate: true,
        items: nestedList,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        onReorderFinished: (item, from, to, newList) {
          setState(() {
            nestedList
              ..clear()
              ..addAll(newList);
          });
        },
        header: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Header',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        footer: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Footer',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item),
            builder: (context, dragAnimation, inDrag) {
              return AnimatedBuilder(
                animation: dragAnimation,
                builder: (context, child) {
                  Widget card = Card(
                    elevation: 8,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(item),
                          const Handle(
                            child: Icon(Icons.menu),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (!inDrag) {
                    card = SizeFadeTransition(
                      animation: itemAnimation,
                      child: card,
                    );
                  }

                  return card;
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}


import 'package:flutter/material.dart';
import 'dart:math' as math;


enum _Widget {
  backgroundImage,
  cardsList,
}

// 🔵 Экран разделен пополам, верхняя часть либо закрашена, либо там находится картинка, как на скринкасте.
// 🔵 На экране находится список карточек с заголовком, который изначально немного перекрывает верхнюю половину.
// 🔵 Есть кнопки добавления / удаления элементов списка, минимальное количество карточек — одна.
// 🔵 Когда список достигает низа экрана, он начинает расти вверх и все больше перекрывает верхнюю половину экрана, но не полностью.
// 🔵 Когда список становится максимальной высоты, его элементы скроллятся внутри.
// 🔵 Главное — адаптивность списка. Анимация, рандомные иконки и прочее — для разнообразия.
// 🔵 Всё должно запускаться в DartPad.

/// Виджет, который позволяет добавлять и удалять элементы списка
/// при это визально спиоск либо растет по количеству элементов (до максимального значения)
/// либо уменьшается до минимального значения
class MultiChildExample extends StatefulWidget {
  const MultiChildExample({super.key});

  @override
  State<MultiChildExample> createState() => _MultiChildExampleState();
}

class _MultiChildExampleState extends State<MultiChildExample> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _duration = const Duration(milliseconds: 200);
  final _cards = <_Card>[];

  @override
  void initState() {
    super.initState();
    _cards.addAll([for (var i = 0; i < 3; i++) _getCard(i)]);
  }

  _Card _getCard(int index) {
    final iconCodePoint = 58000 + math.Random().nextInt(1000);
    return _Card(index: index, iconCodePoint: iconCodePoint);
  }

  void _addItem() {
    final nextIndex = _cards.length;
    final newCard = _getCard(nextIndex);
    _cards.insert(nextIndex, newCard);
    _listKey.currentState!.insertItem(
      nextIndex,
      duration: _duration,
    );
  }

  void _removeItem() {
    if (_cards.length <= 2) return;

    final lastIndex = _cards.length - 1;
    final lastCard = _cards[lastIndex];
    _listKey.currentState!.removeItem(
      lastIndex,
      duration: _duration,
          (_, animation) => SizeTransition(
        sizeFactor: animation,
        child: lastCard,
      ),
    );
    _cards.removeAt(lastIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomMultiChildLayout(
        delegate: _MultiChildExampleDelegate(
          minOverlap: 0.1,
          maxOverlap: 0.7,
        ),
        children: [
          LayoutId(
            id: _Widget.backgroundImage,
            child: const ColoredBox(color: Colors.redAccent),
          ),
          LayoutId(
            id: _Widget.cardsList,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.all(16),
                  primary: false,
                  shrinkWrap: true,
                  initialItemCount: _cards.length,
                  itemBuilder: (_, index, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: _cards[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.yellow,
              onPressed: () => _addItem(),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              backgroundColor: Colors.yellow,
              onPressed: () => _removeItem(),
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final int index;
  final int iconCodePoint;

  const _Card({required this.index, required this.iconCodePoint});

  @override
  Widget build(BuildContext context) {
    final card = index == 0
        ? const Center(
      child: Text(
        'Surf UI Quiz #1',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Card $index'),
        index == 1
            ? const Icon(Icons.flutter_dash)
            : Icon(IconData(iconCodePoint, fontFamily: 'MaterialIcons')),
      ],
    );

    return SizedBox(
      height: 40,
      child: Center(child: card),
    );
  }
}

class _MultiChildExampleDelegate extends MultiChildLayoutDelegate {
  /// Коэффициент минимального перекрытия виджета фона виджетом списка.
  final double minOverlap;

  /// Коэффициент максимального перекрытия виджета фона виджетом списка.
  final double maxOverlap;

  _MultiChildExampleDelegate({
    required this.minOverlap,
    required this.maxOverlap,
  })  : assert(minOverlap >= 0.0 && minOverlap <= 1.0),
        assert(maxOverlap >= 0.0 && maxOverlap <= 1.0),
        assert(minOverlap < maxOverlap);

  @override
  void performLayout(Size size) {
    // Задаем ограничения для виджета фона.
    // Высота равна половине доступной от родителя высоты, в нашем случае половине высоты всего экрана.
    final backgroundImageMaxHeight = size.height / 2;
    final backgroundImageSize = Size(size.width, backgroundImageMaxHeight);
    layoutChild(
      _Widget.backgroundImage,
      BoxConstraints.tight(backgroundImageSize),
    );

    // Задаем ограничения для виджета списка.
    // Максимальная высота определяется коэффициентом максимального перекрытия виджета фона.
    final cardsListSize = Size(
      size.width,
      backgroundImageMaxHeight * (1 + maxOverlap),
    );
    final cardsListLayout = layoutChild(
      _Widget.cardsList,
      BoxConstraints.loose(cardsListSize),
    );

    // Определяем смещение виджета списка.
    // Тут мы смотрим на минимальное значение между двух величин:
    // - offsetDependsOnMinOverlap — это смещение, которое зависит от коэффициента минимального
    // перекрытия и оно будет меньше, когда список маленький.
    // - offsetDependsOnCardListHeight — это смещение, которое зависит от высоты списка и оно
    // будет меньше, когда список будет расти.
    //
    // Т.е. поведение списка (растет вверх или вниз) определяется пересчетом и сравнением указанных
    // величин.
    final offsetDependsOnMinOverlap = backgroundImageMaxHeight * (1 - minOverlap);
    final offsetDependsOnCardListHeight = size.height - cardsListLayout.height;
    positionChild(
      _Widget.cardsList,
      Offset(
        0,
        math.min(offsetDependsOnMinOverlap, offsetDependsOnCardListHeight),
      ),
    );
  }

  @override
  bool shouldRelayout(covariant _MultiChildExampleDelegate oldDelegate) {
    return oldDelegate.minOverlap != minOverlap || oldDelegate.maxOverlap != maxOverlap;
  }
}

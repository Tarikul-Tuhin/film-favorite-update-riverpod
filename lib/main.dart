import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;
  const Film({
    required this.id,
    required this.title,
    required this.description,
    required this.isFavorite,
  });

  Film copy({required bool isFavoriteCopy}) => Film(
      id: id,
      title: title,
      description: description,
      isFavorite: isFavoriteCopy);

  @override
  String toString() => 'Film(id: $id, '
      'title: $title, '
      'description: $description, '
      'isFavorite: $isFavorite)';

  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([id, isFavorite]);
}

const allFilms = [
  Film(
      id: '1',
      title: 'Shashank Redemption',
      description: 'Imdb highest rated',
      isFavorite: false),
  Film(
      id: '2',
      title: 'Bhoot Nath',
      description: 'Bhoot Funny KBC',
      isFavorite: false),
  Film(id: '3', title: 'Titinic', description: 'Love life', isFavorite: false),
  Film(id: '4', title: 'Wall Street', description: 'Talent', isFavorite: false),
  Film(
      id: '5',
      title: 'Night of Champions',
      description: 'Fighting',
      isFavorite: false),
];

class FilmsNotifier extends StateNotifier<List<Film>> {
  FilmsNotifier() : super(allFilms);

  void update(Film film, bool isFavorite) {
    state = state
        .map((thisFilm) => thisFilm.id == film.id
            ? thisFilm.copy(isFavoriteCopy: isFavorite)
            : thisFilm)
        .toList();
  }
}

enum FavoriteStatus {
  all,
  favorite,
  notFavorite,
}

final favoriteStatusProvider =
    StateProvider<FavoriteStatus>((ref) => FavoriteStatus.all);

final allFilmsProvider = StateNotifierProvider<FilmsNotifier, List<Film>>(
    ((ref) => FilmsNotifier()));

final favoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => film.isFavorite),
);

final notFavoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => !film.isFavorite),
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Films'),
      ),
      body: Column(children: [
        const DropDownWidget(),
        Consumer(
          builder: (context, ref, child) {
            print('re-render');
            final filter = ref.watch(favoriteStatusProvider);
            switch (filter) {
              case FavoriteStatus.all:
                return FilmsList(provider: allFilmsProvider);
              case FavoriteStatus.favorite:
                return FilmsList(provider: favoriteFilmsProvider);
              case FavoriteStatus.notFavorite:
                return FilmsList(provider: notFavoriteFilmsProvider);
            }
          },
        )
      ]),
    );
  }
}

class FilmsList extends ConsumerWidget {
  AlwaysAliveProviderBase<Iterable<Film>> provider;
  FilmsList({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('re-render filmList');

    final films = ref.watch(provider);
    print(films.toString());
    return Expanded(
      child: ListView.builder(
        itemCount: films.length,
        itemBuilder: ((context, index) {
          final film = films.elementAt(index);
          final favoriteIcon = film.isFavorite
              ? const Icon(Icons.favorite)
              : const Icon(Icons.favorite_border);

          return ListTile(
            title: Text(film.title),
            subtitle: Text(film.description),
            trailing: IconButton(
              icon: favoriteIcon,
              onPressed: () {
                final isFavorite = !film.isFavorite;
                ref.read(allFilmsProvider.notifier).update(film, isFavorite);
              },
            ),
          );
        }),
      ),
    );
  }
}

class DropDownWidget extends StatelessWidget {
  const DropDownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DropdownButton(
          value: ref.watch(
              favoriteStatusProvider), // when a state change it will get the value
          items: FavoriteStatus.values
              .map(
                (fs) => DropdownMenuItem(
                  value: fs,
                  child: Text(fs
                      .toString()
                      .split('.')
                      .last), // it will show the value like ui part
                ),
              )
              .toList(),

          onChanged: (FavoriteStatus? value) {
            ref.read(favoriteStatusProvider.notifier).state =
                value!; // FavouriteStatus.favorite or FavoriteStatus.all or FavoriteStatus.notFavorite
          }, // change the value
        );
      },
    );
  }
}

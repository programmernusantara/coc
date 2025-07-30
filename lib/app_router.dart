import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/login_page.dart';
import 'presentation/home_page.dart';
import 'presentation/game_1/number_game_page.dart';
import 'presentation/result_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          final userData = state.extra as Map<String, dynamic>;
          return HomePage(userData: userData);
        },
      ),
      GoRoute(
        path: '/number-game',
        name: 'number-game',
        builder: (context, state) {
          final userData = state.extra as Map<String, dynamic>;
          return NumberGamePage(userData: userData);
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ResultPage(
            isCorrect: args['isCorrect'],
            userData: args['userData'],
            gameType: args['gameType'],
            score: args['score'],
          );
        },
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/user_session.dart';

// Import Screens (Placeholder shells)
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/profile_screen.dart';
import '../../features/user_sos/sos_screen.dart';
import '../../features/user_sos/nearby_incidents_page.dart';
import '../../features/volunteer/volunteer_dashboard.dart';
import '../../features/volunteer/incident_map_route.dart';

final appRouterPrv = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard/user',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/dashboard/user/nearby',
        builder: (context, state) => const NearbyIncidentsPage(),
      ),
      GoRoute(
        path: '/dashboard/volunteer',
        builder: (context, state) => const VolunteerDashboard(),
      ),
      GoRoute(
        path: '/dashboard/volunteer/map',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final incidentId = extra?['incidentId'] as String? ?? '';
          return IncidentMapRoute(incidentId: incidentId);
        },
      ),
    ],
    // Redirect logic to enforce session state
    redirect: (context, state) {
      final isLoggedIn = UserSession.current != null;
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }
      
      if (isLoggedIn && isGoingToAuth) {
        final role = UserSession.current?['role'] as String? ?? 'User';
        if (role == 'Volunteer') {
          return '/dashboard/volunteer';
        } else {
          return '/dashboard/user';
        }
      }
      return null;
    },
  );
});
